#' Shiny module UI function for data upload
#'
#' This function represents a shiny dashboard UI module that allows users to
#' upload secuTrial export .zip to the app. This is a prerequisite for using other
#' modules of secuTrialRshiny.
#'
#' @param id string containing a namespace identifier
#' @param label string to be used as sidebar tab label
#' @return shiny.tag list object containing the tab item content
#' @seealso \code{\link{mod_upload_srv}}
#' @import shiny
#' @import shinydashboard
#' @export
#'
mod_upload_UI <- function(id, label){
  ns <- NS(id)
  tabItem(tabName = label,
          fluidRow(
            h2("Data upload"),
            br()
          ),
          fluidRow(
            tags$head(tags$style(".progress-bar{background-color:#dd4b39;}")),
            fileInput(inputId = ns("secuTrial_export_file"),
                      label = "Choose secuTrial export zip",
                      multiple = FALSE,
                      accept = c("zip", "ziparchive", ".zip"),
                      width = 700),
            textOutput(ns("read_sT_data")),
            hr(),
            actionButton(inputId = ns("use_example_data"), label = "Use example data", icon("lightbulb")),
            hr(),
            textOutput(ns("example_sT_data"))
          ),
          fluidRow(
            br(), br(),
            com_footer_UI(ns("file_info"))
          )
  )
}

#' Shiny module server function for data upload
#'
#' This function represents a shiny dashboard server module that allows users to
#' upload secuTrial export .zip to the app. This is a prerequisite for using other
#' modules of secuTrialRshiny.
#'
#' @param input session's input object
#' @param output session's output object
#' @param session session object environment
#' @param sT_export secuTrialdata object generated e.g. with secuTrialR::read_secuTrial()
#' @seealso \code{\link{mod_upload_UI}}
#' @import shiny
#' @importFrom secuTrialR read_secuTrial
#' @importFrom shinyWidgets sendSweetAlert
#' @export
#'
mod_upload_srv <- function(input, output, session, sT_export){
  vals <- reactiveValues()

  # read upload data
  observeEvent(input$secuTrial_export_file$datapath, {
    curr_export <- read_secuTrial(input$secuTrial_export_file$datapath)
    sT_export(curr_export)
  })

  output$read_sT_data <- renderText({
    # catch exception
    if (is.null(input$secuTrial_export_file$datapath)) {
      print("Upload status: Please upload file.")
    } else {
      # select centre dropdown for monitoring cases
      ctr <- sT_export()[[sT_export()$export_options$meta_names$centres]]
      updateSelectInput(session, inputId = "centre",
                        choices = c("all", ctr$mnpctrname)
      )

      if (length(sT_export())) {
        print("Upload status: Upload and reading of data successful.")
      } else {
        print("Upload status: Error: Data could not be read.")
      }
    }
  })

  observe({
    if(length(sT_export())){
      if(!is.null(input$secuTrial_export_file$datapath) & basename(sT_export()$export_options$data_dir) == "0.zip"){
        vals$file_name <- basename(input$secuTrial_export_file$name)
      } else{
        vals$file_name <- basename(sT_export()$export_options$data_dir) ##works for example not for loaded
      }
    } else{
      vals$file_name <- "none"
    }
  })

  observe({
    vals$file_info <- paste0("Loaded file: ", vals$file_name)
  })

  output$file_info <- renderText({
    vals$file_info
  })

  # use example data
  observeEvent(input$use_example_data, {
    path <- system.file("extdata", "sT_exports", "lnames",
                        "s_export_CSV-xls_CTU05_long_ref_miss_en_utf8.zip",
                        package = "secuTrialR")
    curr_export <- read_secuTrial(path)
    sT_export(curr_export)
  })

  observeEvent(input$use_example_data, {
    sendSweetAlert(
      session = session,
      title = "Example data loaded.",
      text = icon("lightbulb"),
      btn_colors = "#ba1e2b",
      btn_labels = "OK"
    )
  })
  return(vals)
}
