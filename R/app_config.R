#' Accès aux fichiers du package
#'
#' Équivalent de `system.file(..., package = "IDGF")`, fonctionne aussi avec
#' `pkgload::load_all()`.
#'
#' @param ... Chemin relatif au dossier `inst/`
#' @noRd
app_sys <- function(...) {
  system.file(..., package = "IDGF")
}


#' Lecture de la configuration de l'application (inst/golem-config.yml)
#'
#' @param value Valeur à lire
#' @param config Configuration à utiliser (variable d'environnement
#'   `GOLEM_CONFIG_ACTIVE`, sinon `R_CONFIG_ACTIVE`, sinon "default")
#' @param use_parent Chercher le fichier dans les dossiers parents
#' @param file Fichier de configuration
#' @noRd
get_golem_config <- function(
  value,
  config = Sys.getenv(
    "GOLEM_CONFIG_ACTIVE",
    Sys.getenv("R_CONFIG_ACTIVE", "default")
  ),
  use_parent = TRUE,
  file = app_sys("golem-config.yml")
) {
  config::get(
    value = value,
    config = config,
    file = file,
    use_parent = use_parent
  )
}
