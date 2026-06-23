# Optimal Pension Reforms: An Application to Brazilian Administrative Data

Research project measuring the welfare effects of Brazil's 2015 pension reform (Lei 13.183/2015) using the **Welfare-weighted MVPF** framework. The reform introduced a points-based eligibility rule (age + contribution years ≥ 85/95 for women/men) that altered both the level and slope of the benefit schedule for early retirees.

## Authors

- **Gustavo Gonzaga** — PUC-Rio
- **Juan Rios** — PUC-Rio
- **Gabriel Lemos** — MIT Sloan

Research assistance: Arthur (PUC-Rio)

## Repository Structure

Functional layout (Gentzkow–Shapiro; restructured 2026-06-23). Full map: `_docs/restructure/MAP_after.md`.

```
config/              # paths.R (one PATHS list + DATA_MODE; NO setwd) + constants.R (economic primitives)
build/               # DATA CONSTRUCTION — full-data / server only
  code/              #   A1-A4, B1-B4, C1-C6, D1-D4, aux_codes_RAIS/
  build_all.R        #   master:  A4 -> B4 -> C6 -> D4
analysis/            # ESTIMATION & RESULTS — runs on the 5% sample
  code/              #   E1-E4, new_counterfactual_claiming3_{gabriel,pure}.R, G1-G5, H1-H3, I1-I4, I6, I7
  analysis_all.R     #   master:  E4 -> gabriel -> pure -> G5 -> I4 -> I6
presentation/        # RESULTS -> DECK
  figures_central_folder/  # collector/update/verify/deck_compare + manifest.csv + from_code/ + static/
  latex/                   # presentation/ (EN, live build) + apresentacao/ (PT)
  build_deck.R             # master:  collect figures -> compile latex/presentation/_main.tex -> PDF
legacy/              # quarantined: F1-F7, G6, I5, old/B1-B2 — each guarded by stop()
RUN.R                # root front door: dispatches to the three masters
_docs/  quality_reports/  Surrogate Indices/  paper/
```

## How to run

The pipeline auto-detects the data environment via `config/paths.R` (override with `PENSION_DATA_MODE` ∈ {full, sample}
and `PENSION_SAMPLE_ROOT` / `PENSION_FULL_ROOT`). From the repo root:

```bash
Rscript analysis/analysis_all.R       # 5% sample: panel -> figures, tables, WMVPF
Rscript presentation/build_deck.R     # figures -> compiled English deck (presentation/latex/presentation/_main.pdf)
Rscript build/build_all.R             # full-data build (server only; DATA_MODE=full)
```

`RUN.R` is a signpost listing these. There is **no `setwd` and no hardcoded path in stage code** — every path resolves
through `config/paths.R`; legacy files are guarded and never run.

## Data

The analysis uses Brazilian administrative records (SUIBE 2012–2019 and RAIS 1995–2020). These datasets are confidential and not included in this repository. Code runs on a restricted-access remote server.

## Pipeline

The pipeline runs sequentially from A (data cleaning) through I (welfare estimation). See `_docs/memory/02_pipeline.md` for detailed documentation of each step, its inputs, and outputs.

## Key Results

- Reform MVPF ≈ 0.31, WMVPF ≈ 0.26
- Optimal local reform: increase slope (bS), decrease level (bL) of benefit schedule
- Budget-neutral optimum: ΔbS* = +0.081 (+350%), ΔbL* = −R$791 (−26%)
