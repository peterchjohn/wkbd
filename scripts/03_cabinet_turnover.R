# ⭐ PROMOTED TO CANONICAL, 17 Aug 2026. This file WAS the _NOCHOW variant; PJ, 17 Aug:
#   "do it, need to sort out file mess!". The pre-Chow-removal original is preserved at
#   _ARCHIVE/scripts/superseded_17aug_prechow_scripts/scripts/03_cabinet_turnover.R
# ✅ This is now the live script for the printed figure and IT IS FINE TO HAND-EDIT.
#   (The 'AUTO-DERIVED / DO NOT HAND-EDIT' lines below described the old derived copy and
#   no longer apply — there is no generator to re-run over this file.)
# 03_cabinet_turnover.R — AUTO-DERIVED 17 Aug 2026. ⛔ DO NOT HAND-EDIT.
# 1. Chow panel (p_bot) removed, with the subtitle that narrated it ("Bottom: Chow F-statistic
#    with and without 2022").
# 2. ⭐ RENUMBERED 2.5 -> 2.4 (old Figure 2.3 dropped, so everything shifts down one).
# 3. ⭐ CROSS-REFERENCE FIXED: the caption pointed at "Fig 2.4" for the Great Officers figure,
#    which is now Figure 2.3. This is exactly the kind of reference the 16 Aug renumbering
#    missed, so it is corrected in the same step rather than left for a sweep.
# ⚠ Cabinet departures prefer a LINEAR trend (+0.271/yr); a break is 3.04 BIC worse. The Chow
#   is still computed and printed to the console; only its panel is removed.

# ============================================================
# 03_cabinet_turnover.R
# Annual full-cabinet departures, 1979–2026
# EXCLUDING Great Officers of State (Chancellor, Home Sec,
# Foreign Sec) to avoid double-counting with Fig 2.4
#
# Two-panel figure: departures (top) + dual Chow (bottom)
# Matches style of 02b_great_officers_combined_figure.R
# ============================================================

rm(list = ls())
.ROOT <- local({
  a <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", a, value = TRUE)
  if (length(m) == 1) normalizePath(file.path(dirname(sub("^--file=", "", m)), ".."))
  else getwd()
})  # portable project root: works via Rscript from anywhere, or falls back to
    # getwd() when sourced interactively (assumes repo root as cwd)
setwd(.ROOT)

if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, ggplot2, tidyr, readr, lubridate, patchwork)

# ============================================================
# LOAD IfG DATA
# ============================================================
appointments <- read_csv("data/raw/ifg_ministers/appointment.csv",
                         show_col_types = FALSE)
person       <- read_csv("data/raw/ifg_ministers/person.csv",
                         show_col_types = FALSE)
post         <- read_csv("data/raw/ifg_ministers/post.csv",
                         show_col_types = FALSE)
cab_status   <- read_csv("data/raw/ifg_ministers/appointment_characteristics.csv",
                         show_col_types = FALSE)

# ============================================================
# IDENTIFY FULL CABINET APPOINTMENTS
# ============================================================
cabinet_ids <- cab_status |>
  filter(cabinet_status == "Full cabinet") |>
  pull(appointment_id) |>
  unique()

cabinet <- appointments |>
  filter(id %in% cabinet_ids) |>
  select(id, person_id, post_id, start_date, end_date) |>
  left_join(post |> select(id, name), by = c("post_id" = "id")) |>
  rename(post_name = name)

# ============================================================
# EXCLUDE GREAT OFFICERS OF STATE
# ============================================================
great_officer_post_ids <- c(
  "a9190617-c45a-49dd-a6ad-77abb6b36815",  # Chancellor of the Exchequer
  "100de08d-152e-45c2-8b0b-cc8e6c54c0a6",  # Home Secretary
  "5f655663-f908-4209-859f-51fed3d01c64",   # Foreign Sec (FCDA)
  "ec5c9bc9-046e-4df2-ac63-b651073778ef"    # Foreign Sec (FCO)
)

n_before <- nrow(cabinet)
cabinet <- cabinet |>
  filter(!post_id %in% great_officer_post_ids)
n_after <- nrow(cabinet)

cat(sprintf("Full cabinet appointments: %d\n", n_before))
cat(sprintf("After excluding great officers: %d (removed %d)\n",
            n_after, n_before - n_after))

# ============================================================
# ANNUAL DEPARTURES (1979–2026)
# ============================================================
cabinet <- cabinet |>
  mutate(
    end_year = year(end_date),
    start_year = year(start_date)
  )

all_years <- tibble(year = 1979:2025)  # 2026 incomplete — update when full year available

