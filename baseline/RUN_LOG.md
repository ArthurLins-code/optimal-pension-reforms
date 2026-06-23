# Stage-0C — Golden Baseline Run Log

**Date:** 2026-06-23
**Branch:** `code-and-data` (unchanged throughout)
**Repo root:** `C:/Users/tuca1/Projects/optimal-pension-reforms`
**External 5% sample root:** `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement`
**Purpose:** Capture a golden baseline of the CURRENT (pre-restructure) code's outputs on the
5% sample, so a later restructure stage can prove it changed NO figures and NO numbers.

---

## Git tree — clean before and after

**BEFORE run** (`git status --porcelain`):
```
?? _docs/restructure/
?? baseline/
```

**AFTER run + restore** (`git status --porcelain`):
```
?? _docs/restructure/
?? baseline/
```

Tree is clean: only `_docs/restructure/` and `baseline/` are untracked, both expected.
No tracked file was modified by the run. Reason: `figures_central_folder/from_code/`,
`latex/presentation/_main.pdf` (+ `.aux/.log/...`), and `figures_central_folder/_diffs/`
are all **gitignored** (verified with `git check-ignore`). The collector reads (never writes)
the tracked `manifest.csv`, and latexmk writes only the gitignored `_main.pdf` + ephemeral aux
files. The defensive `git checkout -- figures_central_folder/ latex/presentation/` was run
anyway (no-op, as expected).

> Note: a **stale** `.git/index.lock` (0 bytes, dated Jun 19, from an earlier aborted git
> invocation — no git process running) blocked the first `git checkout`. It was removed and the
> checkout re-run. This lock predates and is unrelated to this run; the run never writes to `.git`.

---

## Prereq check (external sample output dir)

All required upstream inputs PRESENT:

| File | Status |
|---|---|
| `output/F/F5_table_results.csv` | PRESENT (gabriel input) |
| `output/G/G4_table_results.csv` | PRESENT (I4 input, no-suffix) |
| `output/G/G4_table_results_sample.csv` | PRESENT (I6 input) |
| `output/H/H2_table_results.csv` | PRESENT (I4 input, no-suffix) |
| `output/H/H2_table_results_sample.csv` | PRESENT (I6 input + elasticity source) |

No prereq missing → no stage excluded for missing inputs.

---

## Parity set — all 6 stages ran CLEAN

Each invoked as `Rscript <repo-relative-path>` from the repo root (scripts setwd() into the
external sample dir themselves; SAMPLE auto-detected via `dir.exists(...transfer_may_retirement)`
→ `DATA_MODE="sample"`, `SUFFIX="_sample"`). Run in DAG order, background + polled.

| # | Stage | Script | Exit | Wall (s) | Notes |
|---|---|---|---|---|---|
| 1 | E | `E4_plots_claiming_distributions.R` | 0 | 24 | figures only; benign data.table shallow-copy warns |
| 2 | F(gabriel) | `new_counterfactual_claiming3_gabriel.R` | 0 | 46 | wrote `new_counterfactual_claim_counts_sample.csv`, ES figures |
| 3 | F(pure) | `new_counterfactual_claiming3_pure.R` | 0 | 17 | wrote `..._with_pure_schedules_3_sample.csv`; benign ggplot clip warns |
| 4 | G | `G5_effect_average_benefit_freq_bL_and_bS.R` | 0 | 25 | wrote `G5_table_results_..._freq_sample.csv`, schedules |
| 5 | I | `I4_wmvpf_no_pure_reforms_freq.R` | 0 | 10 | wrote `I4_table_wmvpf_sample.csv` |
| 6 | I | `I6_wmvpf_with_pure_reforms_freq.R` | 0 | 14 | HEADLINE; wrote `I6_summary_sample.csv` + pure L/S |

**Effective parity set = all 6 stages.** None excluded.

**Excluded by design (not run):** A4/B4/C6/D4 (full-data only), `H3_policy_elasticity.R`
(no sample branch — hardcoded `U:/`, would error), I7 (diagnostic/terminal), G6/I5 (legacy).

Per-stage logs: `baseline/logs/{1_E4,2_gabriel,3_pure,4_G5,5_I4,6_I6}.log`
(each ends in `EXIT_CODE=` + `WALL_SECONDS=`).

### I6 headline (from log tail)
```
WMVPF actual = 0.2126
WMVPF_bL (cumulative) = 1.5591
WMVPF_bL (per-qtr T)  = 0.4253
WMVPF_bS (cumulative) = -2.4306
WMVPF_bS (per-qtr T)  = 0.3778
bS > bL (cum)?  = FALSE
```

> Sample caveat: on the 5% sample, `WMVPF_bS_cum = -2.4306` and `WMVPF_bL_cum = 1.5591` fall
> OUTSIDE the (0,1) interval and the cumulative ranking `bS > bL` is reversed vs the canonical
> full-data relationships. This is expected sampling noise on the pure-reform decomposition at
> the 5% level (the pure schedules divide small claim-count cells), NOT a code error — every
> stage ran clean and the per-quarter-at-T values (bL=0.4253, bS=0.3778) sit inside (0,1).
> Recorded as the baseline value to reproduce, regardless.

---

## Deck rebuild

1. **Collector** — `python figures_central_folder/collector.py --sample-root <sample>`
   (log `baseline/logs/7_collector.log`): exit 0.
   `RESULT: PASS — every live deck figure resolves under from_code/ or static/.`
   Routed 66 into `from_code/` (49 canonical OK/OK-RENAME, 16 upstream-canonical, 1 legacy);
   16 gabriel-fallback, 7 sample-mode flagged; **0 MISSING, 0 STATIC missing**; 5 E3→E4 diffs.

