# ==============================================================================
# 01_Data_Cleaning.R
# Hygiene KAP Study - Cleaning, Renaming, and KAP Scoring
# Replicates the scoring methodology of the source thesis (Ch. 3.8):
#   K: % correct out of 20 items per domain (Hand/Attire/Equipment)
#   A: 0-4 Likert, summed per domain, converted to %
#   P: 1-5 Likert (as per the actual questionnaire/raw data), summed per
#      domain, converted to %, with 2 reverse-worded items recoded first
#   Total per domain = mean(K%, A%, P%)   <- matches thesis Table 2/3 values
#   Grading: Good >=75 | Moderate 50-74.9 | Unsatisfactory 25-49.9 | Poor <25
#
# EDIT the file path below to match where your raw .xlsx lives on your machine.
# ==============================================================================

library(tidyverse)
library(readxl)
library(writexl)
library(janitor)

# ------------------------------------------------------------------------
# 1. LOAD RAW DATA
# ------------------------------------------------------------------------
raw_path <- "Hand_hygiene_among_medical_students_of_Khartoum_during_clinical.xlsx"

raw <- read_excel(raw_path, sheet = 1, col_names = TRUE)

stopifnot(ncol(raw) == 64)  # sanity check: file structure hasn't changed

# ------------------------------------------------------------------------
# 2. RENAME COLUMNS (positional - order verified against the questionnaire)
#    HH = Hand Hygiene, AH = Attire Hygiene, EH = Equipment Hygiene
#    K = Knowledge, A = Attitude, P = Practice
#    NOTE: raw column order for Equipment Practice is item 1,2,3,5,4
#    (item 4 "re-use toothpicks" and item 5 "clean other equipment" are
#    swapped in the Google Forms export) - handled explicitly below.
# ------------------------------------------------------------------------
new_names <- c(
  "timestamp", "consent", "gender", "batch",
  paste0("HH_K", 1:10), paste0("AH_K", 1:5), paste0("EH_K", 1:5),
  paste0("HH_A", 1:10), paste0("AH_A", 1:5), paste0("EH_A", 1:5),
  paste0("HH_P", 1:10), paste0("AH_P", 1:5),
  "EH_P1", "EH_P2", "EH_P3", "EH_P5", "EH_P4"
)
names(raw) <- new_names

# ------------------------------------------------------------------------
# 3. BASIC FILTERING
# ------------------------------------------------------------------------
df <- raw %>%
  filter(consent == "Yes") %>%          # drop the 1 non-consenting response
  filter(!is.na(gender))                 # drop rows with missing gender

# ------------------------------------------------------------------------
# 4. BATCH -> STUDY YEAR MAPPING
#    Confirmed against thesis Table 1 (6th=76, 5th=85, 4th=77, 3rd=66):
#    lower batch number = more senior student (entered earlier)
#    CHECK THIS MAPPING against your own batch numbering before trusting it.
# ------------------------------------------------------------------------
df <- df %>%
  mutate(
    study_year = case_when(
      batch == 92 ~ "6th",
      batch == 93 ~ "5th",
      batch == 94 ~ "4th",
      batch == 95 ~ "3rd",
      TRUE ~ NA_character_
    ),
    study_year = factor(study_year, levels = c("3rd", "4th", "5th", "6th")),
    year_group = if_else(study_year %in% c("3rd", "4th"), "Junior (3rd-4th)", "Senior (5th-6th)"),
    year_group = factor(year_group, levels = c("Junior (3rd-4th)", "Senior (5th-6th)")),
    gender = factor(gender, levels = c("Male", "Female"))
  )

# ------------------------------------------------------------------------
# 5. HARMONIZE KNOWLEDGE COLUMNS (Yes/No/Unsure)
#    Google Forms exported some as logical TRUE/FALSE instead of text.
# ------------------------------------------------------------------------
knowledge_cols <- c(paste0("HH_K", 1:10), paste0("AH_K", 1:5), paste0("EH_K", 1:5))

harmonize_yn <- function(x) {
  x <- as.character(x)
  x <- case_when(
    x %in% c("TRUE", "Yes")    ~ "Yes",
    x %in% c("FALSE", "No")    ~ "No",
    x == "Unsure"              ~ "Unsure",
    TRUE                       ~ NA_character_
  )
  x
}

df <- df %>%
  mutate(across(all_of(knowledge_cols), harmonize_yn))

# ------------------------------------------------------------------------
# 6. KNOWLEDGE SCORING
#    "Correct" answer key - reverse-worded items marked below score 1 for "No"
# ------------------------------------------------------------------------
# Items where "No" is the CORRECT answer (all others: "Yes" is correct)
reverse_knowledge_items <- c("HH_K7", "HH_K10", "AH_K2", "EH_K1", "EH_K2")

score_knowledge_item <- function(col_name, values) {
  correct_answer <- if (col_name %in% reverse_knowledge_items) "No" else "Yes"
  as.integer(values == correct_answer)
}

for (col in knowledge_cols) {
  df[[paste0(col, "_correct")]] <- score_knowledge_item(col, df[[col]])
}

