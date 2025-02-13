options(tigris_use_cache = TRUE)

library(tidyverse)
library(scales)
library(tidycensus)
library(sf)

div_css <- htmltools::css(
  font.family = "Bahnschrift",
  max.width = "300px",
  padding = "7px",
  border.padding = "2px",
  border.radius = "5px",
  box.shadow = "0 2px 5px rgba(0,0,0,0.1)"
)

format_moe <- \(x) if_else(!is.na(x), str_glue("{`x`} (+/-)"), "NA")

tract_usd_html <-
  "
  <div style={div_css}>
    <h6 style='color: #670078;'>Census Tract {`tract`}</h6>
    <p>
      <strong>Estimate:</strong> {dollar(`estimate`)} <br>
      <strong>Margin of error:</strong> {format_moe(`moe_pct`)}
    </p>
    <p style='color: #670078; font-weight: bold;'>
      {`county`} County, <br>{`state`}
    </p>
    <p>{`latitude`}, <br>{`longitude`}</p>
  </div>
  "

get_tract <- function(st, var) {
  tract_extract <- \(x) str_extract(x, "Census Tract [0-9]+\\.?[0-9]*")
  county_extract <- \(x) str_extract(x, "([^;]+) County")
  state_extract <- \(x) str_extract(x, "[A-Za-z]+ [A-Za-z]+$")
  
  get_acs(
    geography = "tract",
    state = st,
    variables = var,
    year = 2023,
    geometry = TRUE
  ) |>
    mutate(
      moe_pct = percent_format(accuracy = 0.02)(moe / estimate),
      tract = tract_extract(NAME) |> str_remove("Census Tract "),
      county = county_extract(NAME) |> str_remove(" County"),
      state = state_extract(NAME),
      latitude = st_coordinates(st_centroid(geometry))[,2],
      longitude = st_coordinates(st_centroid(geometry))[,1],
      tract_html = str_glue(tract_usd_html)
    )
}

income_sc <- get_tract("SC", "B19013_001")
write_rds(income_sc, "data/income_sc.rds")

home_values_sc <- get_tract("SC", "B25077_001")
write_rds(home_values_sc, "data/home_values_sc.rds")
