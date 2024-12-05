
# Background ----

# extract LANDFIRE EVT data per bobcat home range
# Randy Swaty and Isabella Oldani
# December 2024

# Dependencies ----

# packages


library(rlandfire)
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

# load LF EVT attributes

evt_atts <- read.csv("data/LF22_EVT_230.csv")

# Download and load LANDFIRE data ----

aoi <- getAOI(male_ranges)


# LFPS Parameters
products <-  c("230EVT")
projection <- 5070
resolution <- 30


# R specific arguments
temp_file <- tempfile(fileext = ".zip")

# call API
ncal <- landfireAPI(products,
                    aoi,
                    projection,
                    resolution,
                    path = temp_file)

# Define the destination path
dest_file <- file.path("data", "landfire_data.zip")

# Move and rename the file
file.rename(temp_file, dest_file)

# Create a temporary directory for unzipping
temp_dir <- tempfile()
dir.create(temp_dir)

# Unzip the file into the temporary directory
unzip(dest_file, exdir = temp_dir)

# Get the list of unzipped files
unzipped_files <- list.files(temp_dir, full.names = TRUE)

# Rename each unzipped file to "landfire_data" with its full original extension
for (file in unzipped_files) {
  file_name <- basename(file)
  file_extension <- sub("^[^.]*", "", file_name)  # Extract the full extension
  new_file_path <- file.path("data", paste0("landfire_data", file_extension))
  file.rename(file, new_file_path)
}

# Clean up the temporary directory
unlink(temp_dir, recursive = TRUE)



# Try to extract ----


# load EVT data
evt <- rast("data/landfire_data.tif") # I used tempdir() to find data, then manually unzipped, moved and renamed
plot(evt)

# Extract raster values based on bobcat ranges
male_cats_evt <- terra::extract(evt, male_ranges, df = TRUE) %>%
  # Extract data from 'evt' based on 'male_ranges' and return as a data frame
  dplyr::mutate(LabNumber = male_ranges$LabNumber[ID]) %>%
  # Add a new column 'LabNumber' using values from 'male_ranges$LabNumber' based on 'ID'
  group_by(LabNumber, US_230EVT) %>%
  # Group the data by 'LabNumber' and 'US_230EVT'
  summarize(count = n())
# Summarize the data by counting the number of occurrences for each group


# Add attributes to extracted dataframes ----

male_cats_evt_atts <- male_cats_evt %>%
  left_join(evt_atts, by = c('US_230EVT' = 'VALUE'))

write.csv(male_cats_evt_atts, file = "outputs/male_cats.csv")





