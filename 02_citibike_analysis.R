###
### Visualizations for Citi Bike analysis
###


###
### Initialization
###
rm(list = ls(all.names = TRUE))
gc()
options(scipen = 999)
library(tidyverse)
library(data.table)
library(scales)
source("./src/viz_functions.R")
citibike_data <- readRDS("./data/citibike_data_clean.rds")


###
### User information
###

### user type
my_pichart_fct(citibike_data, "usertype", "User distribution")
my_pichart_fct(citibike_data[usertype == "customer"],
               "gender", "Gender distribution for customer")
my_pichart_fct(citibike_data[usertype == "subscriber"],
               "gender", "Gender distribution for subscriber")

### birth year
ggplot(citibike_data, aes(x = "", y = birth_year)) +
  geom_violin(adjust = 1.8) +
  labs(title = "Distribution of birth year", x = "", y = "birth_year") +
  facet_grid(~usertype)

### Anonymous user
my_barchart_fct(citibike_data, x_var = "birth_year", by_var = c("birth_year"))
my_barchart_fct(citibike_data, x_var = "birth_year",
                by_var = c("birth_year", "usertype"), fill_var = "usertype")
my_barchart_fct(citibike_data, x_var = "birth_year",
                by_var = c("birth_year", "gender"), fill_var = "gender")
my_barchart_fct(citibike_data[birth_year == 1969], x_var = "usertype",
                by_var = c("usertype", "gender"), fill_var = "gender",
                title = "Restricted to birth year 1969")


###
### Trip information
###

### Month, day, hour
my_barchart_fct(citibike_data, x_var = "month", by_var = c("month", "usertype"),
                fill_var = "usertype", position = "dodge")
my_barchart_fct(citibike_data, x_var = "dayofweek",
                by_var = c("dayofweek", "usertype"), fill_var = "usertype",
                position = "dodge")
my_barchart_fct(citibike_data, x_var = "hour", by_var = c("hour", "usertype"),
                fill_var = "usertype", position = "dodge")

### Rush hour
my_heatmap_fct(citibike_data[usertype == "customer"], x_var = "dayofweek",
               y_var = "hour", by_var = c("hour", "dayofweek"),
               title = "Trips per weekday and hour - customer")
my_heatmap_fct(citibike_data[usertype == "subscriber"], x_var = "dayofweek",
               y_var = "hour", by_var = c("hour", "dayofweek"),
               title = "Trips per weekday and hour - subscriber")


###
### Trip duration
###

ggplot(citibike_data, aes(x = "" , y = tripduration)) +
  geom_violin() +
  labs(title = "Tripduration per usertype", x = "",
       y = "tripduration [in minutes]") +
  facet_grid(~usertype)

ggplot(citibike_data, aes(x = dayofweek , y = tripduration, group = dayofweek)) +
  geom_violin() +
  labs(title = "Tripduration per usertype and day of week", x = "dayofweek",
       y = "tripduration [in minutes]") +
  facet_grid(~usertype)

ggplot(citibike_data[, .("avg" = mean(tripduration)), by = .(month, usertype)],
       aes(x = month, y = avg, group = usertype, color = usertype)) +
  geom_line() +
  labs(x = "month", y = "average tripduration") +
  scale_color_manual(values = mycols)


###
### Stations
###
citibike_station <-
merge(
  citibike_data[, .("N_start" = .N), by = .(start_station_name, usertype)],
  citibike_data[, .("N_end" = .N), by = .(end_station_name, usertype)],
  by.x = c("start_station_name", "usertype"),
  by.y = c("end_station_name", "usertype"),
  all = TRUE
)
setnames(citibike_station, old = "start_station_name", new = "station_name")
citibike_station[, "N" := N_start + N_end]

my_barchart_flip_fct(citibike_station[, lapply(.SD,sum), .SDcols = "N",
                                      by = station_name],
                     x_var = "station_name", title = "Top 5 stations")
my_barchart_flip_fct(citibike_station[usertype == "customer"],
                     x_var = "station_name",
                     title = "Top 5 stations - customer")
my_barchart_flip_fct(citibike_station[usertype == "subscriber"],
                     x_var = "station_name",
                     title = "Top 5 stations - subscriber")


###
### Top trips
###
citibike_data[, trip := paste0(start_station_name, " -\n ", end_station_name)]
citibike_trip <- citibike_data[, .N, by = .(trip, usertype) ]
my_barchart_flip_fct(citibike_trip[, lapply(.SD,sum), .SDcols = "N", by = trip],
                     x_var = "trip", title = "Top 5 trips")
my_barchart_flip_fct(citibike_trip[usertype == "customer"], x_var = "trip",
                     title = "Top 5 trips - customer")
my_barchart_flip_fct(citibike_trip[usertype == "subscriber"], x_var = "trip",
                     title = "Top 5 trips - subscriber")