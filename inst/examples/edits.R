library(shiny)
library(rhandsontable)

ui <- {fluidPage(
  rHandsontableOutput("tbl"),
  h4("Edits"),
  verbatimTextOutput("edit"),
  h4("Paste"),
  verbatimTextOutput("past"),
  h4("Fill"),
  verbatimTextOutput("fill"),
  h4("Undo"),
  verbatimTextOutput("undo"),
  h4("Redo"),
  verbatimTextOutput("redo")
)}

server <- function(input, output, session) {
  output$tbl <- renderRHandsontable({
    iris$Petal.Width = 1:nrow(iris)
    iris <- iris[1:15,]
    rhandsontable(iris, selectCallback = TRUE) %>%
      # hot_cols(columnSorting = TRUE) %>%
      hot_table(highlightCol = TRUE, contextMenu = F, highlightRow = TRUE, stretchH = "all", overflow = "visible") %>%
      # hot_context_menu(allowColEdit = FALSE, allowRowEdit = FALSE) %>%
      # hot_context_menu(copy=TRUE) %>%
      hot_col(col = "Sepal.Length", readOnly = TRUE) %>%
      hot_col(col = "Sepal.Width", readOnly = TRUE) %>%
      hot_col(col = "Petal.Length", readOnly = TRUE) %>%
      hot_col(col = "Petal.Width", type = "numeric", readOnly = FALSE, allowInvalid = FALSE) %>%
      hot_col(col = "Species", readOnly = TRUE) %>%
      hot_validate_numeric(cols = 4, min = 0, max = 10000000000)
  })

  output$edit <- renderPrint({
    req(input$tbl_edit)
    obj <- do.call(cbind, lapply(input$tbl_edit, function(i) unlist(i)))
    obj <- obj[obj[,"oldval"] != obj[,"newval"],]
    req(obj)
    print(obj)
  })
  output$fill <- renderPrint({
    req(input$tbl_fill)
    obj <- do.call(cbind, lapply(input$tbl_fill, function(i) unlist(i)))
    obj <- obj[obj[,"oldval"] != obj[,"newval"],]
    # browser()
    req(obj)
    print(obj)
  })
  output$past <- renderPrint({
    req(input$tbl_pasted)
    # browser()
    obj <- input$tbl_pasted
    cols <- seq(obj$startcol, obj$endcol, 1)
    if (all(cols != 4)) {
      print("colums are readOnly");
      req(FALSE)
    } else {
      col_enabl <- which(cols == 4)
      obj$vals <- unlist(lapply(obj$vals, function(i) {
        i[[col_enabl]]
      }))
    }

    print(paste("start row:", obj$startr))
    print(paste("end row:", obj$endr))
    print(paste("data change:", paste(as.numeric(obj$vals), collapse = ";")))
  })
  output$undo <- renderPrint({
    req(input$tbl_undo)
    obj <- do.call(cbind, lapply(input$tbl_undo, function(i) unlist(i)))
    obj <- obj[obj[,"oldval"] != obj[,"newval"],]
    req(obj)
    print(obj)
  })
  output$redo <- renderPrint({
    req(input$tbl_redo)
    obj <- do.call(cbind, lapply(input$tbl_redo, function(i) unlist(i)))
    obj <- obj[obj[,"oldval"] != obj[,"newval"],]
    req(obj)
    print(obj)
  })

}

shinyApp(ui, server)

