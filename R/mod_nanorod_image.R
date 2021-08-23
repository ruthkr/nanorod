#' nanorod_image UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_nanorod_image_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    title = "Image Input",
    value = "tab-nanorod-detection",
    icon = shiny::icon("image"),
    sidebarLayout(
      sidebarPanel = sidebarPanel(
        width = 4,
        # Image input ----
        # fileInput(
        #   inputId = ns("nanorod_image_dm4"),
        #   label = "File input"
        # ),
        shinyFiles::shinyDirButton(
          id = ns("nanorods_dir"),
          label = "Input directory",
          title = "Select folder"
        ),
        # shinyjs::disabled(
        #   textInput(
        #     inputId = ns("print_dir_path"),
        #     label = NULL,
        #     value = NULL,
        #   )
        # ),
        widget_sep_vert(),
        actionButton(
          inputId = ns("process_image"),
          label = "Process images",
          class = "btn-primary",
          icon = icon("ruler-combined")
        ),

        # Processed table ----
        hr(),
        DT::DTOutput(ns("nanorods_table")),
        widget_sep_vert(),

        # Analyse data ----
        hr(),
        numericInput(
          inputId = ns("bin_width"),
          label = "Histogram interval width",
          value = NULL
        ),
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
                  selected = 1
                )
              ),
              col_6(plotOutput(ns("nanorods_image_raw"), height = "auto")),
              col_6(plotOutput(ns("nanorods_image_processed"), height = "auto"))
            )
          ),
          tabPanel("Nanorod lengths", DT::DTOutput(ns("table_lengths"))),
          tabPanel("Descriptive statistics", DT::DTOutput(ns("table_stat"))),
          tabPanel("Histogram", plotOutput(ns("plot_histogram"))),
          tabPanel("Grouped Nanorod", DT::DTOutput(ns("table_range"))),
          tabPanel("Boxplot", plotOutput(ns("plot_boxplot")))
        )
      )
    )
  )
}

#' nanorod_image Server Functions
#'
#' @noRd
#' @importFrom rlang .data
mod_nanorod_image_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    message("[Nanorods] Started server")

    options(shiny.maxRequestSize = 150 * 1024^2)

    # Make sure process_image actionButton() is disabled on startup
    shinyjs::disable("process_image")
    observe({
      # req(input$nanorod_image_dm4$datapath)
      req(input$nanorods_dir)
      shinyjs::enable("process_image")
      # updateTextInput(
      #   session = session,
      #   inputId = "print_dir_path",
      #   value = paste0(
      #     tools::file_path_as_absolute("~"),
      #     stringr::str_c(unlist(input$nanorods_dir$path), collapse = "/")
      #   )
      # )
    })

    # Load virtualenv ----
    message("[Nanorods] Loading Python environment...")
    virtualenv_dir <- Sys.getenv("VIRTUALENV_NAME")
    python_path <- pyenv_python(version = Sys.getenv("PYTHON_VERSION"))
    reticulate::use_python(python_path, required = TRUE)
    reticulate::use_virtualenv(virtualenv_dir, required = TRUE)
    message("[Nanorods] Python environment loaded successfully:")
    message(utils::str(reticulate::py_config()))

    # Load Python code
    message("[Nanorods] Loading Python script...")
    reticulate::source_python(app_sys("python/electron_microscopy.py"))
    message("[Nanorods] Python script loaded successfully!")
    skimage <- reticulate::import("skimage")

    react_vals <- reactiveValues()

    # Nanorods directory ----
    shinyFiles::shinyDirChoose(
      input,
      id = "nanorods_dir",
      roots = c(home = "~"), # nanorod = app_sys("extdata"),
      filetypes = c("", "dm4", "tiff", "tff"),
      allowDirCreate = FALSE
    )

    # Python image processing ----
    observeEvent(
      input$process_image,
      {
        # Read folder contents
        home_path <- tools::file_path_as_absolute("~")
        raw_dir <- input$nanorods_dir
        dir <- paste0(home_path, stringr::str_c(unlist(raw_dir$path), collapse = "/"))
        image_names <- list.files(dir, pattern = "*.dm4$") %>%
          stringr::str_remove_all(".dm4")
        temp_img_path <- tempdir()

        # Process images
        table_list <- list()

        for (image_name in image_names) {
          image_path <- paste0(dir, "/", image_name, ".dm4")
          image_iter <- paste0("(", which(image_names == image_name), "/", length(image_names), ")")
          message("[Nanorods] Processing image ", image_name, " ", image_iter, "...")

          withProgress(message = paste("Processing DM4 image ", image_iter), {
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
              skimage$measure$regionprops() %>%
              create_length_prop(pixel_size = dm4_list$pixel_size)

            # Process table
            message("[Nanorods] Summarising data...")
            incProgress(3 / 5, detail = "Summarising data")
            table_list[[image_name]] <- skimage$measure$regionprops_table(
              labels,
              properties = c("label", "centroid", "area")
            ) %>%
              as.data.frame() %>%
              dplyr::mutate(
                area = dm4_list$pixel_size * dm4_list$pixel_size * .data$area,
                image_name = image_name,
                length_in_nm = sapply(X = labels_properties, FUN = function(x) x$length)
              ) %>%
              dplyr::select(
                Nanorod_ID = .data$label,
                .data$image_name,
                coord_x = .data$centroid.0,
                coord_y = .data$centroid.1,
                .data$length_in_nm,
                .data$area
              )

            # Render plots
            message("[Nanorods] Rendering images...")
            incProgress(4 / 5, detail = "Rendering images")
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
        }

        table <- dplyr::bind_rows(table_list)

        showNotification(
          ui = "Image processed successfully"
        )

        # Reactive values
        message("[Nanorods] Saving results into react_vals...")
        react_vals$nanorods_table <- table
        react_vals$images_temp_dir <- temp_img_path
        # react_vals$image_names <- image_names

        # Update image selector
        updateSelectizeInput(
          session = session,
          inputId = "image_thumbnail",
          choices = image_names,
          server = TRUE
        )
        message("[Nanorods] Updated nanorod image selector")
      }
    )

    # Show/hide download button
    observeEvent(input$process_image, {
      if (input$process_image == 0) {
        shinyjs::disable("analyse_data")
      } else {
        shinyjs::enable("analyse_data")
      }
    })

    # Nanorods table ----
    output$nanorods_table <- DT::renderDT({
      if (input$process_image == 0) {
        return(DT::datatable(NULL, style = "bootstrap4"))
      }

      input$process_image
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
      }
    )

    # Images ----
    output$nanorods_image_processed <- renderImage(
      {
        if (input$process_image == 0) {
          return(list(src = ""))
        }

        input$image_thumbnail
        isolate({
          image_name <- input$image_thumbnail
          filename <- paste0(react_vals$images_temp_dir, "/", image_name, "_processed.png")
        })

        # Return a list containing the filename
        list(
          src = filename,
          class = "nanorod-img"
        )
      },
      deleteFile = FALSE
    )

    output$nanorods_image_raw <- renderImage(
      {
        if (input$process_image == 0) {
          return(list(src = ""))
        }

        input$image_thumbnail
        isolate({
          image_name <- input$image_thumbnail
          filename <- paste0(react_vals$images_temp_dir, "/", image_name, "_raw.png")
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
    output$table_lengths <- DT::renderDT({
      if (input$process_image == 0) {
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
          bin_width <- input$bin_width
        })

        gg <- plot_hist(data, show_density = FALSE, bin_width = bin_width)

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
# mod_nanorod_image_ui("nanorod_image_ui_1")

## To be copied in the server
# mod_nanorod_image_server("nanorod_image_ui_1")
