pkgs <- c("shiny", "leaflet", "tidyverse", "sf", "glue")

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

towns <- read.csv(file.path(input_dir, "df_towns.csv"))

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
      leafletOutput('map', height="100%", width="100%"),
      absolutePanel(
        top=75, left=10,
        class = "panel panel-default",
        selectInput('town_name', 'Town Name',
                    choices = c('None', sort(towns$location)),
                    selected = "None")
      )
    )
  )
)

server <- function(input, output, session) {

  observe({
    if(input$town_name!="None") {
      town_df <- towns[towns$location==input$town_name, ]
      leafletProxy("map") %>%
        flyTo(lng=town_df$x, lat=town_df$y, zoom=10)
    } else {
      leafletProxy("map") %>%
        flyToBounds(
          lng1 = 137.725724, lat1 = -28.903687,
          lng2 = 151.677076, lat2 = -10.772608
        )
    }
  })

  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addPolygons(
        data=sa2_polygons,
        fillColor="Orange",
        color="black",
        weight=1,
        group="Polygons"
      ) %>%
      addCircleMarkers(
        lng=towns$x,
        lat=towns$y,
        popup=glue("<b>Location:</b> {towns$acute_care_centre}"),
        radius=2,
        fillOpacity=0,
        group="Towns"
      ) %>%
      addLayersControl(
        position="topright",
        baseGroups=c("None", "Polygons"),
        overlayGroups=c("Towns"),
        options=layersControlOptions(collapsed = FALSE)
      )
  })
}

shinyApp(ui, server)
