#------------------------------
# Title: Put in transit data
# Date: Tue Oct 17 09:04:25 2023
# Author: Katherine
#------------------------------


# Libraries ---------------------------------------------------------------

library(tidytransit)
library(tidyverse)



# Read in GTFS feed -------------------------------------------------------

cville <- read_gtfs("https://api.transloc.com/gtfs/charlottesville.zip")

summary(cville)

