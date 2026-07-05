# ==============================================================================
# 02_Descriptive_Statistics.R
# Hygiene KAP Study - Phase 2: Descriptive Statistics & Figures
# Replicates thesis Figure 1 (gender pie), Figure 2 (mean K/A/P/Total bar
# chart), and Table 1 (N per study year), plus a Table 1-style overall
# sample summary.
#
# Run 00_Install_Packages.R and 01_Data_Cleaning.R first.
# ==============================================================================

library(tidyverse)
library(gtsummary)
library(flextable)
library(janitor)

df <- readRDS("cleaned_data/hygiene_kap_cleaned.rds")

dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

# ------------------------------------------------------------------------
# 1. SAMPLE SUMMARY TABLE (gender, study year, batch counts)
# ------------------------------------------------------------------------
sample_summary <- df %>%
  select(gender, study_year, year_group) %>%
  tbl_summary(
    label = list(
      gender ~ "Gender",
      study_year ~ "Study Year",
      year_group ~ "Year Group"
    )
  ) %>%
  modify_header(label = "**Characteristic**") %>%
  bold_labels()

sample_summary

# Save as Word-ready flextable
sample_summary %>%
  as_flex_table() %>%
  save_as_docx(path = "tables/Table1_Sample_Characteristics.docx")

# ------------------------------------------------------------------------
# 2. FIGURE 1 REPLICATION: Gender distribution pie/donut chart
# ------------------------------------------------------------------------
gender_counts <- df %>%
  count(gender) %>%
  mutate(pct = n / sum(n) * 100,
         label = paste0(gender, "\n", round(pct), "%"))

fig1 <- ggplot(gender_counts, aes(x = "", y = n, fill = gender)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  geom_text(aes(label = label), position = position_stack(vjust = 0.5), size = 5) +
  scale_fill_manual(values = c("Male" = "#1f77b4", "Female" = "#ff7f0e")) +
  theme_void() +
  labs(title = paste0("Gender distribution (N = ", nrow(df), ")")) +
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5, face = "bold"))

ggsave("figures/Figure1_Gender_Distribution.png", fig1, width = 6, height = 6, dpi = 300)
ggsave("figures/Figure1_Gender_Distribution.pdf", fig1, width = 6, height = 6, dpi = 300)

# ------------------------------------------------------------------------
# 3. FIGURE 2 REPLICATION: Mean K/A/P/Total scores per domain
# ------------------------------------------------------------------------
score_means <- df %>%
  summarise(
    Hand              = mean(Hand_Total, na.rm = TRUE),
    `Hand Knowledge`   = mean(HH_K_pct, na.rm = TRUE),
    `Hand Attitude`    = mean(HH_A_pct, na.rm = TRUE),
    `Hand Practice`    = mean(HH_P_pct, na.rm = TRUE),
    Attire             = mean(Attire_Total, na.rm = TRUE),
    `Attire Knowledge` = mean(AH_K_pct, na.rm = TRUE),
    `Attire Attitude`  = mean(AH_A_pct, na.rm = TRUE),
    `Attire Practice`  = mean(AH_P_pct, na.rm = TRUE),
    Equipment              = mean(Equipment_Total, na.rm = TRUE),
    `Equipment Knowledge`  = mean(EH_K_pct, na.rm = TRUE),
    `Equipment Attitude`   = mean(EH_A_pct, na.rm = TRUE),
    `Equipment Practice`   = mean(EH_P_pct, na.rm = TRUE)
  ) %>%
  pivot_longer(everything(), names_to = "measure", values_to = "mean_score") %>%
  mutate(
    domain = case_when(
      str_starts(measure, "Hand") ~ "Hand",
      str_starts(measure, "Attire") ~ "Attire",
      str_starts(measure, "Equipment") ~ "Equipment"
    ),
    domain = factor(domain, levels = c("Hand", "Attire", "Equipment")),
    measure = factor(measure, levels = c(
      "Hand", "Hand Knowledge", "Hand Attitude", "Hand Practice",
      "Attire", "Attire Knowledge", "Attire Attitude", "Attire Practice",
      "Equipment", "Equipment Knowledge", "Equipment Attitude", "Equipment Practice"
    )),
    is_total = measure %in% c("Hand", "Attire", "Equipment")
  )

fig2 <- ggplot(score_means, aes(x = measure, y = mean_score, fill = domain, alpha = is_total)) +
  geom_col(color = "black") +
  geom_hline(yintercept = c(25, 50, 75), linetype = "dashed", color = "darkgreen") +
  scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.6), guide = "none") +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_fill_manual(values = c("Hand" = "#4472C4", "Attire" = "#70AD47", "Equipment" = "#ED7D31")) +
  labs(title = "Mean Knowledge, Attitude, and Practice scores by domain",
       x = NULL, y = "Mean score (%)", fill = "Domain") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(face = "bold", hjust = 0.5))

ggsave("figures/Figure2_Mean_KAP_Scores.png", fig2, width = 10, height = 6, dpi = 300)
ggsave("figures/Figure2_Mean_KAP_Scores.pdf", fig2, width = 10, height = 6, dpi = 300)

# ------------------------------------------------------------------------
# 4. GRADING DISTRIBUTION TABLE (Good/Moderate/Unsatisfactory/Poor per domain)
# ------------------------------------------------------------------------
grading_table <- df %>%
  select(Hand_Total_grade, Attire_Total_grade, Equipment_Total_grade) %>%
  rename(Hand = Hand_Total_grade, Attire = Attire_Total_grade, Equipment = Equipment_Total_grade) %>%
  pivot_longer(everything(), names_to = "domain", values_to = "grade") %>%
  count(domain, grade) %>%
  group_by(domain) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ungroup() %>%
  pivot_wider(names_from = domain, values_from = c(n, pct))

print(grading_table)
write_csv(grading_table, "tables/Grading_Distribution.csv")

# ------------------------------------------------------------------------
# 5. NUMERIC SUMMARY (mean +/- SD) FOR ALL SCORE COLUMNS, EXPORTED
# ------------------------------------------------------------------------
numeric_summary <- df %>%
  summarise(across(
    c(HH_K_pct, AH_K_pct, EH_K_pct, HH_A_pct, AH_A_pct, EH_A_pct,
      HH_P_pct, AH_P_pct, EH_P_pct, Hand_Total, Attire_Total, Equipment_Total),
    list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)),
    .names = "{.col}__{.fn}"
  )) %>%
  pivot_longer(everything(), names_to = c("score", "stat"), names_sep = "__") %>%
  pivot_wider(names_from = stat, values_from = value) %>%
  mutate(mean = round(mean, 1), sd = round(sd, 1))

print(numeric_summary, n = 20)
write_csv(numeric_summary, "tables/Score_Summary_Mean_SD.csv")

cat("\n=== Phase 2 complete ===\n")
cat("Figures saved to ./figures/ (PNG + PDF, 300 DPI)\n")
cat("Tables saved to ./tables/\n")
