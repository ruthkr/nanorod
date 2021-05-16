#' @import bslib
#' @noRd
theme <- function() {
  theme <- bs_theme(
    version = 4,
    bootswatch = "united",
    primary = "#2B7BE4",
    secondary = "#8dbaf5",
    # success = "#a4c689",
    # warning = "#fdbe4b",
    # info = "#cbd4dd",
    base_font = font_google("Roboto", wght = c(400, 500, 700)),
    heading_font = font_google("Roboto Condensed"),
    code_font = font_google("Fira Code"),
    "font-size-base" = "1rem"
  )

  return(theme)
}

#' @noRd
app_title <- function(title) {
  div(
    img(class = "navbar-custom-logo", src = "www/favicon.png"),
    div(
      class = "title-container",
      span(title),
      span(class = "title-version", as.character(utils::packageVersion("nanorod")))
    )
  )
}
