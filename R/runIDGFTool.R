#' Applicatif simplifié IDGF (ancien nom)
#'
#' Conservée pour compatibilité avec les versions 2.x du package : lance
#' désormais l'application golem via [run_app()].
#' @param ... Arguments transmis à [run_app()]
#' @export
#' @examples
#' library(IDGF)
#' # runIDGFTool()
runIDGFTool <- function(...) {
  run_app(...)
}
