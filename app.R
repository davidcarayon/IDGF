# Lancement de l'application IDGF (point d'entrée pour SK8, shinyapps, Posit Connect)
# Ce fichier est utilisé par la plateforme de déploiement : ne pas le supprimer.
# Pour lancer en local pendant le développement, préférer dev/run_dev.R.

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
IDGF::run_app()
