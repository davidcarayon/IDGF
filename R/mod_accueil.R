#' Onglet « Accueil » : bandeau animé, chiffres clés, parcours en trois étapes
#'
#' @param id Identifiant du module
#' @noRd
mod_accueil_ui <- function(id) {
  ns <- shiny::NS(id)

  n_codes <- length(unique(transcode$code))
  n_indiciels <- sum(table_metrics$indiciel == 1)
  n_alerte <- sum(rowSums(table_metrics[, c("MINER", "SAT", "COT", "DBO5", "DCO", "MES",
                                            "NK", "NO3", "PO4", "PTOT", "NH4")]) > 0)

  shiny::tagList(
    # ── Bandeau plein écran ─────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-hero",
      shiny::div(class = "idgf-hero-ciel"),
      shiny::div(class = "idgf-hero-soleil"),
      shiny::div(class = "idgf-diatomees", `data-particules` = "18"),
      svg_canopee(),
      svg_morpho(),
      shiny::div(
        class = "container idgf-hero-contenu",
        shiny::div(class = "idgf-surtitre reveal",
                   svg_etoile("idgf-etoile-mini"),
                   "Directive Cadre sur l'Eau · Guyane française"),
        shiny::tags$h1(
          class = "reveal",
          "Lire la santé des fleuves guyanais ",
          shiny::tags$span(class = "irise", "dans leurs diatomées")
        ),
        shiny::tags$p(
          class = "idgf-hero-intro reveal",
          "L'Indice Diatomique de Guyane Française (IDGF) évalue l'état écologique ",
          "des cours d'eau à partir des diatomées benthiques, micro-algues à squelette ",
          "de silice qui gardent la trace des pressions subies par le milieu."
        ),
        shiny::div(
          class = "idgf-hero-actions reveal",
          shiny::tags$a(class = "btn btn-lg idgf-btn-principal", href = "#", `data-goto` = "outil",
                        shiny::icon("calculator"), " Calculer l'IDGF"),
          shiny::tags$a(class = "btn btn-lg idgf-btn-verre", href = "#", `data-goto` = "methode",
                        shiny::icon("microscope"), " Découvrir la méthode")
        )
      ),
      svg_fleuve(),
      shiny::div(class = "idgf-defiler", shiny::tags$span())
    ),

    # ── Chiffres clés ───────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-chiffres",
      shiny::div(
        class = "container",
        shiny::div(
          class = "idgf-grille-chiffres",
          chiffre_cle(n_codes, "codes taxons reconnus", "dna"),
          chiffre_cle(n_indiciels, "taxons indiciels", "seedling"),
          chiffre_cle(n_alerte, "taxons d'alerte", "triangle-exclamation"),
          chiffre_cle(7, "métriques de pression", "gauge-high"),
          chiffre_cle(2, "hydroécorégions", "mountain-sun")
        )
      )
    ),

    # ── Parcours ────────────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section",
      shiny::div(
        class = "container",
        titre_section("De l'inventaire à l'état écologique",
                      "Trois étapes, quelques secondes de calcul."),
        shiny::div(
          class = "idgf-grille-3",
          carte_etape(1, "file-arrow-up", "Déposer un inventaire",
                      "Un fichier Excel ou CSV à quatre colonnes : relevé, code taxon OMNIDIA, abondance, hydroécorégion."),
          carte_etape(2, "flask", "Calculer l'indice",
                      "Transcodage des synonymes, ramené à 400 valves, sept métriques comparées à la référence régionale."),
          carte_etape(3, "chart-pie", "Diagnostiquer",
                      "Note IDGF, classe d'état DCE, fiabilité et diagramme radar des pressions pour chaque relevé.")
        ),
        shiny::div(
          class = "text-center mt-5 reveal",
          shiny::tags$a(class = "btn btn-lg idgf-btn-principal", href = "#", `data-goto` = "outil",
                        "Essayer avec le jeu d'exemple ", shiny::icon("arrow-right"))
        )
      )
    ),

    # ── Encart publication ──────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section idgf-section-sombre",
      shiny::div(class = "idgf-diatomees", `data-particules` = "8"),
      shiny::div(
        class = "container",
        shiny::div(
          class = "idgf-publi reveal carte-lumiere",
          shiny::div(class = "idgf-publi-icone", shiny::icon("book-open")),
          shiny::div(
            shiny::div(class = "idgf-surtitre", "Publication de référence"),
            shiny::tags$h3("A new multimetric index for the evaluation of water ecological quality of French Guiana streams based on benthic diatoms"),
            shiny::tags$p("Carayon D., Eulin-Garrigue A., Vigouroux R. & Delmas F. (2020). ",
                          shiny::tags$em("Ecological Indicators"), ", 113, 106248."),
            shiny::tags$a(class = "btn idgf-btn-principal", href = lien_publi(),
                          target = "_blank", rel = "noopener",
                          shiny::icon("arrow-up-right-from-square"), " Lire l'article")
          )
        )
      )
    )
  )
}


#' Tuile de chiffre clé, avec compteur animé
#' @noRd
chiffre_cle <- function(valeur, libelle, icone) {
  shiny::div(
    class = "idgf-chiffre reveal",
    shiny::div(class = "idgf-chiffre-icone", shiny::icon(icone)),
    shiny::div(class = "idgf-chiffre-valeur", `data-compte` = valeur, "0"),
    shiny::div(class = "idgf-chiffre-libelle", libelle)
  )
}


#' Titre de section (titre + sous-titre)
#' @noRd
titre_section <- function(titre, sous_titre = NULL, clair = FALSE) {
  shiny::div(
    class = paste("idgf-titre-section reveal", if (clair) "clair"),
    shiny::tags$h2(titre),
    if (!is.null(sous_titre)) shiny::tags$p(sous_titre)
  )
}


#' Carte d'étape numérotée
#' @noRd
carte_etape <- function(numero, icone, titre, texte) {
  shiny::div(
    class = "idgf-carte idgf-etape reveal carte-lumiere",
    shiny::div(class = "idgf-etape-numero", numero),
    shiny::div(class = "idgf-carte-icone", shiny::icon(icone)),
    shiny::tags$h4(titre),
    shiny::tags$p(texte)
  )
}
