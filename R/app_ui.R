#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  # Set global ggplot theme
  ggplot2::theme_set(ggplot2::theme_light())
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    shinydisconnect::disconnectMessage(
      text = "An error occurred. Please refresh the page and try again.",
      refresh = "Refresh",
      background = "#FFFFFF",
      colour = "#444444",
      refreshColour = "#E3825C",
      overlayColour = "#000000",
      overlayOpacity = 0.6,
      width = 450,
      top = 100,
      size = 22,
      css = ""
    ),
    # Your application UI logic
    navbarPage(
      title = app_title("nanorod"),
      theme = theme(),
      collapsible = TRUE,

      app_body_home(),
      selected = "tab-nanorod-detection"
      # mod_nanorod_image_ui("nanorod_image_ui_1"),
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www", app_sys("app/www")
  )

  tags$head(
    favicon(ico = "favicon", ext = "png"),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "nanorod"
    ),
    # Add here other external resources
    shinyjs::useShinyjs()
    # for example, you can add shinyalert::useShinyalert()
  )
}

