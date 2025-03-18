make_title <- function(img, hex, text, url = NULL) {
  img_title <- tags$img(src = img, width = "75px", height = "auto", text)
  css <- "color: {hex}; text-decoration: none;"
  tags$a(
    style = str_glue(css), href = url,
    target = "_blank", rel = "noopener noreferrer", img_title
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
      color: #c2ac84;
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

season_levels <- function(x) {
  season_levels <- c("Spring", "Summer", "Autumn", "Winter")
  case_when(
    {{x}} %in% season_levels ~ factor({{x}}, levels = season_levels)
  )
}

season_trees_png <- function(height = 70) {
  levels <- c("Spring", "Summer", "Autumn", "Winter")
  season <- str_to_lower(levels)
  season_trees <- str_glue(
    "<img src='www/tree-{season}.png' height='{height}'/>"
  )
  set_names(season_trees, levels)
}

val_box <- function(title, value, icon_id, hex, ...) {
  value_box(
    title, str_glue("+{value}"), theme = value_box_theme(fg = hex),
    showcase = tags$span(
      tags$img(style = str_glue("color: {hex};"), icon(icon_id))
    ),
    ...
  )
}

theme_set(theme_minimal() + theme(
  legend.position = "none",
  panel.grid = element_blank(),
  text = element_text(family = "Bahnschrift"),
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
  axis.text = element_text(size = 17),
  axis.text.x = element_text(color = "#670078"),
  axis.text.y = ggtext::element_markdown(),
  axis.text.y.left = element_text(color = "#c2ac84")
))

ggiraph_area_col <- function(df, x, y, z, tt = NULL) {
  ggplot(df, aes({{x}}, {{y}}, group = {{z}}, fill = {{z}})) +
    geom_area_interactive(aes(data_id = {{z}})) +
    geom_col_interactive(aes(data_id = {{x}}, tooltip = {{tt}})) +
    scale_x_date(date_labels = "%b") +
    theme(
      axis.text.y.left = element_blank(),
      strip.text.y.left = element_text(
        color = "#c2ac84", angle = 0, size = 17
      )
    )
}

ggiraph_tile <- function(df, x, y, z, tt = NULL) {
  ggplot(df, aes({{x}}, {{y}}, fill = {{y}})) +
    geom_tile_interactive(
      aes(
        data_id = {{z}}, tooltip = {{tt}},
        alpha = {{z}}), color = "white", lwd = 2
    ) +
    coord_fixed() +
    scale_x_discrete(labels = month.abb)
}

ggiraph_seg_pt <- function(df, x, y, z, tt = NULL) {
  ggplot(df, aes({{x}}, {{y}}, color = {{x}})) +
    geom_segment_interactive(
      aes(
        data_id = {{y}}, tooltip = {{tt}},
        x = {{z}}, xend = {{z}}, y = 0, yend = {{y}}
      )
    ) +
    geom_point_interactive(
      aes(data_id = {{y}}, tooltip = {{tt}}, x = {{z}}, y = {{y}}),
      size = 2.5
    )
}

ggiraph_col <- function(df, x, y, fill = NULL, tt = NULL) {
  ggplot(df, aes({{x}}, fct_rev({{y}}))) +
    geom_col_interactive(
      aes(data_id = {{x}}, fill = {{fill}}, tooltip = {{tt}}),
      width = 0.10
    )
}

ggiraph_plot <- function(gg_obj) {
  tools <- c("lasso_select", "lasso_deselect", "saveaspng")
  girafe(
    ggobj = gg_obj,
    width_svg = 12,
    height_svg = 5,
    options = list(
      opts_hover(css = ""),
      opts_hover_inv(
        css = girafe_css(
          css = "opacity: 0.4;",
          area = "opacity: 0.1;",
          point = "opacity: 0.1;",
          line = "opacity: 0.01;"
        )
      ),
      opts_selection(type = "none"),
      opts_sizing(rescale = TRUE),
      opts_toolbar(hidden = tools),
      opts_tooltip(
        css = htmltools::css(
          background = "#fcfbf4",
          border = "1.5px solid",
          border_color = "#c2ac84",
          padding = "9.5px",
          font_weight = 500,
          font_size = "14pt"
        )
      )
    )
  )
}

ggiraph_panel <- function(txt, vbs, plot) {
  nav_panel(
    title = txt, card(vbs),
    card(girafeOutput(plot) |> withSpinner(type = 6))
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
      tooltip = "block_group_html",
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

dt_accordion <- function(txt, table, open = FALSE) {
  accordion(
    accordion_panel(title = txt, card(DTOutput(table))),
    open = open
  )
}

load_table <- function(df) {
  renderDT({
    df |> rename_with(str_to_title) |>
      datatable(selection = "single", filter = "top")
  })
}
