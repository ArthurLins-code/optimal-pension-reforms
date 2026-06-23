# Optimal Pension Reforms — Project Configuration

> MVPF/WMVPF of Brazil's 2015 pension reform (Lei 13.183/2015).
> Gonzaga, Rios (PUC-Rio), Lemos (MIT Sloan). RA: Arthur.

## Repository Structure

Restructured 2026-06-23 into a functional layout (Gentzkow–Shapiro). Full map: `_docs/restructure/MAP_after.md`.

- `config/` — Portability layer: `paths.R` (one `PATHS` list + `DATA_MODE`; **no `setwd` anywhere**) and `constants.R` (economic primitives incl. `ETA`).
- `build/code/` — Data construction, **full-data/server only**: A1-A4, B1-B4, C1-C6, D1-D4, `aux_codes_RAIS/`. Master: `build/build_all.R`.
- `analysis/code/` — Estimation & results, **sample-runnable**: E1-E4, `new_counterfactual_claiming3_{gabriel,pure}.R`, G1-G5, H1-H3, I1-I4, I6, I7. Master: `analysis/analysis_all.R`.
- `presentation/` — `figures_central_folder/` (collector/update/verify/deck_compare + `from_code/` + `static/`) and `latex/` (EN `presentation/`, PT `apresentacao/`). Master: `presentation/build_deck.R`.
- `legacy/` — Quarantined, each guarded by a `stop()`: F1-F7, G6, I5, `old/` B1-B2. Never run.
- `RUN.R` — root front-door signpost dispatching to the three masters.
- `build/{output,temp}`, `analysis/{output,temp}` — generated artifacts (gitignored). In **sample mode the stage I/O lives in the external sample root**, not the repo.
- `data_local/` — 5% anonymized sample (NEVER committed).
- `_docs/memory/` — Knowledge base (01-10). `_docs/restructure/` — restructure spec + MAP_before/after.
- `quality_reports/` — plans, session logs, `restructure_findings.md`, `restructure_parity.md`.
- `versoes do artigo/` — Paper drafts and presentations (gitignored).

## Data

- **Full data:** SUIBE 2012-2019, RAIS 1995-2020. Confidential, on restricted-access server.
- **Sample:** 5% CPF-level in `data_local/` and `transfer_may_retirement/data/`. For pipeline validation ONLY. Do NOT flag "sample MVPF differs from paper" as a bug — that is sampling noise.
- **NEVER commit** anything from `data_local/` or any file containing CPF identifiers.

## Critical Context (read every session)

### 1. Empirical Strategy Reversion
REVERTED to AVERAGE BENEFITS for pure-reform computations.
The "Expenditures path" is ABANDONED.
- **I5 and G6 are LEGACY.** Never rerun. Never review as current.
- Now quarantined in `legacy/` (each guarded with a `stop()`; never run).
- **Canonical deck:** `Retirement_Presentations (old strat reverted).pdf`
  in `versoes do artigo/Presentations/`. This is the ONLY source of truth.
  Other decks in that folder are HISTORICAL — do not consult.

### 2. Stage Letter + Number Convention
Highest number = canonical: A4, B4, C6, D4, E4, H3.
**Exception — G and I:** read ALL files to trace evolution (bug-hunting).
G1-G5 read in full (G6 EXCLUDED). I1-I4 read in full (I5 EXCLUDED).
Canonical rerun targets: G5 and I4.

