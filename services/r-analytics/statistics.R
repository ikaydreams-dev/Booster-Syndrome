# Statistical Analysis Service for Booster

library(dplyr)
library(ggplot2)

calculate_summary_stats <- function(data) {
  summary_stats <- list(
    mean = mean(data, na.rm = TRUE),
    median = median(data, na.rm = TRUE),
    sd = sd(data, na.rm = TRUE),
    min = min(data, na.rm = TRUE),
    max = max(data, na.rm = TRUE),
    q25 = quantile(data, 0.25, na.rm = TRUE),
    q75 = quantile(data, 0.75, na.rm = TRUE)
  )

  return(summary_stats)
}

perform_regression <- function(x, y) {
  model <- lm(y ~ x)

  result <- list(
    coefficients = coef(model),
    r_squared = summary(model)$r.squared,
    p_value = summary(model)$coefficients[2, 4],
    residuals = residuals(model)
  )

  return(result)
}

calculate_correlation <- function(df) {
  cor_matrix <- cor(df, use = "complete.obs")
  return(cor_matrix)
}

detect_outliers <- function(data) {
  q1 <- quantile(data, 0.25, na.rm = TRUE)
  q3 <- quantile(data, 0.75, na.rm = TRUE)
  iqr <- q3 - q1

  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr

  outliers <- data[data < lower_bound | data > upper_bound]

  return(list(
    outliers = outliers,
    lower_bound = lower_bound,
    upper_bound = upper_bound,
    count = length(outliers)
  ))
}

normalize_data <- function(data) {
  (data - min(data, na.rm = TRUE)) / (max(data, na.rm = TRUE) - min(data, na.rm = TRUE))
}

calculate_moving_average <- function(data, window_size) {
  n <- length(data)
  ma <- numeric(n)

  for (i in 1:n) {
    start_idx <- max(1, i - window_size + 1)
    ma[i] <- mean(data[start_idx:i], na.rm = TRUE)
  }

  return(ma)
}

perform_hypothesis_test <- function(group1, group2) {
  test_result <- t.test(group1, group2)

  return(list(
    statistic = test_result$statistic,
    p_value = test_result$p.value,
    confidence_interval = test_result$conf.int,
    significant = test_result$p.value < 0.05
  ))
}

create_distribution_plot <- function(data, title = "Distribution Plot") {
  df <- data.frame(value = data)

  ggplot(df, aes(x = value)) +
    geom_histogram(binwidth = (max(data) - min(data)) / 30,
                   fill = "steelblue",
                   color = "black") +
    labs(title = title, x = "Value", y = "Frequency") +
    theme_minimal()
}

analyze_time_series <- function(data, dates) {
  ts_data <- ts(data, frequency = 365)

  decomposed <- decompose(ts_data)

  return(list(
    trend = decomposed$trend,
    seasonal = decomposed$seasonal,
    random = decomposed$random
  ))
}
