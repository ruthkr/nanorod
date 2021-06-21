#' nanorod_stats UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_nanorod_stats_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    title = "Nanorod Detection",
    value = "tab-nanorod-detection",
    sidebarLayout(
      sidebarPanel = sidebarPanel(
        width = 4,
        # Image input ----
        fileInput(
          inputId = ns("nanorod_image_dm4"),
          label = "File input"
        ),
        actionButton(
          inputId = ns("process_image"),
          label = "Process image",
          class = "btn-primary",
          icon = icon("ruler-combined")
        ),

        # Processed image ----
        hr(),
        DT::DTOutput(ns("nanorods_table")),
        shinyjs::disabled(
          actionButton(
            inputId = ns("analyse_data"),
            label = "Analyse",
            class = "btn-primary",
            icon = icon("ruler-combined")
          )
        ),
      ),
      mainPanel = mainPanel(
        width = 8,
        # Results ----
        h2("Results"),
        tabsetPanel(
          type = "tabs",
          tabPanel(
            "Image results",
            fluidRow(
              col_6(plotOutput(ns("nanorods_image_raw"), height = "auto")),
              col_6(plotOutput(ns("nanorods_image_processed"), height = "auto"))
            )
          ),
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
mod_nanorod_stats_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    message("[Nanorods] Started server")

    options(shiny.maxRequestSize = 150 * 1024^2)

    # Load virtualenv
    virtualenv_dir <- Sys.getenv("VIRTUALENV_NAME")
    python_path <- Sys.getenv("PYTHON_PATH")
    reticulate::use_python(python_path, required = TRUE)
    reticulate::use_virtualenv(virtualenv_dir, required = TRUE)

    # Load Python code
    reticulate::source_python("src/electron_microscopy.py")
    skimage <- reticulate::import("skimage")

    react_vals <- reactiveValues()

    # Python image processing ----
    observeEvent(
      input$process_image,
      {
        # Read inputs
        image <- input$nanorod_image_dm4
        image_name <- image$name
        image_path <- image$datapath

        withProgress(message = "Processing DM4 image", {
          incProgress(0, detail = NULL)

          message("[Nanorods] Reading data...")
          incProgress(1 / 5, detail = "Reading image")
          # Read image
          dm4_list <- open_DM4(filepath = image_path) %>%
            `names<-`(c("filename", "img", "pixel_size"))
          binary <- img_prep(img = dm4_list$img)

          # Watershed and label the image
          message("[Nanorods] Processing image...")
          incProgress(2 / 5, detail = "Processing image")
          labels <- binary %>%
            watershedding() %>%
            filter_labels_by_area(
              area_in_nm2 = 500,
              pixel_size = dm4_list$pixel_size
            ) %>%
            filter_labels_by_minor_axis_length(
              length_in_nm = 40,
              pixel_size = dm4_list$pixel_size
            ) %>%
            reorder_labels()

          # Labels properties
          labels_properties <- labels %>%
            skimage$measure$regionprops()

          # Process table
          message("[Nanorods] Summarising data...")
          incProgress(3 / 5, detail = "Summarising data")
          table <- skimage$measure$regionprops_table(
            labels,
            properties = c("label", "centroid", "feret_diameter_max")
          ) %>%
            as.data.frame() %>%
            dplyr::mutate(
              feret_diameter_max = dm4_list$pixel_size * feret_diameter_max,
              image_name = image_name
            ) %>%
            dplyr::select(
              Nanorod_ID = label,
              image_name,
              coord_x = centroid.0,
              coord_y = centroid.1,
              length_in_nm = feret_diameter_max
            )

          # Render plots
          message("[Nanorods] Rendering images...")
          incProgress(4 / 5, detail = "Rendering images")
          temp_img_path <- tempdir()
          plotfig_separate(
            labels = labels,
            region_properties = labels_properties,
            img = dm4_list$img,
            filename = paste0(temp_img_path, "/", image_name),
            out_dpi = 300
          )

          message("[Nanorods] Image processed successfully")
          incProgress(1, detail = "Done")
        })

        showNotification(
          ui = "Image processed successfully"
        )

        # Reactive values
        message("[Nanorods] Saving results into react_vals...")
        react_vals$nanorods_table <- table
        react_vals$plot_raw_path <- paste0(temp_img_path, "/", image_name, "_raw.png")
        react_vals$plot_processed_path <- paste0(temp_img_path, "/", image_name, "_processed.png")
      }
    )

    output$table_input <- DT::renderDT({
      if (input$process_image == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$process_image
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      data_input <- data_path %>%
        utils::read.csv() %>%
        dplyr::select("length_in_nm")

      table <- render_datatable(data_input)

      return(table)
    })

    output$table_stat <- DT::renderDT({
      if (input$process_image == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$process_image
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      stat_df <- get_summary_stat(data_path)

      table <- render_datatable(stat_df)

      return(table)
    })

    output$plot_histogram <- renderPlot(
      {
        if (input$process_image == 0) {
          return(NULL)
        }

        input$process_image
        isolate({
          data <- input$nanorod_lengths_csv
        })

        data_path <- data$datapath

        gg <- plot_hist(csv_path = data_path)

        return(gg$hist_plot)
      },
      res = 96
    )

    output$table_range <- DT::renderDT({
      if (input$process_image == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$process_image
      isolate({
        data <- input$nanorod_lengths_csv
      })

      data_path <- data$datapath

      gg <- plot_hist(csv_path = data_path)

      table <- render_datatable(gg$grouped_length_df)

      return(table)
    })

    output$plot_boxplot <- renderPlot(
      {
        if (input$process_image == 0) {
          return(NULL)
        }

        input$process_image
        isolate({
          data <- input$nanorod_lengths_csv
        })

        data_path <- data$datapath

        gg <- plot_boxplot(csv_path = data_path)

        return(gg)
      },
      res = 96
    )
  })
}

## To be copied in the UI
# mod_nanorod_stats_ui("nanorod_stats_ui_1")

## To be copied in the server
# mod_nanorod_stats_server("nanorod_stats_ui_1")
