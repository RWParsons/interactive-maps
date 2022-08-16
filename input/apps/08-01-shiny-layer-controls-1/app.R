library(shiny)
library(leaflet)
library(tidyverse)
library(sf)
input_dir <- "../.."

polygons_layer <- readRDS(file.path(input_dir, "stacked_SA1_and_SA2_polygons_year2016_simplified.rds"))

qld_SA2s <- filter(polygons_layer, SA_level == 2)
qld_SA1s <- filter(polygons_layer, SA_level == 1)

# palette for remoteness index
palFac <- colorFactor("Greens", levels = 0:4, ordered = TRUE, reverse = TRUE)


# create index for drive times
bins <- c(0, 30, 60, 120, 180, 240, 300, 360, 900, 1200)

palBin <- colorBin("YlOrRd", domain = min(bins):max(bins), bins = bins, na.color = "transparent")

palNum1 <- colorNumeric(c(palBin(bins[1]), palBin(bins[2])), domain = 0:30, na.color = "transparent")
palNum2 <- colorNumeric(c(palBin(bins[2]), palBin(bins[3])), domain = 30:60, na.color = "transparent")
palNum3 <- colorNumeric(c(palBin(bins[3]), palBin(bins[4])), domain = 60:120, na.color = "transparent")
palNum4 <- colorNumeric(c(palBin(bins[4]), palBin(bins[5])), domain = 120:180, na.color = "transparent")
palNum5 <- colorNumeric(c(palBin(bins[5]), palBin(bins[6])), domain = 180:240, na.color = "transparent")
palNum6 <- colorNumeric(c(palBin(bins[6]), palBin(bins[7])), domain = 240:300, na.color = "transparent")
palNum7 <- colorNumeric(c(palBin(bins[7]), palBin(bins[8])), domain = 300:360, na.color = "transparent")
palNum8 <- colorNumeric(c(palBin(bins[8]), palBin(bins[9])), domain = 360:900, na.color = "transparent")
palNum9 <- colorNumeric(c(palBin(bins[9]), "#000000"), domain = 900:1200, na.color = "transparent")

palNumMix <- function(x) {
  case_when(
    x < 30 ~ palNum1(x),
    x < 60 ~ palNum2(x),
    x < 120 ~ palNum3(x),
    x < 180 ~ palNum4(x),
    x < 240 ~ palNum5(x),
    x < 300 ~ palNum6(x),
    x < 360 ~ palNum7(x),
    x < 900 ~ palNum8(x),
    x < 1200 ~ palNum9(x),
    x >= 1200 ~ "#000000",
    TRUE ~ "transparent"
  )
}

ui <- navbarPage(
  "App-with-a-map",
  id = "nav",
  tabPanel(
    "Map",
    div(
      class = "outer",
      tags$head(
        tags$style(HTML("
            div.outer {
              position: fixed;
              top: 41px;
              left: 0;
              right: 0;
              bottom: 0;
              overflow: hidden;
              padding: 0;
            }
            "))
      ),
      leafletOutput("map", height = "100%", width = "100%"),
      absolutePanel(
        id = "controls", class = "panel panel-default", fixed = TRUE,
        draggable = TRUE, top = 50, left = "auto", right = 10, bottom = "auto",
        width = 330, height = 200,
        h4("Layer"),
        radioButtons(
          inputId = "layer_selection", label = NULL,
          choices = c(
            "None", "SA1 Remoteness", "SA2 Acute Travel Time", "SA2 Rehab Travel Time"
          ),
          selected = "None"
        )
      )
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$layer_selection, {
    # Find out which groups need to be shown and which need to be hidden based on input$layer_selection.
    layer_options <- c("SA1 Remoteness", "SA2 Acute Travel Time", "SA2 Rehab Travel Time")
    if (input$layer_selection == "None") {
      show_group <- c()
    } else {
      show_group <- input$layer_selection
    }
    hide_groups <- layer_options[layer_options != input$layer_selection]

    leafletProxy("map") %>%
      hideGroup(hide_groups) %>%
      showGroup(show_group)
  })

  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addPolygons(
        data = qld_SA1s,
        color = "black",
        weight = 1,
        fillOpacity = 1,
        fillColor = palFac(qld_SA1s$ra),
        group = "SA1 Remoteness"
      ) %>%
      addPolygons(
        data = qld_SA2s,
        color = "black",
        weight = 1,
        fillOpacity = 1,
        fillColor = palNumMix(qld_SA2s$value_acute),
        group = "SA2 Acute Travel Time"
      ) %>%
      addPolygons(
        data = qld_SA2s,
        color = "black",
        weight = 1,
        fillOpacity = 1,
        fillColor = palNumMix(qld_SA2s$value_rehab),
        group = "SA2 Rehab Travel Time"
      )
  })
}

shinyApp(ui, server)
