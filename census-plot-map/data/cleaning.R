library(tidyverse)
library(tidycensus)

substrings <- c(
  "Estimate!!Total:" = "Total",
  "Total!!" = "",
  ":!!" = "; ",
  "Estimate!!" = "",
  " --!!Total" = "",
  " --!!" = "; ",
  "--!!" = "; ",
  "!!" = "; ",
  "--" = "; ",
  ":" = ""
)

v22 <- load_variables(2022, "acs5", cache = TRUE) |>
  filter(geography %in% c("county", "tract", "block group")) |>
  select(name, geography)

v23 <- load_variables(2023, "acs5", cache = TRUE) |>
  select(-geography)

past_12mos <- " (in (the)?|the) (Past|Last) 12 Months"
ia23_usd <- " \\(in 2023 Inflation-Adjusted Dollars\\)"

v23_clean <- inner_join(v22, v23, by = "name") |>
  select(variable = name, concept, label) |>
  mutate(
    label = str_replace_all(label, substrings),
    concept = str_remove(concept, past_12mos),
    concept = str_remove(concept, ia23_usd),
    concept = gsub("--", "; ", concept)
  )

write_rds(v23_clean, "data/v23_clean.rds")
