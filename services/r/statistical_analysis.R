statistical_summary <- function(data) {
  list(
    mean = mean(data, na.rm = TRUE),
    median = median(data, na.rm = TRUE),
    sd = sd(data, na.rm = TRUE),
    var = var(data, na.rm = TRUE),
    min = min(data, na.rm = TRUE),
    max = max(data, na.rm = TRUE),
    q1 = quantile(data, 0.25, na.rm = TRUE),
    q3 = quantile(data, 0.75, na.rm = TRUE),
    iqr = IQR(data, na.rm = TRUE),
    n = length(data)
  )
}

correlation_matrix <- function(data) {
  cor(data, use = "complete.obs")
}

linear_regression <- function(x, y) {
  model <- lm(y ~ x)
  list(
    coefficients = coef(model),
    fitted = fitted(model),
    residuals = residuals(model),
    r_squared = summary(model)$r.squared,
    adj_r_squared = summary(model)$adj.r.squared,
    p_value = summary(model)$coefficients[2, 4]
  )
}

normalize_data <- function(data) {
  (data - min(data, na.rm = TRUE)) / (max(data, na.rm = TRUE) - min(data, na.rm = TRUE))
}

standardize_data <- function(data) {
  (data - mean(data, na.rm = TRUE)) / sd(data, na.rm = TRUE)
}

outliers_iqr <- function(data) {
  q1 <- quantile(data, 0.25, na.rm = TRUE)
  q3 <- quantile(data, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr
  data < lower_bound | data > upper_bound
}

remove_outliers <- function(data) {
  data[!outliers_iqr(data)]
}

moving_average <- function(data, window) {
  stats::filter(data, rep(1/window, window), sides = 2)
}

exponential_smoothing <- function(data, alpha) {
  result <- numeric(length(data))
  result[1] <- data[1]
  for (i in 2:length(data)) {
    result[i] <- alpha * data[i] + (1 - alpha) * result[i-1]
  }
  result
}

hypothesis_test <- function(sample1, sample2, alternative = "two.sided") {
  t.test(sample1, sample2, alternative = alternative)
}

anova_test <- function(groups) {
  aov_result <- aov(value ~ group, data = groups)
  summary(aov_result)
}

chi_square_test <- function(observed, expected) {
  chisq.test(observed, p = expected/sum(expected))
}

bootstrap_ci <- function(data, statistic, R = 1000, conf.level = 0.95) {
  boot_stats <- replicate(R, {
    sample_data <- sample(data, replace = TRUE)
    statistic(sample_data)
  })
  quantile(boot_stats, c((1-conf.level)/2, 1-(1-conf.level)/2))
}

cross_validation <- function(data, k = 5) {
  n <- nrow(data)
  fold_size <- ceiling(n / k)
  folds <- sample(rep(1:k, length.out = n))

  results <- lapply(1:k, function(i) {
    test_idx <- which(folds == i)
    train_idx <- which(folds != i)
    list(train = data[train_idx, ], test = data[test_idx, ])
  })

  results
}

pca_analysis <- function(data, n_components = 2) {
  pca <- prcomp(data, scale. = TRUE)
  list(
    rotation = pca$rotation[, 1:n_components],
    scores = pca$x[, 1:n_components],
    variance_explained = summary(pca)$importance[2, 1:n_components]
  )
}

kmeans_clustering <- function(data, k, max_iter = 100) {
  kmeans(data, centers = k, iter.max = max_iter, nstart = 25)
}

time_series_decompose <- function(ts_data, frequency) {
  ts_obj <- ts(ts_data, frequency = frequency)
  decompose(ts_obj)
}

rolling_window <- function(data, window, FUN) {
  sapply(1:(length(data) - window + 1), function(i) {
    FUN(data[i:(i + window - 1)])
  })
}

detect_changepoints <- function(data, threshold = 2) {
  diffs <- diff(data)
  z_scores <- abs((diffs - mean(diffs)) / sd(diffs))
  which(z_scores > threshold)
}
