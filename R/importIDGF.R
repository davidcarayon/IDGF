#' Import des données
#'
#' @param input Le nom du fichier de données à importer (ou un chemin)
#'
#' @return une liste
#' @importFrom magrittr %>%
#' @export
#'
#' @examples
importIDGF <- function(input){

  filetype <- tools::file_ext(input)

  if(filetype %in% c("xls","xlsx")) {

    df <- suppressWarnings(readxl::read_excel(input))

  } else if (filetype == "csv") {

    df <- suppressWarnings(readr::read_csv2(input) %>% dplyr::select(-X1))

  } else {stop("Merci d'utiliser un fichier d'entrée au format .xls, .xlsx ou .csv")}


  # Test unitaires

  if(ncol(df) != 4) {
    stop('l\'argument df a besoin d\'un tableau avec 4 colonnes précisément : id_releve, cd_taxon, abondance, her (1 ou 2)')
  }

  # Standardisation (transcodage + abondance)

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

    newlines <- suppressWarnings(taxons_missing %>%
                                   dplyr::select(cd_taxon = Taxons_inconnus) %>%
                                   dplyr::bind_rows(table_metrics) %>%
                                   dplyr::mutate_at(dplyr::vars(indiciel:NH4),
                                                    dplyr::funs(ifelse(is.na(.), 0, .))))
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


  res <- list(dataset = df_standard, metadata = tab_her, taxons_missing = taxons_missing, taxons_halins = taxons_halins)

  return(res)

}
