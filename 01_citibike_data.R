###
### Download, preprocess and clean the Citi Bike 2018 data
###


###
### Initialization
###
rm(list = ls(all.names = TRUE))
gc()
library(data.table)
library(lubridate)
library(ggplot2)


###
### Getting raw data from server
###
timeframe <- 201801:201812
citibike_data <-
  rbindlist(lapply(timeframe, function(yyyymm){
    url <- paste0("https://s3.amazonaws.com/tripdata/", yyyymm,
                  "-citibike-tripdata.csv.zip")
    tempdl <- tempfile()
    download.file(url, tempdl)
    file_name <- paste0(yyyymm, "-citibike-tripdata.csv")
    unzip(tempdl, exdir = "./data", file_name)
    file_path <- paste0("./data/", file_name)
    data <- fread(file_path)
    file.remove(file_path)
    return(data)
  }))
#saveRDS(citibike_data, "./data/citibike_data_raw.rds")
#citibike_data <- readRDS("./data/citibike_data_raw.rds")
dim(citibike_data)
head(citibike_data)


###
### Transform data
###
str(citibike_data)
setnames(citibike_data, old = names(citibike_data),
         new = gsub(" ", "_", names(citibike_data)))
citibike_data[, ':=' (
  start_station_id = factor(as.numeric(start_station_id)),
  start_station_name = factor(start_station_name),
  end_station_id = factor(as.numeric(end_station_id)),
  end_station_name = factor(end_station_name),
  bikeid = factor(bikeid),
  usertype = factor(usertype),
  gender = factor(gender),
  tripduration = tripduration / 60
)]
levels(citibike_data$gender) <- c("unknown", "male", "female")
levels(citibike_data$usertype) <- c("customer", "subscriber")


###
### Data cleaning
###

summary(citibike_data)

### checking missing values
data.table(
  "variable" = names(citibike_data),
  "NA" = sapply(1:ncol(citibike_data), function(i)
    any(is.na(citibike_data[, ..i]))),
  "NULL" = sapply(1:ncol(citibike_data), function(i)
    any(levels(citibike_data[[i]]) == "NULL"))
)
# citibike_data[is.na(start_station_id) | is.na(end_station_id) |
#               start_station_name == "NULL" | end_station_name == "NULL"]
citibike_data <-
  citibike_data[!(is.na(start_station_id) | is.na(end_station_id) |
                start_station_name == "NULL" | end_station_name == "NULL")]

### checking tripduration
#short
#citibike_data[tripduration < 2 &
#              as.character(start_station_id) == as.character(end_station_id)]
citibike_data <-
  citibike_data[!(tripduration < 2 &
                as.character(start_station_id) == as.character(end_station_id))]
#long
#quantile(citibike_data$tripduration, probs = 0.99)
#citibike_data[tripduration > 60]
citibike_data <- citibike_data[tripduration <= 60]

### checking station location
#citibike_data[start_station_latitude > 41 | end_station_latitude > 41]
#unique(citibike_data[start_station_latitude > 41]$start_station_id)
#unique(citibike_data[end_station_latitude > 41]$end_station_id)
citibike_data <-
  citibike_data[start_station_latitude <= 41 & end_station_latitude <= 41]

### checking year of birth
ggplot(citibike_data, aes(y = birth_year)) +
  geom_boxplot() +
  coord_flip() +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank())
#citibike_data[birth_year < 1948]
citibike_data <- citibike_data[birth_year >= 1948]

###
### extend data for analysis
###
citibike_data[, ':='(
  date = as.Date(starttime),
  month = factor(month(starttime)),
  dayofweek = factor(ifelse(wday(starttime) - 1 != 0, wday(starttime) - 1, 7)),
  hour = factor(hour(starttime))
)]


###
### save data for analysis
###
dim(citibike_data)
str(citibike_data)
summary(citibike_data)
saveRDS(citibike_data, "./data/citibike_data_clean.rds")