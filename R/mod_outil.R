#' Onglet « Calculer l'IDGF » : interface
#'
#' @param id Identifiant du module
#' @noRd
mod_outil_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bandeau_page("Calculer l'IDGF",
                 "Déposez vos inventaires diatomiques, obtenez l'état écologique de chaque relevé",
                 "calculator"),
    shiny::tags$section(
      class = "idgf-section idgf-outil",
      shiny::div(
        class = "container-xl",
        shiny::div(
          class = "idgf-outil-grille",

          # ── Colonne de gauche : données ─────────────────────────────
          shiny::tags$aside(
            class = "idgf-outil-donnees",
            shiny::div(
              class = "idgf-carte",
              shiny::tags$h4(shiny::icon("database"), " Vos données"),
              shiny::div(
                class = "idgf-depot",
                shiny::div(class = "idgf-depot-icone", shiny::icon("cloud-arrow-up")),
                shiny::div(class = "idgf-depot-texte",
                           shiny::tags$strong("Glissez votre fichier ici"),
                           shiny::tags$small(".xlsx, .xls ou .csv (point-virgule)")),
                shiny::fileInput(ns("fichier"), label = NULL,
                                 accept = c(".xls", ".xlsx", ".csv"),
                                 buttonLabel = shiny::tagList(shiny::icon("folder-open"), " Parcourir"),
                                 placeholder = "Aucun fichier choisi")
              ),
              shiny::div(class = "idgf-ou", shiny::span("ou")),
              shiny::actionButton(ns("exemple"), "Essayer le jeu d'exemple",
                                  icon = shiny::icon("wand-magic-sparkles"),
                                  class = "idgf-btn-verre-sombre w-100"),
              shiny::div(
                class = "idgf-aide",
                shiny::icon("circle-info"),
                shiny::span(
                  "Quatre colonnes : ", shiny::tags$code("id_releve"), ", ", shiny::tags$code("cd_taxon"),
                  ", ", shiny::tags$code("abondance"), ", ", shiny::tags$code("her"), " (1 ou 2). ",
                  shiny::tags$a(href = "www/exemple_IDGF.xlsx", download = NA, "Modèle Excel"), "."
                )
              ),
              shiny::uiOutput(ns("etat_fichier"))
            )
          ),

          # ── Colonne de droite : résultats ───────────────────────────
          shiny::div(class = "idgf-outil-resultats", shiny::uiOutput(ns("resultats")))
        )
      )
    )
  )
}


