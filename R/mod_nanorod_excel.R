#' nanorod_excel UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_nanorod_excel_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    title = "Excel Input",
    value = "tab-nanorod-read",
    icon = shiny::icon("file-excel"),
    sidebarLayout(
      sidebarPanel = sidebarPanel(
        width = 4,
        # shinyFiles::shinyDirButton(
        #   id = ns("nanorods_dir"),
        #   label = "Input directory",
        #   title = "Select folder"
        # ),
        shiny::fileInput(
          inputId = ns("nanorods_xlsx_file"),
          label = "Choose Excel File",
          multiple = TRUE,
          accept = c(".csv", ".xlsx", ".xls", ".png", ".mrc")
        ),
        widget_sep_vert(),
        sliderInput(
          inputId = ns("length_range"),
          label = "Range of nanorod length",
          min = 0,
          max = 300,
          step = 10,
          value = c(0, 300),
          post = " nm"
        ),
        actionButton(
          inputId = ns("read_files"),
          label = "Read files",
          class = "btn-primary",
          icon = icon("file-upload")
        ),

        # Processed table ----
        hr(),
        DT::DTOutput(ns("nanorods_table")),
        widget_sep_vert(),

        # Analyse data ----
        hr(),
        shinyjs::disabled(
          actionButton(
            inputId = ns("analyse_data"),
            label = "Analyse",
            class = "btn-primary",
            icon = icon("cogs")
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
              col_12(
                style = "padding-top: 20px;",
                selectizeInput(
                  inputId = ns("image_thumbnail"),
                  label = "Select image to preview",
                  choices = NULL,
                  selected = 1,
                  width = "600"
                )
              ),
              col_12(plotOutput(ns("nanorods_image_output"), height = "auto"))
            )
          ),
          tabPanel(
            "Nanorod lengths",
            DT::DTOutput(ns("table_lengths"))
          ),
          tabPanel(
            "Descriptive statistics",
            DT::DTOutput(ns("table_stat"))
          ),
          tabPanel(
            "Histogram",
            plotOutput(ns("plot_histogram")),
            numericInput(
              inputId = ns("bin_width"),
              label = "Histogram interval width",
              value = NULL
            ),
            colourpicker::colourInput(
              inputId = ns("histogram_colour"),
              label = "Histogram colour",
              showColour = "background",
              palette = "limited",
              value = "#74add1",
              allowedCols = c(
                "#1b7837", "#5aae61", "#b2df8a", "#a6dba0", "#4575b4", "#74add1", "#abd9e9", "#8da0cb",
                "#8073ac", "#d73027", "#f46d43", "#fb9a99", "#fdae61", "#fee090", "#b3b3b3", "#000000"
              )
            )
          ),
          tabPanel(
            "Grouped Nanorod",
            DT::DTOutput(ns("table_range"))
          ),
          tabPanel(
            "Boxplot",
            plotOutput(ns("plot_boxplot"))
          )
        )
      )
    )
  )
}

