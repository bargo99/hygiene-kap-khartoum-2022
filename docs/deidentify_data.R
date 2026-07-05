# ==============================================================================
# deidentify_data.R
# Produces a de-identified, aggregate-only dataset suitable for public
# sharing (e.g., as a Zenodo/GitHub supplementary file), containing ONLY
# the derived domain scores and grading labels — no raw item-level
# responses, no timestamps, no free text.
#
# Run this AFTER 01_Data_Cleaning.R has produced cleaned_data/hygiene_kap_cleaned.rds
# ==============================================================================

library(tidyverse)

df <- readRDS("cleaned_data/hygiene_kap_cleaned.rds")

public_data <- df %>%
  select(
    gender, study_year, year_group,
    HH_K_pct, AH_K_pct, EH_K_pct,
    HH_A_pct, AH_A_pct, EH_A_pct,
    HH_P_pct, AH_P_pct, EH_P_pct,
    Hand_Total, Attire_Total, Equipment_Total,
    ends_with("_grade")
  ) %>%
  mutate(respondent_id = row_number(), .before = 1)  # arbitrary ID, no link to original form data

dir.create("public_data", showWarnings = FALSE)
write_csv(public_data, "public_data/hygiene_kap_deidentified_scores.csv")

cat("De-identified dataset written to public_data/hygiene_kap_deidentified_scores.csv\n")
cat("Contains only derived scores/grades + gender/year - no item-level responses,\n")
cat("no timestamps, no free text. Review once more before uploading publicly.\n")
