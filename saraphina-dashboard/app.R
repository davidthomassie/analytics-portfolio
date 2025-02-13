library(tidyverse)
library(scales)
library(shiny)
library(shinycssloaders)
library(bslib)
library(ggiraph)
library(mapgl)
library(DT)

source("global.R")
source("utils.R")

ui <- page_navbar(
  nav_spacer(),
  nav_panel(
    title = "Overview",
    navset_tab(
      nav_spacer(),
      ggiraph_panel("Year", year_vbs, "area_col_year"),
      ggiraph_panel("Month", month_vbs, "tile_month"),
      ggiraph_panel("Weekday", weekday_vbs, "seg_pt_weekday"),
      ggiraph_panel("Season", season_vbs, "col_season")
    )
  ),
  nav_panel(
    title = "Marketing",
    load_map("income_map", uiOutput("help_text"), reset_button)
  ),
  nav_panel(
    title = "Data",
    dt_accordion("Year", "year_table", open = TRUE),
    dt_accordion("Month", "month_table"),
    dt_accordion("Weekday", "weekday_table"),
    dt_accordion("Season", "season_table")
  ),
  nav_spacer(),
  nav_icons,
  title = title_saraphina,
  footer = page_footer,
  navbar_options = list(underline = FALSE),
  fillable = FALSE,
  theme = bs_theme(
    "nav-link-color" = "#0e1111;",
    "navbar-light-active-color" = "#c2ac84;",
    "nav-tabs-link-active-color" = "#c2ac84;",
    "nav-link-hover-color" = "#c2ac84 !important;",
    version = 5, base_font = "Bahnschrift"
  ),
  window_title = "Saraphina Dashboard"
)

server <- function(input, output, session) {
  output$area_col_year  <- renderGirafe({
    ggiraph_plot(
      ggiraph_area_col(
        meta_website_year, date, day_total, channel_name, day_tooltip
      ) +
      facet_wrap(
        ~fct_rev(channel_name), ncol = 1, strip.position = "left"
      ) +
      scale_fill_manual(values = channels_pal)
    )
  })
  
  output$tile_month <- renderGirafe({
    ggiraph_plot(
      meta_website_month |>
        ggiraph_tile(
          month_name, channel_name, month_total, month_tooltip
        ) +
        scale_y_discrete(labels = names(channels_pal)) +
        scale_fill_manual(values = channels_pal)
    )
  })
  
  output$seg_pt_weekday <- renderGirafe({
    ggiraph_plot(
      meta_website_weekday |>
        ggiraph_seg_pt(
          channel_name, weekday_total, weekday_name, weekday_tooltip
        ) +
        scale_color_manual(values = channels_pal)
    )
  })
  
  output$col_season <- renderGirafe({
    ggiraph_plot(
      meta_website_season |>
        ggiraph_col(
          season_total, season_name, channel_name, season_tooltip
        ) +
        scale_y_discrete(labels = season_trees_png()) +
        scale_fill_manual(values = channels_pal)
    )
  })
  
  clicked <- reactiveVal(FALSE)
  
  output$help_text <- renderUI({
    if (!clicked()) {
      helpText(
        tags$h3(
          class = "text-primary text-center p-2",
          "Click on a block group to get started!"
        )
      )
    }
  })
  
  income_sc <- read_rds("data/clean/income_sc.rds")
  
  output$income_map <- renderMaplibre({
    withProgress(message = "Progress:", value = 0, {
      build_maplibre(income_sc, session = session)
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
  
  observeEvent(input$reset, {
    clicked(FALSE)
    output$income_map <- renderMaplibre({
      withProgress(message = "Progress:", value = 0, {
        build_maplibre(income_sc, session = session)
      })
    })
  })

  output$year_table <- load_table(meta_website_year)
  output$month_table <- load_table(meta_website_month)
  output$weekday_table <- load_table(meta_website_weekday)
  output$season_table <- load_table(meta_website_season)
}

shinyApp(ui, server)
