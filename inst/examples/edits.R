library(shiny)
library(shinyjs)
library(rhandsontable)

get_table_selection <- function(obj) {
  ## Split at every 4th position
  split4 <- length(obj)/4
  numlist = split(obj, rep(1:split4, each=4))
  rowres <- vector("list", split4)
  for (i in 1:length(numlist)) {
    ## Only Range is returned from rhandsontable
    ## Subtract only odd elements (rowstart/rowend) and increase by 1
    odds <- numlist[[i]][c(1,3)]+1
    ## Make the selection sequence
    rowres[[i]] <- odds[1]:odds[2]
  }
  sort(unique(unlist(rowres)))
}

ui <- {fluidPage(
  useShinyjs(),
  actionButton("browse", "Browser"),
  rHandsontableOutput("tbl"),
  actionButton("selectcells", "Select random cells"),
  h4("Selected"),
  verbatimTextOutput("selected"),
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
  observeEvent(input$browse, {browser()})
  output$tbl <- renderRHandsontable({
    iris$Petal.Width = 1:nrow(iris)
    iris <- iris[1:15,c(1,1,2,3,4,5)]
    rhandsontable(iris, selectCallback = TRUE,
                  allowRemoveRow=FALSE, allowRemoveColumn=FALSE,
                  allowInsertRow=FALSE, allowInsertColumn=FALSE,
                  allowEmpty=FALSE, allowInvalid=FALSE
                  ,autoColumnSize=FALSE, autoRowSize=FALSE,
                  manualRowMove =TRUE,manualColumnMove = TRUE,
                  manualColumnResize=TRUE,
                  autoWrapCol=FALSE, autoWrapRow=FALSE
                  ,dragToScroll=FALSE) %>%
      # hot_cols(columnSorting = TRUE) %>%
      hot_table(highlightCol = TRUE, contextMenu = F, highlightRow = TRUE, stretchH = "all", overflow = "visible") %>%
      # hot_context_menu(allowColEdit = FALSE, allowRowEdit = FALSE) %>%
      # hot_context_menu(copy=TRUE) %>%
      hot_col(col = "Sepal.Length", readOnly = FALSE) %>%
      hot_col(col = "Sepal.Width", readOnly = FALSE) %>%
      hot_col(col = "Petal.Length", readOnly = FALSE) %>%
      hot_col(col = "Petal.Width", type = "numeric", readOnly = FALSE, allowInvalid = FALSE) %>%
      hot_col(col = "Species", readOnly = FALSE) %>%
      hot_validate_numeric(cols = 4, min = 0, max = 10000000000)
  })

  output$selected <- renderPrint({
    # req(input$tbl_selected)
    if (is.null(input$tbl_selected)) {
      NULL
    } else {
      obj <- get_table_selection(input$tbl_selected)
      print(paste("Selected Rows: ", paste(obj, collapse = ", ")))
    }
  })

  observeEvent(input$selectcells, {

    rows = sort(sample(x = 0:14, size = 4, replace = F))

    editablecol = 3
    hotjs <- "HTMLWidgets.getInstance(document.getElementById('tbl'))."
    hotcels <- paste0("hot.selectCells([[",rows[1],", ",editablecol,", ",rows[2],", ",editablecol,"], ",
                      "[",rows[3],", ",editablecol,", ",rows[4],", ",editablecol,"]]);")
    cmd <- paste0(hotjs, hotcels)
    print(cmd)
    shinyjs::delay(200, shinyjs::runjs(HTML(cmd)))

    # HTMLWidgets.getInstance(document.getElementById('tbl')).hot.selectCells([[1, 3, 6, 3], [9, 3, 13, 3]]);
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


# var hot = HTMLWidgets.getInstance(document.getElementById('tbl'))
# hot.hot.selectRows(1);
# hot.hot.selectRows(1,4);
# hot.hot.selectRows([[1,4],[6,7]]);
# hot.hot.getSelected()
## rostar/colstart/rowend/colend
# hot.hot.selectCells([[0, 3, 2, 3],[5, 3, 8, 3]]);

