# MFQ — Mood and Feelings Questionnaire

RShiny webform for the Mood and Feelings Questionnaire. No formal R package structure (no `DESCRIPTION`, no `renv`).

## Current state

- **`app.R`** exists at the root — single-file RShiny webform (no `server.R`/`ui.R`/`global.R` split).
- The app has two pages: **clinician page** (email, codeword, instrument selection) and **questionnaire page** (Likert items from the selected form).
- PDF reports are generated via **Quarto** (the `quarto` CLI must be installed). The `.qmd` template is built inline in `app.R` — no separate template file.
- **Scoring and reference data** live in `materials/`:
  - `mfqProperties.R` — scoring logic and distribution-plot function (`scorePlot`). Uses `tidyverse`.
  - `mfqItems.csv` — items keyed by `form` (child-long, child-short, parent-long, parent-short).
  - `mfqCutOffs.csv` — cut-point ranges (Normal / Elevated / High) per assessment form.
  - `scores.csv` — normative means and SDs per form and population group (Pediatric / Psychiatric).
  - PDFs — reference instruments and validation papers.
- `materials/AGENTS.md` documents the PDF collection only.

## Running the app

```r
shiny::runApp()
```

Requires packages: `shiny`, `tidyverse`, `quarto`. Requires the **Quarto CLI** (install from https://quarto.org).

## Architecture notes

- Four assessment forms: MFQ-Child-Long (33 items), MFQ-Child-Short (13 items), MFQ-Parent-Long (33 items), MFQ-Parent-Short (13 items).
- No PII collected. Email address is collected for recipient routing but not stored.
- Data sources are CSVs in `materials/` — not a database.
- No tests, no CI, no linting/formatting config.

## Conventions

- Use `tidyverse` (dplyr, ggplot2, purrr, etc.) — established in `mfqProperties.R`.
- Keep scoring/distribution logic consistent with `scorePlot()` in `mfqProperties.R`.
- Radio button inputs use `session_id` prefix (`q{sid}_{i}`) to avoid stale values when re-running assessments.
