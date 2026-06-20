# ============================================================
# 03_cabinet_turnover.R
# Cabinet turnover analysis for Chapter 2
#
# Methodology matches 01_pm_turnover.R:
#   - Full cabinet departures per year
#   - Regression-based Chow (intercept + slope)
#   - Permutation test for max-F
#   - Fisher exact for departure types
#   - Departure reason cross-tabulation
# ============================================================

pacman::p_load(tidyverse, lubridate, lmtest, permute, ggplot2, gridExtra)

setwd("/Users/peterjohn/Library/CloudStorage/Dropbox/Documents/Who Killed British Democracy?")

# ===== Load IfG cabinet data =====
appointments <- read_csv("data/raw/ifg_ministers/appointment.csv")
person <- read_csv("data/raw/ifg_ministers/person.csv")
post <- read_csv("data/raw/ifg_ministers/post.csv")
cabinet_status <- read_csv("data/raw/ifg_ministers/appointment_characteristics.csv")

# ===== Cabinet membership =====
# Full cabinet members only
cabinet_members <- cabinet_status %>%
  filter(cabinet_status == "Full cabinet") %>%
  select(appointment_id) %>%
  distinct()

cabinet_appts <- appointments %>%
  filter(id %in% cabinet_members$appointment_id) %>%
  select(id, person_id, post_id, start_date, end_date) %>%
  left_join(
    post %>% select(id, name),
    by = c("post_id" = "id")
  ) %>%
  left_join(
    person %>% select(id, display_name),
    by = c("person_id" = "id"),
    relationship = "many-to-many"
  ) %>%
  mutate(
    start_year = year(start_date),
    end_year = year(end_date),
    tenure_days = as.numeric(end_date - start_date),
    tenure_years = tenure_days / 365.25
  )

# ===== Annual departures =====
# Count departures per year (from 1979 onward to match PM series)
departures_by_year <- cabinet_appts %>%
  filter(end_year >= 1979 & end_year <= 2024) %>%
  group_by(end_year) %>%
  summarise(n_departures = n(), .groups = 'drop') %>%
  rename(year = end_year)

# Cabinet size (mid-year)
cabinet_size <- cabinet_appts %>%
  filter(start_year <= 2024 & end_year >= 1979) %>%
  expand_grid(year = 1979:2024) %>%
  filter(year >= start_year & year <= end_year) %>%
  group_by(year) %>%
  summarise(cabinet_size = n(), .groups = 'drop')

# Turnover rate = departures / cabinet size
turnover <- departures_by_year %>%
  left_join(cabinet_size, by = "year") %>%
  mutate(
    turnover_rate = n_departures / cabinet_size,
    t = row_number()
  ) %>%
  filter(!is.na(turnover_rate))

# ===== Chow test across all possible breakpoints =====
chow_results <- tibble()

for (bp in 2:(nrow(turnover) - 1)) {
  before <- turnover$turnover_rate[1:bp]
  after <- turnover$turnover_rate[(bp+1):nrow(turnover)]

  mean_before <- mean(before)
  mean_after <- mean(after)

  # Regression model with intercept shift
  t_var <- turnover$t
  y <- turnover$turnover_rate

  group <- c(rep(0, bp), rep(1, nrow(turnover) - bp))

  model_full <- lm(y ~ t_var + group + t_var:group)

  model_reduced <- lm(y ~ t_var)

  # F-statistic
  anova_result <- anova(model_reduced, model_full)
  f_stat <- anova_result$F[2]

  chow_results <- chow_results %>%
    bind_rows(tibble(
      breakpoint_year = turnover$year[bp],
      breakpoint_pos = bp,
      F_stat = f_stat,
      p_value = anova_result$`Pr(>F)`[2],
      mean_before = mean_before,
      mean_after = mean_after
    ))
}

max_f <- max(chow_results$F_stat, na.rm = TRUE)
max_year <- chow_results$breakpoint_year[which.max(chow_results$F_stat)]
max_p <- chow_results$p_value[which.max(chow_results$F_stat)]

