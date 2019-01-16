#' Indice Diatomique de Guyane Française
#'
#' Calcule l'indice IDGF à partir d'une ou plusieurs listes floristiques
#' @param df Le tableau contenant la liste floristique, composé de 4 colonnes (dans cet ordre) : id_releve, cd_taxon, abondance, her (1 ou 2)
#' @param lang Argument acceptant deux valeurs : "FR" pour obtenir des résultats en français, "ENG" pour obtenir des résultats en anglais
#'
#' @return Une liste

#'
#' @examples
#' taxa.GF
#' IDGF(taxa, lang = "FR")
#'
#' @export
#'
IDGF <- function(df, lang = "FR") {

  print("1/4 : Vérification des données")
  Sys.sleep(0.5)


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
  print("2/4 : Standardisation et transcodage")
  Sys.sleep(0.5)

names(df) <- c("sample","cd_taxon","abondance","her")

tab_her <- df %>% dplyr::select(sample,her) %>% dplyr::distinct()

missing <- df$cd_taxon[!df$cd_taxon %in% transcode$code]

if(length(missing)>0) {
  warning(paste0("Les taxons",missing,"Ne sont pas répertoriés et ne sont pas pris en compte"))
}

df_standard <- df %>%
  dplyr::left_join(transcode, by = c("cd_taxon"="code")) %>%
  dplyr::select(-cd_taxon) %>%
  dplyr::group_by(sample,code_ref) %>%
  dplyr::summarise(abondance = sum(abondance, na.rm=TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(sample) %>%
  dplyr::mutate(n_valves = sum(abondance)) %>%
  dplyr::ungroup() %>%
  dplyr::rowwise() %>%
  dplyr::mutate(abondance = round(abondance / n_valves * 400)) %>%
  dplyr::ungroup() %>%
  dplyr::select(sample,cd_taxon = code_ref,abondance)

# Calcul des métriques et de l'IDGF (divisé en 2?)

  print("3/4 : Calcul des métriques brutes")
  Sys.sleep(0.5)

metrique_calc <-  df %>%
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
  tidyr::gather(key = param, value = value, -sample:-indiciel) %>%
  dplyr::inner_join(tab_her, by = "sample") %>%
  dplyr::mutate(value = ifelse(indiciel < 300, yes = NA, no = value))



if (lang == "FR") {
tab_indiciel <- metrique_calc %>%
  dplyr::select(sample,indiciel) %>%
  unique() %>%
  dplyr::mutate(`fiabilité` = dplyr::case_when(indiciel < 300 ~ "Indice non calculable, augmenter la pression d'échantillonnage",
                                 indiciel >= 300 & indiciel < 360 ~ "Indice à fiabilité réduite",
                                 indiciel >= 360 ~ "Indice fiable"))}


if (lang == "ENG") {
  tab_indiciel <- metrique_calc %>%
    dplyr::select(sample,indiciel) %>%
    unique() %>%
    dplyr::mutate(reliability = dplyr::case_when(indiciel < 300 ~ "Non-calculable index, sampling effort must be increased",
                                                      indiciel >= 300 & indiciel < 360 ~ "Index with reduced reliability",
                                                      indiciel >= 360 ~ "Reliable index"))}


metriques <- metrique_calc %>%
  dplyr::group_by(sample,her,param) %>%
  dplyr::mutate(EQR = purrr::pmap_dbl(.l = list(value,her,param), .f = Metric2EQR)) %>% # Renvoie metrique/ref
  dplyr::ungroup() %>%
  dplyr::select(sample,param,EQR) %>%
  tidyr::spread(key = param, value = EQR)

print("4/4 : Calcul de l'IDGF et aggrégation")
Sys.sleep(0.5)

if(lang == "FR") {

note_finale <- metrique_calc %>%
  dplyr::group_by(sample,her,param) %>%
  dplyr::mutate(EQR = purrr::pmap_dbl(.l = list(value,her,param), .f = Metric2EQR)) %>% # Renvoie metrique/ref
  dplyr::ungroup() %>%
  dplyr::group_by(sample) %>%
  dplyr::summarise(IDGF = mean(EQR)) %>% # Note IDGF = moyenne des EQR
  dplyr::ungroup() %>%
  dplyr::mutate(IDGF = model_IDGF(IDGF)) %>%
  dplyr::mutate(class = Ratio2Class(IDGF,boundaries = c(0.22,0.44,0.66,0.88),number = FALSE,language = "FR"),
                numclass = Ratio2Class(IDGF,boundaries = c(0.22,0.44,0.66,0.88),number = TRUE,language = "FR")) %>%
  dplyr::mutate(class = factor(class,levels = c("Très bon" , "Bon" ,"Moyen" , "Médiocre" , "Mauvais"))) %>%
  dplyr::inner_join(metriques, by = "sample") %>%
  dplyr::inner_join(tab_indiciel, by = "sample")

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
    dplyr::mutate(class = Ratio2Class(IDGF,boundaries = c(0.22,0.44,0.66,0.88),number = FALSE,language = "ENG"),
                  numclass = Ratio2Class(IDGF,boundaries = c(0.22,0.44,0.66,0.88),number = TRUE,language = "ENG")) %>%
    dplyr::mutate(class = factor(class,levels = c("High" , "Good" ,"Moderate" , "Bad" , "Poor"))) %>%
    dplyr::inner_join(metriques, by = "sample") %>%
    dplyr::inner_join(tab_indiciel, by = "sample")

}

if(lang=="FR") {
note_export <-
  note_finale %>%
  dplyr::select(id_releve = sample, MES:SAT,IDGF,NumClasse = numclass, Classe = class, `fiabilité`)}

if(lang=="ENG") {
  note_export <-
    note_finale %>%
    dplyr::select(id_sample = sample, MES:SAT,IDGF,NumClass = numclass, Class = class, reliability)}


return(note_export)

}



