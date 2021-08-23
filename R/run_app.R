#' Run the Shiny Application
#'
#' @param display.mode The mode in which to display the application. If set to the value \code{"showcase"}, shows application code and metadata from a \code{DESCRIPTION} file in the application directory alongside the application. Defaults to \code{"normal"}, which displays the application normally.
#' @param launch.browser If true, the system's default web browser will be launched automatically after the app is started. Defaults to true in interactive sessions only. This value of this parameter can also be a function to call with the application's URL.
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(
  onStart = NULL,
  enableBookmarking = NULL,
  uiPattern = "/",
  display.mode = "normal",
  launch.browser = TRUE,
  ...
) {
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      # options = options,
      options = list(display.mode = display.mode, launch.browser = launch.browser),
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}
