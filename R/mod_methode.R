#' Description des sept métriques de l'IDGF
#' @noRd
metriques_idgf <- function() {
  tibble::tribble(
    ~code,       ~param,     ~nom,                         ~icone,              ~texte,
    "MES",       "MES",      "Matières en suspension", "water",             "Turbidité et apports de particules fines, notamment liés à l'orpaillage et à l'érosion des sols.",
    "MINE.",     "MINER",    "Minéralisation",          "gem",               "Enrichissement en ions dissous, inhabituel pour les eaux très peu minéralisées de Guyane.",
    "Mat.Orga",  "MORGA",    "Matière organique",       "leaf",              "Pollution organique : la plus sévère des métriques COT, DBO5 et DCO.",
    "N-Orga",    "NORG",     "Azote organique",             "atom",              "Azote réduit (Kjeldahl, ammonium) : la plus sévère des deux métriques.",
    "P-Trophie", "PTROPHIE", "Phosphore",                   "seedling",          "Eutrophisation par le phosphore (orthophosphates, phosphore total).",
    "NO3",       "NO3",      "Nitrates",                    "flask",             "Apports d'azote oxydé, d'origine agricole ou domestique.",
    "SAT.O2",    "SAT",      "Saturation en oxygène",   "wind",              "Désoxygénation du milieu, conséquence fréquente des apports organiques."
  )
}


