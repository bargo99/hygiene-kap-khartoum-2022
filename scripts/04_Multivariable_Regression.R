# ==============================================================================
# 04_Multivariable_Regression.R
# Hygiene KAP Study - Phase 4: Multivariable Regression (extension beyond
# the original thesis, which only reported bivariate comparisons)
#
# Research question: does Knowledge and Attitude predict Practice, after
# adjusting for gender and year group, within each hygiene domain?
#   Model: {Domain}_P_pct ~ {Domain}_K_pct + {Domain}_A_pct + gender + year_group
#
# Outcome is continuous (0-100 practice %) -> multiple linear regression.
#
# Run Phases 1-3 first.
# ==============================================================================

library(tidyverse)
library(broom)
library(car)          # vif()
library(performance)   # check_model() diagnostics
library(gtsummary)
library(flextable)

df <- readRDS("cleaned_data/hygiene_kap_cleaned.rds")
dir.create("tables", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ------------------------------------------------------------------------
# 1. FIT ONE MODEL PER DOMAIN
# ------------------------------------------------------------------------
model_hand <- lm(HH_P_pct ~ HH_K_pct + HH_A_pct + gender + year_group, data = df)
model_attire <- lm(AH_P_pct ~ AH_K_pct + AH_A_pct + gender + year_group, data = df)
model_equipment <- lm(EH_P_pct ~ EH_K_pct + EH_A_pct + gender + year_group, data = df)

models <- list(Hand = model_hand, Attire = model_attire, Equipment = model_equipment)

# ------------------------------------------------------------------------
# 2. ASSUMPTION CHECKS
#    a) Multicollinearity (VIF < 5 is generally fine; K and A scores could
#       correlate, so check this before trusting coefficients)
#    b) Residual diagnostics (linearity, homoscedasticity, normality of
#       residuals) via performance::check_model - saved as PNG per domain
# ------------------------------------------------------------------------
cat("=== Variance Inflation Factors (VIF) ===\n")
walk2(models, names(models), function(m, nm) {
  cat("\n---", nm, "---\n")
  print(vif(m))
})

walk2(models, names(models), function(m, nm) {
  p <- check_model(m, panel = TRUE)
  # check_model() returns a `see_check_model` object, not a plain ggplot,
  # so ggsave() fails with "no applicable method for 'grid.draw'".
  # Use a graphics device + print() instead.
  png(paste0("figures/Diagnostics_", nm, "_Practice_Model.png"),
      width = 10, height = 10, units = "in", res = 300)
  print(p)
  dev.off()
})

# ------------------------------------------------------------------------
# 3. TIDY COEFFICIENT TABLES (estimate, 95% CI, p-value) - saved per domain
# ------------------------------------------------------------------------
regression_summary <- map_dfr(names(models), function(nm) {
  tidy(models[[nm]], conf.int = TRUE) %>%
    mutate(domain = nm, .before = 1) %>%
    mutate(across(where(is.numeric), ~round(., 3)))
})

print(regression_summary, n = 30)
write_csv(regression_summary, "tables/Table4_Multivariable_Regression.csv")

# Model fit stats (R-squared, adjusted R-squared, F-test p-value)
model_fit <- map_dfr(names(models), function(nm) {
  g <- glance(models[[nm]])
  tibble(domain = nm, r_squared = round(g$r.squared, 3),
         adj_r_squared = round(g$adj.r.squared, 3),
         f_p_value = round(g$p.value, 4))
})
print(model_fit)
write_csv(model_fit, "tables/Table4_Model_Fit_Stats.csv")

# ------------------------------------------------------------------------
# 4. PUBLICATION-READY REGRESSION TABLE (gtsummary, all 3 models side-by-side)
# ------------------------------------------------------------------------
tbl_hand <- tbl_regression(model_hand, intercept = TRUE) %>% modify_header(label = "**Hand Practice**")
tbl_attire <- tbl_regression(model_attire, intercept = TRUE) %>% modify_header(label = "**Attire Practice**")
tbl_equipment <- tbl_regression(model_equipment, intercept = TRUE) %>% modify_header(label = "**Equipment Practice**")

combined_tbl <- tbl_merge(
  list(tbl_hand, tbl_attire, tbl_equipment),
  tab_spanner = c("**Hand**", "**Attire**", "**Equipment**")
)

combined_tbl %>% as_flex_table() %>% save_as_docx(path = "tables/Table4_Regression_Pretty.docx")

cat("\n=== Phase 4 complete ===\n")
cat("Check VIF output above: values > 5 flag concerning multicollinearity\n")
cat("(most likely candidate: Knowledge and Attitude scores correlating).\n")
cat("Check figures/Diagnostics_*.png for residual/normality/linearity plots.\n")
cat("Regression tables saved to ./tables/ (csv + publication-ready .docx)\n")
