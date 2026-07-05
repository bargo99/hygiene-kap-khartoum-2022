# Data Dictionary — Hygiene KAP Study (University of Khartoum)

Source: Google Forms export, N=308 raw responses. After excluding non-consent
and missing-gender rows, analytic N should land close to the thesis's N=304.

## Meta / demographics

| Variable | Type | Coding |
|---|---|---|
| `timestamp` | datetime | Form submission time |
| `consent` | character | "Yes"/"No" — filtered to "Yes" only |
| `gender` | factor | "Male", "Female" |
| `batch` | numeric | Raw batch number (92-95) |
| `study_year` | factor | Derived: 92="6th", 93="5th", 94="4th", 95="3rd" |
| `year_group` | factor | Derived: "Junior (3rd-4th)" vs "Senior (5th-6th)" |

## Knowledge items (`HH_K1-10`, `AH_K1-5`, `EH_K1-5`)

- Raw values: "Yes" / "No" / "Unsure" (harmonized from mixed Yes-No-Unsure
  and TRUE/FALSE Google Forms export types)
- `_correct` suffix columns: 1 = correct answer given, 0 = incorrect/unsure
- **Reverse-worded items (correct answer = "No"):** `HH_K7`, `HH_K10`,
  `AH_K2`, `EH_K1`, `EH_K2`. All other knowledge items: correct answer = "Yes".
- Domain scores `HH_K_pct`, `AH_K_pct`, `EH_K_pct` = % of items answered
  correctly within that domain (available-item mean × 100, so partial
  completion doesn't zero out the whole domain).

## Attitude items (`HH_A1-10`, `AH_A1-5`, `EH_A1-5`)

- Raw values: 0-4 Likert scale (0 = Disagree, 4 = Strongly agree)
- No reverse-worded items in this section
- Domain scores `HH_A_pct`, `AH_A_pct`, `EH_A_pct` = mean item score / 4 × 100

## Practice items (`HH_P1-10`, `AH_P1-5`, `EH_P1-5`)

- Raw values: **1-5 Likert scale** (1 = Never, 5 = Always) — kept as-is per
  the actual questionnaire/raw data (the thesis write-up describes a 0-4
  scale, but the source instrument and raw export are 1-5; the resulting
  % scores are equivalent either way)
- **Reverse-worded items** (recoded as `6 - raw` before summing):
  - `AH_P4`: "I consume my meals wearing the clinical coat" → `AH_P4_rev`
  - `EH_P4`: "I re-use toothpicks for checking sensory deficits" → `EH_P4_rev`
  - Note: in the raw file, the Equipment Practice columns are exported in
    order item 1, 2, 3, **5**, **4** (items 4 and 5 are swapped) — renamed
    explicitly by content, not position, to avoid this trap.
- Domain scores `HH_P_pct`, `AH_P_pct`, `EH_P_pct` = (mean item score − 1) / 4 × 100

## Combined domain totals

- `Hand_Total`, `Attire_Total`, `Equipment_Total` = mean(K%, A%, P%) for that
  domain — this matches the "Total (%)" row in the thesis's Table 2/3.

## Grading (applied to every _pct and _Total column)

| Label | Range |
|---|---|
| Poor | < 25% |
| Unsatisfactory | 25% – 49.9% |
| Moderate | 50% – 74.9% |
| Good | ≥ 75% |

## Known data quality notes

- 1 respondent answered "No" to consent — excluded.
- Knowledge columns had mixed logical (TRUE/FALSE) and character (Yes/No)
  types in the raw export from Google Forms — harmonized in cleaning script.
- Equipment items have higher missingness — the form had built-in skip logic
  ("if you don't have the instrument you can skip it"). Scored as
  available-item mean rather than requiring complete response.
