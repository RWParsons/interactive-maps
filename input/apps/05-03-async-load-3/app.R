pkgs <- c("shiny", "leaflet", "tidyverse", "sf", "glue", "shinyjs")

unavailable_pkgs <- c()
for (pkg in pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    unavailable_pkgs <- c(unavailable_pkgs, pkg)
  } else {
    library(pkg, character.only = TRUE)
  }
}

if (length(unavailable_pkgs) != 0) {
  stop(
    "The following pkgs are required to run this example\n",
    "Please run the code below to install them and try again:\n\n",
    "install.packages(", paste0(paste0("'", unavailable_pkgs, "'"), collapse = ", "), ")"
  )
}

input_dir <- "../.."

sa_polygons <- readRDS(file.path(input_dir, "stacked_SA1_and_SA2_polygons_year2016_simplified.rds"))
towns <- read.csv(file.path(input_dir, "df_towns.csv"))

loading_panel_displays <- c(
  paste(
    sep = "<br>",
    "<h2>First fun fact text!</h2>",
    '<img src="https://www.r-project.org/logo/Rlogo.png" alt="R" style="width:200px">'
  ),
  paste(
    sep = "<br>",
    "<h2>Second fun fact text!</h2>",
    '<img src="https://www.rstudio.com/assets/img/logo.svg" alt="dog-1" style="width:200px;">'
  )
)

get_display <- function() {
  loading_panel_displays[sample(1:length(loading_panel_displays), size = 1)]
}

ui <- navbarPage(
  "App-with-a-map",
  id = "nav",
  tabPanel(
    "Map",
    useShinyjs(),
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
        id = "loadingScreen", class = "panel panel-default",
        fixed = TRUE, draggable = TRUE,
        left = "50%", right = "50%", bottom = "50%", top = "50%",
        width = 500, height = 200,
        HTML(get_display())
      )
    )
  )
)

server <- function(input, output, session) {
  rvs <- reactiveValues(to_load = NULL, map = NULL, map_complete = FALSE)

  f <- function() {
    if (is.null(isolate(rvs$to_load))) rvs$to_load <- 1
    if (!is.null(isolate(rvs$to_load)) &
      !isolate(rvs$map_complete) &
      !is.null(isolate(rvs$map))) {
      rvs$to_load <- isolate(rvs$to_load) + 1
    }
  }

  session$onFlushed(f, once = FALSE)

  output$map <- renderLeaflet({
    rvs$map <-
      leaflet() %>%
      addTiles() %>%
      addCircleMarkers(
        lng = towns$x,
        lat = towns$y,
        popup = glue::glue("<b>Location:</b> {towns$acute_care_centre}"),
        radius = 2,
        fillOpacity = 0,
        group = "Towns"
      ) %>%
      addLayersControl(
        position = "topright",
        baseGroups = c("None", "Polygons"),
        overlayGroups = c("Towns"),
        options = layersControlOptions(collapsed = FALSE)
      )
    rvs$map
  })

  observeEvent(rvs$to_load, {
    if (is.null(isolate(rvs$map)) | isolate(rvs$map_complete)) {
      return()
    }
    leafletProxy("map") %>%
      addPolygons(
        data = sa_polygons,
        fillColor = "Orange",
        color = "black",
        weight = 1,
        group = "Polygons"
      )
    hide("loadingScreen")
    if (!isolate(rvs$map_complete)) rvs$map_complete <- TRUE
  })
}

shinyApp(ui, server)