#' Onglet « La méthode »
#'
#' @param id Identifiant du module
#' @noRd
mod_methode_ui <- function(id) {
  ns <- shiny::NS(id)
  met <- metriques_idgf()

  # Valeurs de référence par HER (table interne), dans l'ordre des métriques
  ref <- tidyr::pivot_wider(table_ref, names_from = numher1, values_from = ref)
  ref <- ref[match(met$param, ref$param), ]

  shiny::tagList(
    bandeau_page("La méthode", "Un indice multimétrique bâti pour les eaux amazoniennes",
                 "microscope"),

    # ── Contexte ────────────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section",
      shiny::div(
        class = "container idgf-texte-large",
        shiny::div(
          class = "idgf-grille-2 align-items-center",
          shiny::div(
            class = "reveal",
            shiny::tags$h2("Pourquoi un indice guyanais ?"),
            shiny::tags$p(
              "La Directive Cadre sur l'Eau impose de suivre la qualité écologique des masses d'eau, ",
              "y compris dans les départements d'outre-mer. En Guyane, les cortèges de diatomées sont ",
              "très spécifiques et longtemps restés méconnus : l'évaluation reposait sur une adaptation ",
              "locale de l'IPS, dont les profils de taxons, établis à partir de données mondiales, ",
              "collent mal au contexte amazonien."
            ),
            shiny::tags$p(
              "Neuf années de données des réseaux de suivi et les progrès de la taxonomie ont permis ",
              "le programme 2017-2018 qui a abouti à l'IDGF : une évaluation conforme à la DCE ",
              "(écart à une référence régionale), jugée pertinente par les experts locaux."
            )
          ),
          shiny::div(
            class = "idgf-vitrine reveal",
            svg_diatomee("pennee", "flotte flotte-1"),
            svg_diatomee("centrique", "flotte flotte-2"),
            svg_diatomee("pennee", "flotte flotte-3")
          )
        )
      )
    ),

    # ── Principes ───────────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section idgf-section-teinte",
      shiny::div(
        class = "container",
        titre_section("Trois idées fortes"),
        shiny::div(
          class = "idgf-grille-3",
          carte_principe("filter", "Moins de taxons, mieux choisis",
                         "Seuls les taxons indiciels, dont l'écologie est bien connue en Guyane, entrent dans le calcul. Les synonymes et évolutions taxonomiques sont transcodés automatiquement."),
          carte_principe("triangle-exclamation", "Des taxons d'alerte",
                         "Pour chaque pression (minéralisation, matière organique, nutriments, oxygène, matières en suspension), une liste de taxons signale sa présence."),
          carte_principe("mountain-sun", "Une référence par région",
                         "Chaque métrique est comparée à sa valeur de référence dans l'hydroécorégion du relevé : plaine littorale ou bouclier guyanais.")
        )
      )
    ),

    # ── Calcul pas à pas ────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section",
      shiny::div(
        class = "container",
        titre_section("Le calcul, pas à pas"),
        shiny::div(
          class = "idgf-frise",
          etape_frise("1", "Standardisation",
                      shiny::tagList("Les codes OMNIDIA sont transcodés vers les taxons retenus par l'indice, puis les abondances sont ramenées à ",
                                     shiny::tags$strong("400 valves"), " par relevé.")),
          etape_frise("2", "Métriques de pression",
                      shiny::tagList("Pour chaque pression ", shiny::tags$em("p"), " :",
                                     formule("M<sub>p</sub> = 1 − A<sub>alerte,p</sub> / A<sub>indiciels</sub>"),
                                     "Les pressions proches sont regroupées en gardant la plus sévère (minimum) : matière organique, azote organique, phosphore.")),
          etape_frise("3", "Écart à la référence",
                      shiny::tagList("Chaque métrique est divisée par sa référence dans l'HER, et bornée entre 0 et 1 :",
                                     formule("EQR<sub>p</sub> = min(1, M<sub>p</sub> / Réf<sub>p,HER</sub>)"))),
          etape_frise("4", "Note finale",
                      shiny::tagList("La moyenne des sept EQR est recalée linéairement sur l'échelle 0-1 :",
                                     formule("IDGF = max(0, 3,626943 × EQR̅ − 2,626943)"),
                                     "puis convertie en classe d'état écologique."))
        ),
        shiny::div(class = "idgf-pipeline reveal",
                   shiny::tags$img(src = "www/pipeline.png",
                                   alt = "Enchaînement des fonctions importIDGF, computeIDGF, radarIDGF et exportIDGF"))
      )
    ),

    # ── Métriques ───────────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section idgf-section-sombre",
      shiny::div(class = "idgf-diatomees", `data-particules` = "10"),
      shiny::div(
        class = "container",
        titre_section("Sept métriques, sept pressions",
                      "Les axes du diagramme radar d'appui au diagnostic.", clair = TRUE),
        shiny::div(
          class = "idgf-grille-metriques",
          lapply(seq_len(nrow(met)), function(i) {
            shiny::div(
              class = "idgf-metrique reveal carte-lumiere",
              shiny::div(class = "idgf-metrique-tete",
                         shiny::span(class = "idgf-carte-icone", shiny::icon(met$icone[i])),
                         shiny::span(class = "idgf-metrique-code", met$code[i])),
              shiny::tags$h5(met$nom[i]),
              shiny::tags$p(met$texte[i]),
              shiny::div(
                class = "idgf-metrique-ref",
                shiny::span(shiny::tags$small("Réf. plaine"), sprintf("%.3f", ref[["1"]][i])),
                shiny::span(shiny::tags$small("Réf. bouclier"), sprintf("%.3f", ref[["2"]][i]))
              )
            )
          })
        )
      )
    ),

    # ── HER et classes ──────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section",
      shiny::div(
        class = "container",
        titre_section("Deux régions, cinq classes"),
        shiny::div(
          class = "idgf-grille-2",
          shiny::div(
            class = "idgf-carte idgf-her her-1 reveal carte-lumiere",
            shiny::div(class = "idgf-her-num", "HER 1"),
            shiny::tags$h4("Plaine littorale"),
            shiny::tags$p("Cours d'eau de la frange côtière, sous influence des terrains sédimentaires récents, des mangroves et parfois des intrusions salées (d'où le suivi des taxons halins).")
          ),
          shiny::div(
            class = "idgf-carte idgf-her her-2 reveal carte-lumiere",
            shiny::div(class = "idgf-her-num", "HER 2"),
            shiny::tags$h4("Bouclier guyanais"),
            shiny::tags$p("Cours d'eau de l'intérieur, sur le socle précambrien couvert de forêt amazonienne : eaux très peu minéralisées, souvent acides.")
          )
        ),
        shiny::div(class = "mt-5 reveal", echelle_classes()),
        shiny::div(
          class = "idgf-grille-3 mt-5",
          carte_fiabilite("satisfaisante", "circle-check", "satisfaisante", "≥ 90 %",
                          "des valves appartiennent à des taxons indiciels : l'évaluation est fiable."),
          carte_fiabilite("reduite", "circle-half-stroke", "réduite", "75 – 90 %",
                          "l'évaluation est donnée mais à interpréter avec prudence."),
          carte_fiabilite("nonvalide", "circle-xmark", "non valide", "< 75 %",
                          "trop peu de taxons indiciels : augmenter la pression de comptage.")
        )
      )
    ),

    # ── Format d'entrée ─────────────────────────────────────────────────
    shiny::tags$section(
      class = "idgf-section idgf-section-teinte",
      shiny::div(
        class = "container",
        titre_section("Préparer son fichier",
                      "Excel (.xls, .xlsx) ou CSV (séparateur point-virgule, décimale point), quatre colonnes dans cet ordre."),
        shiny::div(
          class = "idgf-grille-2 align-items-center",
          shiny::div(
            class = "idgf-carte reveal",
            shiny::tags$table(
              class = "table idgf-table-format mb-0",
              shiny::tags$thead(shiny::tags$tr(
                shiny::tags$th("id_releve"), shiny::tags$th("cd_taxon"),
                shiny::tags$th("abondance"), shiny::tags$th("her"))),
              shiny::tags$tbody(
                lapply(seq_len(4), function(i) {
                  shiny::tags$tr(lapply(taxa.GF[i, ], function(v) shiny::tags$td(as.character(v))))
                })
              )
            )
          ),
          shiny::div(
            class = "reveal",
            shiny::tags$dl(
              class = "idgf-champs",
              shiny::tags$dt("id_releve"), shiny::tags$dd("Identifiant unique du relevé (texte ou nombre)."),
              shiny::tags$dt("cd_taxon"), shiny::tags$dd("Code OMNIDIA à quatre caractères (ex. ADCT, CA07)."),
              shiny::tags$dt("abondance"), shiny::tags$dd("Nombre de valves comptées (entier positif)."),
              shiny::tags$dt("her"), shiny::tags$dd("1 = plaine littorale, 2 = bouclier guyanais.")
            ),
            shiny::tags$a(class = "btn idgf-btn-principal", href = "www/exemple_IDGF.xlsx", download = NA,
                          shiny::icon("file-excel"), " Télécharger le fichier d'exemple")
          )
        )
      )
    )
  )
}


