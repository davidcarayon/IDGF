#' Sortie graphique de l'IDGF
#'
#' Calcule l'indice IDGF à partir d'une ou plusieurs listes floristiques
#' @param resultat_IDGF Les résultats issus de la fonction IDGF()
#' @return Graphiques radar de chaque relevé présent dans le tableau initial
#'
#' @examples
#' res.IDGF <- IDGF(taxa.GF, lang = "FR")
#' Radar_IDGF(res.IDGF)
#' @importFrom magrittr %>%
#' @export
#'
Diagnostic_IDGF <- function(result_IDGF, lang = "FR"){

  if(lang == "FR") {

  id_releves <- result_IDGF %>% dplyr::mutate(nc = nchar(Classe)) %>%
    dplyr::filter(nc > 0) %>%
    dplyr::pull(id_releve) %>%
    unique()

  result_graph <- result_IDGF %>%
    dplyr::filter(id_releve %in% id_releves) %>%
    dplyr::select(id_releve,MES:SAT) %>%
    dplyr::mutate_at(dplyr::vars(MES:SAT),as.numeric) %>%
    tidyr::gather(key = param, value = EQR, -id_releve) %>%
    dplyr::mutate(radar_metric = 1 - EQR) %>%
    dplyr::mutate(color_radar = ifelse(radar_metric < 0.4, yes = "low", no = "high"))

  for( i in id_releves) {
    plot<-result_graph %>%
      dplyr::filter(id_releve == i) %>%
    ggplot2::ggplot(ggplot2::aes(x = param, y = radar_metric)) +
      ggplot2::geom_bar(ggplot2::aes(fill = color_radar),stat = "identity",color="black", alpha = 0.7) +
      ggplot2::scale_fill_manual(values = c("high" = "indianred2","low" = "steelblue2"))+
      ggplot2::guides(fill = FALSE)+
      ggplot2::geom_text(ggplot2::aes(x = param, y = radar_metric, label = round(EQR,2)), nudge_y = 0.05) +
      ggplot2::ylim(0,1) +
      ggplot2::guides(fill = FALSE) +
      ggplot2::coord_polar() +
      ggplot2::theme_bw() +
      ggplot2::theme(panel.grid.major = ggplot2::element_line(color = "grey75"))+
      ggplot2::labs(title = i) +
      ggplot2::theme(axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank(), axis.title = ggplot2::element_blank()) +
      ggplot2::theme(axis.text.x = ggplot2::element_text(face = "bold",size = 9,color="black"))


    print(plot)

    cat(crayon::green(paste0("\u2713",i,"\n")))

  }}



  if(lang == "ENG") {

    id_releves <- result_IDGF %>% dplyr::mutate(nc = nchar(Class)) %>%
      dplyr::filter(nc > 0) %>%
      dplyr::pull(id_sample) %>%
      unique()

    result_graph <- result_IDGF %>%
      dplyr::filter(id_sample %in% id_releves) %>%
      dplyr::select(id_sample,MES:SAT) %>%
      dplyr::mutate_at(dplyr::vars(MES:SAT),as.numeric) %>%
      tidyr::gather(key = param, value = EQR, -id_sample) %>%
      dplyr::mutate(radar_metric = 1 - EQR) %>%
      dplyr::mutate(color_radar = ifelse(1-EQR < 0.4, yes = "low", no = "high"))

    for( i in id_releves) {
      plot<-result_graph %>%
        dplyr::filter(id_sample == i) %>%
        ggplot2::ggplot(ggplot2::aes(x = param, y = radar_metric)) +
        ggplot2::geom_bar(ggplot2::aes(fill = color_radar),stat = "identity",color="black", alpha = 0.7) +
        ggplot2::scale_fill_manual(values = c("high" = "indianred2","low" = "steelblue2"))+
        ggplot2::guides(fill = FALSE)+
        ggplot2::geom_text(ggplot2::aes(x = param, y = radar_metric, label = round(EQR,2)), nudge_y = 0.05) +
        ggplot2::ylim(0,1) +
        ggplot2::guides(fill = FALSE) +
        ggplot2::coord_polar() +
        ggplot2::theme_bw() +
        ggplot2::theme(panel.grid.major = ggplot2::element_line(color = "grey75"))+
        ggplot2::labs(title = i) +
        ggplot2::theme(axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank(), axis.title = ggplot2::element_blank()) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(face = "bold",size = 9,color="black"))


      print(plot)

      cat(crayon::green(paste0("\u2713",i,"\n")))

    }}

}
