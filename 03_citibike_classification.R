###
### Classification models for Citi Bike user
###


###
### Initialization
###
rm(list = ls(all.names = TRUE))
gc()
options(scipen = 999)
library(data.table)
library(pROC)
library(ranger)
source("./src/classification_functions.R")


###
### Reduce size of data set
###
citibike_data <- readRDS("./data/citibike_data_clean.rds")
set.seed(1969)
subsample_index <-
 sample(1:nrow(citibike_data), round(nrow(citibike_data)*0.05))
citibike_data <- citibike_data[subsample_index]
prop.table(table(citibike_data$usertype))
#saveRDS(citibike_data, "./data/citibike_data_subsample.rds")
#citibike_data <- readRDS("./data/citibike_data_subsample.rds")


###
### Define new features
###

citibike_data[, gender_bin :=
                factor(ifelse(gender == "unknown", "unknwon", "known"))]
citibike_data[, user_anonym :=
                factor(ifelse(gender == "unknown" & birth_year == 1969, 1, 0))]
citibike_data[, weekend :=
                factor(ifelse(dayofweek %in% c(6, 7), 1, 0))]
citibike_data[, rushhour :=
                factor(ifelse(weekend == 1 & hour %in% c(6:9, 16:20), 1, 0))]
citibike_data[, circle_trip :=
                factor(ifelse(as.character(start_station_name) ==
                              as.character(end_station_name), 1, 0))]
citibike_data[month %in% c(1, 2, 12), season := "winter"]
citibike_data[month %in% 3:5, season := "spring"]
citibike_data[month %in% 6:8, season := "summer"]
citibike_data[month %in% 9:11, season := "fall"]
citibike_data[, season := factor(season)]
citibike_data[hour %in% 5:11, time_of_day := "morning"]
citibike_data[hour %in% 12:17, time_of_day := "afternoon"]
citibike_data[hour %in% 18:22, time_of_day := "evening"]
citibike_data[hour %in% c(23, 0, 1, 2, 3, 4), time_of_day := "night"]
citibike_data[, time_of_day := factor(time_of_day)]

###
### Train / val / test split
###

set.seed(1969)
train_size <- 0.6
test_size <- 0.2
val_size <- 0.2
split_index <-
  sample(1:3, nrow(citibike_data), prob = c(train_size, test_size, val_size),
         replace = T )
citibike_train <- citibike_data[split_index == 1,]
citibike_val <- citibike_data[split_index == 2,]
citibike_test <- citibike_data[split_index == 3,]
#prop.table(table(citibike_train$usertype))
#prop.table(table(citibike_val$usertype))
#prop.table(table(citibike_test$usertype))
actual_train <- citibike_train$usertype
actual_val <- citibike_val$usertype
actual_test <- citibike_test$usertype


###
### Benchmark models
###
#prediction_prob_benchmark <- rep(1, length(actual_val))
#evaluate_model(actual_val, prediction_prob_benchmark)
#prediction_prob_benchmark <- ifelse(citibike_val$user_anonym == 0, 1, 0)
#evaluate_model(actual_val, prediction_prob_benchmark)


###
### Logistic Regression
###

###
glm1 <-
  glm(usertype ~ user_anonym + tripduration,
      data = citibike_train, family = "binomial")
summary(glm1)
prediction_glm1_prob <-
  as.vector(predict.glm(glm1, citibike_val, type = "response"))
evaluate_model(actual_val, prediction_glm1_prob)

###
glm2 <-
  glm(usertype ~ (user_anonym + poly(tripduration, 2))^2,
      data = citibike_train, family = "binomial")
summary(glm2)
prediction_glm2_prob <-
  as.vector(predict.glm(glm2, citibike_val, type = "response"))
evaluate_model(actual_val, prediction_glm2_prob)

###
glm3 <-
  glm(usertype ~ user_anonym + rushhour,
      data = citibike_train, family = "binomial")
summary(glm3)
prediction_glm3_prob <-
  as.vector(predict.glm(glm3, citibike_val, type = "response"))
evaluate_model(actual_val, prediction_glm3_prob)

###
glm4 <-
  glm(usertype ~ user_anonym + circle_trip + weekend,
      data = citibike_train, family = "binomial")
summary(glm4)
prediction_glm4_prob <-
  as.vector(predict.glm(glm4, citibike_val, type = "response"))
evaluate_model(actual_val, prediction_glm4_prob)

###
glm5 <-
  glm(usertype ~ user_anonym + circle_trip + weekend +
        (poly(start_station_latitude, 2) + poly(start_station_longitude, 2))^2 +
        (poly(end_station_latitude, 2) + poly(end_station_longitude, 2))^2,
      data = citibike_train, family = "binomial")
summary(glm5)
prediction_glm5_prob <-
  as.vector(predict.glm(glm5, citibike_val, type = "response"))
evaluate_model(actual_val, prediction_glm5_prob)

###
glm6 <-
  glm(usertype ~  user_anonym + tripduration + rushhour + circle_trip +
        weekend + season + time_of_day +
        (poly(start_station_latitude, 2) + poly(start_station_longitude, 2))^2 +
        (poly(end_station_latitude, 2) + poly(end_station_longitude, 2))^2,
      data = citibike_train, family = "binomial")
summary(glm6)
prediction_glm6_prob <-
  as.vector(predict.glm(glm6, citibike_val, type = "response"))
evaluate_model(actual_val, prediction_glm6_prob)


###
### Random forest
###

###
rf1 <-
  ranger(usertype ~  user_anonym + tripduration + rushhour + circle_trip +
         weekend + season + time_of_day +
         start_station_latitude + start_station_longitude +
         end_station_latitude + end_station_longitude,
         data = citibike_train, num.trees = 25, oob.error = FALSE,
         probability = TRUE)
prediction_rf1_prob <- predict(rf1, citibike_val)$predictions[,2]
evaluate_model(actual_val, prediction_rf1_prob)