#' Interface utilisateur de l'application
#'
#' @param request Paramètre interne de Shiny (bookmarking)
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    golem_add_external_resources(),
    bslib::page_navbar(
      id = "nav",
      title = shiny::tags$span(
        class = "idgf-marque",
        shiny::tags$img(src = "www/idgf_logo.png", alt = "Logo IDGF"),
        shiny::tags$span(class = "idgf-marque-texte", "IDGF")
      ),
      window_title = "IDGF – Indice Diatomique de Guyane Française",
      theme = theme_idgf(),
      padding = 0,
      gap = 0,
      fillable = FALSE,
      lang = "fr",
      bslib::nav_panel("Accueil", value = "accueil", icon = shiny::icon("leaf"),
                       mod_accueil_ui("accueil")),
      bslib::nav_panel("La méthode", value = "methode", icon = shiny::icon("microscope"),
                       mod_methode_ui("methode")),
      bslib::nav_panel("Calculer l'IDGF", value = "outil", icon = shiny::icon("calculator"),
                       mod_outil_ui("outil")),
      bslib::nav_panel("Références", value = "references", icon = shiny::icon("book-open"),
                       mod_references_ui("references")),
      bslib::nav_spacer(),
      bslib::nav_item(
        shiny::tags$a(
          class = "btn btn-sm idgf-btn-nav",
          href = "#", `data-goto` = "outil",
          shiny::icon("play"), " Lancer l'outil"
        )
      ),
      footer = pied_de_page()
    )
  )
}


#' Pied de page commun à tous les onglets
#' @noRd
pied_de_page <- function() {
  shiny::tags$footer(
    class = "idgf-pied",
    svg_fleuve(classe = "idgf-pied-vague"),
    shiny::div(
      class = "container idgf-pied-contenu",
      shiny::div(
        shiny::tags$strong("IDGF"), " – Indice Diatomique de Guyane Française",
        shiny::br(),
        shiny::tags$small(
          "INRAE – UR EABX, Bordeaux. Application libre sous licence GPL-3. ",
          paste0("Version ", utils::packageVersion("IDGF"), ".")
        )
      ),
      shiny::div(
        class = "idgf-pied-liens",
        shiny::tags$a(href = lien_publi(), target = "_blank", rel = "noopener",
                      shiny::icon("file-lines"), " Publication"),
        shiny::tags$a(href = "https://hydrobio-dce.inrae.fr/", target = "_blank", rel = "noopener",
                      shiny::icon("water"), " Hydrobio-DCE"),
        shiny::tags$a(href = "https://github.com/davidcarayon/IDGF", target = "_blank", rel = "noopener",
                      shiny::icon("code"), " Code source")
      )
    )
  )
}


#' Ressources externes (CSS compilé par bslib, JavaScript, favicon)
#'
#' @noRd
golem_add_external_resources <- function() {
  golem::add_resource_path("www", app_sys("app/www"))

  shiny::tags$head(
    golem::favicon(ico = "www/idgf_logo.png", ext = "png"),
    shiny::tags$meta(name = "description",
                     content = "Indice Diatomique de Guyane Française : méthode et outil de calcul"),
    shiny::tags$script(src = "www/idgf.js")
  )
}
