library(shiny)
library(leaflet)
library(tidyverse)
library(sf)
input_dir <- "../.."

sa2_polygons <- readRDS(file.path(input_dir, "stacked_SA1_and_SA2_polygons_year2016_simplified.rds")) %>%
  filter(SA_level==2)

ui <- navbarPage(
  "App-with-a-map", id="nav",
  tabPanel(
    "Map",
    leafletOutput('map')
  )
)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addPolygons(
        data=sa2_polygons,
        fillColor="Orange",
        color="black",
        weight=1,
        group="Polygons"
      )
  })
}

shinyApp(ui, server)