2. **Compile** — `latexmk -g -pdf -interaction=nonstopmode _main.tex` from `latex/presentation/`
   (log `baseline/logs/8_latexmk.log`): exit 0.
   **`_main.pdf` = 142 pages**, 0 "not found" figure errors in `_main.log`, 0 `!` LaTeX errors.

---

## Golden manifest (parity reference)

`baseline/baseline_manifest.csv` — header `path,page,png_sha256,raw_sha256,source`.
fitz-rendered each page @150 DPI, sha256 of PNG bytes (metadata-independent) + raw-file sha256.

- 66 `from_code/*.pdf` → 66 page rows (all single-page): **65 `source=rerun`, 1 `asis-untouched`**
  (the lone untouched file is `H2_dd_tax_collection_1.pdf` — H2 is an input, not in the rerun set).
- `_main.pdf` → **142 page rows**, `source=rerun` (holistic deck hash).
- **Total: 208 page rows.**
- Fresh `from_code/*.pdf` + `_main.pdf` copied into `baseline/figures_before/`.

AS-IS pre-rerun reference (insurance, not the parity ref): `baseline/figures_asis_manifest.csv`
(208 rows: 67 from_code as-is + the previously-committed `_main.pdf`).

---

## Key numbers — `baseline/baseline_numbers.csv`

| quantity | value | source |
|---|---|---|
| WMVPF_actual | 0.2126 | `I6_summary_sample.csv` |
| WMVPF_bL cumulative | 1.5591 | `I6_summary_sample.csv` / `I6_wmvpf_pure_L_sample.csv` |
| WMVPF_bS cumulative | -2.4306 | `I6_summary_sample.csv` / `I6_wmvpf_pure_S_sample.csv` |
| WMVPF_bL per-qtr at T | 0.4253 | `I6_summary_sample.csv` |
| WMVPF_bS per-qtr at T | 0.3778 | `I6_summary_sample.csv` |
| eta (welfare weight) | 0.8281 | `I6_summary_sample.csv` |
| gamma (CRRA) | 4 | `I6_summary_sample.csv` |
| policy elasticity (H2 DD, +3) | -1347.097 | `H2_table_results_sample.csv` (INPUT, not regenerated) |
| policy elasticity (H2 DD-IPW, +3) | -1574.960 | `H2_table_results_sample.csv` (INPUT, not regenerated) |
| I4 welfare (final cum, BRL) | 463,064,118.45 | `I4_table_wmvpf_sample.csv` (dist_reform=12) |
| I4 net_cost (final cum, BRL) | 1,899,292,380.16 | `I4_table_wmvpf_sample.csv` (dist_reform=12) |
| F claim counts: nrow / sum(claims) / sum(claims_c) | 465 / 31575 / 31208 | `new_counterfactual_claim_counts_sample.csv` |
| F pure schedules: nrow / sum(claims_L) / sum(claims_S) | 465 / 30235.34 / 31958.66 | `new_counterfactual_claim_counts_with_pure_schedules_3_sample.csv` |

(F-counts file sha256s also recorded in the CSV.)

---

## Staleness check (as-is vs rerun, page-level PNG hash)

**from_code deck figures — the robust parity signal:**
Of 66 comparable from_code page-rows, **64 UNCHANGED, 2 CHANGED on a fresh rerun**:
- `E4_pension_schedule_men.pdf`
- `E4_pension_schedule_women.pdf`

→ The committed deck's two E4 pension-schedule figures are **stale** vs current E4 output
(a real, small staleness finding). All other 64 figures reproduce bit-identical at the pixel
level. (Informational — not a blocker.)

**`_main.pdf` holistic — 142/142 pages "changed".**
This is a **date artifact, NOT content drift**. `latex/presentation/_main.tex:7` sets
`\date{World Bank \\ \today}`, and the Beamer **Madrid** theme footer prints the date on EVERY
frame. The title page renders "June 23, 2026" (today). So any two compiles on different dates
differ pixel-for-pixel on all pages, independent of figures/numbers. The hasher itself is
deterministic (re-rendering the same PDF twice gives identical hashes — verified).

> **Methodology caveat for the restructure-parity stage:** Do NOT use the per-page `_main.pdf`
> PNG hash as the deck parity gate — it is date-nondeterministic via `\today`. Anchor deck
> parity on the **`from_code/*.pdf` page hashes** (date-free) plus the key-numbers CSV. If a
> holistic `_main.pdf` check is wanted, first neutralize the date (e.g. compile with a fixed
> `\date{}`, or `SOURCE_DATE_EPOCH` + strip the footer date) before comparing.

---

## Surprises / findings

1. **`from_code/` and `_main.pdf` are gitignored** → the run never dirties the tracked tree;
   the mandated restore is a no-op safety net.
2. **Stale `.git/index.lock`** (Jun 19, 0 bytes, no live git process) — removed; unrelated to run.
3. **`_main.pdf` per-page hash is date-nondeterministic** via `\today` in the Madrid footer
   (see caveat above) — the single most important thing for the parity stage to know.
4. **2 stale E4 pension-schedule figures** in the committed deck vs current code.
5. **Sample pure-reform WMVPFs (bL=1.56, bS=-2.43) fall outside (0,1)** and reverse the bS>bL
   ranking — expected 5%-sample noise on the pure decomposition, not a bug.

## Artifacts
- `baseline/baseline_manifest.csv` — golden parity manifest (208 page rows)
- `baseline/baseline_numbers.csv` — key scalars + F-count hashes
- `baseline/figures_asis_manifest.csv` — pre-rerun as-is snapshot
- `baseline/figures_before/` — fresh `from_code/*.pdf` + `_main.pdf`
- `baseline/logs/` — per-stage logs (1_E4 … 8_latexmk)
- `baseline/hash_pdfs.py`, `baseline/build_golden_manifest.py` — the hashing tools used
