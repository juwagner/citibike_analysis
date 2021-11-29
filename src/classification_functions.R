###
### Functions for classification of Citi Bike data
###


### Evaluate a model
evaluate_model <- function(truth, prediction_prob, threshold = 0.5){
  prediction <- ifelse(prediction_prob >= threshold, "subscriber", "customer")
  print(table(truth, prediction))
  print(100 * prop.table( table(truth, prediction)))
  true_pos <- sum(truth == prediction & prediction == "customer")
  true_neg <- sum(truth == prediction & prediction == "subscriber")
  false_pos <- sum(truth != prediction & prediction == "customer")
  false_neg <-  sum(truth != prediction & prediction == "subscriber")
  accuracy <-
    100 * (true_pos + true_neg) / (true_pos + true_neg + false_pos + false_neg)
  precision <- ifelse((true_pos + false_pos) == 0, 1,
                      100 * true_pos / (true_pos + false_pos))
  recall <- 100 * true_pos / (true_pos + false_neg)
  F1_score <- 2*(precision * recall) / (precision + recall)
  auc <- 100*auc(truth, prediction_prob)
  cat("\naccuracy:  ", round(accuracy, 4), "\nprecision: ", round(precision, 4),
      "\nrecall: \ \ \ ", round(recall, 4), "\nF1-score: \ ", round(F1_score, 4),
      "\nAUC: \ \ \ \ \ \ ", round(auc, 4), "\n ")
}