#' nanorod_stats UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_nanorod_stats_ui <- function(id){
  ns <- NS(id)
  tabPanel(
    title = "Nanorod Detection",
    value = "tab-nanorod-detection",

    sidebarLayout(
      sidebarPanel = sidebarPanel(
        width = 5,

        fileInput(
          inputId = ns("nanorod_lengths_csv"),
          label = "File input"
        ),
        actionButton(
          inputId = ns("calculate"),
          label = "Calculate",
          class = "btn-primary",
          icon = icon("calculator")
        )
      ),
      mainPanel = mainPanel(
        width = 7,
        h2("Results"),

        tabsetPanel(
          type = "tabs",
          tabPanel("Nanorod lengths", DT::DTOutput(ns("table_input"))),
          tabPanel("Descriptive statistics", DT::DTOutput(ns("table_stat"))),
          tabPanel("Histogram", plotOutput(ns("plot_histogram"))),
          tabPanel("Grouped Nanorod", DT::DTOutput(ns("table_range"))),
          tabPanel("Boxplot", plotOutput(ns("plot_boxplot")))
        )
      )
    )
  )
}

#' nanorod_stats Server Functions
#'
#' @noRd
mod_nanorod_stats_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    output$table_input <- DT::renderDT({
      if (input$calculate == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$calculate
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      data_input <- data_path %>%
        utils::read.csv(col.names = c("Length"))

      table <- render_datatable(data_input)

      return(table)

    })

    output$table_stat <- DT::renderDT({
      if (input$calculate == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$calculate
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      stat_df <- get_summary_stat(data_path)

      table <- render_datatable(stat_df)

      return(table)

    })

    output$plot_histogram <- renderPlot({
      if (input$calculate == 0) {
        return(NULL)
      }

      input$calculate
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      gg <- plot_hist(csv_path = data_path)

      return(gg$hist_plot)
    }, res = 96)

    output$table_range <- DT::renderDT({
      if (input$calculate == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$calculate
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      gg <- plot_hist(csv_path = data_path)

      table <- render_datatable(gg$grouped_length_df)

      return(table)

    })

    output$plot_boxplot <- renderPlot({
      if (input$calculate == 0) {
        return(NULL)
      }

      input$calculate
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      gg <- plot_boxplot(csv_path = data_path)

      return(gg)
    }, res = 96)
  })
}

## To be copied in the UI
# mod_nanorod_stats_ui("nanorod_stats_ui_1")

## To be copied in the server
# mod_nanorod_stats_server("nanorod_stats_ui_1")
