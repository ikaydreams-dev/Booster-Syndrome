# Booster Syndrome Analytics
library(dplyr)
library(ggplot2)
library(lubridate)

# Load event data
load_events <- function(filepath) {
  events <- read.csv(filepath, stringsAsFactors = FALSE)
  events$timestamp <- as.POSIXct(events$timestamp, origin = "1970-01-01")
  return(events)
}

# Calculate daily active users
calculate_dau <- function(events) {
  events %>%
    mutate(date = as.Date(timestamp)) %>%
    group_by(date) %>%
    summarise(
      dau = n_distinct(user_id),
      total_events = n()
    )
}

# Calculate retention
calculate_retention <- function(events, cohort_date) {
  cohort_users <- events %>%
    filter(as.Date(timestamp) == cohort_date,
           event_type == "signup") %>%
    pull(user_id) %>%
    unique()

  retention_data <- data.frame()

  for (day in 0:30) {
    check_date <- cohort_date + days(day)

    active_users <- events %>%
      filter(as.Date(timestamp) == check_date,
             user_id %in% cohort_users) %>%
      pull(user_id) %>%
      unique() %>%
      length()

    retention_rate <- (active_users / length(cohort_users)) * 100

    retention_data <- rbind(retention_data, data.frame(
      day = day,
      active_users = active_users,
      retention_rate = retention_rate
    ))
  }

  return(retention_data)
}

# Event funnel analysis
analyze_funnel <- function(events, steps) {
  funnel_data <- data.frame()

  for (i in 1:length(steps)) {
    step <- steps[i]

    users <- events %>%
      filter(event_type == step) %>%
      pull(user_id) %>%
      unique()

    if (i == 1) {
      conversion_rate <- 100
    } else {
      conversion_rate <- (length(users) / initial_users) * 100
    }

    if (i == 1) {
      initial_users <- length(users)
    }

    funnel_data <- rbind(funnel_data, data.frame(
      step = step,
      users = length(users),
      conversion_rate = conversion_rate
    ))
  }

  return(funnel_data)
}

# Cohort analysis
cohort_analysis <- function(events) {
  events %>%
    mutate(
      cohort_month = floor_date(timestamp, "month"),
      event_month = floor_date(timestamp, "month")
    ) %>%
    group_by(cohort_month, event_month) %>%
    summarise(
      users = n_distinct(user_id),
      events = n()
    ) %>%
    ungroup()
}

# Plot retention curve
plot_retention <- function(retention_data) {
  ggplot(retention_data, aes(x = day, y = retention_rate)) +
    geom_line(color = "blue", size = 1) +
    geom_point(color = "red", size = 2) +
    labs(
      title = "User Retention Over Time",
      x = "Days Since Signup",
      y = "Retention Rate (%)"
    ) +
    theme_minimal()
}

# Plot event distribution
plot_event_distribution <- function(events) {
  events %>%
    group_by(event_type) %>%
    summarise(count = n()) %>%
    ggplot(aes(x = reorder(event_type, -count), y = count)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    labs(
      title = "Event Distribution",
      x = "Event Type",
      y = "Count"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# Export results
export_results <- function(data, filename) {
  write.csv(data, filename, row.names = FALSE)
  print(paste("Results exported to:", filename))
}
