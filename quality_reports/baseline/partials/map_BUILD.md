# map_BUILD.md — Data construction stage (A4, B4, C6, D4 + D1/D3 + aux)

> AREA: data construction (pipeline stages A–D). Read in full: A4, B4, C6, D4.
> Lighter map: D1, D3. Inventory only: aux_codes_RAIS/*.
>
> **GLOBAL NOTE (applies to A4, B4, C6, D4, D1, D3):** These canonical BUILD-stage
> files do NOT implement the `dir.exists()` sample/full auto-select pattern that the
> downstream analysis files (E4/F/G5/H3/I4/I6) use. Every one of them hardcodes
> `.libPaths('F:/docs/R-library')` and `setwd('U:/Documents/Paper/directory_2025')`
> at the top and reads `working/*.csv.gz`. They are **FULL-DATA / SERVER ONLY**.
> On the sample machine `working/` does not exist, so these scripts are NOT in the
> sample parity set — the panel + cross-section are *inputs* in sample mode, produced
> upstream on the restricted server. There is NO "_sample" suffix branch in any BUILD file.

---

## A4_balance_check.R

- LANG: R
- PURPOSE: Balance check (means/SDs/diff/p-values + significance stars) between uniquely-identified vs duplicated individuals across the three SUIBE datasets (unidentified, semi-identified, merged); emits a LaTeX + CSV balance table.
- INPUTS:
  - full-mode (only mode): `working/A1_suibe_semi.csv.gz`, `working/A2_suibe_unid.csv.gz`, `working/A3_merged_suibe.csv.gz` (all relative to `setwd` dir `U:/Documents/Paper/directory_2025`)
  - sample-mode: N/A — no sample branch; reads A1/A2/A3 working files that do not exist on the sample.
- OUTPUTS:
  - `output/A/A4_balance_check.csv` (fwrite, line 278)
  - `<dir>/output/A/A4_balance_check.tex` (writeLines, line 280, absolute via `paste0(dir,...)`)
- DEP-EDGES: Consumes A1/A2/A3 outputs (A-stage upstream, all .R: A1/A2/A3 not in my area). Standalone diagnostic — NO downstream pipeline stage consumes A4's CSV/TEX (table goes into the paper, not the data pipeline). Per CLAUDE verification-protocol "A4 -> (standalone)".
- FRAGILE-PATHS:
  - L10 `.libPaths('F:/docs/R-library')`
  - L15 `dir <- 'U:/Documents/Paper/directory_2025'`
  - L16 `setwd(paste(dir))`
  - L24/26/28 `fread('working/A1_suibe_semi.csv.gz' | 'working/A2_suibe_unid.csv.gz' | 'working/A3_merged_suibe.csv.gz')`
  - L278 `fwrite(..., 'output/A/A4_balance_check.csv')`
  - L280 `writeLines(..., paste0(dir,'/output/A/A4_balance_check.tex'))`

---

## B4_create_clean_candidates_cross.R

- LANG: R
- PURPOSE: Builds rich CPF-level (CPF_mode) cross-sections of RAIS-merge candidates, one per claiming year 2010–2019. Opens RAIS 1995–2020 (4 vintage-specific reader fns for codebook changes), deflates wages to 2019 via INPC, harmonizes CNAE/CBO codes & municipality, then derives ~16 feature blocks (schooling, sector cnae2/3, occupation cbo3/4, employment-prob 10/15yr, avg salary, last RAIS year, geography uf/microregion/municipality at 2/5/8/10/15yr horizons, end-of-year employment, n contracts, hours, tenure, legal-status, firm size, contract type, retirement-dismissal dummies, post-claim employment dummy), and joins them onto B2 candidate cross.
- INPUTS:
  - full-mode (only mode): `working/A3_merged_suibe.csv.gz` (L26); `working/B2_full_candidates_cross.dta` via read_dta (L28); `working/B3_full_candidates_panel/B3_<y>.csv` for y in 1995:2020 via the 4 reader fns (L87/121/159/198); `<dir>/extra/inpc/tabela_inpc.csv` (L36); `<dir>/extra/conversao_cnae_cbo/conversao_cnae.csv` (L41); `<dir>/extra/conversao_cnae_cbo/conversao_cbo.csv` (L44); `extra/microrregioes.dta` (L47)
  - sample-mode: N/A — relies on `working/` + `extra/` which are absent on the sample (shared-facts: sample mode has no working/ and no extra/).
- OUTPUTS:
  - `working/B4_clean_candidates_cross/B4_<y>.csv.gz` for y in 2010:2019 (fwrite, L641, inside the year loop)
- DEP-EDGES: Consumes A3 output (A3_merged_suibe), B2 output (B2_full_candidates_cross.dta, a .do upstream), B3 output (B3 panel CSVs, a .do upstream). Produces B4_<y> cross-sections consumed downstream by C-stage (C1/C4/C5 → C6) which feed C5_restricted_sample read by C6/D1/D3. Per protocol "B4 -> C6, D4".
- FRAGILE-PATHS:
  - L12 `.libPaths('F:/docs/R-library')`; L17 `dir <- 'U:/Documents/Paper/directory_2025'`; L18 `setwd(paste(dir))`
  - L26 `fread('working/A3_merged_suibe.csv.gz')`
  - L28 `read_dta('working/B2_full_candidates_cross.dta')`
  - L36 `fread(paste0(dir,'/extra/inpc/tabela_inpc.csv'))`
  - L41 `fread(paste0(dir,'/extra/conversao_cnae_cbo/conversao_cnae.csv'))`
  - L44 `fread(paste0(dir,'/extra/conversao_cnae_cbo/conversao_cbo.csv'))`
  - L47 `read_dta('extra/microrregioes.dta')`
  - L87/121/159/198 `fread(paste0('working/B3_full_candidates_panel/B3_',y,'.csv'))`
  - L641 `fwrite(cross, paste0('working/B4_clean_candidates_cross/B4_',y,'.csv.gz'))`
- NA-NOTE (not a bug, documented): many block aggregations use `max(..., na.rm=T)` / `mean()` on group subsets; the `max(mN, na.rm=T)` calls in the employment-prob block (L361-366) produce `-Inf` warnings for all-NA groups but those are immediately overwritten by rowSums logic — sampling-mode irrelevant since file is full-only.

---

## C6_estimate_continuous_contrib.R

- LANG: R
- PURPOSE: Imputes a continuous contributive time for claimants. For each gender × discrete-years-of-contribution cell, fits `feols` of (continuous−discrete contrib diff) on a rich polynomial+interaction covariate set with high-dim FEs (microrregiao, affiliation/sector/issue type, schooling, cnae2, cbo3, natjur, firmsize, contract type, race), predicts the diff, reconstructs `pred_contr_time = years_contr + predicted_diff`, and sets `contr_time_est` = observed `contr_time_fp` when present else the prediction. Also draws (interactive, not saved) density/prediction diagnostic panels.
- INPUTS:
  - full-mode (only mode): `working/C5_restricted_sample.csv.gz` (L26); `<dir>/extra/Expectativa_Vida_IBGE.xlsx` via read_excel (L29)
  - sample-mode: N/A — reads `working/` + `extra/`, absent on sample.
- OUTPUTS:
  - `working/C6_estimated_contrib_time.csv.gz` (fwrite, L433) — columns `CPF_mode, pred_contr_time, contr_time_est`
- DEP-EDGES: Consumes C5 output (C5_restricted_sample, from C5_restrict_sample.R; C-stage upstream of my area). Produces C6_estimated_contrib_time consumed by D1 (L27) and D3 (L36) which feed the panel D4 via D3. Per protocol "C6 -> D4".
- FRAGILE-PATHS:
  - L12 `.libPaths('F:/docs/R-library')`; L17 `dir <- 'U:/Documents/Paper/directory_2025'`; L18 `setwd(paste(dir))`
  - L26 `fread('working/C5_restricted_sample.csv.gz')`
  - L29 `read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx'))`
  - L433 `fwrite(dt, 'working/C6_estimated_contrib_time.csv.gz')`
- NOTE: the `expectativa`/`aux_expectativa` survival-table block (L29-49) is built but NOT used downstream in C6 (no merge onto suibe; life-expectancy is consumed in D1/D3 instead). Dead-ish in C6 but harmless. The covariate formula uses `^2` inside `feols` fml which fixest treats literally (poly terms) — consistent across the example model and the women/men loops, so internally consistent.

---

## D4_create_panel.R  (canonical panel)

- LANG: R
- PURPOSE: Builds the final SUIBE–RAIS quarterly panel. Re-opens filtered RAIS 2002–2020 (C3 filtered files), restricts to cross-section individuals, deflates earnings to 2019 (INPC), spreads each contract to month-level earnings, winsorizes monthly earnings at 1%/99%, computes monthly tax collection (payroll 20% + individual SS bracket + income-tax bracket), melts to month-level, balances the panel 2002–2020 via `CJ`, then (from 2010 on) joins cross-sectional vars and collapses to **quarter** cells (`num==3` complete quarters) twice — once keyed on distance-to-reform, once on distance-to-claim — adding reform/claim/issue distances, benefits, claiming hazard, distance-to-threshold, period-contributive-time, points & `points_norm` (centered at 85 women / 95 men). Saves two panels.
- INPUTS:
  - full-mode (only mode): `working/D3_cross_section.csv.gz` (L34); `working/C3_filtered_rais/C3_<y>.csv` for y 2002:2020 (L87); `<dir>/extra/inpc/tabela_inpc.csv` (L41); `<dir>/extra/conversao_cnae_cbo/conversao_cnae.csv` (L46); `<dir>/extra/conversao_cnae_cbo/conversao_cbo.csv` (L49); `extra/microrregioes.dta` (L52)
  - sample-mode: N/A — full-only (reads `working/` + `extra/`).
- OUTPUTS:
  - `working/D4_panel_reform.csv.gz` (fwrite, L411)
  - `working/D4_panel_claim.csv.gz` (fwrite, L413)
- DEP-EDGES: Consumes **D3 output** (D3_cross_section.csv.gz, line 34) and C3 filtered RAIS. Note D4 reads D3, NOT D1 — so the canonical panel is built off the D3 cross-section. Produces D4_panel_{reform,claim} consumed downstream by E4/F/G5/H3 (the analysis panel inputs). Per protocol "D4 -> E4, F-new, G5, H3".
- FRAGILE-PATHS:
  - L11 `.libPaths('F:/docs/R-library')`; L16 `dir <- 'U:/Documents/Paper/directory_2025'`; L17 `setwd(paste(dir))`
  - L34 `fread('working/D3_cross_section.csv.gz')`
  - L41 `fread(paste0(dir,'/extra/inpc/tabela_inpc.csv'))`; L46/49 conv_cnae/conv_cbo under `<dir>/extra/conversao_cnae_cbo/`
  - L52 `read_dta('extra/microrregioes.dta')`
  - L87 `fread(paste0('working/C3_filtered_rais/C3_',y,'.csv'))`
  - L411 `fwrite(..., 'working/D4_panel_reform.csv.gz')`; L413 `fwrite(..., 'working/D4_panel_claim.csv.gz')`
- O3 CONFIRMATION — STRAY ')' near line ~249: **NOT PRESENT / NO BUG.** Exact context:
  - L244 `contr_time_est)],` (closes the `cs_save[,.(...)]` arg of left_join)
  - L245 `by = 'indiv') %>%` (closes the left_join call)
  - L246 `arrange(indiv, year_month)`
  - L247 blank, L248 `gc()`, L249 blank, L250 comment, L252 `panel[, dist_reform_months := ...]`.
  - There is no orphan `)` after the L248 `gc()`. The `left_join(...)` opened at L237 is balanced and closed at L245. The file parses cleanly. (If a reviewer flagged a stray paren around 249 it is a false positive — likely an off-by-N line drift from an earlier file version.)
- NA-NOTE (documented, not flagged as sampling): winsorization at L172-175 uses unconditional `quantile()` on `earnings` with default `na.rm=FALSE`; if `earnings` ever contains NA the quantiles return NA. In practice `earnings` here is the melted non-NA non-zero values, so safe. Tax-bracket constants (998, 1751.81, 5839.45, etc., L180-189) are hardcoded 2019-ish magic numbers with `div<-1` (no per-year deflation of the bracket cutoffs) — intentional given earnings already deflated to 2019; noting as an uncommented-magic-number style point, not a bug.

---

## D1_create_cross_section.R  (lighter — read by G5)

- LANG: R
- PURPOSE: Final SUIBE–RAIS cross-section. Joins C5 restricted sample with C6 estimated contrib time, derives eligibility age/points, distances to 85/95 (pre-2019) vs 86/96 (2019) cutoffs at eligibility & claiming, claim/elig quarters, post-reform dummy, salary-benefit category, above-cutoff dummy, estimated fator previdenciario via IBGE life-expectancy, then drops bookkeeping cols and renames `CPF_mode -> indiv`.
- INPUTS:
  - full-mode (only mode): `working/C5_restricted_sample.csv.gz` (L25); `working/C6_estimated_contrib_time.csv.gz` (L27); `<dir>/extra/Expectativa_Vida_IBGE.xlsx` (L29)
  - sample-mode: N/A (full-only).
- OUTPUTS: `working/D1_cross_section.csv.gz` (fwrite, L177)
- DEP-EDGES: Consumes C5 + C6 output. Produces **D1_cross_section.csv.gz consumed by G5** (per shared-facts: G5 reads working/D1_cross_section.csv.gz).
- FRAGILE-PATHS: L11 libPaths F:/; L16 dir U:/; L17 setwd; L25/27 fread working/C5,C6; L29 read_excel `<dir>/extra/Expectativa_Vida_IBGE.xlsx`; L177 fwrite `working/D1_cross_section.csv.gz`.

---

## D3_create_cross_section.R  (lighter — read by I4/E4/H3 and by D4)

- LANG: R
- PURPOSE: Same cross-section construction as D1 (near-identical body) with two additions: (a) builds `aux_normalization` calendar table (L25-32, NOT in D1) and (b) computes `points_d`/`points_norm` (normalized points centered 85/95) **inside the cross-section** (L165-168) which D1 does not. Saves D3_cross_section.
- INPUTS: identical to D1 — full-mode only: `working/C5_restricted_sample.csv.gz` (L34); `working/C6_estimated_contrib_time.csv.gz` (L36); `<dir>/extra/Expectativa_Vida_IBGE.xlsx` (L38). sample-mode: N/A.
- OUTPUTS: `working/D3_cross_section.csv.gz` (fwrite, L191)
- DEP-EDGES: Consumes C5 + C6 output. Produces **D3_cross_section.csv.gz consumed by D4 (L34), E4, H3, and I4** (per shared-facts).
- FRAGILE-PATHS: L11 libPaths F:/; L16 dir U:/; L17 setwd; L34/36 fread working/C5,C6; L38 read_excel `<dir>/extra/Expectativa_Vida_IBGE.xlsx`; L191 fwrite `working/D3_cross_section.csv.gz`.

---

## D1-vs-D3 SPLIT (flagged inconsistency — documented, NOT fixed)

Two cross-section builders coexist; both read the SAME inputs (C5 + C6 + IBGE life-expectancy) and both rename `CPF_mode -> indiv`. Differences:

| Aspect | D1 | D3 |
|---|---|---|
| `aux_normalization` calendar table | absent | built L25-32 (`year_month` as `as.yearmon` string; D2 lineage) |
| `points_d` / `points_norm` in cross-section | NOT created | created L165-168 (`points_norm` = points_d −85 women / −95 men) |
| Drop list of bookkeeping cols | drops `...,'expec_ibge'` too (L164-167) — i.e. `expec_ibge` removed | does NOT drop `expec_ibge` (L178-181) → `expec_ibge` survives into D3 output |
| Output | `working/D1_cross_section.csv.gz` | `working/D3_cross_section.csv.gz` |

Consumer split (the flagged inconsistency):
- **G5 reads D1** (`working/D1_cross_section.csv.gz`).
- **D4 (panel), E4, H3, I4 read D3** (`working/D3_cross_section.csv.gz`).

Consequence to document (do NOT fix): G5's individual-level cross-section (D1) lacks the in-cross-section `points_norm`/`expec_ibge` columns that D3 carries, while D4/E4/H3/I4 get the D3 variant. Since G5 also derives its own normalized points downstream this may be benign, but the canonical analysis files are NOT all reading the same cross-section file — a single cross-section source would be cleaner. Confirmed by direct read: D1 fwrite target L177, D3 fwrite target L191, D4 read L34, and shared-facts G5→D1 / {E4,H3,I4}→D3.

---

## aux_codes_RAIS/ — INVENTORY ONLY (not mapped; server-only RAIS extraction helpers)

All are restricted-server Stata/R utilities that produce RAIS extracts upstream of the A/B stages; none run on the sample machine. Hardcoded server paths throughout (`U:\`, `F:/RAIS/...`).

- `Puxa RAIS.do` (Stata) — Bernardo's master RAIS-pull script: loops years/regions pulling worker IDs + contract records from raw RAIS. Output: per-year RAIS extracts on server. (`clear all` at top.)
- `Build_munic_panel.do` (Stata) — builds a yearly municipality-level RAIS panel (FIRST_YEAR/LAST_YEAR/REGIONS globals). Output: municipality panel .dta.
- `Build_estab_panel.do` (Stata) — builds a quarterly establishment-level RAIS panel. Output: establishment panel .dta.
- `Build_worker_panel.do` (Stata) — builds a monthly worker-level RAIS panel. Output: worker panel .dta.
- `join_rais_few_vars.R` (R) — merges a few RAIS variables across contract-level parquet files for 2009–2011 from `F:/RAIS/admin/id_data/contract_level/`; writes to `temp_merge_results/`. Output: merged per-year RAIS var subset.
- `Sample_RAIS_arthur.do` (Stata) — takes a 5% random sample of RAIS IDs (matches duplicates, draws sample). `cd "U:\Desktop\Dissertação\ID_worker"`. Output: 5% sampled ID list (this is the seed of the sample pipeline).
- `Mappings_CBO/code/cod_cbo_informality.do` (Stata) — translates COD(PNAD-C)→CBO(RAIS), computes 4-digit-occupation informality share. Output: `COD_CBO_share_informality.dta`.
- `Mappings_CBO/code/groups_cbo.do` (Stata) — builds CBO94↔CBO2002 group classifications. Output: `CBO1994_dummies.dta`, `CBO2002_dummies.dta`, `CBO1994_2002_occup_group.dta`.

## NOTED-ONLY (existence only, not mapped per instructions)
A1-A3 (.R), B1-B3 (.do), C1-C5 (.R/.do), D2 (.R), old/B1-B2. These are non-canonical siblings / upstream that no canonical file in my area re-reads beyond the C5→C6 and B2/B3→B4 and A3→{A4,B4} edges already documented.
