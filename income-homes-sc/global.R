source("utils.R")

census_logo <- link_logo("census-logo-black.svg", "https://www.census.gov")

urls <- c(
  bluesky = "https://bsky.app/profile/davidthomassie.bsky.social",
  linkedin = "https://www.linkedin.com/in/davidthomassie",
  github = "https://github.com/davidthomassie/analytics-portfolio/tree/main/income-homes-sc"
)

nav_icons <- nav_item(
  nav_icon("bluesky", "#add8e6", urls["bluesky"]),
  nav_icon("linkedin", "#0072b1", urls["linkedin"]),
  nav_icon("github", "#333", urls["github"])
)

help_html <- tags$h3(
  class = "text-primary text-center p-2",
  "Click on a tract to get started!"
)

reset_income <- reset_button("reset_income")
reset_homes <- reset_button("reset_homes")

info_icon <- \(...) tooltip(bsicons::bs_icon("info-circle"), ...)

page_footer <- tags$div(
  class = "d-flex justify-content-between p-3 text-muted fst-italic",
  tags$small(
    "Data: 2023 5-Year ACS estimates ",
    info_icon("American Community Survey (2019-2023)")
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
