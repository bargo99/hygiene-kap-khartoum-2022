# ==============================================================================
# 00_Install_Packages.R
# Hygiene KAP Study - Package Setup
# Run this once before any other script.
# ==============================================================================

required_packages <- c(
  "tidyverse",   # data wrangling + ggplot2
  "readxl",      # read the raw .xlsx
  "writexl",     # write cleaned .xlsx
  "janitor",     # clean_names(), tabyl()
  "gtsummary",   # publication-ready Table 1 / comparison tables
  "flextable",   # export gtsummary tables to Word/PDF-ready tables
  "rstatix",     # tidy stats tests (t-test, chi-sq, wilcox, etc.)
  "ggpubr",      # publication-ready ggplot themes + stat annotations
  "car",         # Levene's test, VIF (if regression phase is added later)
  "broom",       # tidy model output
  "performance", # model diagnostics (if regression phase is added later)
  "sjPlot",      # regression tables/plots (if regression phase is added later)
  "corrplot",    # correlation heatmaps
  "patchwork"    # combine multiple ggplots into one figure
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, installed)

if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, dependencies = TRUE)
} else {
  message("All required packages are already installed.")
}

# Load once to confirm everything works
invisible(lapply(required_packages, library, character.only = TRUE))

message("\nSetup complete. You can now run 01_Data_Cleaning.R")