#' Bandeau de titre des pages intérieures
#' @noRd
bandeau_page <- function(titre, sous_titre, icone) {
  shiny::tags$section(
    class = "idgf-bandeau",
    shiny::div(class = "idgf-diatomees", `data-particules` = "10"),
    svg_canopee(),
    shiny::div(
      class = "container idgf-bandeau-contenu",
      shiny::div(class = "idgf-bandeau-icone reveal", shiny::icon(icone)),
      shiny::tags$h1(class = "reveal", titre),
      shiny::tags$p(class = "reveal", sous_titre)
    ),
    svg_fleuve()
  )
}


#' Carte de principe
#' @noRd
carte_principe <- function(icone, titre, texte) {
  shiny::div(
    class = "idgf-carte reveal carte-lumiere",
    shiny::div(class = "idgf-carte-icone", shiny::icon(icone)),
    shiny::tags$h4(titre),
    shiny::tags$p(texte)
  )
}


#' Étape de la frise de calcul
#' @noRd
etape_frise <- function(numero, titre, contenu) {
  shiny::div(
    class = "idgf-frise-etape reveal",
    shiny::div(class = "idgf-frise-point", numero),
    shiny::div(class = "idgf-frise-contenu", shiny::tags$h4(titre), shiny::div(contenu))
  )
}


#' Formule mise en forme
#' @noRd
formule <- function(html) {
  shiny::div(class = "idgf-formule", shiny::HTML(html))
}


#' Échelle des classes d'état écologique (bornes de l'IDGF)
#' @noRd
echelle_classes <- function() {
  bornes <- c(0, 0.25, 0.50, 0.75, 0.88, 1)
  classes <- rev(names(couleurs_classes))
  shiny::div(
    class = "idgf-echelle",
    shiny::div(
      class = "idgf-echelle-barre",
      lapply(seq_along(classes), function(i) {
        shiny::div(
          class = "idgf-echelle-segment",
          style = sprintf("flex:%.2f; --c:%s; --i:%d", bornes[i + 1] - bornes[i],
                          couleurs_classes[[classes[i]]], i),
          shiny::span(classes[i])
        )
      })
    ),
    shiny::div(
      class = "idgf-echelle-bornes",
      lapply(bornes, function(b) shiny::span(style = sprintf("left:%.0f%%", b * 100),
                                              formatC(b, format = "f", digits = 2, decimal.mark = ",")))
    )
  )
}


#' Carte de niveau de fiabilité
#' @noRd
carte_fiabilite <- function(classe, icone, niveau, seuil, texte) {
  shiny::div(
    class = paste("idgf-carte idgf-fiabilite reveal", classe),
    shiny::div(class = "idgf-carte-icone", shiny::icon(icone)),
    shiny::tags$h5("Fiabilité ", niveau),
    shiny::div(class = "idgf-fiabilite-seuil", seuil),
    shiny::tags$p(texte)
  )
}
