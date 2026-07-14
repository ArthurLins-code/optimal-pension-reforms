# Stage-3 Restructure PARITY Report

**Date:** 2026-06-23
**Branch:** `code-and-data` (unchanged throughout — no add/commit/mv/rm/checkout/push to any tracked file)
**Repo root:** `C:/Users/tuca1/Projects/optimal-pension-reforms`
**External 5% sample root:** `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement`
**DATA_MODE:** `sample` (auto-resolved by `config/paths.R` via existing sample root)

---

## OVERALL VERDICT: **PASS**

The NEW (restructured) pipeline reproduces the pre-restructure golden baseline **exactly** on the
5% sample:

- **FIGURES — 66 / 66 MATCH** (pixel-identical PNG@150DPI sha256), 0 MISMATCH / 0 MISSING / 0 EXTRA.
- **NUMBERS — 26 / 26 MATCH** (floats within rel-tol 1e-6; F-count CSV sha256s byte-identical; integers exact).
- **DECK — compiled to 142 pages** (matches baseline); `verify_deck.py` resolves **72/72** unique includes, 0 unresolved.

> One **RESTRUCTURE-CAUSED finding** (FINDING-1, below) was hit: the analysis master crashes at
> `new_counterfactual_claiming3_pure.R` because 30 of its `ggsave()` calls still use a LEGACY
> RELATIVE path. It is a path/cwd defect, **not** a numerical/figure-content defect — once the
> stage runs, every figure and number is bit-identical to baseline. A clean, tree-safe workaround
> (a directory junction, removed afterward) let the masters run end-to-end and produce full parity
> data. The orchestrator should FIX FINDING-1 (migrate the 30 paths to `PATHS$output_new_counter`)
> and re-loop; parity is otherwise PROVEN.

> **FINDING-1 RESOLVED (orchestrator, commit `1d1cb3f`).** The 30 `ggsave()` paths in
> `analysis/code/new_counterfactual_claiming3_pure.R` L348-380 were migrated
> `'output/new_counter_claiming/X.pdf'` → `file.path(PATHS$output_new_counter, 'X.pdf')`. A clean **master
> re-run with NO junction** then confirmed: `analysis/analysis_all.R` **EXIT=0** (all 6 stages
> E4→gabriel→pure→G5→I4→I6), `presentation/build_deck.R` **EXIT=0** (deck **142 pages**, verify_deck **72/72**),
> the four headline numbers bit-exact (WMVPF_actual=0.2126, eta=0.8281, bL_cum=1.5591, bS_cum=-2.4306), and the 30
> figures now land in `<external>/output/new_counter_claiming/`. **Stage 3 fully closed: PARITY PASS, masters run
> end-to-end with no workaround.**

---

## STEP 0 — git tree BEFORE

```
?? _docs/restructure/
?? baseline/
```
Branch = `code-and-data`. Clean (only the two expected untracked dirs).

---

## STEP 1 — Re-run of the NEW pipeline

### (a) `Rscript analysis/analysis_all.R` — MASTER

**First attempt: FAILED (EXIT=1)** at stage 3 (`new_counterfactual_claiming3_pure.R`):

```
Error in `ggsave()`:
! Cannot find directory 'output/new_counter_claiming'.
ℹ Please supply an existing directory or use `create.dir = TRUE`.
 ... 6. └─ggplot2::ggsave(...)  [pure.R lines 348-380]
```

This is **FINDING-1 (RESTRUCTURE-CAUSED)** — see classification below. The stage's CSV outputs
(`...with_pure_schedules_3_sample.csv`, 465 rows) were written successfully via absolute `PATHS$`
paths *before* the crash; only the 30 relative-path diagnostic figures aborted it.

**Workaround applied (no pipeline file edited; tree-safe):** a Windows directory **junction**
`repo_root/output -> <external>/output` was created so the legacy relative path
`output/new_counter_claiming/...` resolves to the external dir (where it already exists),
reproducing the pre-restructure runtime contract. `here::here()` still resolves the repo root
(`.here` sentinel), and config's absolute `PATHS$` paths are unaffected. The junction was
**removed after the run**; the final tree is clean (STEP 6).

**Re-run with junction in place: PASSED (EXIT=0)** — all 6 stages clean, in DAG order:

| # | Stage | Script | Exit | Wall |
|---|-------|--------|------|------|
| 1 | E | `E4_plots_claiming_distributions.R` | 0 | 12.1s |
| 2 | F(gabriel) | `new_counterfactual_claiming3_gabriel.R` | 0 | 35.8s |
| 3 | F(pure) | `new_counterfactual_claiming3_pure.R` | 0 | 12.8s |
| 4 | G | `G5_effect_average_benefit_freq_bL_and_bS.R` | 0 | 18.9s |
| 5 | I | `I4_wmvpf_no_pure_reforms_freq.R` | 0 | 7.0s |
| 6 | I | `I6_wmvpf_with_pure_reforms_freq.R` | 0 | 8.0s |

