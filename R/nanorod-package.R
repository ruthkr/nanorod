#' \code{nanorod} package
#'
#' See the README on
#' \href{https://github.com/ruthkr/nanorod/}{GitHub}
#'
#' @docType package
#' @name nanorod
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(
    c(
      ".",
      "..density..",
      # Python functions
      "open_DM4",
      "img_prep",
      "watershedding",
      "filter_labels_by_area",
      "filter_labels_by_minor_axis_length",
      "reorder_labels",
      "create_length_prop",
      "plotfig_separate"
    )
  )
}
