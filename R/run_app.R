#' Lancer l'application IDGF
#'
#' Lance l'application Shiny de l'IDGF : présentation de la méthode, référence
#' bibliographique et outil de calcul (import, résultats, diagrammes, export).
#'
#' @param onStart,options,enableBookmarking,uiPattern Voir [shiny::shinyApp()]
#' @param ... Options transmises à l'application (lues par `golem::get_golem_options()`)
#' @export
#' @examples
#' # IDGF::run_app()
run_app <- function(
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  uiPattern = "/",
  ...
) {
  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}
