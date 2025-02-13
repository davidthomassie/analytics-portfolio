options(tigris_use_cache = TRUE)

library(tidyverse)
library(tidycensus)
library(shiny)
library(bslib)
library(ggiraph)
library(scales)
library(patchwork)
library(DT)

source("global.R")
source("utils.R")

ui <- page_navbar(
  nav_spacer(),
  nav_panel(
    "Plot + Map",
    tags$div(
      class = "d-flex justify-content-center text-center",
      state_selection, uiOutput("download_btn_ui")
    ),
    uiOutput("plot_map_ui"),
    uiOutput("help_text"),
    card(DTOutput("table"))
  ),
  nav_spacer(),
  nav_icons,
  title = census_logo,
  footer = page_footer,
  fillable = FALSE,
  navbar_options = list(underline = FALSE),
  theme = bs_theme(version = 5, base_font = "Bahnschrift"),
  window_title = "Census Plot + Map"
)

server <- function(input, output, session) {
  output$help_text <- renderUI({
    if (is_null(input$table_rows_selected)) {
      helpText(
        tags$h2(
          class = "text-primary text-center p-2",
          "Click on a row to get started!"
        )
      )
    }
  })
  
  v23 <- read_rds("data/v23_clean.rds")
  
  output$table <- renderDT({
    v23 |> rename_with(str_to_title) |>
      datatable(selection = "single", filter = "top")
  })
  
  row_selected <- reactive({
    req(input$table_rows_selected)
    v23 |> slice(input$table_rows_selected[1])
  })
  
  plot_confirmation <- reactiveVal(NULL)
  confirmed <- reactiveVal(NULL)
  
  output$download_btn_ui <- renderUI({
    if (!is.null(confirmed())) {
      downloadButton(
        class = "btn btn-outline-primary btn-sm px-3 py-2 mx-3 mb-3",
        outputId = "download_acs_csv",
        label = str_glue(
          "{confirmed()$variable}_{abbr(input$state)}.csv"
        )
      )
    }
  })
  
  output$download_acs_csv <- downloadHandler(
    filename = \() str_glue(
      "{confirmed()$variable}_{abbr(input$state)}.csv"
    ),
    content = function(file) {
      acs_data <- get_acs(
        geography = "county",
        state = input$state,
        variables = confirmed()$variable,
        year = 2023
      )
      acs_clean <- acs_data |>
        separate(NAME, into = c("county", "state"), sep = ", ") |>
        mutate(
          county = str_to_title(gsub(" County", "", county)),
          concept = confirmed()$concept,
          label = confirmed()$label
        )
      write_csv(acs_clean, file)
    }
  )
  
  observeEvent(input$table_rows_selected, {
    req(input$table_rows_selected)
    modal_confirmation(
      text_h2 = row_selected()$variable,
      text_h4 = row_selected()$concept,
      text_h5 = row_selected()$label
    )
    plot_confirmation(row_selected())
  })
  
  observeEvent(input$confirm_plot, {
    req(plot_confirmation())
    confirmed(plot_confirmation())
    removeModal()
  })
  
  output$plot_map <- renderGirafe({
    req(confirmed())
    withProgress(message = "Progress:", value = 0, {
      plot_map_acs(
        input$state, confirmed()$variable,
        confirmed(), session = session
      )
    })
  })
  
  output$plot_map_ui <- renderUI({
    req(confirmed())
    card(girafeOutput("plot_map"))
  })
}

shinyApp(ui, server)
