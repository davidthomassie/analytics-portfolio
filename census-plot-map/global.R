source("utils.R")

census_logo <- link_logo("census-logo-black.svg", "https://www.census.gov")

urls <- c(
  bluesky = "https://bsky.app/profile/davidthomassie.bsky.social",
  linkedin = "https://www.linkedin.com/in/davidthomassie",
  github = "https://github.com/davidthomassie/analytics-portfolio/tree/main/census-plot-map"
)

nav_icons <- nav_item(
  nav_icon("bluesky", "#add8e6", urls["bluesky"]),
  nav_icon("linkedin", "#0072b1", urls["linkedin"]),
  nav_icon("github", "#333", urls["github"])
)

state_selection <- tags$div(
  tags$head(
    tags$style(
      HTML(".selectize-input {height: 40px !important;}")
    )
  ),
  selectInput(
    "state", NULL, choices = state.name,
    selected = "South Carolina", width = "250px", 
  )
)

info_icon <- \(...) tooltip(bsicons::bs_icon("info-circle"), ...)

page_footer <- tags$div(
  class = "d-flex justify-content-between p-3 text-muted fst-italic",
  tags$small(
    "Data: 2023 5-Year ACS estimates ",
    info_icon(
      tags$div("American Community Survey (2019-2023)"),
      tags$div(
        style = "font-style: italic;",
        "*2022 data used if 2023 estimates unavailable"
      )
    )
  ),
  tags$small("Source: U.S. Census Bureau"),
  tags$small(
    "Developer: David Thomassie ",
    info_icon(
      tags$div("\u00A9 2024"),
      tags$div(
        style = "font-style: italic;",
        "(not affiliated with the U.S. Census Bureau)"
      )
    )
  )
)