#' Onglet « Calculer l'IDGF » : logique serveur
#'
#' @param id Identifiant du module
#' @noRd
mod_outil_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Résultat du dernier calcul : list(nom, donnees, res, resrad) ou NULL
    calcul <- shiny::reactiveVal(NULL)

    lancer_calcul <- function(chemin, nom) {
      resultat <- tryCatch(
        shiny::withProgress(message = "Calcul de l'IDGF", value = 0.05, {
          shiny::incProgress(0.15, detail = "import et transcodage")
          donnees <- suppressWarnings(importIDGF(chemin))
          shiny::incProgress(0.4, detail = "métriques et écart à la référence")
          res <- suppressWarnings(computeIDGF(donnees))
          if (nrow(res) == 0) stop("aucun relevé n'a pu être évalué (codes taxons ou HER reconnus ?)")
          shiny::incProgress(0.3, detail = "diagrammes de diagnostic")
          resrad <- suppressMessages(radarIDGF(res))
          list(nom = nom, donnees = donnees, res = res, resrad = resrad)
        }),
        error = function(e) {
          shiny::showNotification(
            shiny::tagList(shiny::tags$strong("Le fichier n'a pas pu être traité."), shiny::br(),
                           conditionMessage(e)),
            type = "error", duration = 12
          )
          NULL
        }
      )
      if (!is.null(resultat)) calcul(resultat)
    }

    shiny::observeEvent(input$fichier, lancer_calcul(input$fichier$datapath, input$fichier$name))
    shiny::observeEvent(input$exemple, lancer_calcul(app_sys("input_test.xlsx"), "Jeu d'exemple"))

    # ── Bandeau d'état sous le dépôt ──────────────────────────────────
    output$etat_fichier <- shiny::renderUI({
      x <- calcul()
      if (is.null(x)) return(NULL)
      shiny::div(
        class = "idgf-etat-ok",
        shiny::icon("circle-check"),
        shiny::div(shiny::tags$strong(x$nom),
                   shiny::tags$small(sprintf("%d relevé(s) évalué(s)", nrow(x$res))))
      )
    })

    # ── Zone de résultats ─────────────────────────────────────────────
    output$resultats <- shiny::renderUI({
      x <- calcul()
      if (is.null(x)) return(etat_vide())

      res <- x$res
      idgf <- suppressWarnings(as.numeric(res$IDGF))
      bons <- mean(res$Classe %in% c("Très bon", "Bon")) * 100
      non_valides <- sum(grepl("non valide", res$`fiabilité`))
      inconnus <- unique(unlist(strsplit(res$Taxons_inconnus[res$Taxons_inconnus != ""], ",")))

      shiny::tagList(
        shiny::div(
          class = "idgf-tuiles",
          tuile("layer-group", nrow(res), "relevés évalués"),
          tuile("gauge-high", format(round(stats::median(idgf, na.rm = TRUE), 2), decimal.mark = ","),
                "IDGF médian", decimales = 2),
          tuile("leaf", round(bons), "% bon ou très bon"),
          tuile(if (non_valides > 0) "triangle-exclamation" else "circle-check", non_valides,
                "non valide(s)", alerte = non_valides > 0),
          tuile("question", length(inconnus), "taxon(s) inconnu(s)", alerte = length(inconnus) > 0)
        ),
        shiny::div(class = "idgf-carte idgf-apparition", repartition_classes(res$Classe)),
        bslib::navset_card_underline(
          id = ns("onglets"),
          full_screen = TRUE,
          bslib::nav_panel(
            shiny::tagList(shiny::icon("chart-pie"), " Diagnostic par relevé"),
            shiny::div(
              class = "idgf-choix-releve",
              shiny::selectInput(ns("releve"), "Relevé", choices = as.character(res$id_releve),
                                 selectize = TRUE, width = "100%")
            ),
            shiny::div(
              class = "idgf-diagnostic",
              shiny::uiOutput(ns("fiche")),
              shiny::div(class = "idgf-radar",
                         shiny::plotOutput(ns("radar"), height = "430px"))
            )
          ),
          bslib::nav_panel(
            shiny::tagList(shiny::icon("table"), " Tableau complet"),
            DT::DTOutput(ns("tableau"))
          ),
          bslib::nav_panel(
            shiny::tagList(shiny::icon("download"), " Export"),
            shiny::div(
              class = "idgf-export",
              shiny::div(
                class = "idgf-export-option",
                shiny::div(class = "idgf-carte-icone", shiny::icon("file-zipper")),
                shiny::tags$h5("Archive complète"),
                shiny::tags$p("Tableau des résultats (.csv) et un diagramme radar (.png) par relevé."),
                shiny::downloadButton(ns("dl_zip"), "Télécharger le .zip", class = "idgf-btn-principal")
              ),
              shiny::div(
                class = "idgf-export-option",
                shiny::div(class = "idgf-carte-icone", shiny::icon("file-csv")),
                shiny::tags$h5("Tableau seul"),
                shiny::tags$p("Résultats au format .csv (point-virgule), lisible directement dans Excel."),
                shiny::downloadButton(ns("dl_csv"), "Télécharger le .csv", class = "idgf-btn-verre-sombre")
              )
            )
          )
        )
      )
    })

    # Ligne de résultats du relevé choisi
    releve_choisi <- shiny::reactive({
      x <- calcul()
      shiny::req(x, input$releve)
      ligne <- x$res[as.character(x$res$id_releve) == input$releve, ]
      shiny::req(nrow(ligne) == 1)
      ligne
    })

    # ── Fiche du relevé : jauge, fiabilité, barres des métriques ──────
    output$fiche <- shiny::renderUI({
      ligne <- releve_choisi()
      x <- calcul()
      her <- x$donnees$metadata$her[as.character(x$donnees$metadata$sample) == input$releve][1]
      fiche_releve(ligne, her)
    })

    output$radar <- shiny::renderPlot({
      x <- calcul()
      shiny::req(x, input$releve)
      graphe <- x$resrad$plot[as.character(x$resrad$id_releve) == input$releve]
      shiny::req(length(graphe) == 1)
      graphe[[1]] +
        ggplot2::coord_polar(clip = "off") +
        ggplot2::labs(title = NULL) +
        ggplot2::theme(
          plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          legend.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          panel.border = ggplot2::element_blank(),
          axis.text.x = ggplot2::element_text(face = "bold", size = 12, colour = "#14302a"),
          panel.grid.major = ggplot2::element_line(colour = "#14302a33", linetype = "dashed"),
          plot.margin = ggplot2::margin(20, 10, 20, 30)
        )
    }, bg = "transparent", res = 110)

    # ── Tableau complet ───────────────────────────────────────────────
    output$tableau <- DT::renderDT({
      x <- calcul()
      shiny::req(x)
      tab <- x$res
      tab$id_releve <- as.character(tab$id_releve)
      DT::datatable(
        tab,
        rownames = FALSE,
        class = "compact hover nowrap",
        fillContainer = FALSE,
        options = list(
          scrollX = TRUE, pageLength = 15, dom = "ftip",
          language = langue_dt()
        )
      ) |>
        DT::formatStyle(
          "Classe",
          backgroundColor = DT::styleEqual(names(couleurs_classes), unname(couleurs_classes)),
          color = DT::styleEqual(names(couleurs_classes), unname(texte_classes)),
          fontWeight = "600"
        ) |>
        DT::formatStyle(
          "fiabilité",
          color = DT::styleEqual(
            c("Fiabilité : satisfaisante", "Fiabilité : réduite",
              "Indice non valide, augmenter la pression de comptage"),
            c("#1f6f4a", "#b57a00", "#d62828")
          )
        )
    })

    # ── Exports ───────────────────────────────────────────────────────
    output$dl_zip <- shiny::downloadHandler(
      filename = function() sprintf("export_IDGF_%s.zip", Sys.Date()),
      content = function(file) {
        x <- calcul()
        shiny::req(x)
        shiny::withProgress(message = "Production des diagrammes", detail = "quelques secondes", value = 0.2, {
          dossier <- tempfile("idgf_")
          on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
          exportIDGF(x$resrad, outdir = dossier)
          shiny::incProgress(0.7)
          zip::zip(zipfile = file, files = list.files(dossier, recursive = TRUE), root = dossier)
        })
      },
      contentType = "application/zip"
    )

    output$dl_csv <- shiny::downloadHandler(
      filename = function() sprintf("resultats_idgf_%s.csv", Sys.Date()),
      content = function(file) {
        x <- calcul()
        shiny::req(x)
        utils::write.csv2(x$res, file, row.names = FALSE, fileEncoding = "UTF-8")
      },
      contentType = "text/csv"
    )
  })
}


