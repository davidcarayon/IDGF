#' Applicatif simplifié IDGF
#'
#' Cette fonction exécute un applicatif développé via le package Rshiny pour proposer une interface graphique.
#' @importFrom magrittr %>%
#' @export
#' @examples
#' library(IDGF)
#' # runIDGFTool()
runIDGFTool <- function() {
  appDir <- system.file("myApp", package = "IDGF")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `IDGF`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
