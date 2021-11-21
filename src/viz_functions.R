###
### Functions for visualization of Citi Bike analysis
###


### Color setup
mycols <- c("#CD534CFF", "#0073C2FF", "#EFC000FF", "#868686FF")

### Pi chart
my_pichart_fct <- function(dt, fill_var, title){
  dt <- dt[, .N, by = fill_var]
  dt <- dt[order((-1)^(length(dt[[fill_var]]))*desc(dt[, ..fill_var]))]
  dt[, prop := round(100*N / sum(N), 2)]
  dt[, pos := cumsum(prop) - 0.5*prop]
  dt$x <- 2
  ggplot(dt, aes_string(x = "x", y = "prop", fill = fill_var)) +
    geom_bar(width = 1, stat = "identity") +
    coord_polar("y", start = 0) +
    theme_void() +
    geom_text(aes(y = pos, label = paste0(prop, " % \n", N))) +
    scale_fill_manual(fill_var, values = mycols) +
    labs(title = title) +
    xlim(1, 2.5)
}

### Heatmap
my_heatmap_fct <- function(dt, x_var, y_var, by_var, title = "") {
  dt <- dt[, .("N" = .N / 1000000), by = by_var]
  ggplot(dt, aes_string(x = x_var, y = y_var, fill = "N")) +
    geom_tile() +
    scale_fill_gradient(low = "white", high = "blue",
                        name = "Number of trips [in mio.]") +
    labs(title = title, x = x_var, y = y_var)
}

### Bar chart
my_barchart_fct <-
  function(dt, x_var, by_var, fill_var = NA, title = "", position = "stack"){
  dt <- dt[, .("N" = .N / 1000000), by = by_var]
  if (is.na(fill_var)) {
    ggplot(dt, aes_string(x = x_var, y = "N")) +
      geom_bar(stat = "identity") +
      labs(x = x_var, y = "Number of trips [in mio.]", title = title)
  } else{
    ggplot(dt, aes_string(x = x_var, y = "N", fill = fill_var)) +
      geom_bar(stat = "identity", position = position) +
      scale_fill_manual(values = mycols) +
      labs(x = x_var, y = "Number of trips [in mio.]", title = title)
  }
}

### Bar chart with flipped coordinates
my_barchart_flip_fct <- function(dt, x_var, title){
  dt[, N := N / 1000000]
  dt <- dt[order(-N)][1:5]
  ggplot(dt, aes_string(x = paste0("reorder(", x_var, ", N)"), y = "N")) +
    geom_bar(stat = "identity") +
    coord_flip() +
    labs(title = title, x = "", y = "Number of trips [in mio.]")
}