#' État vide de la zone de résultats (avant tout calcul)
#' @noRd
etat_vide <- function() {
  shiny::div(
    class = "idgf-vide",
    shiny::div(
      class = "idgf-vide-visuel",
      svg_diatomee("centrique", "flotte flotte-1"),
      svg_diatomee("pennee", "flotte flotte-2")
    ),
    shiny::tags$h3("Vos résultats apparaîtront ici"),
    shiny::tags$p("Déposez un fichier d'inventaires, ou lancez le jeu d'exemple pour voir l'outil en action.")
  )
}


#' Tuile de synthèse (avec compteur animé)
#' @noRd
tuile <- function(icone, valeur, libelle, alerte = FALSE, decimales = 0) {
  num <- suppressWarnings(as.numeric(sub(",", ".", valeur)))
  shiny::div(
    class = paste("idgf-tuile", if (alerte) "alerte"),
    shiny::div(class = "idgf-tuile-icone", shiny::icon(icone)),
    shiny::div(
      shiny::div(class = "idgf-tuile-valeur",
                 `data-compte` = if (!is.na(num)) num,
                 `data-decimales` = decimales,
                 valeur),
      shiny::div(class = "idgf-tuile-libelle", libelle)
    )
  )
}


#' Barre de répartition des relevés par classe d'état
#' @noRd
repartition_classes <- function(classes) {
  n <- table(factor(classes, levels = names(couleurs_classes)))
  total <- sum(n)
  shiny::tagList(
    shiny::tags$h5(class = "mb-3", "Répartition des relevés par classe d'état"),
    shiny::div(
      class = "idgf-repartition",
      lapply(names(n)[n > 0], function(cl) {
        shiny::div(
          class = "idgf-repartition-segment",
          style = sprintf("flex:%d; --c:%s", n[[cl]], couleurs_classes[[cl]]),
          title = sprintf("%s : %d relevé(s)", cl, n[[cl]]),
          if (n[[cl]] / total >= 0.08) n[[cl]]
        )
      })
    ),
    shiny::div(
      class = "idgf-legende",
      lapply(names(n), function(cl) {
        shiny::span(shiny::tags$i(style = sprintf("background:%s", couleurs_classes[[cl]])),
                    sprintf("%s (%d)", cl, n[[cl]]))
      })
    )
  )
}


