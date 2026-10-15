#' Import des données
#'
#'Cette fonction procède à l'import d'un fichier de données destiné au calcul de l'IDGF. Le tableau importé doit être composé de 4 colonnes (dans cet ordre) : id_releve, cd_taxon, abondance, her (1 pour la plaine littorale ou 2 pour le bouclier Guyanais). Les formats de fichier acceptés sont les formats excels (.xls et .xlsx) et le format .csv en veillant à utiliser le point-virgule comme séparateur et le point comme décimale.
#' @param input Le nom du fichier de données à importer (ou un chemin)
#'
#' @return Renvoie une liste à 4 éléments contenant (1) le jeu de données importé (2) les métadonnées relatives à l'HER (3) les taxons inconnus et (4) les taxons halins
#' @importFrom magrittr %>%
#' @export
#'
#' @examples
#' library(IDGF)
#' data <- system.file("input_test.xlsx", package = "IDGF")
#' IDGFdata <- importIDGF(data)
#' names(IDGFdata)
importIDGF <- function(input){

  filetype <- tolower(tools::file_ext(input))

  if(filetype %in% c("xls","xlsx")) {

    df <- suppressWarnings(readxl::read_excel(input))

  } else if (filetype == "csv") {

    # Une éventuelle colonne de numéros de ligne (export R/Excel) est ignorée
    df <- suppressWarnings(readr::read_csv2(input, show_col_types = FALSE)) %>%
      dplyr::select(-dplyr::any_of(c("X1", "...1")))

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
    dplyr::summarise(Taxons_inconnus = paste(cd_taxon,collapse = ","), .groups = "drop")

  taxons_halins <- subset(df, cd_taxon %in% subset(table_metrics,halin == 1)$cd_taxon) %>%
    dplyr::group_by(sample) %>%
    dplyr::summarise(Taxons_halins = paste(cd_taxon,collapse = ","), .groups = "drop")


  df_standard <- df %>%
    dplyr::left_join(transcode, by = c("cd_taxon"="code")) %>%
    dplyr::select(-cd_taxon) %>%
    dplyr::group_by(sample,IDGF_v1) %>%
    dplyr::summarise(abondance = sum(abondance, na.rm=TRUE), .groups = "drop") %>%
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
