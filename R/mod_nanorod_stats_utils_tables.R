render_datatable <- function(data, out_filename = "data") {
  table <- DT::datatable(
    data = data,
    style = "bootstrap4",
    rownames = FALSE,
    selection = "none",
    extensions = "Buttons",
    options = list(
      pageLength = 10,
      filter = FALSE,
      lengthChange = FALSE,
      scrollX = TRUE,
      dom = "tB",
      buttons = list(
        list(
          extend = "csv",
          filename = out_filename
        ),
        list(
          extend = "excel",
          filename = out_filename
        )
      )
    )
  )

  return(table)
}
