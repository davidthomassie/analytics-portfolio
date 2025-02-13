link_logo <- function(img, url) {
  tags$a(
    tags$img(src = img, width = "90px", height = "auto", ""),
    href = url, target = "_blank", rel = "noopener noreferrer"
  )
}

nav_icon <- function(id, hex, url = NULL) {
  icon_class <- str_glue("{id}-icon")
  icon_css <- str_glue(
    "
    .{icon_class} {{
      color: {hex};
      transition: color 0.3s;
    }}
    .{icon_class}:hover {{
      color: #c2ac84 !important;
    }}
    "
  )
  
  nav_item(
    tags$head(tags$style(HTML(icon_css))),
    tags$a(
      icon(class = icon_class, id), href = url,
      target = "_blank", rel = "noopener noreferrer"
    )
  )
}

build_maplibre <- function(acs, session) {
  setProgress(value = 0.1, detail = "initializing helper functions...")
  
  min_max_seq <- function(numeric_vector, n_breaks) {
    numeric_vector <- numeric_vector[!is.na(numeric_vector)]
    seq(0, max(numeric_vector), length.out = n_breaks)
  }
  
  map_pal <- \(x, y) viridisLite::viridis(x, direction = 1, option = y)
  unit_fmt <- label_currency(scale_cut = append(cut_short_scale(), 1, 1))
  
  setProgress(value = 0.3, detail = "calculating centroids...")
  
  centroids <- acs |> mutate(geometry = sf::st_centroid(geometry))
  
  setProgress(value = 1, detail = "rendering map...")
  
  maplibre(bounds = acs) |>
    add_fill_layer(
      id = "acs",
      source = acs,
      fill_opacity = 0.5,
      fill_color = interpolate(
        column = "estimate",
        na_color = "#eee",
        values = min_max_seq(acs$estimate, 10),
        stops = map_pal(10, "turbo")
      ),
      hover_options = list(fill_opacity = 0)
    ) |>
    add_categorical_legend(
      legend_title = "Estimate",
      position = "bottom-left",
      circular_patches = TRUE,
      values = unit_fmt(min_max_seq(acs$estimate, 5)),
      colors = map_pal(5, "turbo")
    ) |>
    add_circle_layer(
      id = "centroids",
      source = centroids,
      min_zoom = 11,
      circle_radius = 4,
      circle_stroke_width = 1.5,
      circle_color = "#f00",
      circle_stroke_color = "#fff8dc",
      tooltip = "tract_html",
      hover_options = list(
        circle_radius = 8,
        circle_color = "#fff8dc",
        circle_stroke_color = "#4ea24e"
      )
    ) |>
    add_navigation_control() |>
    add_geocoder_control(position = "top-left")
}

load_map <- \(x, ...) card(maplibreOutput(x) |> withSpinner(type = 6), ...)

reset_button <- \(x) actionButton(x, "Reset", icon("rotate-left"))