#' nanorod_excel Server Functions
#'
#' @noRd
#' @importFrom rlang .data
mod_nanorod_excel_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    message("[Nanorods] Started server")

    options(shiny.maxRequestSize = 150 * 1024^2)

    # Make sure read_files actionButton() is disabled on startup
    shinyjs::disable("read_files")
    observe({
      # req(input$nanorods_dir)
      req(input$nanorods_xlsx_file$datapath)
      shinyjs::enable("read_files")
      # updateTextInput(
      #   session = session,
      #   inputId = "print_dir_path",
      #   value = paste0(
      #     tools::file_path_as_absolute("~"),
      #     stringr::str_c(unlist(input$nanorods_dir$path), collapse = "/")
      #   )
      # )
    })

    react_vals <- reactiveValues()

    # Nanorods directory ----
    # shinyFiles::shinyDirChoose(
    #   input,
    #   id = "nanorods_dir",
    #   roots = c(home = "~"), # nanorod = app_sys("extdata"),
    #   filetypes = c("", "xlsx", "xls", "png"),
    #   allowDirCreate = FALSE
    # )

    # Python image processing ----
    observeEvent(
      input$read_files,
      {
        # Either use {shiny} or {shinyFile} to upload files
        upload_method <- "shiny"
        length_range <- input$length_range

        if (upload_method == "shiny") {
          # Read folder contents
          files <- input$nanorods_xlsx_file
          excel_path <- files %>%
            dplyr::filter(stringr::str_detect(.data$name, "\\.xls*.$")) %>%
            dplyr::pull(.data$datapath)
          image_names <- files %>%
            dplyr::filter(stringr::str_detect(.data$name, "\\.png$"))
          temp_img_path <- NULL

          # Read XLSX file
          table <- excel_path %>%
            purrr::map(readxl::read_xlsx) %>%
            purrr::reduce(dplyr::bind_rows)
        } else if (upload_method == "shinyFiles") {
          # Read folder contents
          home_path <- tools::file_path_as_absolute("~")
          raw_dir <- input$nanorods_dir
          dir <- paste0(home_path, stringr::str_c(unlist(raw_dir$path), collapse = "/"))
          excel_path <- list.files(dir, pattern = "*.xls*.$")
          image_names <- list.files(dir, pattern = "*.png$") %>%
            stringr::str_remove_all(".png")
          temp_img_path <- dir

          # Read XLSX file
          table <- readxl::read_xlsx(paste0(dir, "/", excel_path))
        }

        # Process XLSX file
        if (!("Area in nm square" %in% colnames(table))) {
          table$`Area in nm square` <- NA
        }

        table <- table %>%
          dplyr::select(
            image_name = .data$`Image name`,
            Nanorod_ID = .data$`Nanorod ID`,
            length_in_nm = .data$`Length in nm`,
            area = .data$`Area in nm square`,
            coord_x = .data$`Coordinate in X`,
            coord_y = .data$`Coordinate in Y`
          ) %>%
          dplyr::mutate(
            image_name = stringr::str_replace_all(.data$image_name, ".mrc$", ".png")
          ) %>%
          dplyr::filter(
            .data$length_in_nm >= length_range[[1]],
            .data$length_in_nm <= length_range[[2]]
          )

        showNotification(
          ui = "Files read successfully"
        )

        # Reactive values
        message("[Nanorods] Saving results into react_vals...")
        react_vals$nanorods_table <- table
        react_vals$images_temp_dir <- temp_img_path

        # Update image selector
        updateSelectizeInput(
          session = session,
          inputId = "image_thumbnail",
          choices = image_names$name,
          # choices = image_names,
          server = TRUE
        )
        message("[Nanorods] Updated nanorod image selector")
      }
    )

    # Show/hide download button
    observeEvent(input$read_files, {
      if (input$read_files == 0) {
        shinyjs::disable("analyse_data")
      } else {
        shinyjs::enable("analyse_data")
      }
    })

    # Nanorods table ----
    output$nanorods_table <- DT::renderDT(server = FALSE, {
      if (input$read_files == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$read_files
      isolate({
        data <- react_vals$nanorods_table
      })

      # For debugging
      # data <- iris %>%
      #   `colnames<-`(c("Nanorod_ID", "length_in_nm", "coord_x", "coord_y"))

      table <- data %>%
        dplyr::select(
          .data$image_name,
          .data$Nanorod_ID,
          .data$length_in_nm,
          .data$area
          # .data$coord_x,
          # .data$coord_y
        ) %>%
        render_datatable(
          selection = "multiple",
          colnames = c("Image name", "ID", "Length (nm)", "Area (nm\u00b2)")
        ) %>%
        DT::formatRound(
          columns = c("length_in_nm", "area"),
          digits = 2
        )

      return(table)
    })

    observeEvent(
      input$analyse_data,
      {
        data <- react_vals$nanorods_table
        sel_rows <- input$nanorods_table_rows_selected

        lengths <- data %>%
          dplyr::select(.data$image_name, .data$Nanorod_ID, .data$length_in_nm, .data$area)

        if (!is.null(sel_rows)) {
          lengths <- lengths %>%
            dplyr::slice(-sel_rows)
        }
        react_vals$lengths <- lengths

        showNotification(
          ui = "Data analysed successfully"
        )
      }
    )

    # Images ----
    output$nanorods_image_output <- renderImage(
      {
        if (input$image_thumbnail == "") {
          return(list(src = ""))
        }

        input$image_thumbnail
        isolate({
          image_name <- input$image_thumbnail
          filename <- input$nanorods_xlsx_file %>%
            dplyr::filter(.data$name == image_name) %>%
            dplyr::pull(.data$datapath)
          # filename <- paste0(react_vals$images_temp_dir, "/", image_name, ".png")
        })

        # Return a list containing the filename
        list(
          src = filename,
          class = "nanorod-img"
        )
      },
      deleteFile = FALSE
    )

    # Other outputs ----
    output$table_lengths <- DT::renderDT(server = FALSE, {
      if (input$read_files == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$analyse_data
      isolate({
        data <- react_vals$lengths
      })

      table <- data %>%
        render_datatable_justified(
          colnames = c("Image name", "ID", "Length (nm)", "Area (nm\u00b2)")
        ) %>%
        DT::formatRound(
          columns = c("length_in_nm", "area"),
          digits = 2
        )

      return(table)
    })

    output$table_stat <- DT::renderDT({
      if (input$analyse_data == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$analyse_data
      isolate({
        data <- react_vals$lengths
      })

      stat_df <- get_summary_stat(data)

      table <- render_datatable_justified_nopage(stat_df)

      return(table)
    })

    output$plot_histogram <- renderPlot(
      {
        if (input$analyse_data == 0) {
          return(NULL)
        }

        input$analyse_data
        isolate({
          data <- react_vals$lengths
        })

        bin_width <- input$bin_width
        colour <- input$histogram_colour

        gg <- plot_hist(
          data,
          show_density = FALSE,
          bin_width = bin_width,
          col_choice = colour
        )

        return(gg$hist_plot)
      },
      res = 96
    )

    output$table_range <- DT::renderDT({
      if (input$analyse_data == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$analyse_data
      isolate({
        data <- react_vals$lengths
        bin_width <- input$bin_width
      })

      gg <- plot_hist(data, show_density = FALSE, bin_width = bin_width)
      table <- render_datatable_justified(gg$grouped_length_df)

      return(table)
    })

    output$plot_boxplot <- renderPlot(
      {
        if (input$analyse_data == 0) {
          return(NULL)
        }

        input$analyse_data
        isolate({
          data <- react_vals$lengths
        })

        gg <- plot_boxplot(data)

        return(gg)
      },
      res = 96
    )
  })
}

## To be copied in the UI
# mod_nanorod_excel_ui("nanorod_excel_ui_1")

## To be copied in the server
# mod_nanorod_excel_server("nanorod_excel_ui_1")
