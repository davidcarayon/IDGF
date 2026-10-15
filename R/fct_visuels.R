# Éléments graphiques SVG de l'interface : canopée, fleuve, morpho, diatomées.
# Tout est vectoriel et animé en CSS (inst/app/styles/idgf.scss) : aucune image lourde.

#' Silhouette de canopée (plusieurs plans superposés, effet parallaxe)
#' @noRd
svg_canopee <- function() {
  # Profil de canopée : une suite de couronnes d'arbres de tailles irrégulières
  couronnes <- function(graine, base, amplitude, n) {
    set.seed(graine)
    x <- seq(-40, 1480, length.out = n)
    h <- base - stats::runif(n, 0.35, 1) * amplitude
    d <- sprintf("M-40 %d", base)
    for (i in seq_len(n - 1)) {
      xm <- (x[i] + x[i + 1]) / 2
      d <- paste0(d, sprintf(" Q%.0f %.0f %.0f %.0f", xm, h[i] - amplitude * 0.35, x[i + 1], h[i + 1]))
    }
    paste0(d, " L1480 420 L-40 420 Z")
  }
  plan <- function(classe, d) sprintf('<path class="%s" d="%s"/>', classe, d)

  shiny::HTML(paste0(
    '<svg class="idgf-canopee" viewBox="0 0 1440 420" preserveAspectRatio="none" aria-hidden="true">',
    plan("plan plan-3", couronnes(3, 250, 110, 26)),
    plan("plan plan-2", couronnes(7, 300, 120, 20)),
    plan("plan plan-1", couronnes(11, 350, 120, 15)),
    "</svg>"
  ))
}


#' Fleuve animé (vagues superposées)
#' @param classe Classe CSS du SVG
#' @noRd
svg_fleuve <- function(classe = "idgf-fleuve") {
  vague <- "M0 40 C 180 10, 360 70, 540 40 S 900 10, 1080 40 S 1440 70, 1620 40 S 1980 10, 2160 40 S 2520 70, 2880 40 L2880 120 L0 120 Z"
  shiny::HTML(paste0(
    '<svg class="', classe, '" viewBox="0 0 1440 120" preserveAspectRatio="none" aria-hidden="true">',
    '<path class="vague vague-1" d="', vague, '"/>',
    '<path class="vague vague-2" d="', vague, '"/>',
    '<path class="vague vague-3" d="', vague, '"/>',
    "</svg>"
  ))
}


#' Morpho bleu qui traverse l'écran (ailes qui battent, reflets irisés)
#' @noRd
svg_morpho <- function() {
  shiny::HTML(paste0(
    '<div class="idgf-morpho" aria-hidden="true"><svg viewBox="-60 -50 120 100">',
    '<defs><linearGradient id="irise" x1="0" y1="0" x2="1" y2="1">',
    '<stop offset="0" stop-color="#7ee8fa"/><stop offset="0.45" stop-color="#1fa2ff"/>',
    '<stop offset="1" stop-color="#1d2f9c"/></linearGradient></defs>',
    '<g class="aile aile-g">',
    '<path d="M-2 -4 C -20 -48, -58 -44, -54 -14 C -52 0, -30 4, -2 2 Z" fill="url(#irise)"/>',
    '<path d="M-2 2 C -26 6, -44 30, -30 40 C -18 46, -6 26, -2 8 Z" fill="url(#irise)"/>',
    '<path d="M-54 -14 C -52 0, -30 4, -2 2" fill="none" stroke="#0b1d4a" stroke-width="3"/>',
    "</g>",
    '<g class="aile aile-d">',
    '<path d="M2 -4 C 20 -48, 58 -44, 54 -14 C 52 0, 30 4, 2 2 Z" fill="url(#irise)"/>',
    '<path d="M2 2 C 26 6, 44 30, 30 40 C 18 46, 6 26, 2 8 Z" fill="url(#irise)"/>',
    '<path d="M54 -14 C 52 0, 30 4, 2 2" fill="none" stroke="#0b1d4a" stroke-width="3"/>',
    "</g>",
    '<ellipse cx="0" cy="2" rx="2.6" ry="20" fill="#13203a"/>',
    '<path d="M-1 -17 Q -6 -30 -10 -34 M1 -17 Q 6 -30 10 -34" stroke="#13203a" stroke-width="1.2" fill="none"/>',
    "</svg></div>"
  ))
}


#' Diatomée stylisée (pennée ou centrique), en SVG
#'
#' @param type "pennee" ou "centrique"
#' @param classe Classe CSS supplémentaire
#' @noRd
svg_diatomee <- function(type = c("pennee", "centrique"), classe = "") {
  type <- match.arg(type)
  if (type == "pennee") {
    # Valve elliptique allongée, raphé central et stries transversales
    stries <- vapply(seq(-34, 34, by = 4.5), function(y) {
      demi <- 9.5 * sqrt(max(0, 1 - (y / 40)^2))
      sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/>',
              -demi, y, -2.2, y, 2.2, y, demi, y)
    }, character(1))
    corps <- paste0(
      '<ellipse cx="0" cy="0" rx="12" ry="42" class="valve"/>',
      '<g class="stries">', paste(stries, collapse = ""), "</g>",
      '<line x1="0" y1="-36" x2="0" y2="36" class="raphe"/>',
      '<circle cx="0" cy="0" r="2.4" class="nodule"/>'
    )
    vb <- "-16 -46 32 92"
  } else {
    # Valve circulaire, stries rayonnantes et anneau central
    rayons <- vapply(seq(0, 345, by = 15), function(a) {
      r <- a * pi / 180
      sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/>',
              14 * cos(r), 14 * sin(r), 34 * cos(r), 34 * sin(r))
    }, character(1))
    corps <- paste0(
      '<circle cx="0" cy="0" r="38" class="valve"/>',
      '<g class="stries">', paste(rayons, collapse = ""), "</g>",
      '<circle cx="0" cy="0" r="11" class="anneau"/>'
    )
    vb <- "-42 -42 84 84"
  }
  shiny::HTML(sprintf(
    '<svg class="idgf-diatomee %s %s" viewBox="%s" aria-hidden="true">%s</svg>',
    type, classe, vb, corps
  ))
}


#' Étoile à cinq branches (rappel du drapeau de la Guyane)
#' @noRd
svg_etoile <- function(classe = "idgf-etoile") {
  pts <- vapply(0:9, function(i) {
    r <- if (i %% 2 == 0) 50 else 20
    a <- -pi / 2 + i * pi / 5
    sprintf("%.1f,%.1f", r * cos(a), r * sin(a))
  }, character(1))
  shiny::HTML(sprintf(
    '<svg class="%s" viewBox="-52 -52 104 104" aria-hidden="true"><polygon points="%s"/></svg>',
    classe, paste(pts, collapse = " ")
  ))
}
