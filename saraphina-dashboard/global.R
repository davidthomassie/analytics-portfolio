source("utils.R")

meta_website_year <- read_csv("data/clean/meta_website_year.csv") |>
  mutate(date = ymd(date))

meta_website_month <- read_csv("data/clean/meta_website_month.csv") |>
  mutate(month_name = month(month, label = TRUE, abbr = FALSE))

meta_website_weekday <- read_csv("data/clean/meta_website_weekday.csv") |>
  mutate(weekday_name = wday(weekday, label = TRUE, abbr = FALSE))

meta_website_season <- read_csv("data/clean/meta_website_season.csv") |>
  mutate(season_name = season_levels(season_name))

channels_pal <- set_names(
  unique(meta_website_year$channel_color),
  unique(meta_website_year$channel_name)
)

seasons_pal <- set_names(
  unique(meta_website_season$season_color),
  unique(meta_website_season$season_name)
)

urls <- c(
  website = "https://www.saraphinaportraits.com",
  instagram = "https://www.instagram.com/saraphinaportraits",
  facebook = "https://www.facebook.com/saraphinaportraits",
  github = "https://github.com/davidthomassie/analytics-portfolio/tree/main/saraphina-dashboard"
)

nav_icons <- nav_item(
  nav_icon("squarespace", channels_pal["Website"], urls["website"]),
  nav_icon("instagram", channels_pal["Instagram"], urls["instagram"]),
  nav_icon("facebook", channels_pal["Facebook"], urls["facebook"])
)

title_saraphina <- make_title(
  "saraphina-logo.svg", "#c2ac84", "Saraphina Portraits", urls["website"]
)

info_icon <- \(...) tooltip(bsicons::bs_icon("info-circle"), ...)

info_github <- tooltip(
  tags$a(
    icon(style = "color: #333;", "github"), href = urls["github"],
    target = "_blank", rel = "noopener noreferrer"
  ),
  tags$div("\u00A9 2024 David Thomassie"),
  tags$div(
    style = "font-style: italic;",
    "(not affiliated with the U.S. Census Bureau)"
  )
)

page_footer <- tags$div(
  class = "d-flex justify-content-between p-3 text-muted fst-italic",
  tags$small(
    "Data ",
    info_icon(
      tags$div(
        style = "text-align: left;",
        tags$li("Website clicks"),
        tags$li("Instagram followers"),
        tags$li("Facebook likes"),
        tags$li("ACS5 income estimates")
      )
    )
  ),
  tags$small(
    "Source ",
    info_icon(
      tags$div(
        style = "text-align: left;",
        tags$li("Google Search Console"),
        tags$li("Meta Business Suite"),
        tags$li("U.S. Census Bureau")
      )
    )
  ),
  tags$small("Developer ", info_github)
)

year_totals <- meta_website_year |>
  group_by(channel_name) |> summarize(total = sum(day_total)) |>
  pivot_wider(names_from = channel_name, values_from = total)

month_averages <- meta_website_month |>
  group_by(channel_name) |>
  summarize(month_average = round(mean(month_total), 2)) |>
  pivot_wider(names_from = channel_name, values_from = month_average)

weekday_averages <- meta_website_weekday |>
  group_by(channel_name) |>
  summarize(weekday_average = round(mean(weekday_total), 2)) |>
  pivot_wider(names_from = channel_name, values_from = weekday_average)

season_averages <- meta_website_season |>
  group_by(season_name) |>
  summarize(season_average = round(mean(season_total), 2)) |>
  pivot_wider(names_from = season_name, values_from = season_average)

year_vbs <- layout_columns(
  val_box(
    "Website clicks", year_totals$Website, "squarespace",
    channels_pal["Website"], tags$p("Yearly total")
  ),
  val_box(
    "Instagram followers", year_totals$Instagram, "instagram",
    channels_pal["Instagram"], tags$p("Yearly total")
  ),
  val_box(
    "Facebook page likes", year_totals$Facebook, "facebook",
    channels_pal["Facebook"], tags$p("Yearly total")
  )
)
  
month_vbs <- layout_columns(
  val_box(
    "Website clicks", month_averages$Website, "squarespace",
    channels_pal["Website"], tags$p("Monthly average")
  ),
  val_box(
    "Instagram followers", month_averages$Instagram, "instagram",
    channels_pal["Instagram"], tags$p("Monthly average")
  ),
  val_box(
    "Facebook page likes", month_averages$Facebook, "facebook",
    channels_pal["Facebook"], tags$p("Monthly average")
  )
)

weekday_vbs <- layout_columns(
  val_box(
    "Website clicks", weekday_averages$Website, "squarespace",
    channels_pal["Website"], tags$p("Weekday average")
  ),
  val_box(
    "Instagram followers", weekday_averages$Instagram, "instagram",
    channels_pal["Instagram"], tags$p("Weekday average")
  ),
  val_box(
    "Facebook page likes", weekday_averages$Facebook, "facebook",
    channels_pal["Facebook"], tags$p("Weekday average")
  )
)

season_vbs <- layout_columns(
  val_box(
    "Spring", season_averages$Spring, "tree",
    seasons_pal["Spring"], tags$p("Seasonal average")
  ),
  val_box(
    "Summer", season_averages$Summer, "sun",
    seasons_pal["Summer"], tags$p("Seasonal average")
  ),
  val_box(
    "Autumn", season_averages$Autumn, "leaf",
    seasons_pal["Autumn"], tags$p("Seasonal average")
  ),
  val_box(
    "Winter", season_averages$Winter, "snowflake",
    seasons_pal["Winter"], tags$p("Seasonal average")
  )
)

reset_button <- actionButton("reset", "Reset", icon("rotate-left"))