### 3. F-Stage Methodology Discontinuity
- OLD method (F1-F7): LEGACY. Do not rerun.
- NEW method: `new_counterfactual_claiming3_pure.R` (CANONICAL).
  Upstream: `new_counterfactual_claiming3_gabriel.R` (Gabriel's file).
- **Downstream audit required:** G5, H3, I4 may still reference old F
  outputs (paths, variable names, object schemas from F1-F7). Flag as bugs.

### 4. Sample = Validation, Not Replication
Flag substantive bugs: NaN/NA propagation, wrong signs, reversed
inequalities, formula-slide mismatches, orders-of-magnitude errors,
monotonicity violations. Do NOT flag sampling noise **unprompted**.
However, when the user explicitly states an expected interval, number,
or objective (e.g., "WMVPF should be in (0,1)"), DO flag sample results
that violate the stated expectation — explain why the deviation is likely
sampling noise (or not), rather than silently dismissing it.

### 5. Identifier Convention
Data uses `cpf_anon` (id_0000001, id_0000002, ...). Old code may use
`indiv`. Reconcile per-file (semantic search + confirmation), NOT
project-wide find-replace — `indiv` may appear in non-CPF contexts.

### 6. Commit Contract
Every commit body: WHY + phase/stage reference.
Claude commits: "Made by: Claude (model: <model>)".
User instructions: "Reason given by user: ..." verbatim.

### 7. Workflow Directives
- Plan-first for non-trivial work. Plans to `_docs/plans/`.
- Verify-after: run on sample when possible, else state "static-checked only".
- Session logs in `_docs/session_logs/`.
- Pause-friendly: checkpoint summary at every stopping point.
- Token-budget aware: ask whether to continue or pause at natural breaks.

## Pipeline (canonical files)

| Stage | Canonical File (new path) | Lang | Purpose |
|-------|---------------|------|---------|
| A | `build/code/A4_balance_check.R` | R | SUIBE balance |
| B | `build/code/B4_create_clean_candidates_cross.R` | R | RAIS features cross-section |
| C | `build/code/C6_estimate_continuous_contrib.R` | R | Impute contribution time |
| D | `build/code/D4_create_panel.R` | R | Panel construction |
| E | `analysis/code/E4_plots_claiming_distributions.R` | R | Diagnostic plots |
| F | `analysis/code/new_counterfactual_claiming3_pure.R` | R | Counterfactual (NEW method); upstream `…_gabriel.R` |
| G | `analysis/code/G5_effect_average_benefit_freq_bL_and_bS.R` | R | DD on average benefits |
| H | `analysis/code/H3_policy_elasticity.R` | R | IPW-DD elasticity (**full-data only — no sample branch**) |
| I | `analysis/code/I4_wmvpf_no_pure_reforms_freq.R` | R | WMVPF estimation (+ `I6` pure L/S decomposition) |

B1-B3 and C3 are Stata `.do` files (upstream of their R canonical siblings), in `build/code/`.

**Sample parity set** (runs via `analysis/analysis_all.R`): E4 → gabriel → pure → G5 → I4 → I6. A4-D4 and H3 are
full-data only. Stages depend on pre-supplied tables `output/{F/F5,G/G4,H/H2}_table_results*.csv` (non-canonical/legacy
producers — see `quality_reports/restructure_findings.md`).

## Key Relationships (exact numbers vary by data/specification)

- MVPF, WMVPF in (0, 1) — reform costs more than beneficiaries' WTP
- WMVPF_bS > WMVPF_bL — slope reform more welfare-efficient than level
- Budget-neutral optimum: increase bS, decrease bL
- gamma (CRRA) = 4 baseline; Bunching window W = 4 points; DiD ref = -2
- RR women: 0.69 + 0.021*p; RR men: 0.82 + 0.025*p
- Thresholds: p_bar = 85 (women), 95 (men)

Validation criterion: code implements the canonical deck methodology
correctly (formulas, signs, decomposition logic). Do NOT flag
number differences unless they indicate substantive errors.

## Commands

```bash
Rscript analysis/analysis_all.R                   # Sample pipeline end-to-end (panel -> figures, tables, WMVPF)
Rscript presentation/build_deck.R                 # Collect figures + compile the English deck
Rscript build/build_all.R                         # Full-data build (server only; DATA_MODE=full)
Rscript analysis/code/<script>.R                  # A single analysis stage (build/code/ for A-D)
# Overrides: PENSION_DATA_MODE={full,sample}, PENSION_SAMPLE_ROOT=<path>, PENSION_FULL_ROOT=<path>
stata-mp -b do build/code/<script>.do             # Run a Stata stage (.do)
python scripts/quality_score.py <file>            # Quality score
```

## Knowledge Base

Read before planning: `_docs/memory/01_project_overview.md` through
`_docs/memory/10_corrections_log.md`.
