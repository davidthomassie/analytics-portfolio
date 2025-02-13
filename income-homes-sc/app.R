library(tidyverse)
library(scales)
library(mapgl)
library(shiny)
library(bslib)
library(shinycssloaders)

source("global.R")
source("utils.R")

ui <- page_navbar(
  nav_spacer(),
  nav_panel(
    title = "Income",
    load_map("income_map", uiOutput("income_help"), reset_income)
  ),
  nav_panel(
    title = "Homes",
    load_map("homes_map", uiOutput("homes_help"), reset_homes)
  ),
  nav_spacer(),
  nav_icons,
  title = census_logo,
  footer = page_footer,
  padding = 5,
  navbar_options = list(underline = FALSE),
  fillable = FALSE,
  theme = bs_theme(
    "nav-link-hover-color" = "#c2ac84 !important;",
    version = 5, base_font = "Bahnschrift"
  ),
  window_title = "Income & Homes - SC"
)

server <- function(input, output, session) {
  clicked <- reactiveVal(FALSE)
  
  help_text <- \(x) if (!x) helpText(help_html)
  
  output$income_help <- renderUI({help_text(clicked())})
  output$homes_help <- renderUI({help_text(clicked())})
  
  income_sc <- read_rds("data/income_sc.rds")
  homes_sc <- read_rds("data/home_values_sc.rds")
  
  output$income_map <- renderMaplibre({
    withProgress(message = "Progress:", value = 0, {
      build_maplibre(income_sc, session = session)
    })
  })
  
  output$homes_map <- renderMaplibre({
    withProgress(message = "Progress:", value = 0, {
      build_maplibre(homes_sc, session = session)
    })
  })
  
  click_handler <- function(id) {
    map_click <- reactive({str_glue("{id}_feature_click")})
    zoom_level <- reactive({str_glue("{id}_zoom")})
    
    observeEvent(input[[map_click()]], {
      clicked(TRUE)
      
      feature_click <- input[[map_click()]]
      lng_lat <- c(feature_click$lng, feature_click$lat)
      
      map_zoom <- input[[zoom_level()]]
      req(map_zoom)
      
      if (map_zoom < 11) {
        maplibre_proxy(id) |>
          fly_to(center = lng_lat, pitch = 60, zoom = 11)
      }
      else if (feature_click$layer == "centroids") {
        maplibre_proxy(id) |>
          fly_to(center = lng_lat, pitch = 60, zoom = 13)
      }
    })
  }
  
  click_handler("income_map")
  click_handler("homes_map")
  
  observeEvent(input$reset_income, {
    output$income_map <- renderMaplibre({
      withProgress(message = "Progress:", value = 0, {
        build_maplibre(income_sc, session = session)
      })
    })
  })
  
  observeEvent(input$reset_homes, {
    output$homes_map <- renderMaplibre({
      withProgress(message = "Progress:", value = 0, {
        build_maplibre(homes_sc, session = session)
      })
    })
  })
}

shinyApp(ui, server)