I6 headline (from log): `WMVPF actual = 0.2126`, `bS > bL (cum)? = FALSE` — matches baseline.
Prerequisite tables (legacy F5, sibling G4/H2 — sample + no-suffix) all present; no stage excluded.

Logs: `baseline/logs_stage3/1_analysis_all.log`,
`baseline/logs_stage3/1_analysis_all_TAIL.txt` (the failing first-attempt tail),
`baseline/logs_stage3/3_pure_fallback.log` (an earlier standalone fallback probe).

### (b) `Rscript presentation/build_deck.R` — MASTER — **PASSED (EXIT=0)**

- **collector.py:** `RESULT: PASS - every live deck figure resolves under from_code/ or static/.`
  Routed **66** into `from_code/` (49 canonical OK/OK-RENAME, 16 upstream-canonical, 1 legacy-flagged);
  **MISSING (routable) = 0, STATIC missing = 0**.
- **latexmk:** `Output written on _main.pdf (142 pages, 1269490 bytes).` 0 LaTeX `!` errors.
- **verify_deck.py:** `active \includegraphics : 74 refs, 72 unique` → `resolved 72, unresolved 0`.

Log: `baseline/logs_stage3/2_build_deck.log`.

---

## STEP 2 — Recompute (stage3 artifacts)

- `baseline/stage3_manifest.csv` — 208 page rows (66 `from_code/*.pdf` @ 1 page each + 142 `_main.pdf` pages).
  Hashing METHOD is byte-identical to the baseline helper (`build_golden_manifest.py`): fitz render
  each page @150 DPI, sha256 the PNG bytes (+ raw-file sha256). `path` column = BARE filename, to
  join 1:1 against `baseline_manifest.csv`.
- `baseline/stage3_numbers.csv` — 26 quantities re-extracted from the external output dir
  (`output/I/I6_summary_sample.csv`, `I4_table_wmvpf_sample.csv`, `output/F/new_counterfactual_claim_counts*_sample.csv`).
  The 3 H2 policy-elasticities are read from the **unchanged INPUT** `output/H/H2_table_results_sample.csv`
  (H2 is not regenerated by the 6 stages — same file under both baseline and stage3).
- Compiled deck page count recorded: **142**.

Recompute log: `baseline/logs_stage3/4_recompute.log` (0 manifest errors).

---

## STEP 3 — Comparison (the parity verdict)

### Figures (join on filename + page; `_main.pdf` excluded — see methodology note)

| Status | Count |
|--------|-------|
| MATCH | **66** |
| MISMATCH | 0 |
| MISSING | 0 |
| EXTRA | 0 |

All 66 `from_code` figures reproduce **bit-identical at the pixel level**. Full per-figure CSV:
`baseline/stage3_compare_figures.csv` (66 rows, every row MATCH).

> **`_main.pdf` holistic hash deliberately NOT used as the gate.** The Beamer Madrid `\today`
> footer stamps the build date on all 142 pages, so they always differ across compile dates
> (baseline RUN_LOG methodology caveat). Deck parity is instead asserted via: (i) compiled to
> **142 pages**, and (ii) `verify_deck.py` = **72/72 includes resolve, 0 unresolved**.

### Numbers (join on quantity; floats rel-tol < 1e-6; sha256/integers exact)

| Status | Count |
|--------|-------|
| MATCH | **26** |
| MISMATCH | 0 |

| quantity | baseline | stage3 | match |
|----------|----------|--------|-------|
| WMVPF_actual | 0.2126 | **0.2126** | exact |
| WMVPF_bL_cumulative | 1.5591 | **1.5591** | exact |
| WMVPF_bS_cumulative | -2.4306 | **-2.4306** | exact |
| WMVPF_bL_perqtr_at_T | 0.4253 | 0.4253 | exact |
| WMVPF_bS_perqtr_at_T | 0.3778 | 0.3778 | exact |
| eta | 0.8281 | **0.8281** | exact |
| gamma_CRRA | 4 | 4 | exact |
| cons_beneficiaries | 1536.4 | 1536.4 | exact |
| cons_population | 1473.1 | 1473.1 | exact |
| quarters_analyzed | 13 | 13 | exact |
| WMVPF_actual_I4_welfare_lastrow | 463064118.453698 | 463064118.453698 | exact |
| WMVPF_actual_I4_netcost_lastrow | 1899292380.16178 | 1899292380.16178 | exact |
| F_claim_counts_sample_nrow | 465 | 465 | exact |
| F_claim_counts_sample_sha256 | 4b452d7f… | 4b452d7f… | **exact (byte-identical)** |
| F_claim_counts_sample_sum_claims | 31575 | 31575 | exact |
| F_claim_counts_sample_sum_claims_c | 31208 | 31208 | exact |
| F_pure_schedules_sample_nrow | 465 | 465 | exact |
| F_pure_schedules_sample_sha256 | d27c1d11… | d27c1d11… | **exact (byte-identical)** |
| F_pure_schedules_sample_sum_claims | 31575 | 31575 | exact |
| F_pure_schedules_sample_sum_claims_c | 31208 | 31208 | exact |
| F_pure_schedules_sample_sum_claims_L | 30235.3353 | 30235.3353 | exact |
| F_pure_schedules_sample_sum_claims_S | 31958.6647 | 31958.6647 | exact |
| policy_elasticity_H2_DD_qtr3 | -1347.097 | -1347.09708940015 | reldiff 6.6e-8 (INPUT, unchanged) |
| policy_elasticity_H2_DDIPW_qtr3 | -1574.960 | -1574.95997769676 | reldiff 1.4e-8 (INPUT, unchanged) |
| policy_elasticity_H2_DD_qtr0 | -1234.869 | -1234.86913989299 | reldiff 1.1e-7 (INPUT, unchanged) |
| deck_main_pdf_pages | 142 | 142 | exact |

