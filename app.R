library(shiny)
library(tidyverse)
library(quarto)

items_df <- read.csv("materials/mfqItems.csv", stringsAsFactors = FALSE)

instruments <- c(
  "MFQ-Child-Short (13 items)" = "child-short",
  "MFQ-Parent-Short (13 items)" = "parent-short",
  "MFQ-Child-Long (33 items)" = "child-long",
  "MFQ-Parent-Long (33 items)" = "parent-long"
)

ui <- fluidPage(
  titlePanel("Mood and Feelings Questionnaire"),
  uiOutput("page")
)

server <- function(input, output, session) {
  rv <- reactiveValues(
    page = "clinician",
    session_id = 0L,
    report_path = NULL
  )

  clinician <- reactiveValues(
    email = NULL,
    codeword = NULL,
    instrument = NULL
  )

  output$page <- renderUI({
    switch(rv$page,
      "clinician"     = clinician_page(),
      "questionnaire" = questionnaire_page(),
      "complete"      = complete_page()
    )
  })

  clinician_page <- reactive({
    tagList(
      h3("Clinician Information"),
      textInput("email", "Recipient email address",
        placeholder = "clinician@example.com"),
      textInput("codeword", "Codeword / Identifier",
        placeholder = "e.g., Date and time of appointment"),
      selectInput("instrument", "Assessment instrument",
        choices = names(instruments)),
      actionButton("start", "Start assessment",
        class = "btn-primary btn-lg")
    )
  })

  questionnaire_page <- reactive({
    sid <- rv$session_id
    instr <- clinician$instrument
    form <- instruments[[instr]]
    items <- items_df$item[items_df$form == form]

    tagList(
      h3(instr),
      p(strong("Codeword:"), clinician$codeword),
      hr(),
      tags$div(
        class = "table-responsive",
        tags$table(
          class = "table table-bordered table-hover",
          style = "margin-bottom: 0;",
          tags$thead(
            tags$tr(
              tags$th("Item"),
              tags$th(style = "text-align: center; width: 100px;", "Not True"),
              tags$th(style = "text-align: center; width: 100px;", "Sometimes"),
              tags$th(style = "text-align: center; width: 100px;", "True")
            )
          ),
          tags$tbody(
            lapply(seq_along(items), function(i) {
              nm <- paste0("q", sid, "_", i)
              tags$tr(
                id = nm, class = "shiny-input-radiogroup", role = "radiogroup",
                tags$td(paste0(i, ". ", items[i])),
                tags$td(style = "text-align: center; vertical-align: middle;",
                  tags$input(type = "radio", name = nm, value = "0")
                ),
                tags$td(style = "text-align: center; vertical-align: middle;",
                  tags$input(type = "radio", name = nm, value = "1")
                ),
                tags$td(style = "text-align: center; vertical-align: middle;",
                  tags$input(type = "radio", name = nm, value = "2")
                )
              )
            })
          )
        )
      ),
      hr(),
      actionButton("submit", "Submit",
        class = "btn-success btn-lg")
    )
  })

  complete_page <- reactive({
    tagList(
      h3("Report generated"),
      downloadButton("download", "Download PDF report",
        class = "btn-primary btn-lg"),
      br(), br(),
      actionButton("reset", "Complete another assessment")
    )
  })

  observeEvent(input$start, {
    if (is.null(input$email) || nchar(trimws(input$email)) == 0) {
      showNotification("Please enter a recipient email address.",
        type = "error")
      return()
    }
    clinician$email <- input$email
    clinician$codeword <- input$codeword
    clinician$instrument <- input$instrument
    rv$session_id <- rv$session_id + 1L
    rv$page <- "questionnaire"
  })

  observeEvent(input$submit, {
    sid <- rv$session_id
    instr <- clinician$instrument
    form <- instruments[[instr]]
    items <- items_df$item[items_df$form == form]

    n_answered <- sum(!map_lgl(seq_along(items), ~ is.null(input[[paste0("q", sid, "_", .x)]])))
    n_total <- length(items)
    if (n_answered < n_total) {
      showNotification(
        paste0("Please answer all ", n_total, " items (", n_answered,
               " answered so far)."),
        type = "error", duration = 10
      )
      return()
    }

    responses <- map_dfr(seq_along(items), function(i) {
      val <- input[[paste0("q", sid, "_", i)]]
      tibble(
        Item = items[i],
        Response = if (is.null(val)) NA_character_ else val
      )
    })

    responses <- responses |>
      mutate(
        Score = as.numeric(Response),
        ResponseLabel = factor(Response,
          levels = c("0", "1", "2"),
          labels = c("Not True", "Sometimes", "True"))
      )

    data_path <- tempfile(fileext = ".csv")
    write.csv(responses, data_path, row.names = FALSE)

    withProgress(
      message = "Rendering PDF report...",
      value = 0.5,
      {
        quarto::quarto_render("mfqReport.qmd", execute_params = list(
          instrument = instr,
          codeword = clinician$codeword,
          data_path = data_path
        ), quiet = TRUE)
        incProgress(1, detail = "Done")
      }
    )

    rv$report_path <- "mfqReport.pdf"
    rv$page <- "complete"
  })

  output$download <- downloadHandler(
    filename = function() {
      cw <- gsub("[^A-Za-z0-9]", "_", clinician$codeword)
      paste0("MFQ_", cw, "_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      file.copy(rv$report_path, file)
    }
  )

  observeEvent(input$reset, {
    rv$page <- "clinician"
  })
}

shinyApp(ui, server)
