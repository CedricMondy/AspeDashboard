#' Graphique de la série chronologique des métriques IPR sur une station ou un groupe de stations
#'
#' Cette fonction renvoie un graphique ggplot2 en treillis avec une colonne par métrique IPR et une ligne par station.
#'
#' @param df_metriques Dataframe contenant les données. Il doit contenir une variable "annee" ainsi que
#'     trois variables pour d'identifier les stations (ou points de prélèvement) et les métriques, ainsi que
#'     pour donner la valeur des métriques.
#' @param var_id_sta Variable servant à identifier les stations ou points.
#'     Cette variable donnera les étiquettes des lignes du graphique.
#' @param var_nom_metrique Variable contenant les noms des métriques (ex : dio, dti).
#' @param var_valeur_metrique Variable numérique contenant les valeurs des métriques.
#' @param station_sel Vecteur caractère indiquant les points ou stations à sélectionner.
#' @param nb_colonnes Entier. Nombre de colonnes du graphique. Par défaut nb_colonnes = 7 pour les 7 métriques IPR.
#'     Dans le cas où une seule station est sélectionnée, et seulement dans ce cas, nb_colonnes peut être différent de 7.
#' @param max_axe_y Numérique. Limite supérieure de l'axe des ordonnées. Par défaut max_axe_y = 10.
#' @param id_sta_max_caract Entier. Nombre maximum de caractères dans l'identifiant de la station, au-delà duquel il sera
#'     découpé pour tenir sur plusieurs lignes. Par défaut c'est 25 caractères.
#' @param inv_y Booléen. Indique l'axe des ordonnées pointe vers le bas (TRUE, par défaut) ou
#'     vers le haut. NB pour l'IPR, plus l'indice est faible plus la qualité est élevée.
#'     C'est l'inverse pour l'IPR+.
#' @param orientation Caractère. Par défaut les métriques sont organisées horizontalement (orientation = "h"). Pour permettre
#'     d'organiser les métriques en 2 colonnes correspondant aux métriques de richesse et de densité, il faut
#'     spécifier orientation = "v". Cet argument ne fonctionne que si une seule station est sélectionnée.
#'
#' @return Un graphique ggplot2.
#' @export
#'
#' @importFrom ggplot2 ggplot aes coord_cartesian geom_line geom_point facet_grid facet_wrap labs guides theme element_text
#' @importFrom dplyr enquo filter mutate
#' @importFrom stringr str_wrap
#'
#' @examples
#' \dontrun{
#' # préparation des données
#' metriques <- mef_creer_passerelle() %>%
#' select(-lop_id, -pre_id) %>%
#'   distinct() %>%
#'   mef_ajouter_metriques() %>%
#'   mef_ajouter_libelle() %>%
#'   mef_ajouter_ope_date() %>%
#'   filter(!is.na(ner)) %>%
#'   select(-ends_with("observe"), -ends_with("theorique")) %>%
#'   pivot_longer(cols = ner:dti,
#'                names_to = "metrique",
#'                values_to = "valeur")
#'
#' # affichage
#' gg_temp_metriq_grille(df_metriques = metriques,
#'                       station_sel = c("La Berre à Portel-des-Corbières", "LA BERENCE A GAVRAY"),
#'                       var_id_sta = pop_libelle,
#'                       var_nom_metrique = metrique,
#'                       var_valeur_metrique = valeur)
#'
#' gg_temp_metriq_grille(df_metriques = metriques,
#'                       station_sel = c("La Berre à Portel-des-Corbières"),
#'                       var_id_sta = pop_libelle,
#'                       var_nom_metrique = metrique,
#'                       var_valeur_metrique = valeur,
#'                       nb_colonnes = 2,
#'                       orientation = "v"
#' )
#' }
gg_temp_metriq_grille <- function(df_metriques,
                                  var_id_sta,
                                  var_nom_metrique,
                                  var_valeur_metrique,
                                  station_sel = NULL,
                                  nb_colonnes = 7,
                                  max_axe_y = 10,
                                  id_sta_max_caract = 25,
                                  inv_y = TRUE,
                                  orientation = FALSE)

{
  # gestion évaluation
  var_id_sta <- enquo(var_id_sta)
  var_nom_metrique <- enquo(var_nom_metrique)
  var_valeur_metrique <- enquo(var_valeur_metrique)

  # sélection des données
  if (!is.null(station_sel))
  {
    df_metriques <- df_metriques %>%
      filter(!!var_id_sta %in% station_sel)
  }

  # passage de la variable d'identification de la station en facteur et découpage si dépasse id_sta_max_caract caractères
  df_metriques <- df_metriques %>%
    mutate(
      !!var_id_sta := str_wrap(!!var_id_sta, width = id_sta_max_caract),
      !!var_id_sta := as.factor(!!var_id_sta)
    )

  # graphique de base
  plot_ipr_station <- ggplot(data = df_metriques,
                             aes(x = annee,
                                 y = !!var_valeur_metrique)) +
    geom_line(size = 1) +
    geom_point(size = 2, shape = 16) +
    labs(title = "Evolution des m\u00e9triques IPR",
         x = "",
         y = "") +
    theme(legend.position = "bottom",
          strip.text.x = element_text(size = 8),
          axis.text.x = element_text(angle = 45, hjust = 1))

  # Gestion du nombre de colonnes du graphique. Par défaut c'est 7 mais modifiable dans le cas où une seule station
  if((df_metriques %>% pull(!!var_id_sta) %>% unique() %>% length()) == 1 & # une seule station
      nb_colonnes != 7) {

    plot_ipr_station <- plot_ipr_station +
      facet_wrap(facets = vars(!!var_nom_metrique),
                 ncol = nb_colonnes,
                 dir = orientation) # pour disposition des graf en colonnes on réordonne les modalités des métriques

  } else {

    plot_ipr_station <- plot_ipr_station +
      facet_grid(rows = vars(!!var_id_sta),
                 cols = vars(!!var_nom_metrique))

  }

  # orientation de l'axe des IPR selon l'argument inv_y
  if (inv_y) {
    plot_ipr_station <- plot_ipr_station +
      coord_cartesian(ylim = c(max_axe_y, 0))
  } else {
    plot_ipr_station <- plot_ipr_station +
      coord_cartesian(ylim = c(0, max_axe_y))
  }

  # affichage
  plot_ipr_station
}
