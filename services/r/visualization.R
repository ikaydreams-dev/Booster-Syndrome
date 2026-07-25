# Data Visualization Utilities

# Plotting functions
create_histogram <- function(data, bins = 30, title = "Histogram") {
  hist(data, 
       breaks = bins,
       main = title,
       xlab = "Value",
       ylab = "Frequency",
       col = "steelblue",
       border = "white")
}

create_scatter_plot <- function(x, y, title = "Scatter Plot") {
  plot(x, y,
       main = title,
       xlab = "X",
       ylab = "Y",
       pch = 19,
       col = rgb(0, 0, 1, 0.5))
}

create_boxplot <- function(data, title = "Box Plot") {
  boxplot(data,
          main = title,
          ylab = "Value",
          col = "lightblue",
          border = "darkblue")
}

create_line_chart <- function(x, y, title = "Line Chart") {
  plot(x, y,
       type = "l",
       main = title,
       xlab = "X",
       ylab = "Y",
       col = "darkblue",
       lwd = 2)
}

# Multi-plot function
create_multi_plot <- function(data_list, titles, rows = 2, cols = 2) {
  par(mfrow = c(rows, cols))
  for (i in seq_along(data_list)) {
    hist(data_list[[i]], 
         main = titles[i],
         col = "steelblue",
         border = "white")
  }
  par(mfrow = c(1, 1))
}

# Correlation heatmap
create_correlation_heatmap <- function(correlation_matrix) {
  heatmap(correlation_matrix,
          col = colorRampPalette(c("blue", "white", "red"))(100),
          scale = "none",
          main = "Correlation Heatmap")
}