#' Fiche détaillée d'un relevé
#'
#' @param ligne Ligne de résultats de `computeIDGF()`
#' @param her Numéro d'hydroécorégion (1 ou 2)
#' @noRd
fiche_releve <- function(ligne, her) {
  idgf <- suppressWarnings(as.numeric(ligne$IDGF))
  classe <- ligne$Classe
  couleur <- couleurs_classes[[classe]]
  fiab <- ligne$`fiabilité`
  fiab_classe <- if (grepl("non valide", fiab)) "nonvalide" else if (grepl("réduite", fiab)) "reduite" else "satisfaisante"
  rampe <- grDevices::colorRampPalette(c("#FC4E07", "#E7B800", "#00AFBB"))(101)
  met <- metriques_idgf()

  liste_taxons <- function(titre, valeurs) {
    if (is.null(valeurs) || is.na(valeurs) || valeurs == "") return(NULL)
    shiny::div(
      class = "idgf-taxons",
      shiny::tags$small(titre),
      lapply(strsplit(valeurs, ",")[[1]], function(t) shiny::span(class = "idgf-puce", t))
    )
  }

  shiny::div(
    class = "idgf-fiche",
    shiny::div(
      class = "idgf-fiche-tete",
      shiny::div(
        class = "idgf-jauge",
        style = sprintf("--p:%.0f; --c:%s", idgf * 100, couleur),
        shiny::div(class = "idgf-jauge-centre",
                   shiny::span(class = "idgf-jauge-valeur", formatC(idgf, format = "f", digits = 2, decimal.mark = ",")),
                   shiny::span(class = "idgf-jauge-libelle", "IDGF"))
      ),
      shiny::div(
        class = "idgf-fiche-infos",
        shiny::span(class = "idgf-classe", style = sprintf("--c:%s; --t:%s", couleur, texte_classes[[classe]]), classe),
        shiny::div(class = paste("idgf-fiab", fiab_classe), shiny::icon("shield-halved"), " ", fiab),
        shiny::div(
          class = "idgf-fiche-meta",
          shiny::span(shiny::icon("mountain-sun"),
                      if (identical(as.numeric(her), 1)) " Plaine littorale (HER 1)" else " Bouclier guyanais (HER 2)"),
          shiny::span(shiny::icon("seedling"), sprintf(" %s %% indiciels", format(ligne$pourcentage_indiciels, decimal.mark = ","))),
          shiny::span(shiny::icon("water"), sprintf(" %s %% halins", format(ligne$pourcentage_halins, decimal.mark = ",")))
        )
      )
    ),
    shiny::div(
      class = "idgf-barres",
      lapply(seq_len(nrow(met)), function(i) {
        eqr <- suppressWarnings(as.numeric(ligne[[met$code[i]]]))
        if (is.na(eqr)) return(NULL)
        shiny::div(
          class = "idgf-barre",
          title = met$nom[i],
          shiny::span(class = "idgf-barre-nom", met$code[i]),
          shiny::div(class = "idgf-barre-piste",
                     shiny::div(class = "idgf-barre-remplie",
                                style = sprintf("--l:%.0f%%; --c:%s; --d:%dms", eqr * 100,
                                                rampe[round(eqr * 100) + 1], i * 70))),
          shiny::span(class = "idgf-barre-valeur", formatC(eqr, format = "f", digits = 2, decimal.mark = ","))
        )
      })
    ),
    liste_taxons("Taxons halins", ligne$Taxons_halins),
    liste_taxons("Codes inconnus (ignorés)", ligne$Taxons_inconnus)
  )
}


#' Traduction française de DataTables (sans appel réseau)
#' @noRd
langue_dt <- function() {
  list(
    search = "Rechercher :",
    info = "Relevés _START_ à _END_ sur _TOTAL_",
    infoEmpty = "Aucun relevé",
    infoFiltered = "(filtrés parmi _MAX_)",
    zeroRecords = "Aucun relevé ne correspond",
    paginate = list(first = "Premier", last = "Dernier", `next` = "Suivant", previous = "Précédent")
  )
}
