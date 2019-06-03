#' Sorties graphiques de l'IDGF
#'
#' Produit des diagrammes d'appui au diagnostic basés sur les résultats d'un IDGF
#' @param result_IDGF Les résultats issus de la fonction `IDGF()`
#' @return Graphiques d'appui au diagnostic pour chaque relevé présent dans le tableau initial
#'
#' @examples
#' res.IDGF <- IDGF(taxa.GF)
#' Diagnostic_IDGF(res.IDGF)
#' @importFrom magrittr %>%
#' @export
#'
Diagnostic_IDGF <- function(result_IDGF){

  id_releves <- result_IDGF %>% dplyr::mutate(nc = nchar(Classe)) %>%
    dplyr::filter(nc > 0) %>%
    dplyr::pull(id_releve) %>%
    unique()

  result_graph <- result_IDGF %>%
    dplyr::filter(id_releve %in% id_releves) %>%
    dplyr::select(id_releve,MES:SAT.O2) %>%
    dplyr::mutate_at(dplyr::vars(MES:SAT.O2),as.numeric) %>%
    tidyr::gather(key = param, value = EQR, -id_releve) %>%
    dplyr::mutate(radar_metric = 1 - EQR) %>%
    dplyr::mutate(param = factor(param, levels = c("SAT.O2","Mat.Orga","N-Orga","P-Trophie","NO3","MINE.","MES")))

  for( i in id_releves) {

    class <- result_IDGF %>% dplyr::filter(id_releve == i) %>% dplyr::pull(Classe)

    plot<-result_graph %>%
      dplyr::filter(id_releve == i) %>%
    ggplot2::ggplot(ggplot2::aes(x = param, y = radar_metric)) +
      ggplot2::geom_bar(ggplot2::aes(fill = EQR),stat = "identity",color="black") +
      ggplot2::scale_y_continuous(limits = c(0,1))+
      ggplot2::scale_fill_gradientn(breaks = c(0,0.2,0.4,0.6,0.8,1.0), limits = c(0,1),colours = c("#FC4E07", "#E7B800", "#00AFBB"))+
      ggplot2::coord_polar() +
      ggplot2::theme_bw() +
      ggplot2::theme(panel.grid.major = ggplot2::element_line(color = "grey75"))+
      ggplot2::labs(title = paste0("Station = ",i,"\nÉtat : ",class)) +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face= "bold"))+
      ggplot2::theme(axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank(), axis.title = ggplot2::element_blank()) +
      ggplot2::theme(axis.text.x = ggplot2::element_text(face = "bold",size = 11,color="black"))


    print(plot)

    cat(crayon::green(paste0("\u2713 Graphique exporté pour la station...",i,"\n")))

  }



}
