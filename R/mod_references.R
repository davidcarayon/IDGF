#' Onglet « Références » : publication, rapport, package, contacts
#'
#' @param id Identifiant du module
#' @noRd
mod_references_ui <- function(id) {
  ns <- shiny::NS(id)

  citation_publi <- paste(
    "Carayon, D., Eulin-Garrigue, A., Vigouroux, R., & Delmas, F. (2020).",
    "A new multimetric index for the evaluation of water ecological quality of French Guiana streams",
    "based on benthic diatoms. Ecological Indicators, 113, 106248.",
    "https://doi.org/10.1016/j.ecolind.2020.106248"
  )
  citation_package <- sprintf(
    "Carayon, D. & Delmas, F. (2020). IDGF : Indice Diatomique de Guyane Française. Package R version %s.",
    utils::packageVersion("IDGF")
  )

  shiny::tagList(
    bandeau_page("Références", "Publication, rapport, code source et contacts", "book-open"),
    shiny::tags$section(
      class = "idgf-section",
      shiny::div(
        class = "container",
        shiny::div(
          class = "d-flex flex-column gap-4",

          # Publication de référence
          shiny::div(
            class = "idgf-carte idgf-reference principale reveal carte-lumiere",
            shiny::div(class = "idgf-carte-icone", shiny::icon("file-lines")),
            shiny::div(
              shiny::div(class = "idgf-surtitre", "Article scientifique de référence"),
              shiny::tags$h4("A new multimetric index for the evaluation of water ecological quality of French Guiana streams based on benthic diatoms"),
              shiny::tags$p(
                "Article qui décrit la construction de l'IDGF : jeu de données des réseaux de suivi guyanais, ",
                "sélection des taxons indiciels et d'alerte, calcul des métriques, définition des références ",
                "par hydroécorégion et validation de l'indice."
              ),
              bloc_citation(citation_publi),
              shiny::div(
                class = "idgf-boutons",
                shiny::tags$a(class = "btn idgf-btn-principal", href = lien_publi(),
                              target = "_blank", rel = "noopener",
                              shiny::icon("arrow-up-right-from-square"), " Lire l'article (DOI)")
              )
            )
          ),

          shiny::div(
            class = "idgf-grille-2",
            # Rapport final
            shiny::div(
              class = "idgf-carte idgf-reference reveal carte-lumiere",
              shiny::div(class = "idgf-carte-icone", shiny::icon("book")),
              shiny::div(
                shiny::div(class = "idgf-surtitre", "Rapport technique"),
                shiny::tags$h4("Évaluation de l'état écologique des cours d'eau de Guyane française"),
                shiny::tags$p(
                  "Carayon D., Eulin A., Vigouroux R. & Delmas F. (2019). L'Indice Diatomique pour la Guyane ",
                  "Française (IDGF) : rapport final."
                ),
                shiny::tags$a(class = "btn idgf-btn-verre-sombre", href = "https://hydrobio-dce.inrae.fr/",
                              target = "_blank", rel = "noopener",
                              shiny::icon("water"), " Espace Hydrobio-DCE")
              )
            ),
            # Package R
            shiny::div(
              class = "idgf-carte idgf-reference reveal carte-lumiere",
              shiny::div(class = "idgf-carte-icone", shiny::icon("r-project")),
              shiny::div(
                shiny::div(class = "idgf-surtitre", "Package R"),
                shiny::tags$h4("Calculer l'IDGF dans R"),
                shiny::tags$p("Les fonctions de cette application sont utilisables en script :"),
                shiny::tags$pre(
                  class = "idgf-formule text-start",
                  shiny::tags$code(
                    "remotes::install_github(\"davidcarayon/IDGF\")\n",
                    "res <- IDGF::importIDGF(\"fichier.xlsx\") |>\n",
                    "  IDGF::computeIDGF()"
                  )
                ),
                bloc_citation(citation_package),
                shiny::tags$a(class = "btn idgf-btn-verre-sombre", href = "https://github.com/davidcarayon/IDGF",
                              target = "_blank", rel = "noopener",
                              shiny::icon("code"), " Code source")
              )
            )
          )
        )
      )
    ),

    # Contacts
    shiny::tags$section(
      class = "idgf-section idgf-section-teinte",
      shiny::div(
        class = "container",
        titre_section("Contacts", "Une question sur l'outil ou sur l'interprétation des résultats ?"),
        shiny::div(
          class = "idgf-contacts reveal",
          contact("DC", "David Carayon", "david.carayon@inrae.fr"),
          contact("SB", "Sébastien Boutry", "sebastien.boutry@inrae.fr"),
          contact("FD", "François Delmas", "francois.delmas@inrae.fr")
        ),
        shiny::tags$p(
          class = "text-center mt-5 small reveal",
          style = "max-width: 760px; margin-left: auto; margin-right: auto; opacity: .75;",
          "Logiciel libre sous licence GNU GPL version 3 ou ultérieure, diffusé sans garantie. ",
          "Toute modification du code est susceptible de modifier le calcul de l'état diatomique, ",
          "qui ne serait alors plus conforme à la réglementation en vigueur."
        )
      )
    )
  )
}


#' Bloc de citation avec bouton « copier »
#' @noRd
bloc_citation <- function(texte) {
  shiny::div(
    class = "idgf-citation",
    shiny::span(class = "idgf-citation-texte", texte),
    shiny::tags$button(type = "button", class = "idgf-copier", title = "Copier la citation",
                       `aria-label` = "Copier la citation", shiny::icon("copy"))
  )
}


#' Carte de contact
#' @noRd
contact <- function(initiales, nom, courriel) {
  shiny::tags$a(
    class = "idgf-contact",
    href = paste0("mailto:", courriel),
    shiny::span(class = "idgf-avatar", initiales),
    shiny::span(shiny::tags$strong(nom), shiny::tags$small(courriel))
  )
}
