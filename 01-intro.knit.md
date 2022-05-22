# Introduction {#intro}

This book focuses on using `leaflet` and `shiny` together to make interactive maps.

Here's a simple leaflet map.

```r
library(leaflet)
```

```
## Warning: package 'leaflet' was built under R version 4.1.3
```

```r
leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
```

<div class="figure">

```{=html}
<div id="htmlwidget-8aefa0da5e4e79a481de" style="width:100%;height:480px;" class="leaflet html-widget"></div>
<script type="application/json" data-for="htmlwidget-8aefa0da5e4e79a481de">{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"addTiles","args":["https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",null,null,{"minZoom":0,"maxZoom":18,"tileSize":256,"subdomains":"abc","errorTileUrl":"","tms":false,"noWrap":false,"zoomOffset":0,"zoomReverse":false,"opacity":1,"zIndex":1,"detectRetina":false,"attribution":"&copy; <a href=\"https://openstreetmap.org\">OpenStreetMap<\/a> contributors, <a href=\"https://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA<\/a>"}]},{"method":"addMarkers","args":[-36.852,174.768,null,null,null,{"interactive":true,"draggable":false,"keyboard":true,"title":"","alt":"","zIndexOffset":0,"opacity":1,"riseOnHover":false,"riseOffset":250},"The birthplace of R",null,null,null,null,{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},null]}],"limits":{"lat":[-36.852,-36.852],"lng":[174.768,174.768]}},"evals":[],"jsHooks":[]}</script>
```

<p class="caption">(\#fig:leaflet-simple)Simple leaflet map</p>
</div>

Before we begin adding to this map, we need to create the layers that we want to add.

In the iTRAQI app, we used markers, rasters and polygons to show the key locations and interpolations.

See the [iTRAQI shiny app here](https://access.healthequity.link/) and read more about it in the information tab of the app. 

Chapter \@ref(building) will focus on these first steps, before making any maps or interactivity. If you're already well-versed in making these layers and the `sf` R package, you can skip to the latter chapters. 


## leaflet layers

> To display statistical area level 1 and 2 (SA1 and SA2) regions on the map, we will be using `sf` objects with MULTIPOLYGON geometries. These are multipolygons because some of these areas include distinct areas, such as a set of islands, that aren't contained within a single polygon.

> To display the location of acute and rehab centers and town locations with travel times that we used for interpolations, we used (spatial) data.frames that had longitudes and latitudes for their location.

> To display the continuous interpolations, we used [`RasterLayer`](https://rdrr.io/cran/raster/man/raster.html) objects.


Using a polygon and raster layer that's used in the iTRAQI map and some markers in a data.frame, we can make see the basic approach that we use to display these on a leaflet map.

First, lets make a data.frame with the coordinates for the Princess Alexandra  and Townsville University Hospitals, and download a raster and polygon layer from the iTRAQI app GitHub repository.


```r
library(tidyverse)
```

```
## -- Attaching packages --------------------------------------- tidyverse 1.3.1 --
```

```
## v ggplot2 3.3.6     v purrr   0.3.4
## v tibble  3.1.2     v dplyr   1.0.6
## v tidyr   1.1.3     v stringr 1.4.0
## v readr   2.1.2     v forcats 0.5.1
```

```
## Warning: package 'ggplot2' was built under R version 4.1.3
```

```
## Warning: package 'readr' was built under R version 4.1.2
```

```
## -- Conflicts ------------------------------------------ tidyverse_conflicts() --
## x dplyr::filter() masks stats::filter()
## x dplyr::lag()    masks stats::lag()
```

```r
download_layer <- function(layer_name, save_dir="input") {
  githubURL <- glue::glue("https://raw.githubusercontent.com/RWParsons/iTRAQI_app/main/input/layers/{layer_name}")
  download.file(githubURL, file.path(save_dir, layer_name), method="curl")
  readRDS(file.path(save_dir, layer_name))
}

raster_layer <- download_layer("rehab_raster.rds") %>%
  raster::raster(., layer=1)

polygons_layer <- download_layer("stacked_SA1_and_SA2_polygons_year2016_simplified.rds")
polygons_layer <- polygons_layer[polygons_layer$SA_level==2, ]
marker_locations <- data.frame(
  centre_name=c("Princess Alexandra Hospital (PAH)", "Townsville University Hospital"),
  x=c(153.033519, 146.762041),
  y=c(-27.497374, -19.320502)
)
```

Here, in figure \@ref(fig:leaflet-objects), we make a leaflet map with the three object types. We will use these three functions, `addPolygons()`, `addRasterImage()`, and `addMarkers()` to add almost all of the content to our leaflet maps.



