#' Palette de l'application (thème Guyane : canopée, fleuves, morpho, drapeau)
#' @noRd
palette_idgf <- c(
  canopee = "#0d3b2e",
  feuille = "#1f6f4a",
  lime = "#a8c523",
  marine = "#1d4a8c",
  morpho = "#1fa2ff",
  soleil = "#f6c445",
  etoile = "#d62828",
  laterite = "#b5562c",
  sable = "#faf6ec"
)

#' Couleurs réglementaires des classes d'état écologique (DCE)
#' @noRd
couleurs_classes <- c(
  "Très bon" = "#0070c0",
  "Bon" = "#00b050",
  "Moyen" = "#ffd500",
  "Médiocre" = "#ff8c00",
  "Mauvais" = "#e02020"
)

#' Couleur de texte lisible sur chaque couleur de classe
#' @noRd
texte_classes <- c("#ffffff", "#ffffff", "#14302a", "#14302a", "#ffffff") |>
  stats::setNames(names(couleurs_classes))

#' Lien vers la publication de référence
#' @noRd
lien_publi <- function() "https://doi.org/10.1016/j.ecolind.2020.106248"

#' Thème bslib de l'application (Bootstrap 5 + SCSS maison)
#' @noRd
theme_idgf <- function() {
  p <- palette_idgf
  bslib::bs_theme(
    version = 5,
    bg = p[["sable"]],
    fg = "#14302a",
    primary = p[["feuille"]],
    secondary = p[["marine"]],
    success = "#00b050",
    info = p[["morpho"]],
    warning = p[["soleil"]],
    danger = p[["etoile"]],
    base_font = bslib::font_google("Outfit", local = FALSE),
    heading_font = bslib::font_google(
      "Fraunces",
      wght = c(400, 600, 800),
      local = FALSE
    ),
    code_font = bslib::font_google("JetBrains Mono", local = FALSE),
    "border-radius" = "0.9rem",
    "border-radius-lg" = "1.4rem",
    "navbar-bg" = p[["canopee"]]
  ) |>
    bslib::bs_add_rules(sass::sass_file(app_sys("app/styles/idgf.scss")))
}
