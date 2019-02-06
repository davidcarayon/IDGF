model_IDGF <- function(meanEQR) {

  value = round((3.626943 * meanEQR) -2.626943,2)

  ifelse(value < 0, yes = return(0), no = return(value))

}


Metric2EQR <- function(metric,HER,par) {
  refvalue = table_ref %>% dplyr::filter(numher1 == HER & param == par) %>%
    dplyr::select(ref) %>% dplyr::pull()
  value = metric/refvalue
  EQR = round(ifelse(value > 1, yes = 1, no = value),3)
  return(EQR)

}

Ratio2Class <- function(x,boundaries = c(0.2,0.4,0.6,0.8), number = TRUE, language = "FR") {

  if(length(boundaries) != 4 | !is.numeric(boundaries)) {
    stop("The boundaries argument should be a numeric vector of length 4")
  }


  if(number) {
    class <- dplyr::case_when(x < boundaries[1] ~ 5,
                       x >= boundaries[1] & x < boundaries[2] ~ 4,
                       x >= boundaries[2] & x < boundaries[3]~3,
                       x >= boundaries[3] & x < boundaries[4]~2,
                       x >= boundaries[4] ~ 1)

    return(class)

  } else {


    if(language %in% c("FR","ENG") == FALSE) {
      stop("Language should be one of two : 'FR' or 'ENG'")
    }


    if(language == "ENG") {

      class <- dplyr::case_when(x < boundaries[1] ~ "Poor",
                         x >= boundaries[1] & x < boundaries[2] ~ "Bad",
                         x >= boundaries[2] & x < boundaries[3]~"Moderate",
                         x >= boundaries[3] & x < boundaries[4]~"Good",
                         x >= boundaries[4] ~ "High")

    }

    if(language == "FR") {

      class <- dplyr::case_when(x < boundaries[1] ~ "Mauvais",
                         x >= boundaries[1] & x < boundaries[2] ~ "Médiocre",
                         x >= boundaries[2] & x < boundaries[3]~"Moyen",
                         x >= boundaries[3] & x < boundaries[4]~"Bon",
                         x >= boundaries[4] ~ "Très bon")

    }

    return(class)

  }

}




