#------------------------------
# Title: utils.R
# Date: Wed Oct 18 17:18:47 2023
# Author: Katherine
#------------------------------

# update with your name to fill in the error message
teacher_name <- "Ms.Taylor"

# Teaching helper function ------------------------------------------------

teaching_wrapper <- function(helper_function,success_message,teacher_name) {
  tryCatch(
    expr =  {
      object <- helper_function
      message(success_message)
      if(!is.function(object)){
      return(object)
      }
    },
    error = function(e) {
      message(paste0(
        "Something went wrong!",
        " Call ",
        teacher_name,
        " over to help!",
        sep = ""
      ))
      print(e)
    },
    warning = function(w) {
      object <- helper_function
      
      message(
        paste0(
          "Looks like there was a warning, but you should be good to go. Call ",
          teacher_name,
          " over if you have any questions.",
          sep = ""
        )
      )
      print(w)
      if(!is.function(object)){
        return(object)
      }
    }
  )
  
}

# Load libraries ----------------------------------------------------------


load_libraries_h <- function(){
  packages <- c(
    "r5r",
    "sf",
    "data.table",
    "tidytransit",
    "here",
    "osmextract",
    "tidyverse",
    "janitor",
    "gtfstools"
  )
  for (package_name in packages) {
    if (!require(package_name, character.only = TRUE)) {
      install.packages(package_name,repos = "http://cran.us.r-project.org")
    }
    library(package_name,character.only = TRUE)
  }
  return(0)
}

# export
load_libraries <- function() {
  teaching_wrapper(load_libraries_h(),"Nice work! All your packages are loaded and installed",teacher_name)
}


setup_h <- function() {
  # expand memory allocated to Java
  options(java.parameters = "-Xmx2G")
  # load in GTFS data
  cville <- read_gtfs("https://api.transloc.com/gtfs/charlottesville.zip")
  cville_updated <- frequencies_to_stop_times(cville)
  write_gtfs(cville_updated, here("data", "clean-data", "cville_gtfs.zip"))
  return(0)
}

# export
setup <- function() {
  teaching_wrapper(setup_h(),"Nice work! All your map and transit data is ready to go!",teacher_name)
}

#@TODO: create function that could look at different points of interest
point_of_interest_h <- function() {
  libraries <- read_csv(here("data/raw-data/PLS_FY2021 PUD_CSV/pls_fy21_outlet_pud21i.csv"))
  
  # can filter to points in the bounding box
  cville_libs <- libraries |>
    filter(STABR == "VA") |>
    # @TODO: change hardcoding to variables with the bounding box
    filter(LONGITUD >= -78.75232765690151 & LONGITUD <= -78.06764000995683) |>
    filter(LATITUDE >= 37.78699608830537 & LATITUDE <= 38.34057907754285)
  
  # need to format as points of interest
  poi <- cville_libs |>
    select(LIBNAME, LONGITUD, LATITUDE) |>
    clean_names() |>
    rename(lon = longitud, lat = latitude, id = libname)
  
  return(poi)
}

#export 
point_of_interest <- function() {
  teaching_wrapper(point_of_interest_h(),"Nice work! Your point of interest data is ready to go!",teacher_name)
}

r5r_start_h <- function(){
  r5r_core <- setup_r5(data_path = here("data", "clean-data"))
  return(r5r_core)
}

# export
r5r_start <- function() {
  teaching_wrapper(r5r_start_h(), "Cool beans! You have the r5r engine up and running!", teacher_name)
}

time_travel_h <- function(date_time,poi,r5r_core){
  
  
  mode <- c("WALK", "TRANSIT")
  max_walk_time <- 30 # minutes
  max_trip_duration <- 120 # minutes
  departure_datetime <- as.POSIXct(date_time,
                                   format = "%d-%m-%Y %H:%M:%S"
  )
  
  ttm <- travel_time_matrix(
    r5r_core = r5r_core,
    origins = poi,
    destinations = poi,
    mode = mode,
    departure_datetime = departure_datetime,
    max_walk_time = max_walk_time,
    max_trip_duration = max_trip_duration
  )
  
  return(ttm)
}

# export
time_travel <- function(date_time,poi,r5r_core) {
  teaching_wrapper(time_travel_h(date_time,poi,r5r_core),"Great job! Take a look at your time travel matrix by typing View(ttm) in the console",teacher_name)
}

isochrone_map_h <- function(point1,point2,date_time,r5r_core){
  origin1 <- point1
  departure_datetime <- as.POSIXct(date_time,
                                   format = "%d-%m-%Y %H:%M:%S"
  )
  iso1 <- isochrone(r5r_core,
                    origin = origin1,
                    mode = c("walk", "transit"),
                    departure_datetime = departure_datetime,
                    cutoffs = seq(0, 100, 10)
  )
  
  origin2 <- point2
  iso2 <- isochrone(r5r_core,
                    origin = origin2,
                    mode = c("walk", "transit"),
                    departure_datetime = departure_datetime,
                    cutoffs = seq(0, 100, 10)
  )
  
  
  colors <- c(
    "#ffe0a5", "#ffcb69", "#ffa600", "#ff7c43", "#f95d6a",
    "#d45087", "#a05195", "#665191", "#2f4b7c", "#003f5c"
  )
  
  street_net <- street_network_to_sf(r5r_core)
  
  plot_object <- ggplot() +
    geom_sf(data = street_net$edges, color = "gray85") +
    geom_sf(data = iso1, aes(fill = factor(isochrone))) +
    geom_sf(data = iso2, aes(fill = factor(isochrone))) +
    geom_point(data = origin1, color = "red", aes(x = lon, y = lat)) +
    geom_point(data = origin2, color = "blue", aes(x = lon, y = lat)) +
    scale_fill_manual(values = rev(colors)) +
    theme_minimal()
  
  return(plot_object)
}

# export
isochrone_map <- function(point1,point2,date,r5r_core) {
  teaching_wrapper(isochrone_map_h(point1,point2,date,r5r_core),"Wow! Look at the cool map you've made!",teacher_name)
}

clean_up_h <- function(r5r_core) {
  r5r::stop_r5(r5r_core) # need to remove r5r objects from memory
  rJava::.jgc(R.gc = TRUE)
  return(0)
}

# export
clean_up <- function(r5r_core){
  teaching_wrapper(clean_up_h(r5r_core), "Good job cleaning up your computer!",teacher_name)
}

  
