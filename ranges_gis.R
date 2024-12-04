
# Background ----

# extract LANDFIRE EVT data per bobcat home range
# Randy Swaty and Isabella Oldani
# December 2024

# Dependencies ----

# packages

library(foreign)
library(raster)
library(rlandfire)
library(scales)
library(sf)
library(terra)
library(tidyverse)

# read shapefiles
female_ranges <- st_read("data/2023 Female Bobcat Home Ranges.shp") %>% 
  st_transform(crs = 5070) %>%
  st_sf()

# check the shape
vect(female_ranges)
# plot the shape
plot(female_ranges)

# Something is wrong with female data-missing attributes

male_ranges <- st_read("data/2023 Male Bobcat Home Ranges.shp") %>% 
  st_transform(crs = 5070) %>%
  st_sf()

# check the shape
vect(male_ranges)
# plot the shape
plot(male_ranges)

# looks reasonable

# Download and load LANDFIRE data ----

aoi <- getAOI(male_ranges)


# LFPS Parameters
products <-  c("230EVT")
projection <- 5070
resolution <- 30


# R specific arguments
save_file <- tempfile(fileext = ".zip")

# call API
ncal <- landfireAPI(products,
                    aoi,
                    projection,
                    resolution,
                    path = save_file)

evt <- rast("data/lf_evt.tif") # I used tempdir() to find data, then manually unzipped, moved and renamed
plot(evt)

## Try to extract ----

# my attempt
male_cats_evt <- terra::extract(evt, male_ranges, df = TRUE, ID = TRUE) %>%
  group_by(ID,  US_230EVT) %>%
  summarize(count = n()) 
# OK but not sure which cat belongs to which ID

# Extract raster values from chatGPT
male_cats_evt <- terra::extract(evt, male_ranges, df = TRUE) %>%
  dplyr::mutate(LabNumber = male_ranges$LabNumber[ID]) %>%
  group_by(LabNumber, US_230EVT) %>%
  summarize(count = n())