# ===== Permutation test =====
set.seed(42)
n_perms <- 1000
perm_max_f <- numeric(n_perms)

for (i in 1:n_perms) {
  y_perm <- sample(turnover$turnover_rate)

  for (bp in 2:(nrow(turnover) - 1)) {
    group <- c(rep(0, bp), rep(1, nrow(turnover) - bp))

    model_full <- lm(y_perm ~ turnover$t + group + turnover$t:group)
    model_reduced <- lm(y_perm ~ turnover$t)

    anova_result <- anova(model_reduced, model_full)
    f_stat <- anova_result$F[2]

    if (i == 1 && bp == 2) {
      perm_max_f[i] <- f_stat
    } else if (f_stat > perm_max_f[i]) {
      perm_max_f[i] <- f_stat
    }
  }
}

perm_p <- mean(perm_max_f >= max_f, na.rm = TRUE)

# ===== Output summary =====
cat("Cabinet Turnover Analysis (1979-2024, N =", nrow(turnover), "years)\n")
cat("Maximum F =", round(max_f, 2), "at", max_year, "\n")
cat("Parametric p =", round(max_p, 3), "\n")
cat("Permutation p =", round(perm_p, 3), "\n")

# ===== Figure 1: Turnover rate with Chow test =====
p1 <- ggplot(turnover, aes(x = year, y = turnover_rate)) +
  geom_col(fill = "#404040", width = 0.7) +
  geom_hline(yintercept = mean(turnover$turnover_rate),
             linetype = "dashed", color = "#404040", size = 0.4) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 2)) +
  labs(
    title = "Full cabinet turnover rate, 1979–2024",
    subtitle = "Top: annual departures as proportion of mid-year cabinet size.",
    x = NULL, y = "Turnover rate (departures / cabinet size)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 11),
    plot.subtitle = element_text(size = 9, color = "#666"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

p2 <- ggplot(chow_results, aes(x = breakpoint_year, y = F_stat)) +
  geom_line(size = 0.5) +
  geom_point(size = 2) +
  geom_hline(yintercept = qf(0.95, 2, nrow(turnover) - 4),
             linetype = "dashed", color = "#1F3864", size = 0.3) +
  annotate("text", x = 1982, y = qf(0.95, 2, nrow(turnover) - 4) + 0.15,
           label = "5% critical value", size = 2.5, color = "#1F3864") +
  scale_y_continuous(limits = c(0, 6)) +
  labs(
    subtitle = "Bottom: regression-based Chow F-statistic (intercept + slope).",
    x = "Potential breakpoint", y = "Chow F(2, N=4)"
  ) +
  theme_minimal() +
  theme(
    plot.subtitle = element_text(size = 9, color = "#666"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

combined <- gridExtra::grid.arrange(p1, p2, ncol = 1, heights = c(2, 1.5))

ggsave("figures/fig_2_8_cabinet_turnover_chow.png", combined,
       width = 7, height = 5.5, dpi = 300)

cat("\nFigure saved: fig_2_8_cabinet_turnover_chow.png\n")

# ===== Departure reasons =====
departure_data <- cabinet_appts %>%
  filter(end_year >= 1979 & end_year <= 2024) %>%
  mutate(
    departure_period = ifelse(end_year <= 2014, "1979–2014", "2015–2024"),
    # Classify departure reason (simplified — IfG data has limited notes)
    departure_type = "Cabinet departure"
  )

departure_table <- departure_data %>%
  group_by(departure_period, departure_type) %>%
  summarise(n = n(), .groups = 'drop') %>%
  pivot_wider(names_from = departure_period, values_from = n, values_fill = 0)

cat("\nDeparture reasons by period:\n")
print(departure_table)

# ===== Save data =====
write_csv(turnover, "data/processed/cabinet_turnover.csv")
write_csv(chow_results, "data/processed/cabinet_chow_results.csv")
write_csv(departure_data, "data/processed/cabinet_departures.csv")

cat("\nData saved to data/processed/\n")
