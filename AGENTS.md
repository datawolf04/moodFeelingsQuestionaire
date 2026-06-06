# MFQ — Mood and Feelings Questionnaire

Single-file RShiny webform (`app.R`). Three pages: clinician (email, codeword, instrument), questionnaire (Likert items), complete (confirmation). PDF report rendered via **Quarto CLI** + `mfqReport.qmd`.

## Run & requirements

```r
shiny::runApp()
```

Packages: `shiny`, `tidyverse`, `quarto`, `blastula`, `gt`. Quarto CLI must be installed (https://quarto.org).

## Security

- **`.Renviron` IS tracked by git** — it contains real SMTP credentials committed to the repo. The `.mygitignore` file lists `.Renviron` but is not honored because it's not named `.gitignore`. Do NOT commit changes to `.Renviron`. Consider migrating to environment-managed secrets like GitHub Secrets.
- `#.Renviron#` (Vim backup) exists untracked — add to `.gitignore`.
- No PII collected by the app; email is for routing only, not stored.

## SMTP (blastula)

Set in `.Renviron`:

| Variable | Purpose |
|---|---|
| `SMTP_HOST` | SMTP server hostname |
| `SMTP_PORT` | SMTP port (587 for TLS) |
| `SMTP_USER` | SMTP username |
| `SMTP_PASSWORD` | SMTP password env var name |
| `SMTP_FROM` | From-address |

## Data flow

```
app.R  ──reads──►  materials/mfqItems.csv     (items by form)
                    materials/mfqCutOffs.csv   (reference only — NOT loaded by code)
                    materials/scores.csv       (reference only — NOT loaded by code)

app.R  ──render──►  mfqReport.qmd  ──source──►  materials/mfqProperties.R
                                                └── scorePlot() — hardcodes normative data inline
```

**Quirk:** `mfqProperties.R` builds `scores` and `cutoffs` data.frames inline, not from the CSVs. If you update the CSVs, the changes have **no effect** unless you also update the R code.

## Architecture notes

- **Single-file app** — no `server.R`/`ui.R`/`global.R` split.
- **Four forms:** MFQ-Child-Long (33 items), MFQ-Child-Short (13), MFQ-Parent-Long (33), MFQ-Parent-Short (13). Items stored in `materials/mfqItems.csv` keyed by `form`.
- **Radio buttons** are raw HTML (`<input type="radio">`) with `shiny-input-radiogroup` class on `<tr>`, not `radioButtons()`. Input names use the pattern `q{sid}_{i}` where `sid` is a session counter incremented per assessment — prevents stale values when re-running assessments without page refresh.
- **Scoring:** Not True=0, Sometimes=1, True=2. Total = sum. Cut-point ranges per form in `mfqProperties.R`.
- **`scorePlot()` special case:** MFQ-Parent-Short has only 2 cut-point ranges (Normal, High) instead of 3 — no "Elevated" tier, different color mapping.
- **QMD report** calls `source('materials/mfqProperties.R')` — relative to project root at render time. Uses `gt` for the item-response table; `title.tex` customizes PDF title and forces table float to `[H]`.
- **`/materials/`** — CSVs, `mfqProperties.R` (scoring + plot), and committed reference PDFs. `materials/AGENTS.md` documents the PDF collection.

## Conventions

- Use `tidyverse` throughout.
- Radio-button input names: `q{sid}_{i}` pattern.
- No tests, no CI, no linting/formatting config.
