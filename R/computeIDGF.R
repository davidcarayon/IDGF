#' Calcul de l'IDGF
#'
#' Cette fonction procède au calcul des différentes métriques constitutives de l'IDGF puis à l'évaluation de l'état écologique en se basant sur différentes tables de référence internes et sur l'indication de l'HER dans les données d'entrée.
#' @param IDGFdata Données importées par `importIDGF()`
#'
#' @return Renvoie un tableau présentant l'ensemble des résultats (score par métrique, évaluation de l'état écologique, statistiques sur les taxons indiciels/halins/inconnus)
#' @importFrom magrittr %>%
#' @export
#'
#' @examples
#' library(IDGF)
#' data <- system.file("input_test.xlsx", package = "IDGF")
#' IDGFdata <- importIDGF(data)
#' IDGFres <- computeIDGF(IDGFdata)
#' head(IDGFres)
computeIDGF <- function(IDGFdata){

  df_standard <- IDGFdata$dataset


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
    dplyr::inner_join(IDGFdata$metadata, by = "sample")


  tab_indiciel <- metrique_calc %>%
    dplyr::select(sample,indiciel,halin) %>%
    unique() %>%
    dplyr::mutate(`fiabilité` = dplyr::case_when(indiciel < 300  ~ "Indice non valide, augmenter la pression de comptage",
                                                 indiciel >= 300 & indiciel < 360 ~ "Fiabilité : réduite",
                                                 indiciel >= 360 ~ "Fiabilité : satisfaisante"))


  metriques <- metrique_calc %>%
    dplyr::group_by(sample,her,param) %>%
    dplyr::mutate(EQR = purrr::pmap_dbl(.l = list(value,her,param), .f = Metric2EQR)) %>% # Renvoie metrique/ref
    dplyr::ungroup() %>%
    dplyr::select(sample,param,EQR) %>%
    tidyr::spread(key = param, value = EQR) %>%
    dplyr::mutate_at(dplyr::vars(MES:SAT),round,2)


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
    dplyr::inner_join(metriques, by = "sample") %>%
    dplyr::inner_join(tab_indiciel, by = "sample") %>%
    dplyr::mutate(indiciel = ifelse(indiciel > 400, yes = 400, no = indiciel)) %>%
    dplyr::mutate(halin = round(halin / 400 * 100,2),
                  indiciel = round(indiciel / 400 * 100,2)) %>%

    dplyr::left_join(IDGFdata$taxons_missing, by = "sample") %>%
    dplyr::left_join(IDGFdata$taxons_halins, by = "sample") %>%
    dplyr::mutate_at(dplyr::vars(IDGF,class:SAT,Taxons_inconnus,Taxons_halins),
                     dplyr::funs(ifelse(is.na(.), "", .))) %>%
    dplyr::select(id_releve = sample,pourcentage_indiciels = indiciel,pourcentage_halins = halin, MES:SAT,IDGF,NumClasse = numclass, Classe = class, `fiabilité`, Taxons_halins,Taxons_inconnus) %>%
    dplyr::rename("MINE."="MINER","SAT.O2"="SAT","Mat.Orga"="MORGA","P-Trophie"="PTROPHIE","N-Orga"="NORG")


  return(note_finale)


}
