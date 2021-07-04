render_datatable <- function(data, out_filename = "data", selection = "none", ...) {
  table <- DT::datatable(
    data = data,
    style = "bootstrap4",
    rownames = FALSE,
    selection = selection,
    extensions = "Buttons",
    options = list(
      pageLength = 50,
      lengthMenu = list(c(25, 50, 100, -1), c("25", "50", "100", "All")),
      pagingType = "full",
      filter = FALSE,
      lengthChange = TRUE,
      scrollX = TRUE,
      scrollY = 500,
      dom = "
      <'row'<'col-sm-12'l>>
      <'row'<'col-sm-12'tr>>
      <'row'<'col-sm-12'i>>
      <'row'<'col-sm-12 col-md-7'pB>>
      ",
      buttons = list(
        list(
          extend = "collection",
          buttons = list(
            list(extend = "csv", filename = out_filename),
            list(extend = "excel", filename = out_filename)
          ),
          text = "<i class='fa fa-download' role='presentation' aria-label='download icon'></i> Download"
        )
      )
      # dom = "tBp",
      # buttons = list(
      #   list(
      #     extend = "csv",
      #     filename = out_filename
      #   ),
      #   list(
      #     extend = "excel",
      #     filename = out_filename
      #   )
      # )
    ),
    ...
  )

  return(table)
}

render_datatable_justified <- function(data, out_filename = "data", selection = "none", ...) {
  table <- DT::datatable(
    data = data,
    style = "bootstrap4",
    rownames = FALSE,
    selection = selection,
    extensions = "Buttons",
    options = list(
      pageLength = 10,
      filter = FALSE,
      lengthChange = FALSE,
      scrollX = TRUE,
      columnDefs = list(
        # list(width = "100px", targets = c(0)),
        list(className = 'dt-center', targets = c(0, 1))
      ),
      dom = "
      <'row'<'col-sm-12'tr>>
      <'row'<'col-sm-12 col-md-7'pB><'col-sm-12 col-md-5 text-right'i>>
      ",
      buttons = list(
        list(
          extend = "collection",
          buttons = list(
            list(extend = "csv", filename = out_filename),
            list(extend = "excel", filename = out_filename)
          ),
          text = "<i class='fa fa-download' role='presentation' aria-label='download icon'></i> Download"
        )
      )
      # dom = "tBp",
      # buttons = list(
      #   list(
      #     extend = "csv",
      #     filename = out_filename
      #   ),
      #   list(
      #     extend = "excel",
      #     filename = out_filename
      #   )
      # )
    ),
    ...
  )

  return(table)
}

render_datatable_justified_nopage <- function(data, out_filename = "data", selection = "none", ...) {
  table <- DT::datatable(
    data = data,
    style = "bootstrap4",
    rownames = FALSE,
    selection = selection,
    extensions = "Buttons",
    options = list(
      pageLength = 10,
      filter = FALSE,
      lengthChange = FALSE,
      scrollX = TRUE,
      columnDefs = list(
        # list(width = "100px", targets = c(0)),
        list(className = 'dt-center', targets = c(0, 1))
      ),
      dom = "
      <'row'<'col-sm-12'tr>>
      <'row'<'col-sm-12 col-md-7'B><'col-sm-12 col-md-5 text-right'i>>
      ",
      buttons = list(
        list(
          extend = "collection",
          buttons = list(
            list(extend = "csv", filename = out_filename),
            list(extend = "excel", filename = out_filename)
          ),
          text = "<i class='fa fa-download' role='presentation' aria-label='download icon'></i> Download"
        )
      )
      # dom = "tBp",
      # buttons = list(
      #   list(
      #     extend = "csv",
      #     filename = out_filename
      #   ),
      #   list(
      #     extend = "excel",
      #     filename = out_filename
      #   )
      # )
    ),
    ...
  )

  return(table)
}
