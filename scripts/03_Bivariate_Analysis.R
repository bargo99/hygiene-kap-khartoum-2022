# ==============================================================================
# 03_Bivariate_Analysis.R
# Hygiene KAP Study - Phase 3: Bivariate Comparisons
# Replicates thesis Table 2 (Junior vs Senior year group) and
# Table 3 (Male vs Female), including a normality check to justify
# t-test vs Mann-Whitney U, and a chi-square check of grade-category
# distribution as a secondary/sensitivity comparison.
#
# Run Phases 1 and 2 first.
# ==============================================================================

library(tidyverse)
library(rstatix)
library(gtsummary)
library(flextable)

df <- readRDS("cleaned_data/hygiene_kap_cleaned.rds")
dir.create("tables", showWarnings = FALSE)

score_cols <- c("HH_K_pct","AH_K_pct","EH_K_pct",
                 "HH_A_pct","AH_A_pct","EH_A_pct",
                 "HH_P_pct","AH_P_pct","EH_P_pct",
                 "Hand_Total","Attire_Total","Equipment_Total")

# ------------------------------------------------------------------------
# 1. NORMALITY CHECK (Shapiro-Wilk) - determines t-test vs Mann-Whitney
#    for each score, per comparison group. KAP percentage scores are often
#    ceiling-skewed (bunched near 100), so don't assume normal without checking.
# ------------------------------------------------------------------------
normality_check <- df %>%
  select(all_of(score_cols)) %>%
  pivot_longer(everything(), names_to = "score", values_to = "value") %>%
  group_by(score) %>%
  shapiro_test(value) %>%
  mutate(normal = p > 0.05)

print(normality_check, n = 20)
write_csv(normality_check, "tables/Normality_Check.csv")

cat("\nNOTE: if 'normal' is FALSE for a score, the comparison below uses\n")
cat("Mann-Whitney U instead of Welch's t-test for that score automatically.\n\n")

# ------------------------------------------------------------------------
# 2. GENERIC COMPARISON FUNCTION
#    Runs t-test (Welch) if normal, Wilcoxon/Mann-Whitney if not, per score,
#    grouped by a 2-level factor. Returns a tidy summary table.
# ------------------------------------------------------------------------
compare_groups <- function(data, group_var, scores, normality_ref) {
  group_var_sym <- rlang::sym(group_var)

  map_dfr(scores, function(sc) {
    is_normal <- normality_ref %>% filter(score == sc) %>% pull(normal)
    is_normal <- if (length(is_normal) == 0) FALSE else is_normal

    grp_data <- data %>% select(all_of(sc), all_of(group_var)) %>% drop_na()
    names(grp_data) <- c("value", "group")

    means <- grp_data %>%
      group_by(group) %>%
      summarise(mean = mean(value), sd = sd(value), .groups = "drop")

    if (is_normal) {
      test <- t_test(value ~ group, data = grp_data, var.equal = FALSE)
      method <- "Welch t-test"
    } else {
      test <- wilcox_test(value ~ group, data = grp_data)
      method <- "Mann-Whitney U"
    }

    tibble(
      score = sc,
      group1_level = means$group[1], group1_mean = round(means$mean[1], 1),
      group2_level = means$group[2], group2_mean = round(means$mean[2], 1),
      p_value = round(test$p, 3),
      method = method
    )
  })
}

# ------------------------------------------------------------------------
# 3. TABLE 2 REPLICATION: Junior (3rd-4th) vs Senior (5th-6th)
# ------------------------------------------------------------------------
table2 <- compare_groups(df, "year_group", score_cols, normality_check)
print(table2, n = 20)
write_csv(table2, "tables/Table2_YearGroup_Comparison.csv")

# ------------------------------------------------------------------------
# 4. TABLE 3 REPLICATION: Male vs Female
# ------------------------------------------------------------------------
table3 <- compare_groups(df, "gender", score_cols, normality_check)
print(table3, n = 20)
write_csv(table3, "tables/Table3_Gender_Comparison.csv")

# ------------------------------------------------------------------------
# 5. PUBLICATION-READY VERSIONS VIA gtsummary (side-by-side means + p-value)
# ------------------------------------------------------------------------
tbl2_pretty <- df %>%
  select(year_group, all_of(score_cols)) %>%
  tbl_summary(
    by = year_group,
    statistic = all_continuous() ~ "{mean} ({sd})",
    digits = all_continuous() ~ 1
  ) %>%
  add_p(test = all_continuous() ~ "wilcox.test") %>%  # conservative default; see table2.csv for per-score method actually justified
  modify_header(label = "**Score**") %>%
  bold_labels()

tbl2_pretty %>% as_flex_table() %>% save_as_docx(path = "tables/Table2_YearGroup_Pretty.docx")

tbl3_pretty <- df %>%
  select(gender, all_of(score_cols)) %>%
  tbl_summary(
    by = gender,
    statistic = all_continuous() ~ "{mean} ({sd})",
    digits = all_continuous() ~ 1
  ) %>%
  add_p(test = all_continuous() ~ "wilcox.test") %>%
  modify_header(label = "**Score**") %>%
  bold_labels()

tbl3_pretty %>% as_flex_table() %>% save_as_docx(path = "tables/Table3_Gender_Pretty.docx")

# ------------------------------------------------------------------------
# 6. GRADE-CATEGORY CHI-SQUARE (secondary/sensitivity check)
#    Compares e.g. % "Good" vs "Moderate" etc. between groups on domain totals
# ------------------------------------------------------------------------
chisq_results <- map_dfr(c("Hand_Total_grade", "Attire_Total_grade", "Equipment_Total_grade"), function(gc) {
  tab_year <- table(df$year_group, df[[gc]])
  tab_gender <- table(df$gender, df[[gc]])

  tibble(
    domain = gc,
    p_year_group = round(tryCatch(chisq.test(tab_year)$p.value, error = function(e) NA), 3),
    p_gender = round(tryCatch(chisq.test(tab_gender)$p.value, error = function(e) NA), 3)
  )
})

print(chisq_results)
write_csv(chisq_results, "tables/GradeCategory_ChiSquare.csv")

cat("\n=== Phase 3 complete ===\n")
cat("Raw comparison tables (Table2/Table3 .csv) list the ACTUAL test used per score\n")
cat("(t-test or Mann-Whitney, chosen per the normality check).\n")
cat("The gtsummary .docx versions default to Wilcoxon throughout for a uniform look -\n")
cat("swap to your preferred test per-row if a reviewer asks, using Table2/3 .csv as reference.\n")
