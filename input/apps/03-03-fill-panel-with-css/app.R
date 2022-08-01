pkgs <- c("shiny", "leaflet", "tidyverse", "sf")

unavailable_pkgs <- c()
for (pkg in pkgs) {
  if(!requireNamespace(pkg, quietly = TRUE)) {
    unavailable_pkgs <- c(unavailable_pkgs, pkg)
  } else {
    library(pkg, character.only = TRUE)
  }
}

if (length(unavailable_pkgs) != 0) {
  stop(
    "The following pkgs are required to run this example\n",
    "Please run the code below to install them and try again:\n\n",
    "install.packages(", paste0(paste0("'", unavailable_pkgs, "'"), collapse=", "), ")"
  )
}

input_dir <- "../.."

sa2_polygons <- readRDS(file.path(input_dir, "stacked_SA1_and_SA2_polygons_year2016_simplified.rds")) %>%
  filter(SA_level==2)

ui <- navbarPage(
  "App-with-a-map", id="nav",
  tabPanel(
    "Map",
    div(
      class="outer",
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
            "
        ))
      ),
      leafletOutput('map', height="100%", width="100%")
    )
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