Full per-number CSV: `baseline/stage3_compare_numbers.csv`.

---

## STEP 4 — Classification of diffs

**There are ZERO blocking parity diffs.** Figures and numbers all MATCH. The one operational issue:

### FINDING-1 (RESTRUCTURE-CAUSED) — `pure.R` legacy relative `ggsave` paths — BLOCKS the master, NOT parity

- **File:** `analysis/code/new_counterfactual_claiming3_pure.R`, lines **348–380** (30 `ggsave()` calls).
- **Cause:** these write to the LEGACY RELATIVE path
  `'output/new_counter_claiming/new_counterfactual_claiming3_pure_{level,slope}_reform_claiming_frequency_quarterly_*.pdf'`.
  The restructured config layer (lines 18–30) correctly defines absolute `PATHS$output_new_counter`
  and `dir.create()`s it at the EXTERNAL root, **but the 30 figure paths were not migrated** and the
  script has **no `setwd()`** (per the no-setwd policy). Under the master, cwd = repo root, where
  `output/new_counter_claiming/` does not exist → `ggsave()` aborts the stage (EXIT=1).
- **Why it's not a parity diff:** (i) these 30 figures are **NOT in the baseline 66 from_code set**
  and are **NOT collected into the deck**; (ii) the stage's canonical CSV outputs are written via
  absolute `PATHS$` paths *before* the crash and are bit-identical to baseline (F sha256s MATCH).
  Sibling `gabriel.R` was migrated correctly (uses absolute `PATHS$`) and ran clean — confirming
  this is an isolated un-migrated tail in pure.R.
- **Suggested fix (orchestrator):** replace the 30 literal `'output/new_counter_claiming/...'`
  filenames with `file.path(PATHS$output_new_counter, "...")` (matching how lines 29–30 already
  resolve that dir). Then the master needs no junction. Re-loop parity afterward.

### Pre-existing (NOT a blocker) — the 2 E4 pension-schedule figures

`E4_pension_schedule_men.pdf` / `..._women.pdf` were the baseline's known-stale-in-committed-deck
item. Because the baseline manifest captured them from a fresh rerun, they were expected to MATCH
now — and they do (**MATCH**, status confirmed). No action.

### Cosmetic-only — the `_main.pdf` per-page date footer

Not gated (see methodology note); deck parity anchored on from_code hashes + page count + verify_deck.

---

## STEP 5 — Run exit codes (summary)

| Step | Command | Exit |
|------|---------|------|
| analysis master (1st attempt) | `Rscript analysis/analysis_all.R` | **1** (FINDING-1) |
| analysis master (junction workaround) | `Rscript analysis/analysis_all.R` | **0** |
| deck master | `Rscript presentation/build_deck.R` | **0** |
| recompute | `python baseline/stage3_recompute.py` | 0 |
| compare | `python baseline/stage3_compare.py` | 0 → **PASS** |

---

## STEP 6 — git tree AFTER

```
?? _docs/restructure/
?? baseline/
```
Clean. No TRACKED file modified. The directory junction was removed; one stray default
`Rplots.pdf` (R graphics-device artifact, untracked, never committed) was deleted. `from_code/*.pdf`
and `_main.pdf` are gitignored, so the regeneration never dirtied the tracked tree.

---

## Artifacts

- `quality_reports/restructure_parity.md` — this report
- `baseline/stage3_manifest.csv` — 208 page-row golden-method manifest (NEW structure)
- `baseline/stage3_numbers.csv` — 26 re-extracted key numbers
- `baseline/stage3_compare_figures.csv` — 66-row per-figure verdict (all MATCH)
- `baseline/stage3_compare_numbers.csv` — 26-row per-number verdict (all MATCH)
- `baseline/stage3_recompute.py`, `baseline/stage3_compare.py` — the recompute + compare tools
- `baseline/logs_stage3/` — `1_analysis_all.log`, `1_analysis_all_TAIL.txt`, `2_build_deck.log`,
  `3_pure_fallback.log`, `4_recompute.log`, `5_compare.log`
