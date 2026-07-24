# Data Analysis Utilities

# Statistical functions
calculate_statistics <- function(data) {
  list(
    mean = mean(data, na.rm = TRUE),
    median = median(data, na.rm = TRUE),
    sd = sd(data, na.rm = TRUE),
    min = min(data, na.rm = TRUE),
    max = max(data, na.rm = TRUE),
    q25 = quantile(data, 0.25, na.rm = TRUE),
    q75 = quantile(data, 0.75, na.rm = TRUE)
  )
}

# Data cleaning
remove_outliers <- function(data, threshold = 3) {
  z_scores <- abs(scale(data))
  data[z_scores < threshold]
}

fill_missing <- function(data, method = "mean") {
  if (method == "mean") {
    data[is.na(data)] <- mean(data, na.rm = TRUE)
  } else if (method == "median") {
    data[is.na(data)] <- median(data, na.rm = TRUE)
  } else if (method == "zero") {
    data[is.na(data)] <- 0
  }
  data
}

# Correlation analysis
calculate_correlation <- function(x, y, method = "pearson") {
  cor(x, y, method = method, use = "complete.obs")
}

correlation_matrix <- function(df) {
  cor(df, use = "complete.obs")
}

# Linear regression
fit_linear_model <- function(data, formula) {
  model <- lm(formula, data = data)
  list(
    coefficients = coef(model),
    r_squared = summary(model)$r.squared,
    residuals = residuals(model),
    fitted = fitted(model)
  )
}

# Time series analysis
moving_average <- function(data, window) {
  stats::filter(data, rep(1/window, window), sides = 2)
}

# Data transformation
normalize <- function(data) {
  (data - min(data)) / (max(data) - min(data))
}

standardize <- function(data) {
  (data - mean(data)) / sd(data)
}
