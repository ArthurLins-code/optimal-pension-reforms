# Building the panel from raw data — server runbook (A → B → C → D)

**Audience:** an operator on the restricted-access **server** (`DATA_MODE=full`) who needs to rebuild the
analysis-ready panel from raw **SUIBE** + **RAIS** admin data.

**What the build does:** stages A→B→C→D turn raw microdata into the quarterly SUIBE–RAIS panel that the
analysis phase (E→I, `analysis/analysis_all.R`) consumes.

> ⚠️ **`build/build_all.R` does NOT build from raw.** It only re-runs the 4 canonical *heads*
> (A4 / B4 / C6 / D4) over an **already-populated** `working/` directory (`build_all.R:19-22`; its own header
> `:16-18` says the upstream lineage "must be run first on the server if rebuilding from raw"). A true
> from-raw rebuild is the **~14-step sequence below**, run **in order**, alternating **R** (`Rscript`) and
> **Stata** (`stata-mp -b do`).

> ⚠️ **Server-only, not zip-and-run.** This needs the confidential raw data, the R + Stata toolchain, and the
> external `U:/…/directory_2025` working tree. The repo ships **code only** — no data, no packages, no F5.

---

## 0 · Before you start — provisioning

| Need | Detail |
|---|---|
| **Env / roots** | `PENSION_DATA_MODE=full`; and either the author's drives exist or override `PENSION_FULL_BUILD_ROOT` (build root, default `U:/Documents/Paper/directory_2025`), `PENSION_FULL_ROOT` (analysis root, `F:/…`), `PENSION_R_LIBPATH` (default `F:/docs/R-library`). See `config/paths.R:26-53`. |
| **Working tree** | `<build_root>/{raw,extra,working,tmp,output}` must pre-exist — the upstream scripts + `.do` files write into `working/…` relative to a hardcoded `cd` (see §3). |
| **Raw SUIBE** | per-year xlsx under `<build_root>/raw/suibe_{identified,unidentified}/…` (confidential 2012–2019 concessions). |
| **Raw RAIS** | `F:/data/rais/output/data/full/<YYYY>.dta`, 1985–2020 (read by B1/B3/C3). If these extracts don't exist, run/point `build/code/aux_codes_RAIS/` first (it produces them). |
| **`extra/` tables** | IBGE life-expectancy (`Expectativa_Vida_IBGE.xlsx`), INPC, CBO/CNAE crosswalks, `microrregioes.dta`, teto previdência, salário mínimo, população, `corresp_ibge_inss`. None are in the repo. |
| **Toolchain** | **R** with ~23 CRAN packages (no `renv.lock` — install by hand) **+ Stata** for the `.do` steps. |

> **Package-load gotcha:** in the 4 heads (A4/B4/C6/D4) the `library()` loop runs *before* the
> `.libPaths(PENSION_R_LIBPATH)` redirect, so those packages must sit on R's **default** libpath at startup —
> the redirect is too late to help them. (A1–A3 set `.libPaths` first and are fine.)

---

## 1 · The dependency chain

Every arrow is a real file handoff (`working/…`), so the order is not optional. Cross-block handoffs exist at
**every** boundary — B reads A, C reads B, D reads C:

```
  raw SUIBE ─► A1 ─┐
  raw SUIBE ─► A2 ─┼─► A3 ─┬─► A3_merged_suibe.csv.gz ───────────────┐
                           └─► A3_candidates_suibe.dta ──┐            │
                                                         ▼            │
  raw RAIS ─► B1 ─► B2 ◄────────(A3 candidates)          B3 ─► B4 ◄───┤ (A3 + B2 + B3)
                     │                                    ▲    │
                     └─► B2 corresp ─────────────────────┘    ▼
                                                          C1 ◄─┘ (A3 + B4)
                        B2 corresp + C1 cpf + raw RAIS ─► C3      │
                                                          │       ▼
                                             C1 + C3 ─►  C4 ─►  C5 ─► C6
                                                                       │
                                                          ┌────────────┴───────────┐
                                                          ▼                        ▼
                                       (C5 + C6) ─► D3 ──► D4 ◄─ C3      (C5+C6) ─► D1 ─► D2 ◄─ C3
                                                          │                              │
                                                          ▼                              ▼
                                              D4_panel_{reform,claim}.csv.gz      D2_panel.csv.gz
                                                          └──────────► [ analysis E–I ] ◄──────┘
```

**The D layer is FOUR files, not one.** The `D4` head (new panel) is not enough: downstream analysis
(`G5`, `gabriel`, `I4`, `I6`) reads the **old pair D1/D2** for quarterly fields D3/D4 don't carry (flag
`g5-d1`). Run **D1, D2, D3, D4**.

---

## 2 · The ordered run sequence (14 spine steps + 2 optional diagnostics)

Set `PENSION_DATA_MODE=full` once, then run top-to-bottom. `R` = `Rscript build/code/<file>`;
`Stata` = `stata-mp -b do build/code/<file>`.

