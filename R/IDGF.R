#' Indice Diatomique de Guyane Française
#'
#' Calcule l'indice IDGF à partir d'une ou plusieurs listes floristiques
#' @param df Le tableau contenant la liste floristique, composé de 4 colonnes (dans cet ordre) : id_releve, cd_taxon, abondance, her (1 pour la plaine littorale ou 2 pour le bouclier Guyanais)
#' @param lang Argument acceptant deux valeurs : "FR" pour obtenir des résultats en français, "ENG" pour obtenir des résultats en anglais
#'
#' @return Tableau des résultats

#'
#' @examples
#' head(taxa.GF)
#' taxa <- taxa.GF
#' IDGF(taxa, lang = "FR")
#' @importFrom magrittr %>%
#' @importFrom stats na.omit
#' @export
#'
IDGF <- function(df, lang = "FR") {

  cat("1/4 : Vérification des données\n")


# Test unitaires

  if(sum(!class(df) %in% c("tbl_df","tbl","data.frame")) > 0) {
    stop('df doit être un dataframe ou un tibble')
  }

  if(!lang %in% c("FR","ENG")){
    stop('lang n\'accepte que deux valeurs : "FR" ou "ENG"')
  }

  if(ncol(df) != 4) {
    stop('l\'argument df a besoin d\'un tableau avec 4 colonnes précisément : id_releve, cd_taxon, abondance, her (1 ou 2)')
  }

# Standardisation (transcodage + abondance)
  cat("2/4 : Standardisation et transcodage\n")

names(df) <- c("sample","cd_taxon","abondance","her")
if(is.factor(df$cd_taxon)) {df$cd_taxon = as.character(df$cd_taxon)}

tab_her <- df %>% dplyr::select(sample,her) %>% dplyr::distinct()

taxons_missing<- subset(df, !(cd_taxon %in% table_metrics$cd_taxon)) %>%
  dplyr::group_by(sample) %>%
  dplyr::summarise(Taxons_inconnus = paste(cd_taxon,collapse = ","))

taxons_halins <- subset(df, cd_taxon %in% subset(table_metrics,halin == 1)$cd_taxon) %>%
  dplyr::group_by(sample) %>%
  dplyr::summarise(Taxons_halins = paste(cd_taxon,collapse = ","))


# Ajout des taxons manquants
if(nrow(taxons_missing>0)) {

  newlines <- taxons_missing %>%
    dplyr::select(cd_taxon = Taxons_inconnus) %>%
    dplyr::bind_rows(table_metrics) %>%
    dplyr::mutate_at(dplyr::vars(indiciel:NH4),
              dplyr::funs(ifelse(is.na(.), 0, .)))
}


df_standard <- df %>%
  dplyr::left_join(transcode, by = c("cd_taxon"="code")) %>%
  dplyr::select(-cd_taxon) %>%
  dplyr::group_by(sample,IDGF_v1) %>%
  dplyr::summarise(abondance = sum(abondance, na.rm=TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(sample) %>%
  dplyr::mutate(n_valves = sum(abondance)) %>%
  dplyr::ungroup() %>%
  dplyr::rowwise() %>%
  dplyr::mutate(abondance = round(abondance / n_valves * 400)) %>%
  dplyr::ungroup() %>%
  dplyr::select(sample,cd_taxon = IDGF_v1,abondance)

# Calcul des métriques et de l'IDGF (divisé en 2?)

  cat("3/4 : Calcul des métriques brutes\n")

metrique_calc <-  df_standard %>%
  dplyr::inner_join(table_metrics, by = "cd_taxon") %>%
  dplyr::mutate_at(.vars = dplyr::vars(indiciel:NH4),.funs = dplyr::funs(.*abondance)) %>%
  dplyr::group_by(sample) %>%
  dplyr::summarise_at(dplyr::vars(indiciel:NH4),sum) %>%
  dplyr::mutate_at(.vars = dplyr::vars(MINER:NH4),.funs=dplyr::funs(1-./indiciel)) %>%
  dplyr::ungroup() %>%
  dplyr::rowwise() %>%
  dplyr:: mutate(MORGA = min(COT,DBO5,DCO),
         PTROPHIE = min(PO4,PTOT),
         NORG = min(NK,NH4)) %>%
  dplyr::ungroup() %>%
  dplyr::select(-COT:-DCO,-NK,-NH4,-PO4,-PTOT) %>%
  tidyr::gather(key = param, value = value, -sample:-indiciel,-halin) %>%
  dplyr::inner_join(tab_her, by = "sample") %>%
  dplyr::mutate(value = ifelse(indiciel < 300, yes = NA, no = value))



if (lang == "FR") {
tab_indiciel <- metrique_calc %>%
  dplyr::select(sample,indiciel,halin) %>%
  unique() %>%
  dplyr::mutate(`fiabilité` = dplyr::case_when(indiciel < 300  ~ "Indice non calculable, augmenter la pression de comptage",
                                 indiciel >= 300 & indiciel < 360 ~ "Indice à fiabilité réduite",
                                 indiciel >= 360 ~ "Indice fiable"))
  }



if (lang == "ENG") {
  tab_indiciel <- metrique_calc %>%
    dplyr::select(sample,indiciel,halin) %>%
    unique() %>%
    dplyr::mutate(reliability = dplyr::case_when(indiciel < 300 ~ "Non-calculable index, counting effort must be increased",
                                                 indiciel >= 300 & indiciel < 360 ~ "Index with reduced reliability",
                                                 indiciel >= 360 ~ "Reliable index"))
  }


metriques <- metrique_calc %>%
  dplyr::group_by(sample,her,param) %>%
  dplyr::mutate(EQR = purrr::pmap_dbl(.l = list(value,her,param), .f = Metric2EQR)) %>% # Renvoie metrique/ref
  dplyr::ungroup() %>%
  dplyr::select(sample,param,EQR) %>%
  tidyr::spread(key = param, value = EQR) %>%
  dplyr::mutate_at(dplyr::vars(MES:SAT),round,2)

cat("4/4 : Calcul de l'IDGF et aggrégation\n")

if(lang == "FR") {

note_finale <- metrique_calc %>%
  dplyr::group_by(sample,her,param) %>%
  dplyr::mutate(EQR = purrr::pmap_dbl(.l = list(value,her,param), .f = Metric2EQR)) %>% # Renvoie metrique/ref
  dplyr::ungroup() %>%
  dplyr::group_by(sample) %>%
  dplyr::summarise(IDGF = mean(EQR)) %>% # Note IDGF = moyenne des EQR
  dplyr::ungroup() %>%
  dplyr::mutate(IDGF = model_IDGF(IDGF)) %>%
  dplyr::mutate(IDGF = round(IDGF,2)) %>%
  dplyr::mutate(class = Ratio2Class(IDGF,boundaries = c(0.25,0.50,0.75,0.88),number = FALSE,language = "FR"),
                numclass = Ratio2Class(IDGF,boundaries = c(0.25,0.50,0.75,0.88),number = TRUE,language = "FR")) %>%
  dplyr::mutate(class = factor(class,levels = c("Très bon" , "Bon" ,"Moyen" , "Médiocre" , "Mauvais"))) %>%
  dplyr::inner_join(metriques, by = "sample") %>%
  dplyr::inner_join(tab_indiciel, by = "sample") %>%
  dplyr::mutate(indiciel = ifelse(indiciel > 400, yes = 400, no = indiciel)) %>%
  dplyr::mutate(halin = round(halin / 400 * 100,2),
                indiciel = round(indiciel / 400 * 100,2)) %>%

  dplyr::left_join(taxons_missing, by = "sample") %>%
  dplyr::left_join(taxons_halins, by = "sample") %>%
  dplyr::mutate_at(dplyr::vars(IDGF,class:SAT,Taxons_inconnus,Taxons_halins),
                   dplyr::funs(ifelse(is.na(.), "", .)))


}

if(lang == "ENG") {

  note_finale <- metrique_calc %>%
    dplyr::group_by(sample,her,param) %>%
    dplyr::mutate(EQR = purrr::pmap_dbl(.l = list(value,her,param), .f = Metric2EQR)) %>% # Renvoie metrique/ref
    dplyr::ungroup() %>%
    dplyr::group_by(sample) %>%
    dplyr::summarise(IDGF = mean(EQR)) %>% # Note IDGF = moyenne des EQR
    dplyr::ungroup() %>%
    dplyr::mutate(IDGF = model_IDGF(IDGF)) %>%
    dplyr::mutate(IDGF = round(IDGF,2)) %>%
    dplyr::mutate(class = Ratio2Class(IDGF,boundaries = c(0.25,0.50,0.75,0.88),number = FALSE,language = "ENG"),
                  numclass = Ratio2Class(IDGF,boundaries = c(0.25,0.50,0.75,0.88),number = TRUE,language = "ENG")) %>%
    dplyr::mutate(class = factor(class,levels = c("High" , "Good" ,"Moderate" , "Bad" , "Poor"))) %>%
    dplyr::inner_join(metriques, by = "sample") %>%
    dplyr::inner_join(tab_indiciel, by = "sample") %>%
    dplyr::mutate(indiciel = ifelse(indiciel > 400, yes = 400, no = indiciel)) %>%
    dplyr::mutate(halin = halin / 400 * 100,
                  indiciel = indiciel / 400 * 100) %>%
    dplyr::left_join(taxons_missing, by = "sample") %>%
    dplyr::left_join(taxons_halins, by = "sample") %>%
    dplyr::mutate_at(dplyr::vars(IDGF,class:SAT,Taxons_inconnus,Taxons_halins),
                     dplyr::funs(ifelse(is.na(.), "", .)))
}

if(lang=="FR") {
note_export <-
  note_finale %>%
  dplyr::select(id_releve = sample,pourcentage_indiciels = indiciel,pourcentage_halins = halin, MES:SAT,IDGF,NumClasse = numclass, Classe = class, `fiabilité`, Taxons_halins,Taxons_inconnus)}

if(lang=="ENG") {
  note_export <-
    note_finale %>%
    dplyr::select(id_sample = sample,pourcentage_indiciels = indiciel,pourcentage_halins = halin, MES:SAT,IDGF,NumClass = numclass, Class = class, reliability, Haline_taxa = Taxons_halins,Unknown_taxa = Taxons_inconnus)}

cat(crayon::green("\u2713 Calcul de l'IDGF terminé\n"))

return(note_export)

}
