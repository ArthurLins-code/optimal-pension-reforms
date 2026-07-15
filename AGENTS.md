# Optimal Pension Reforms — Project Configuration

> MVPF/WMVPF of Brazil's 2015 pension reform (Lei 13.183/2015).
> Gonzaga, Rios (PUC-Rio), Lemos (MIT Sloan). RA: Arthur.

## Repository Structure

- `build/code/` — Data construction stages A-D (.R and .do; full-data/server only)
- `analysis/code/` — Estimation and results stages E-I (.R)
- `latex/` — Deck sources: `presentation/` (English), `apresentacao/` (Portuguese), and shared `figures/`
- `latex/figures/from_code/` — Tracked generated figures used by the English deck
- `latex/figures/static/` — Tracked manual or external figures used by the English deck
- `deck_tools/figures_central_folder/` — Figure collector, verifier, comparer, manifest, and to-do register
- `deck_tools/build_deck.R` — Collect figures and compile the English deck
- `data_local/` — 5% anonymized sample (NEVER committed)
- `_docs/memory/` — Knowledge base (01-10)
- `_docs/plans/` — Session plans
- `_docs/session_logs/` — Session logs
- `_docs/quality_reports/` — Stage reports, reviews
- `paper/` — Paper drafts and presentations (gitignored)

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
  in `paper/Presentations/`. This is the ONLY source of truth.
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
Codex commits: "Made by: Codex (model: <model>)".
User instructions: "Reason given by user: ..." verbatim.

### 7. Workflow Directives
- Plan-first for non-trivial work. Plans to `_docs/plans/`.
- Verify-after: run on sample when possible, else state "static-checked only".
- Session logs in `_docs/session_logs/`.
- Pause-friendly: checkpoint summary at every stopping point.
- Token-budget aware: ask whether to continue or pause at natural breaks.
- Side-chat edits: assume the user may keep editing Codex's edits; do not
  suggest commit messages unless explicitly asked, and always report all source
  lines changed in each edit.
- When suggesting an exact LaTeX replacement in chat, put the replacement in a
  fenced `latex` code block rather than only inline text. If the equation is too
  long to read comfortably, also state the substantive change in prose.

## Pipeline (canonical files)

| Stage | Canonical File | Lang | Purpose |
|-------|---------------|------|---------|
| A | `build/code/A4_balance_check.R` | R | SUIBE balance |
| B | `build/code/B4_create_clean_candidates_cross.R` | R | RAIS features cross-section |
| C | `build/code/C6_estimate_continuous_contrib.R` | R | Impute contribution time |
| D | `build/code/D4_create_panel.R` | R | Panel construction |
| E | `analysis/code/E4_plots_claiming_distributions.R` | R | Diagnostic plots |
| F | `analysis/code/new_counterfactual_claiming3_pure.R` | R | Counterfactual (NEW method) |
| G | `analysis/code/G5_effect_average_benefit_freq_bL_and_bS.R` | R | DD on average benefits |
| H | `analysis/code/H3_policy_elasticity.R` | R | IPW-DD elasticity |
| I | `analysis/code/I4_wmvpf_no_pure_reforms_freq.R` | R | WMVPF estimation |

B1-B3 and C3 are Stata `.do` files in `build/code/` (upstream of their R canonical siblings).

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
Rscript analysis/analysis_all.R                   # Run sample analysis pipeline
Rscript deck_tools/build_deck.R                   # Collect figures and compile English deck
Rscript analysis/code/<script>.R                  # Run analysis script
Rscript build/code/<script>.R                     # Run build script
stata-mp -b do build/code/<script>.do             # Run Stata script
python scripts/quality_score.py <file>            # Quality score
```

## Knowledge Base

Read before planning: `_docs/memory/01_project_overview.md` through
`_docs/memory/10_corrections_log.md`.
