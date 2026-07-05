Hygiene Practices During Clinical Training: KAP Study Analysis Code
![DOI](https://zenodo.org/badge/DOI/PLACEHOLDER.svg)
<!-- Replace the badge above with the real one Zenodo gives you after your
Analysis code and data dictionary for a cross-sectional study of Knowledge,
Attitudes, and Practice (KAP) regarding hand, attire, and equipment hygiene
among medical students at the University of Khartoum Faculty of Medicine.
This repository accompanies the manuscript:
> [Author names]. Hygiene practices during clinical training: knowledge,
> attitudes and practice among a cohort of Sudanese medical students at
> Khartoum University. [Journal, year, DOI once assigned]
An earlier version of this study (data collected November 2021–May 2022,
n=304) was reported as an undergraduate thesis at the Department of
Community Medicine, University of Khartoum (supervisor: Dr. Siham Ahmed
Balla). This repository documents the reanalysis/extension performed for
journal submission.
What's here
File	Purpose
`scripts/00_Install_Packages.R`	Installs all required R packages
`scripts/01_Data_Cleaning.R`	Cleans raw export, harmonizes types, computes all KAP domain scores and grading
`scripts/02_Descriptive_Statistics.R`	Table 1, Figures 1–2, grading distribution
`scripts/03_Bivariate_Analysis.R`	Normality checks, Table 2 (year group) and Table 3 (gender) comparisons
`scripts/04_Multivariable_Regression.R`	Table 4 — multivariable regression of Practice on Knowledge/Attitude/gender/year, with diagnostics
`docs/DATA_DICTIONARY.md`	Full variable list, scoring formulas, reverse-coded items, grading cutoffs
`docs/deidentify_data.R`	Produces the shareable, de-identified dataset from the raw export (see Data Availability below)
Reproducing the analysis
Install R (>= 4.2) and RStudio.
Clone this repo.
Place the raw data file in the repo root (see Data Availability —
the raw file itself is not included in this repository).
Run scripts in order: `00` → `01` → `02` → `03` → `04`.
Each script is self-contained and reads the output of the previous one
from `cleaned_data/`.
Data Availability
Individual-level survey responses are not included in this repository, as
the original informed consent process did not cover public data deposition.
A de-identified, aggregate-scored dataset (containing only the derived
Knowledge/Attitude/Practice percentage scores and grading labels per
respondent — no free text, no timestamps, no item-level responses) is
available from the corresponding author upon reasonable request.
The full analysis code, scoring logic, and data dictionary needed to
reproduce all tables and figures from a compatible raw export are provided
in this repository.
Archiving on Zenodo
This repository is set up to be archived on Zenodo for a citable DOI:
Go to zenodo.org and log in with your GitHub account.
Go to GitHub in your Zenodo account settings, find this repository
in the list, and flip the toggle to On.
Create a Release on GitHub (not just a commit/tag push) — e.g.
`v1.0.0`, "Submission version". Zenodo automatically archives it and
mints a DOI within a few minutes.
Copy the DOI badge Zenodo gives you into the top of this README,
replacing the placeholder badge above.
Use that DOI in your manuscript's Data Availability statement.
Every subsequent GitHub release gets its own DOI automatically, with a
"concept DOI" that always points to the latest version — useful if you
need to update the code after peer review.
Citation
If you use this code, please cite the archived release via its Zenodo DOI
(see badge above, once minted) or the published manuscript once available.
See `CITATION.cff` for machine-readable citation metadata.
License
Code is released under the MIT License (see `LICENSE`). This does not
apply to any data, which remains subject to the terms described above.
