#------------------------------
# Title: Test Cville r5r analysis
# Date: Wed Oct 18 13:41:36 2023
# Author: Katherine
#------------------------------


# Libraries ---------------------------------------------------------------

library(r5r)
library(sf)
library(data.table)
library(tidytransit)
library(here)
library(osmextract)
library(tidyverse)
library(janitor)
# install.packages("gtfstools")
library(gtfstools)

options(java.parameters = "-Xmx2G") #increase Java memory allocation


# Get data ----------------------------------------------------------------
# pbf file
cville_map <- oe_read(here("data/clean-data/cville_clip.pbf"))

# ggplot() +
#   geom_sf(data = cville_map$geometry,
#           inherit.aes = FALSE,
#           color = "black")
# this actually plotted?

# gtfs file
# needed if gtfs data isn't downloaded
cville <- read_gtfs("https://api.transloc.com/gtfs/charlottesville.zip")
cville$frequencies
write_gtfs(cville, here("data","raw-data","cville_gtfs.zip"))

cville_updated <- frequencies_to_stop_times(cville)
write_gtfs(cville_updated, here("data","clean-data","cville_gtfs.zip"))

# need points of interest
# going to be libraries
libraries <- read_csv("data/raw-data/PLS_FY2021 PUD_CSV/pls_fy21_outlet_pud21i.csv")

# can filter to points in the bounding box
cville_libs <- libraries |> 
  filter(STABR == "VA") |> 
  #@TODO: change hardcoding to variables with the bounding box
  filter(LONGITUD >= -78.75232765690151 & LONGITUD <= -78.06764000995683) |> 
  filter(LATITUDE >= 37.78699608830537 & LATITUDE <=38.34057907754285 )

# need to format as points of interest
poi <- cville_libs |> 
  select(LIBNAME,LONGITUD,LATITUDE) |> 
  clean_names() |> 
  rename(lon = longitud, lat = latitude, id = libname)


# Run r5r -----------------------------------------------------------------

r5r_core <- setup_r5(data_path = here("data","clean-data"))

mode <- c("WALK", "TRANSIT")
max_walk_time <- 30 # minutes
max_trip_duration <- 120 # minutes
departure_datetime <- as.POSIXct("24-10-2023 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")


# Time travel matrix ------------------------------------------------------
ttm <- travel_time_matrix(r5r_core = r5r_core,
                          origins = poi,
                          destinations = poi,
                          mode = mode,
                          departure_datetime = departure_datetime,
                          max_walk_time = max_walk_time,
                          max_trip_duration = max_trip_duration)

ettm <- expanded_travel_time_matrix(r5r_core = r5r_core,
                                    origins = poi,
                                    destinations = poi,
                                    mode = mode,
                                    departure_datetime = departure_datetime,
                                    breakdown = TRUE,
                                    max_walk_time = max_walk_time,
                                    max_trip_duration = max_trip_duration)

head(ettm)


# Detailed itineraries ----------------------------------------------------

origins <- poi[4,]
destinations <- poi[6,]
mode <- c("WALK", "TRANSIT")
max_walk_time <- 60 # minutes
departure_datetime <- as.POSIXct("24-10-2023 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")
# this is not working due to the GTFS file
det <- detailed_itineraries(r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            mode = mode,
                            departure_datetime = departure_datetime,
                            max_walk_time = max_walk_time,
                            shortest_path = FALSE)

head(det)

street_net <- street_network_to_sf(r5r_core)

# extract public transport network
transit_net <- r5r::transit_network_to_sf(r5r_core)

# plot
ggplot() +
  geom_sf(data = street_net$edges, color='gray85') +
  geom_sf(data = det, aes(color=mode)) +
  facet_wrap(.~option) + 
  theme_void()

# Isochrone map -----------------------------------------------------------

origin1 <- poi[4,]
iso1 <- isochrone(r5r_core,
                  origin = origin1,
                  mode = c("walk","transit"),
                  departure_datetime = departure_datetime,
                  cutoffs = seq(0, 100, 10)
)

origin2 <- poi[5,]
iso2 <- isochrone(r5r_core,
                  origin = origin2,
                  mode = c("walk","transit"),
                  departure_datetime = departure_datetime,
                  cutoffs = seq(0, 100, 10)
)



head(iso1)

colors <- c('#ffe0a5','#ffcb69','#ffa600','#ff7c43','#f95d6a',
            '#d45087','#a05195','#665191','#2f4b7c','#003f5c')

ggplot() +
  geom_sf(data = street_net$edges, color = 'gray85')+ 
  geom_sf(data=iso1, aes(fill=factor(isochrone))) +
  geom_sf(data=iso2, aes(fill=factor(isochrone))) +
  geom_point(data=origin1, color='red', aes(x=lon, y=lat)) +
  geom_point(data=origin2, color='blue', aes(x=lon, y=lat)) +
  scale_fill_manual(values = rev(colors))+
  theme_minimal()
ggsave(here("figures/isochrone_sample.jpg"))
  
# Clean up ----------------------------------------------------------------

r5r::stop_r5(r5r_core) # need to remove r5r objects from memory
rJava::.jgc(R.gc = TRUE)
