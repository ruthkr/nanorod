#' @importFrom rlang .data
get_summary_stat <- function(data) {
  data <- data %>%
    dplyr::select(nanorod_id = .data$Nanorod_ID, length = .data$length_in_nm)

  length <- data$length

  df <- data.frame(
    "Statistic" = c("Mean", "Median", "SD", "Min", "Max", "Count"),
    "Value" = c(mean(length), stats::median(length), stats::sd(length), min(length), max(length), length(length))
  ) %>%
    dplyr::mutate(Value = round(.data$Value, 2))

  return(df)
}

#' @importFrom rlang .data
plot_hist <- function(data, show_density = FALSE, bin_width = NA, col_choice = "#74add1", bin_accuracy = 5, opacity_choice = 1) {
  # Read data
  data <- data %>%
    dplyr::select(length = .data$length_in_nm)

  # Define the bin width
  if (is.na(bin_width)) {
    # https://stats.stackexchange.com/questions/798/calculating-optimal-number-of-bins-in-a-histogram
    bw <- 2 * stats::IQR(data$length) / length(data$length)^(1 / 3)
  } else {
    bw <- bin_width
  }

  # Define pars for bin
  round_any <- function(x, accuracy, f = round) {
    f(x / accuracy) * accuracy
  }

  length_range <- range(data$length)

  bw_round <- round_any(bw, bin_accuracy, ceiling)

  x_breaks <- seq(
    length_range[[1]] %>% round_any(bin_accuracy, floor) - bw_round,
    length_range[[2]] %>% round_any(bin_accuracy, ceiling) + bw_round,
    bw_round
  )

  df_to_plot <- data %>%
    dplyr::mutate(
      bin = cut(
        length,
        breaks = x_breaks,
        right = FALSE
      )
    ) %>%
    # arrange(Length) %>%
    dplyr::group_by(.data$bin) %>%
    dplyr::summarise(
      count = dplyr::n()
    )

  grouped_df <- df_to_plot %>%
    `colnames<-`(c("Range", "Count"))

  # Plot hist
  gghist <- df_to_plot %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      bin_centre = .data$bin %>%
        stringr::str_extract_all("[0-9]+") %>%
        unlist() %>%
        as.numeric() %>%
        mean()
    ) %>%
    # Plot
    ggplot2::ggplot() +
    ggplot2::geom_col(
      mapping = ggplot2::aes(x = .data$bin_centre, y = .data$count),
      fill = col_choice, color = "#e9ecef", alpha = opacity_choice
    ) +
    ggplot2::scale_x_continuous(breaks = x_breaks) +
    ggplot2::labs(x = "Length (nm)", y = "Counts")

  if (show_density) {
    gghist <- gghist +
      # ggplot2::geom_density(
      #   data = data,
      #   mapping = ggplot2::aes(x = .data$length)
      # )
      ggplot2::geom_line(
        data = data %>% dplyr::select(length),
        mapping = ggplot2::aes(y = ..density..),
        stat = "density"
      )
  }

  list_output <- list(
    grouped_length_df = grouped_df,
    hist_plot = gghist
  )

  return(list_output)
}

#' @importFrom rlang .data
plot_boxplot <- function(data, col_choice = "#74add1", opacity_choice = 1) {
  # Read data
  data <- data %>%
    dplyr::select(length = .data$length_in_nm)

  ggboxplot <- data %>%
    ggplot2::ggplot() +
    ggplot2::aes(y = .data$length) +
    ggplot2::geom_boxplot(fill = col_choice, alpha = opacity_choice) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank()
    ) +
    ggplot2::labs(y = "Length")

  return(ggboxplot)
}
