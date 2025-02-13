abbr <- \(x) state.abb[grep(str_glue("^{x}$"), state.name)]

usd_regex <- "(dollar|Dollar|dollars|Dollars|Earnings)"

usd_detect <- \(x, y) any(str_detect(c(x, y), usd_regex))

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

modal_confirmation <- function(text_h2, text_h4, text_h5) {
  showModal(
    modalDialog(
      tags$div(
        tags$div(
          class = "modal-header border-0",
          tags$h2(class = "w-100 text-center fs-2", text_h2)
        ),
        tags$div(
          class = "modal-content p-3",
          tags$div(
            class = "mb-4",
            tags$h4(class = "text-primary mb-3", text_h4),
            tags$h5(class = "text-muted", text_h5)
          )
        )
      ),
      title = NULL,
      easyClose = TRUE,
      footer = tags$div(
        tagAppendAttributes(
          class = "btn btn-outline-secondary",
          modalButton("Back", icon("rotate-left"))
        ),
        actionButton(
          class = "btn btn-outline-primary", "confirm_plot", "Plot"
        )
      )
    )
  )
}

format_scale <- function(n, cut = TRUE, usd = FALSE) {
  formatter <- if(usd) label_currency else label_comma
  short_cut <- append(cut_short_scale(), 1, 1)

  case_when(
    n >= 1e4 & cut ~ formatter(scale_cut = short_cut)(n),
    between(n, 1e3, 9999) & cut ~ formatter(accuracy = 100)(n),
    between(n, 1e2, 999) & cut ~ formatter(accuracy = 10)(n),
    TRUE ~ formatter(accuracy = 1)(n)
  )
}

plot_acs <- function(acs) {
  wrap <- \(x) str_wrap(unique(x), width = 50)
  is_usd <- usd_detect(unique(acs$concept), unique(acs$label))

  acs |>
    slice_max(estimate, n = 10, na_rm = TRUE) |>
    ggplot(aes(estimate, county, fill = estimate)) +
    geom_point_interactive(
      aes(data_id = GEOID, tooltip = tooltip),
      color = "#336699", size = 3, show.legend = FALSE
    ) +
    scale_x_continuous(labels = \(x) format_scale(x, usd = is_usd)) +
    theme_minimal() +
    theme(
      plot.title = element_text(margin = margin(3, 3, 3, 3)),
      axis.text.x = element_text(margin = margin(5, 3, 5, 3)),
      axis.text.y = element_text(hjust = 0)
    ) +
    labs(title = wrap(acs$concept), x = wrap(acs$label), y = NULL)
}

map_acs <- function(acs) {
  min_max_seq <- function(numeric_vector, n_breaks) {
    numeric_vector <- numeric_vector[!is.na(numeric_vector)]
    seq(0, max(numeric_vector), length.out = n_breaks)
  }

  is_usd <- usd_detect(unique(acs$concept), unique(acs$label))

  acs |>
    ggplot(aes(fill = estimate, tooltip = tooltip)) +
    geom_sf_interactive(aes(data_id = GEOID)) +
    scale_fill_viridis_c(
      option = "viridis",
      labels = \(x) format_scale(x, usd = is_usd),
      na.value = "#eee",
      guide = guide_legend(title = "Estimate", reverse = TRUE),
      breaks = min_max_seq(acs$estimate, 5)
    ) +
    labs(caption = acs$caption) +
    theme_void() +
    theme(
      text = element_text(family = "Bahnschrift"),
      plot.caption = element_text(face = "italic"),
      plot.caption.position = "plot"
    )
}

plot_map_acs <- function(acs_st, acs_var, var_info, session) {
  setProgress(value = 0.1, detail = "pulling data...")

  acs5 <- get_acs(
    geography = "county",
    state = acs_st,
    variables = acs_var,
    year = 2023,
    geometry = TRUE
  ) |>
    mutate(caption = "2023 5-Year American Community Survey")
  
  if (all(is.na(acs5$estimate))) {
    acs5 <- get_acs(
      geography = "county",
      state = acs_st,
      variables = acs_var,
      year = 2022,
      geometry = TRUE
    ) |>
      mutate(caption = "*2022 5-Year American Community Survey")
  }

  setProgress(value = 0.3, detail = "transforming data...")

  shift_geo <- \(x) x |> tigris::shift_geometry()

  if (acs_st %in% c("Alaska", "Hawaii")) {
    acs5 <- shift_geo(acs5)
  }

  acs <- acs5 |>
    inner_join(var_info, by = "variable") |>
    separate(col = NAME, into = c("county", "state"), sep = ", ") |>
    mutate(
      county = reorder(gsub(" County", "", county), estimate),
      county = str_to_title(county),
      estimate_fmt = format_scale(
        estimate, cut = FALSE, usd = usd_detect(concept, label)
      ),
      tooltip = str_glue("{county}: {estimate_fmt}")
    )

  setProgress(value = 1, detail = "rendering plot + map...")

  girafe(
    ggobj = plot_acs(acs) + map_acs(acs),
    width_svg = 10, height_svg = 5,
    options = list(
      opts_sizing(rescale = TRUE),
      opts_hover(css = "fill: #a51c30;"),
      opts_hover_inv(css = girafe_css(css = "opacity: 0.3;")),
      opts_toolbar(
        hidden = c("lasso_select", "lasso_deselect"),
        tooltips = list(
          saveaspng = str_glue("Download {acs_var}_{abbr(acs_st)}.png")
        ),
        pngname = str_glue("{acs_var}_{abbr(acs_st)}")
      )
    )
  )
}