| # | stage | lang | reads | writes |
|---|-------|------|-------|--------|
| 1 | `A1_clean_suibe_semidentified.R` | R | raw SUIBE identified xlsx | `working/A1_suibe_semi.csv.gz` |
| 2 | `A2_clean_suibe_unidentified.R` | R | raw SUIBE unidentified xlsx + extras | `working/A2_suibe_unid.csv.gz` |
| 3 | `A3_merge_suibes.R` | R | A1 + A2 + IBGE | `working/A3_merged_suibe.csv.gz` **+ `A3_candidates_suibe.dta`** |
| 4 | `B1_create_rais_cross.do` | **Stata** | raw RAIS | `working/B1_full_rais_cross.dta` + `B1_corresp_pis_cpf.dta` |
| 5 | `B2_create_candidates_cross.do` | **Stata** | B1 **+ A3_candidates_suibe.dta** | `working/B2_full_candidates_cross.dta` + `B2_full_candidates_corresp_pis_cpf.dta` |
| 6 | `B3_create_candidates_panel.do` | **Stata** | raw RAIS + B2 corresp | `working/B3_full_candidates_panel/B3_<YYYY>.csv` |
| 7 | `B4_create_clean_candidates_cross.R` *(head)* | R | A3 + B2 + B3 + extras | `working/B4_clean_candidates_cross/B4_<YYYY>.csv.gz` |
| 8 | `C1_merge_suibe_rais_logit.R` | R | A3 + B4 | `working/C1_merged_suibe_rais.csv.gz` + `C1_merged_suibe_rais_cpf.dta` |
| 9 | `C3_filter_rais.do` | **Stata** | B2 corresp + C1 cpf + raw RAIS | `working/C3_filtered_rais/C3_<YYYY>.csv` + corresp |
| 10 | `C4_calculate_stats_rais.R` | R | C1 + C3 + extras | `working/C4_stats_rais.csv.gz` |
| 11 | `C5_restrict_sample.R` | R | C1 + C4 | `working/C5_restricted_sample.csv.gz` |
| 12 | `C6_estimate_continuous_contrib.R` *(head)* | R | C5 + IBGE | `working/C6_estimated_contrib_time.csv.gz` |
| 13 | `D3_create_cross_section.R` | R | C5 + C6 + IBGE | `working/D3_cross_section.csv.gz` |
| 13′ | `D1_create_cross_section.R` | R | C5 + C6 + IBGE | `working/D1_cross_section.csv.gz` *(live dep — see §1)* |
| 14 | `D4_create_panel.R` *(head)* | R | D3 + C3 + extras | `working/D4_panel_reform.csv.gz` + `D4_panel_claim.csv.gz` |
| 14′ | `D2_create_panel.R` | R | D1 + C3 + extras | `working/D2_panel.csv.gz` *(live dep — see §1)* |

**Optional diagnostics (off the data spine, produce reports only, safe to skip):**
`A4_balance_check.R` → `output/A/A4_balance_check.{csv,tex}` · `C2_balance_check.R` → `output/C/C2_*`.

Once the full chain has run, `Rscript build/build_all.R` only **re-runs the 4 heads** over the now-populated
`working/` — it is a convenience/consistency check, not required, and it never touches the upstream steps.

---

## 3 · Known issues (documented, not fixed here)

- **Split-brain config wiring.** The 4 heads (A4/B4/C6/D4) go through `config/paths.R` and honor
  `PENSION_FULL_BUILD_ROOT`. The **10 upstream R scripts** (A1–A3, C1–C5, D1–D3) **and all 4 `.do` files**
  still `setwd('U:/Documents/Paper/directory_2025')` (`.do`: `cd`) and read raw RAIS from literal `F:/…`
  paths. So they run **only on that exact drive layout**; setting `PENSION_FULL_BUILD_ROOT` to relocate the
  build moves *only the heads* and silently desyncs them from the still-`U:/` upstream. (Open flag **`O11`**;
  the setwd-modernization is a deferred follow-up.)
- **F5 is not a build output.** `F5_table_results.csv` is a legacy *analysis* prerequisite (its only producers
  are the quarantined `legacy/F5–F7`), staged separately at `<analysis_root>/output/F/`. The build does not
  produce it.
- **Panels land in `working/`, not `output/`.** The final `D4_panel_*.csv.gz` (and D1/D2/D3) live under
  `<build_root>/working/`. The only build stage that writes to `output/` is the A4 diagnostic.

---

## 4 · Then run the analysis

With `working/` populated (D1–D4 present) + `extra/Expectativa_Vida_IBGE.xlsx` + the external
`F5_table_results.csv` staged, run `Rscript analysis/analysis_all.R` (full mode). Note `H3` is not on the
master — run it manually if you need its outputs. See `guides/WORKFLOW_GUIDE_SERVER.html` for the full
server picture.

<sub>Source of truth: the read/write handoffs above are traced from the stage code (`build/code/*`). This is
documentation — the full-data build is server-only and unverified from a laptop.</sub>
