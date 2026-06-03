# MFQ — Mood and Feelings Questionnaire

RShiny webform for the Mood and Feelings Questionnaire. No formal R package structure (no `DESCRIPTION`, no `renv`).

## Current state

- **`app.R`** exists at the root — single-file RShiny webform (no `server.R`/`ui.R`/`global.R` split).
- The app has three pages: **clinician page** (email, codeword, instrument selection), **questionnaire page** (Likert items from the selected form), and **complete page** (confirmation that the report was emailed).
- PDF reports are generated via **Quarto** (the `quarto` CLI must be installed). The `.qmd` template is `mfqReport.qmd` at the root, rendered via `quarto::quarto_render()` with `execute_params`.
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

Requires packages: `shiny`, `tidyverse`, `quarto`, `blastula`. Requires the **Quarto CLI** (install from https://quarto.org).

### Email setup (SMTP)

The app emails the PDF report via SMTP using `blastula`. Set these environment variables (e.g. in `.Renviron`):

| Variable | Description |
|---|---|
| `SMTP_HOST` | SMTP server hostname |
| `SMTP_PORT` | SMTP port (e.g. 587 for TLS, 465 for SSL) |
| `SMTP_USER` | SMTP username |
| `SMTP_PASSWORD` | SMTP password (referenced by `blastula::creds_envvar`) |
| `SMTP_FROM` | From-address for the email |

Example for Gmail:

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=you@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=you@gmail.com
```

## Architecture notes

- Four assessment forms: MFQ-Child-Long (33 items), MFQ-Child-Short (13 items), MFQ-Parent-Long (33 items), MFQ-Parent-Short (13 items).
- No PII collected. Email address is collected for recipient routing but not stored.
- Data sources are CSVs in `materials/` — not a database.
- No tests, no CI, no linting/formatting config.

## Conventions

- Use `tidyverse` (dplyr, ggplot2, purrr, etc.) — established in `mfqProperties.R`.
- Keep scoring/distribution logic consistent with `scorePlot()` in `mfqProperties.R`.
- Radio button inputs use `session_id` prefix (`q{sid}_{i}`) to avoid stale values when re-running assessments.