annual <- cabinet |>
  filter(end_year >= 1979, end_year <= 2025) |>
  group_by(end_year) |>
  summarise(departures = n(), .groups = "drop") |>
  rename(year = end_year) |>
  right_join(all_years, by = "year") |>
  mutate(departures = replace_na(departures, 0)) |>
  arrange(year)

mean_dep <- mean(annual$departures)

cat(sprintf("\nAnnual departures 1979-2026: mean = %.1f\n", mean_dep))

# ============================================================
# CHOW TEST (with and without 2022)
# ============================================================

# --- fast closed-form simple-OLS residual sum of squares (intercept + one slope) ---
# Numerically identical to lm(y ~ t) RSS (verified to < 1e-13) but ~100x faster.
# Removes the permutation-loop bottleneck (10,000 perms x every break x 3 lm fits,
# run twice) that pushed this script past the 200s road-test cap. set.seed(42) and
# n_perm are unchanged, so reported permutation p-values are identical.
.rss_lin <- function(y, t) {
  n <- length(y)
  if (n < 3) return(0)                 # <=2 points fit exactly (RSS 0), matching lm
  mt <- mean(t); my <- mean(y)
  Stt <- sum((t - mt)^2)
  if (Stt == 0) return(sum((y - my)^2))
  b <- sum((t - mt) * (y - my)) / Stt
  sum((y - (my - b * mt) - b * t)^2)
}
chow_regression <- function(y, t, k) {
  n <- length(y)
  if (k < 3 || k > n - 3) return(NA_real_)
  rss_pool  <- .rss_lin(y, t)
  rss_split <- .rss_lin(y[1:k], t[1:k]) + .rss_lin(y[(k+1):n], t[(k+1):n])
  p <- 2
  ((rss_pool - rss_split) / p) / (rss_split / (n - 2 * p))
}

run_chow <- function(df, label) {
  y <- df$departures
  t_seq <- seq_along(y)
  n <- length(y)
  ks <- seq(3, n - 3)
  fstats <- sapply(ks, function(k) chow_regression(y, t_seq, k))

  fs <- tibble(
    k     = ks,
    year  = df$year[ks],
    fstat = fstats,
    series = label
  ) |> filter(!is.na(fstat))

  crit <- qf(0.95, df1 = 2, df2 = n - 4)
  bp <- fs |> slice_max(fstat, n = 1)

  # Permutation test
  set.seed(42)
  n_perm <- 10000
  perm_maxF <- replicate(n_perm, {
    y_p <- sample(y)
    f_p <- sapply(ks, function(k) chow_regression(y_p, t_seq, k))
    max(f_p, na.rm = TRUE)
  })
  perm_p <- mean(perm_maxF >= bp$fstat)

  list(fs = fs, bp = bp, crit = crit, perm_p = perm_p, n = n)
}

# Full series
res_all <- run_chow(annual, "All years")

# Excluding 2022
annual_ex <- annual |> filter(year != 2022)
res_ex  <- run_chow(annual_ex, "Excluding 2022")

fs_both <- bind_rows(res_all$fs, res_ex$fs)

cat(sprintf("\n========== CHOW TEST: ALL YEARS ==========\n"))
cat(sprintf("Data-preferred break: %d\n", res_all$bp$year))
cat(sprintf("F(2,%d) = %.2f, critical value (5%%) = %.2f\n",
            res_all$n - 4, res_all$bp$fstat, res_all$crit))
cat(sprintf("Significant: %s\n",
            ifelse(res_all$bp$fstat > res_all$crit, "YES", "NO")))
cat(sprintf("Permutation p = %.4f (%d permutations)\n", res_all$perm_p, 10000))

cat(sprintf("\n========== CHOW TEST: EXCLUDING 2022 ==========\n"))
cat(sprintf("Data-preferred break: %d\n", res_ex$bp$year))
cat(sprintf("F(2,%d) = %.2f, critical value (5%%) = %.2f\n",
            res_ex$n - 4, res_ex$bp$fstat, res_ex$crit))
cat(sprintf("Significant: %s\n",
            ifelse(res_ex$bp$fstat > res_ex$crit, "YES", "NO")))
cat(sprintf("Permutation p = %.4f (%d permutations)\n", res_ex$perm_p, 10000))

# ============================================================
# FIGURE: TWO-PANEL (departures + dual Chow)
# ============================================================

