library(shiny)
library(leaflet)
library(tidyverse)
library(sf)
input_dir <- "../.."

leaflet_css_and_js <- tags$head(
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
  )),
  # add in methods from https://github.com/rstudio/leaflet/pull/598
  tags$script(HTML(
    '
window.LeafletWidget.methods.setStyle = function(category, layerId, style){
  var map = this;
  if (!layerId){
    return;
  } else if (!(typeof(layerId) === "object" && layerId.length)){ // in case a single layerid is given
    layerId = [layerId];
  }

  //convert columnstore to row store
  style = HTMLWidgets.dataframeToD3(style);
  //console.log(style);

  layerId.forEach(function(d,i){
    var layer = map.layerManager.getLayer(category, d);
    if (layer){ // or should this raise an error?
      layer.setStyle(style[i]);
    }
  });
};

window.LeafletWidget.methods.setRadius = function(layerId, radius){
  var map = this;
  if (!layerId){
    return;
  } else if (!(typeof(layerId) === "object" && layerId.length)){ // in case a single layerid is given
    layerId = [layerId];
    radius = [radius];
  }

  layerId.forEach(function(d,i){
    var layer = map.layerManager.getLayer("marker", d);
    if (layer){ // or should this raise an error?
      layer.setRadius(radius[i]);
    }
  });
};
'
  ))
)

setShapeStyle <- function(map, data = getMapData(map), layerId,
                          stroke = NULL, color = NULL,
                          weight = NULL, opacity = NULL,
                          fill = NULL, fillColor = NULL,
                          fillOpacity = NULL, dashArray = NULL,
                          smoothFactor = NULL, noClip = NULL,
                          options = NULL) {
  options <- c(
    list(layerId = layerId),
    options,
    filterNULL(list(
      stroke = stroke, color = color,
      weight = weight, opacity = opacity,
      fill = fill, fillColor = fillColor,
      fillOpacity = fillOpacity, dashArray = dashArray,
      smoothFactor = smoothFactor, noClip = noClip
    ))
  )
  # evaluate all options
  options <- evalFormula(options, data = data)
  # make them the same length (by building a data.frame)
  options <- do.call(data.frame, c(options, list(stringsAsFactors = FALSE)))

  layerId <- options[[1]]
  style <- options[-1] # drop layer column

  leaflet::invokeMethod(map, data, "setStyle", "shape", layerId, style)
}

polygons_layer <- readRDS(file.path(input_dir, "stacked_SA1_and_SA2_polygons_year2016_simplified.rds"))

qld_SA2s <- filter(polygons_layer, SA_level==2)
qld_SA1s <- filter(polygons_layer, SA_level==1)

# palette for remoteness index
palFac <- colorFactor("Greens", levels=0:4, ordered=TRUE, reverse=TRUE)

# create index for drive times
bins <- c(0, 30, 60, 120, 180, 240, 300, 360, 900, 1200)

palBin <- colorBin("YlOrRd", domain = min(bins):max(bins), bins=bins, na.color="transparent")

palNum1 <- colorNumeric(c(palBin(bins[1]), palBin(bins[2])), domain=0:30, na.color="transparent")
palNum2 <- colorNumeric(c(palBin(bins[2]), palBin(bins[3])), domain=30:60, na.color="transparent")
palNum3 <- colorNumeric(c(palBin(bins[3]), palBin(bins[4])), domain=60:120, na.color="transparent")
palNum4 <- colorNumeric(c(palBin(bins[4]), palBin(bins[5])), domain=120:180, na.color="transparent")
palNum5 <- colorNumeric(c(palBin(bins[5]), palBin(bins[6])), domain=180:240, na.color="transparent")
palNum6 <- colorNumeric(c(palBin(bins[6]), palBin(bins[7])), domain=240:300, na.color="transparent")
palNum7 <- colorNumeric(c(palBin(bins[7]), palBin(bins[8])), domain=300:360, na.color="transparent")
palNum8 <- colorNumeric(c(palBin(bins[8]), palBin(bins[9])), domain=360:900, na.color="transparent")
palNum9 <- colorNumeric(c(palBin(bins[9]), "#000000"), domain=900:1200, na.color="transparent")

palNumMix <- function(x){
  case_when(
    x < 30  ~ palNum1(x),
    x < 60  ~ palNum2(x),
    x < 120 ~ palNum3(x),
    x < 180 ~ palNum4(x),
    x < 240 ~ palNum5(x),
    x < 300 ~ palNum6(x),
    x < 360 ~ palNum7(x),
    x < 900 ~ palNum8(x),
    x <1200 ~ palNum9(x),
    x >=1200~ "#000000",
    TRUE ~ "transparent"
  )
}


ui <- navbarPage(
  "App-with-a-map", id="nav",
  tabPanel(
    "Map",
    div(
      class="outer",
      leaflet_css_and_js,
      leafletOutput('map', height="100%", width="100%"),
      absolutePanel(

        id = "controls", class = "panel panel-default", fixed = TRUE,
        draggable = TRUE, top = 50, left = "auto", right = 10, bottom = "auto",
        width = 330, height = 200,
        h4("Layer"),
        radioButtons(
          inputId="layer_selection", label=NULL,
          choices=c(
            "None", "SA2 Acute", "SA2 Rehab"
          ),
          selected="None"
        )
      )
    )
  )
)

server <- function(input, output, session) {

  observeEvent(input$layer_selection, {
    # find out what the care type was - will either be "acute" or "rehab" as that's the first word
    care_type_selected <- str_extract(tolower(input$layer_selection), "[a-z]*$")

    f_update_fill <- function(map) {
      fill <- switch(
        care_type_selected,
        "acute"=palNumMix(qld_SA2s$value_acute),
        "rehab"=palNumMix(qld_SA2s$value_rehab)
      )

      setShapeStyle(
        map=map,
        layerId=qld_SA2s$CODE,
        fillColor=fill
      ) %>%
        showGroup("qld_SA2s")
    }


    if(input$layer_selection == "None") {
      leafletProxy("map") %>% hideGroup("qld_SA2s")
    } else {
      leafletProxy("map") %>% f_update_fill()
    }
  })

  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addPolygons(
        data=qld_SA2s,
        color="black",
        weight=1,
        fillOpacity=1,
        group="qld_SA2s",
        layerId=qld_SA2s$CODE
      )
  })
}

shinyApp(ui, server)
