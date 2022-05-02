#' Export des résultats et graphiques issus de l'IDGF
#'
#' Cette fonction permet de sauvegarder les résultats issus de l'applicatif IDGF sous forme de tableau (.csv) et de graphiques (.png) dans un répertoire défini par l'utilisateur.
#'
#' @param IDGFres Résultats IDGF issus de `computeIDGF()` ou `radarIDGF()`
#' @param outdir Dossier de destination des fichiers, à définir par l'utilisateur
#'
#' @return Les résultats sont exportés dans le dossier défini par l'utilisateur
#' @importFrom magrittr %>%
#' @export
#'
#' @examples
#' library(IDGF)
#' data <- system.file("input_test.xlsx", package = "IDGF")
#' IDGFdata <- importIDGF(data)
#' IDGFres <- computeIDGF(IDGFdata)
#' IDGFresrad <- radarIDGF(IDGFres)
#' exportIDGF(IDGFresrad, outdir = "sorties")
exportIDGF <- function(IDGFres, outdir = paste0("RES_",Sys.Date())){


  if(!dir.exists(outdir)) {dir.create(outdir, recursive = TRUE)}

  s.time <- paste0(strsplit(as.character(Sys.time())," ")[[1]],collapse = "_")
  time <- Sys.Date()

  write.csv2(IDGFres %>% dplyr::select(1:16),paste0(outdir,"/resultats_idgf_",time,".csv"), row.names = FALSE)

  ## Sortie des graphiques si ils sont présent dans le tableau de résultat
  if(ncol(IDGFres) == 17) {

    output <- file.path(outdir,"Graphiques_diagnostic")

    if(!dir.exists(output)) {dir.create(output, recursive = TRUE)}

    tab_res <- IDGFres %>% dplyr::select(id_releve,plot) %>%
      dplyr::mutate(path = file.path(output,id_releve)) %>%
      dplyr::mutate(png_path = glue::glue("{path}.png"))


    export_plot <- function(id_releve,plot,png_path) {

      print(plot) %>%
        ggplot2::ggsave(filename=png_path,dpi = "retina", width = 7.62, height = 6.48)
    }

    purrr::pwalk(.l = list(tab_res$id_releve,tab_res$plot,tab_res$png_path), .f = export_plot)


  }

}
