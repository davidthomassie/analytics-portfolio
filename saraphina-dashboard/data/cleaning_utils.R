library(tidyverse)
library(scales)
library(janitor)
library(tidycensus)
library(sf)

name <- function(x) {
  case_when(
    x %in% "website_clicks"      ~ "Website",
    x %in% "instagram_followers" ~ "Instagram",
    x %in% "facebook_page_likes" ~ "Facebook"
  )
}

type <- function(x) {
  case_when(
    x %in% "Website" ~ "click",
    x %in% "Instagram" ~ "follower",
    x %in% "Facebook" ~ "like"
  )
}

type_color <- function(x) {
  case_when(
    x %in% "Website" ~ "#670078",
    x %in% "Instagram" ~ "#dd2a7b",
    x %in% "Facebook" ~ "#316ff6"
  )
}

tt_day <- function(n, name, type, day) {
  case_when(
    n != 1 ~ str_glue("+{n} {name} {type}s on {day}"),
    n == 1 ~ str_glue("+{n} {name} {type} on {day}")
  )
}

tt_month <- function(n, name, type, month) {
  case_when(
    n != 1 ~ str_glue("+{n} {name} {type}s in {month}"),
    n == 1 ~ str_glue("+{n} {name} {type} in {month}")
  )
}

tt_weekday <- function(n, name, type, weekday) {
  case_when(
    n != 1 ~ str_glue("+{n} {name} {type}s on {weekday}s"),
    n == 1 ~ str_glue("+{n} {name} {type} on {weekday}s")
  )
}

tt_season <- function(n, name, type, season) {
  case_when(
    n != 1 ~ str_glue("+{n} {name} {type}s in {season}"),
    n == 1 ~ str_glue("+{n} {name} {type} in {season}")
  )
}

season <- function(date) {
  x <- month(date)
  case_when(
    x %in% c(3:5)     ~ "Spring",
    x %in% c(6:8)     ~ "Summer",
    x %in% c(9:11)    ~ "Autumn",
    x %in% c(1:2, 12) ~ "Winter"
  )
}

season_color <- function(x) {
  case_when(
    x %in% "Spring" ~ "#0f9d58",
    x %in% "Summer" ~ "#f4b400",
    x %in% "Autumn" ~ "#a52a2a",
    x %in% "Winter" ~ "#4285f4"
  )
}
