test_that("l'interface se construit", {
  ui <- app_ui(NULL)
  expect_s3_class(ui, "shiny.tag.list")
  html <- as.character(ui)
  expect_match(html, "doi.org/10.1016/j.ecolind.2020.106248", fixed = TRUE)
})

test_that("le serveur calcule à partir du jeu d'exemple", {
  shiny::testServer(mod_outil_server, {
    session$setInputs(exemple = 1)
    expect_equal(nrow(calcul()$res), 12)
    session$setInputs(releve = "792")
    expect_equal(as.numeric(releve_choisi()$IDGF), 0.87)
  })
})