# Top panel: annual departures
p_top <- ggplot(annual, aes(x = year, y = departures)) +
  geom_col(fill = "#404040", width = 0.7) +
  geom_hline(yintercept = mean_dep,
             linetype = "dashed", colour = "grey50", linewidth = 0.4) +
  annotate("text", x = 1982, y = mean_dep + 0.5,
           label = paste0("Mean = ", round(mean_dep, 1), " per year"),
           colour = "grey40", size = 2.8, hjust = 0) +
  scale_x_continuous(breaks = seq(1980, 2025, 5), expand = expansion(add = 0.5)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Departures per year") +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_blank()
  )

# Bottom panel: dual Chow F-statistics
p_bot <- ggplot(fs_both, aes(x = year, y = fstat, linetype = series)) +
  geom_hline(yintercept = res_all$crit, linetype = "dashed",
             colour = "#888888", linewidth = 0.5) +
  geom_line(colour = "#000000", linewidth = 0.6) +
  geom_point(data = res_all$bp, aes(x = year, y = fstat),
             shape = 21, fill = "white", colour = "#000000",
             size = 3.5, stroke = 1.3, inherit.aes = FALSE) +
  geom_point(data = res_ex$bp, aes(x = year, y = fstat),
             shape = 21, fill = "grey60", colour = "#000000",
             size = 3.5, stroke = 1.3, inherit.aes = FALSE) +
  annotate("text", x = res_all$bp$year - 2, y = res_all$bp$fstat,
           label = as.character(res_all$bp$year),
           colour = "#000000", size = 3, hjust = 1, fontface = "bold") +
  annotate("text", x = res_ex$bp$year - 2, y = res_ex$bp$fstat,
           label = as.character(res_ex$bp$year),
           colour = "#555555", size = 3, hjust = 1, fontface = "bold") +
  annotate("text", x = min(fs_both$year), y = res_all$crit + 0.2,
           label = "5% critical value", colour = "#888888", size = 2.5, hjust = 0) +
  scale_linetype_manual(values = c("All years" = "solid",
                                   "Excluding 2022" = "dotted"),
                        name = NULL) +
  scale_x_continuous(breaks = seq(1980, 2025, 5), expand = expansion(add = 0.5)) +
  labs(x = NULL, y = "Chow F(2, N\u22124)") +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position    = c(0.15, 0.85),
    legend.text        = element_text(size = 8),
    legend.background  = element_rect(fill = "white", colour = NA)
  )

fig <- p_top +
  plot_annotation(
    title = "Figure 2.3: Annual cabinet departures (excluding Great Officers), 1979\u20132025",
    caption = "Source: Institute for Government ministers database. Great Officers excluded (see Figure 2.2).",
    theme = theme(
# 17 Aug, PJ: "some of the titles are too small typface". Title size was a raw pt value while
# canvases run 6.5-10 in, so the SAME pt looked large on a narrow figure and small on a wide
# one - a 68% spread in apparent size. Titles are now set at ~1.75 pt per inch of canvas
# (this figure is 9.0 in wide, so 15.5 pt), which is the ratio the narrow figures already had.
      plot.title   = element_text(face = "bold", size = 15.5),
      plot.caption = element_text(size = 7, colour = "grey40")
    )
  )

ggsave("figures/fig_2_3_cabinet_turnover.png",
       fig, width = 9, height = 4.2, dpi = 300)
cat("\nSaved: figures/fig_2_3_cabinet_turnover.png\n")

# ============================================================
# SAVE ANNUAL SERIES (for later combining)
# ============================================================
write_csv(annual, "data/processed/cabinet_annual_departures.csv")
cat("Saved: data/processed/cabinet_annual_departures.csv\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================
cat("\n========== SUMMARY FOR CHAPTER TEXT ==========\n\n")
cat(sprintf("Years covered: %d-%d (%d years)\n",
            min(annual$year), max(annual$year), nrow(annual)))
cat(sprintf("Total departures: %d\n", sum(annual$departures)))
cat(sprintf("Mean departures per year: %.1f\n", mean_dep))
cat(sprintf("Maximum departures: %d (%s)\n",
            max(annual$departures),
            paste(annual$year[annual$departures == max(annual$departures)],
                  collapse = ", ")))

cat("\n--- Pre vs post 2010 ---\n")
pre  <- annual |> filter(year < 2010)
post <- annual |> filter(year >= 2010)
cat(sprintf("1979-2009: mean %.1f departures/year\n", mean(pre$departures)))
cat(sprintf("2010-2026: mean %.1f departures/year\n", mean(post$departures)))

cat("\n--- Decade means ---\n")
annual |>
  mutate(decade = paste0(floor(year / 10) * 10, "s")) |>
  group_by(decade) |>
  summarise(mean_deps = round(mean(departures), 1),
            max_deps = max(departures),
            .groups = "drop") |>
  print()

cat("\n========== SCRIPT COMPLETE ==========\n")
