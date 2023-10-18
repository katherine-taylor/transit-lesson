#------------------------------
# Title: Sample r5r analysis
# Date: Tue Oct 17 09:29:48 2023
# Author: Katherine
#------------------------------


# Libraries ---------------------------------------------------------------

library(r5r)
library(sf)
library(data.table)
library(ggplot2)

options(java.parameters = "-Xmx2G") #increase Java memory allocation


# Read in files -----------------------------------------------------------
data_path <- system.file("extdata/poa", package = "r5r")
list.files(data_path)

poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
head(poi)

points <- fread(file.path(data_path, "poa_hexgrid.csv")) # data with origin/destination pairs

# sample points
sampled_rows <-  sample(1:nrow(points), 200, replace=TRUE)
points <- points[ sampled_rows, ]
head(points)


# Set up r5r --------------------------------------------------------------

# Indicate the path where OSM and GTFS data are stored
r5r_core <- setup_r5(data_path = data_path)


departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# calculate accessibility
access <- accessibility(r5r_core = r5r_core,
                        origins = points,
                        destinations = points,
                        opportunities_colnames = c("schools", "healthcare"),
                        mode = c("WALK", "TRANSIT"),
                        departure_datetime = departure_datetime,
                        decay_function = "step",
                        cutoffs = 60
)
head(access)


# Routing analysis --------------------------------------------------------
mode <- c("WALK", "TRANSIT")
max_walk_time <- 30 # minutes
max_trip_duration <- 120 # minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# calculate a travel time matrix
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

origins <- poi[10,]
destinations <- poi[12,]
mode <- c("WALK", "TRANSIT")
max_walk_time <- 60 # minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# calculate detailed itineraries
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



# Clean up ----------------------------------------------------------------

r5r::stop_r5(r5r_core) # need to remove r5r objects from memory
rJava::.jgc(R.gc = TRUE)
