#' Boxplot for phenotype data
#'
#' @param data Input data (\code{\link{pathology}} filtered by phenotype, mouse model, and tissue, with mouse models expanded via \code{\link{expand_mouse_model_factor_from_selection}}).
#' @param mouse_model_groups Mouse models
#' @param use_theme_sage Whether to use \code{\link[sagethemes]{theme_sage}}. Defaults to TRUE.
#'
#' @return A ggplot2 object.
#' @export
magora_boxplot <- function(data, mouse_model_groups, use_theme_sage = TRUE) {

  # Generate a set of boxplots for each mouse_model_group
  p <- data[mouse_model_groups] %>%
    purrr::imap(~ magora_boxplot_single(.x, .y, use_theme_sage))

  # Set height proportions based on number of models within each
  model_heights <- magora::pathology_mouse_models[names(p)] %>%
    purrr::map_dbl(length)

  total_models <- sum(model_heights)

  model_heights <- model_heights %>%
    purrr::map_dbl(~ .x / total_models)

  patchwork::wrap_plots(p) +
    patchwork::plot_layout(ncol = 1, heights = model_heights)
}

magora_boxplot_single <- function(data, mouse_model_group, use_theme_sage = TRUE) {
  data <- data %>%
    expand_mouse_model_factor_from_selection(magora::pathology_mouse_models[[mouse_model_group]])

  # Generate annotation for mouse models (facets) that won't have any data
  measured_annotation <- data %>%
    dplyr::count(.data$mouse_model, .drop = FALSE) %>%
    dplyr::filter(.data$n == 0) %>%
    dplyr::mutate(label = "Data Not Available")

  # If data only contains one sex, generate fake data and set alpha and color so that boxplot legend/dodging are correct
  data <- data %>%
    dplyr::mutate(
      alpha = 0.8,
      color = "black"
    )
  if (length(as.character(unique(data[["sex"]]))) != length(levels(data[["sex"]]))) {
    missing_sex <- levels(data[["sex"]])[levels(data[["sex"]]) != as.character(unique(data[["sex"]]))]
    data <- data %>%
      dplyr::bind_rows(
        data %>%
          dplyr::mutate(
            sex = missing_sex,
            alpha = 0,
            color = NA_character_
          )
      ) %>%
      dplyr::mutate(
        sex = forcats::fct_expand(.data$sex, levels(data[["sex"]])),
        sex = forcats::fct_relevel(.data$sex, levels(data[["sex"]]))
      )
  }

  # Check if data is all zeros for setting axis from 0-10
  # Do this before generating "fake" data, so those panels aren't affected
  all_zeros <- nrow(data) > 0 & all(data[["value"]] == 0)

  # If there is no data at all, generate "fake" data that won't be shown, but ensures panels are the same size and appearance of if there was data
  no_data <- nrow(data) == 0

  if (no_data) {
    age_levels <- levels(data[["age"]])
    sex_levels <- levels(data[["sex"]])

    data <- tidyr::crossing(
      age = age_levels,
      sex = sex_levels,
      mouse_model = magora::pathology_mouse_models[[mouse_model_group]]
    ) %>%
      dplyr::mutate(
        value = 0, alpha = 0, color = NA_character_,
        age = forcats::fct_relevel(.data$age, age_levels),
        sex = forcats::fct_relevel(.data$sex, sex_levels),
        mouse_model = forcats::fct_relevel(.data$mouse_model, magora::pathology_mouse_models[[mouse_model_group]])
      )
  }

  p <- ggplot2::ggplot(data) +
    ggplot2::facet_wrap(ggplot2::vars(.data$mouse_model),
      ncol = 2,
      drop = FALSE
    )

  # Box plots
  p <- p +
    ggplot2::geom_boxplot(ggplot2::aes(x = .data$age, y = .data$value, fill = .data$sex, color = .data$color, alpha = .data$alpha), position = ggplot2::position_dodge2(preserve = "single"), outlier.shape = NA) +
    ggplot2::geom_point(ggplot2::aes(x = .data$age, y = .data$value, fill = .data$sex, alpha = .data$alpha, text = .data$value), position = ggplot2::position_jitterdodge(jitter.width = 0.1, seed = 1234)) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_color_identity() +
    ggplot2::scale_x_discrete(drop = FALSE)

  # Axes and scales
  p <- p +
    ggplot2::labs(x = "Age (Months)", y = unique(data[["phenotype_units"]]), fill = "Sex", color = "Sex") +
    sagethemes::scale_fill_sage_d()

  # Set limits - start at 0 and go to range
  # Unless all 0s, then start at 0 and go to 10
  if (all_zeros) {
    p <- p +
      ggplot2::scale_y_continuous(limits = c(0, 10), breaks = scales::pretty_breaks())
  } else {
    p <- p +
      ggplot2::scale_y_continuous(limits = c(0, NA))
  }

  # Annotations
  if (nrow(measured_annotation) > 0) {
    y_range <- ggplot2::layer_scales(p)$y$range$range
    y_mid <- (y_range[[2]] + y_range[[1]]) / 2
    x_mid <- length(levels(data[["age"]])) / 2 + 0.5

    p <- p +
      ggplot2::geom_text(data = measured_annotation, mapping = ggplot2::aes(x = x_mid, y = y_mid, label = .data$label), size = 5, vjust = 0.5, family = ifelse(use_theme_sage, "Lato", ""))
  }

  if (use_theme_sage) {
    p <- p +
      sagethemes::theme_sage(base_size = 16)
  } else {
    p <- p +
      ggplot2::theme_minimal(base_size = 16)
  }

  p <- p +
    ggplot2::theme(
      legend.key = ggplot2::element_blank()
    )

  # Axes set to blank fake data if there is no data, but don't actually want to show the axes
  # Also hide legend, which exists because of fake data
  if (no_data) {
    p <- p +
      ggplot2::theme(
        axis.text.x = ggplot2::element_blank(),
        axis.text.y = ggplot2::element_blank()
      ) +
      ggplot2::guides(fill = FALSE)
  }

  p <- p +
    ggplot2::ggtitle(mouse_model_group) +
    ggplot2::theme(plot.title.position = "plot")

  p
}