df <- df %>%
  rowwise() %>%
  mutate(
    HH_K_pct = mean(c_across(paste0("HH_K", 1:10, "_correct")), na.rm = TRUE) * 100,
    AH_K_pct = mean(c_across(paste0("AH_K", 1:5, "_correct")), na.rm = TRUE) * 100,
    EH_K_pct = mean(c_across(paste0("EH_K", 1:5, "_correct")), na.rm = TRUE) * 100
  ) %>%
  ungroup()

# ------------------------------------------------------------------------
# 7. ATTITUDE SCORING (0-4 Likert, no reverse items, % of max)
# ------------------------------------------------------------------------
df <- df %>%
  rowwise() %>%
  mutate(
    HH_A_pct = mean(c_across(paste0("HH_A", 1:10)), na.rm = TRUE) / 4 * 100,
    AH_A_pct = mean(c_across(paste0("AH_A", 1:5)),  na.rm = TRUE) / 4 * 100,
    EH_A_pct = mean(c_across(paste0("EH_A", 1:5)),  na.rm = TRUE) / 4 * 100
  ) %>%
  ungroup()

# ------------------------------------------------------------------------
# 8. PRACTICE SCORING (1-5 Likert as per questionnaire, % of max)
#    Reverse-worded items recoded first: recoded = 6 - raw  (since scale is 1-5)
# ------------------------------------------------------------------------
df <- df %>%
  mutate(
    AH_P4_rev = 6 - AH_P4,   # "I consume my meals wearing the clinical coat"
    EH_P4_rev = 6 - EH_P4    # "I re-use toothpicks for checking sensory deficits"
  )

df <- df %>%
  rowwise() %>%
  mutate(
    HH_P_pct = (mean(c_across(paste0("HH_P", 1:10)), na.rm = TRUE) - 1) / 4 * 100,
    AH_P_pct = (mean(c_across(c("AH_P1", "AH_P2", "AH_P3", "AH_P4_rev", "AH_P5")), na.rm = TRUE) - 1) / 4 * 100,
    EH_P_pct = (mean(c_across(c("EH_P1", "EH_P2", "EH_P3", "EH_P4_rev", "EH_P5")), na.rm = TRUE) - 1) / 4 * 100
  ) %>%
  ungroup()

# ------------------------------------------------------------------------
# 9. DOMAIN TOTALS (mean of K/A/P %, matches thesis Table 2/3 "Total" row)
# ------------------------------------------------------------------------
df <- df %>%
  mutate(
    Hand_Total      = rowMeans(cbind(HH_K_pct, HH_A_pct, HH_P_pct), na.rm = TRUE),
    Attire_Total    = rowMeans(cbind(AH_K_pct, AH_A_pct, AH_P_pct), na.rm = TRUE),
    Equipment_Total = rowMeans(cbind(EH_K_pct, EH_A_pct, EH_P_pct), na.rm = TRUE)
  )

# ------------------------------------------------------------------------
# 10. GRADING (Good >=75 | Moderate 50-74.9 | Unsatisfactory 25-49.9 | Poor <25)
# ------------------------------------------------------------------------
grade_score <- function(x) {
  cut(x,
      breaks = c(-Inf, 25, 50, 75, Inf),
      labels = c("Poor", "Unsatisfactory", "Moderate", "Good"),
      right = FALSE)
}

score_cols <- c("HH_K_pct","AH_K_pct","EH_K_pct",
                 "HH_A_pct","AH_A_pct","EH_A_pct",
                 "HH_P_pct","AH_P_pct","EH_P_pct",
                 "Hand_Total","Attire_Total","Equipment_Total")

for (col in score_cols) {
  df[[paste0(col, "_grade")]] <- grade_score(df[[col]])
}

# ------------------------------------------------------------------------
# 11. MISSINGNESS REPORT (check before proceeding - especially Equipment
#     items, which had built-in Google Form skip logic: "if you don't have
#     the instrument you can skip it")
# ------------------------------------------------------------------------
missing_report <- df %>%
  summarise(across(all_of(c(knowledge_cols,
                             paste0("HH_A",1:10), paste0("AH_A",1:5), paste0("EH_A",1:5),
                             paste0("HH_P",1:10), paste0("AH_P",1:5),
                             "EH_P1","EH_P2","EH_P3","EH_P4","EH_P5")),
                   ~ round(mean(is.na(.)) * 100, 1))) %>%
  pivot_longer(everything(), names_to = "item", values_to = "pct_missing") %>%
  arrange(desc(pct_missing))

print(missing_report, n = 20)

# ------------------------------------------------------------------------
# 12. SAVE CLEANED DATA
# ------------------------------------------------------------------------
dir.create("cleaned_data", showWarnings = FALSE)

write_csv(df, "cleaned_data/hygiene_kap_cleaned.csv")
write_xlsx(df, "cleaned_data/hygiene_kap_cleaned.xlsx")
saveRDS(df, "cleaned_data/hygiene_kap_cleaned.rds")

cat("\n=== Cleaning complete ===\n")
cat("N respondents after filtering:", nrow(df), "\n")
cat("Cleaned files saved to ./cleaned_data/\n")
cat("Study year distribution:\n")
print(table(df$study_year, useNA = "ifany"))
cat("\nCheck the missing_report above - if Equipment items show high\n")
cat("missingness (~10-15%), that's expected skip-logic, not a data error.\n")
