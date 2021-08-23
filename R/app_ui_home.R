#' The app home
#'
#' @import shiny
#' @noRd
app_body_home <- function() {
  tabPanel(
    title = "About",
    # icon = icon("info-circle"),
    id = "tab-home",
    value = "home",
    col_12(
      # class = "home-page",
      h2("About this tool"),
      includeMarkdown(
        app_sys("app/www", "app_body.md")
      ),
      actionButton(
        inputId = "btn_github",
        label = "Source code",
        class = "btn-primary",
        icon = icon("github"),
        onclick = "window.open('https://github.com/ruthkr/nanorod', '_blank')"
      )
    )
  )
}
