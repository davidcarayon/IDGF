exemple <- system.file("input_test.xlsx", package = "IDGF")

test_that("le calcul sur le jeu d'exemple donne les résultats de la version 2.0", {
  res <- suppressWarnings(computeIDGF(suppressWarnings(importIDGF(exemple))))
  expect_equal(nrow(res), 12)
  attendu <- c(`792` = 0.87, `821` = 0.58, `841` = 0.68, `851` = 0.89)
  expect_equal(as.numeric(res$IDGF[match(names(attendu), res$id_releve)]), unname(attendu))
  expect_equal(res$Classe[res$id_releve == 851], "Très bon")
})

test_that("la note est bornée à 0 relevé par relevé", {
  expect_equal(model_IDGF(c(0.5, 0.95, 1)), c(0, 0.82, 1))
})

test_that("un fichier CSV donne le même résultat que le fichier Excel", {
  csv <- tempfile(fileext = ".csv")
  utils::write.csv2(readxl::read_excel(exemple), csv, row.names = FALSE)
  a <- suppressWarnings(computeIDGF(suppressWarnings(importIDGF(exemple))))
  b <- suppressWarnings(computeIDGF(suppressWarnings(importIDGF(csv))))
  expect_equal(as.data.frame(a), as.data.frame(b))
})

test_that("un format de fichier inconnu est refusé", {
  expect_error(importIDGF("donnees.txt"), "format")
})
