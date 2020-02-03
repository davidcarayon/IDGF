#' Run the shiny App
#'
#' @importFrom magrittr %>%
#' @export
runIDGFTool <- function() {
  appDir <- system.file("myApp", package = "IDGF")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `IDGF`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
