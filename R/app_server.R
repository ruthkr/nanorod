#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  mod_nanorod_image_server("nanorod_image_ui_1")
  mod_nanorod_excel_server("nanorod_excel_ui_1")
}
