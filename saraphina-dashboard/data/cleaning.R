source("data/cleaning_utils.R")

meta_raw_2022_2023 <- "data/raw/meta_visits_2022_2023.csv"
website_raw_2023 <- "data/raw/website_dates_2023.csv"

meta_website_merged <-
  clean_names(read_csv(meta_raw_2022_2023)) |>
  mutate(date = ymd_hms(date)) |>
  inner_join(clean_names(read_csv(website_raw_2023)), by = "date") |>
  rename(website_clicks = clicks)

write_csv(meta_website_merged, "data/raw/meta_website_merged_2023.csv")

meta_website_2023 <- read_csv("data/raw/meta_website_merged_2023.csv")

meta_website_year <- meta_website_2023 |>
  select(date, facebook_page_likes, instagram_followers, website_clicks) |>
  pivot_longer(-date, names_to = "channel", values_to = "day_total") |>
  mutate(
    day_name = format(date, "%b %d, %Y"),
    channel_name = name(channel), channel_type = type(channel_name),
    channel_color = type_color(channel_name),
    day_tooltip = tt_day(day_total, channel_name, channel_type, day_name)
  )

meta_website_month <- meta_website_year |>
  group_by(channel, month = month(date)) |>
  summarize(month_total = sum(day_total), .groups = "drop") |>
  mutate(
    month_name = month(month, label = TRUE, abbr = FALSE),
    channel_name = name(channel), channel_type = type(channel_name),
    channel_color = type_color(channel_name),
    month_tooltip = tt_month(
      month_total, channel_name, channel_type, month_name
    )
  )

meta_website_weekday <- meta_website_year |>
  group_by(channel, weekday = wday(date)) |>
  summarize(weekday_total = sum(day_total), .groups = "drop") |>
  mutate(
    weekday_name = wday(weekday, label = TRUE, abbr = FALSE),
    channel_name = name(channel), channel_type = type(channel_name),
    channel_color = type_color(channel_name),
    weekday_tooltip = tt_weekday(
      weekday_total, channel_name, channel_type, weekday_name
    )
  )

meta_website_season <- meta_website_year |>
  group_by(channel, season_name = season(date)) |>
  summarize(season_total = sum(day_total), .groups = "drop") |>
  mutate(
    channel_name = name(channel), channel_type = type(channel_name),
    season_color = season_color(season_name),
    season_tooltip = tt_season(
      season_total, channel_name, channel_type, season_name
    )
  )

write_csv(meta_website_year, "data/clean/meta_website_year.csv")
write_csv(meta_website_month, "data/clean/meta_website_month.csv")
write_csv(meta_website_weekday, "data/clean/meta_website_weekday.csv")
write_csv(meta_website_season, "data/clean/meta_website_season.csv")

div_css <- htmltools::css(
  font.family = "Bahnschrift",
  max.width = "300px",
  padding = "7px",
  border.padding = "2px",
  border.radius = "5px",
  box.shadow = "0 2px 5px rgba(0,0,0,0.1)"
)

format_moe <- \(x) if_else(!is.na(x), str_glue("{`x`} (+/-)"), "NA")

block_group_usd_html <-
  "
  <div style={div_css}>
    <h6 style='color: #670078; margin-top: 0px;'>Block Group: {`block_group`}</h6>
    <p>
      <strong>Estimate:</strong> {dollar(estimate)} <br>
      <strong>Margin of error:</strong> {format_moe(`moe_pct`)}
    </p>
    <p style='color: #670078; font-weight: bold;'>
      Census Tract {`tract`}<br>{`county`} County,<br>{`state`}
    </p>
    <p>{`latitude`},<br>{`longitude`}</p>
  </div>
  "

get_block_group <- function(st, var) {
  block_group_extract <- \(x) str_extract(x, "Block Group [0-9]+")
  tract_extract <- \(x) str_extract(x, "Census Tract [0-9]+\\.?[0-9]*")
  county_extract <- \(x) str_extract(x, "([^;]+) County")
  state_extract <- \(x) str_extract(x, "[A-Za-z]+ [A-Za-z]+$")
  
  get_acs(
    geography = "block group",
    state = st,
    variables = var,
    year = 2023,
    geometry = TRUE
  ) |>
    mutate(
      moe_pct = percent_format(accuracy = 0.02)(moe / estimate),
      block_group = block_group_extract(NAME) |> str_remove("Block Group "),
      tract = tract_extract(NAME) |> str_remove("Census Tract "),
      county = county_extract(NAME) |> str_remove(" County"),
      state = state_extract(NAME),
      latitude = st_coordinates(st_centroid(geometry))[,2],
      longitude = st_coordinates(st_centroid(geometry))[,1],
      block_group_html = str_glue(block_group_usd_html)
    )
}

income_sc <- get_block_group("SC", "B19013_001")
write_rds(income_sc, "data/clean/income_sc.rds")
