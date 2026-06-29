# map_ANALYSIS.md — Estimation & Results area

Area owner: Mapper-ANALYSIS. Files mapped in full (read line-by-line):
E4, new_counterfactual_claiming3_gabriel.R, new_counterfactual_claiming3_pure.R,
G5, H3, I4, I6, I7. (I7b_beta_comparison_diagnostic.R exists but is NOT in scope —
note only.)

Data-mode roots (auto-selected via dir.exists):
- FULL: `F:/Users/tucalins/Documents/transf_11_11/directory_2025` (also `U:/Documents/Paper/directory_2025` and `U:/Documents/transf_11_11/directory_2025` variants in some files). NOT present on this machine.
- SAMPLE: `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement` (EXISTS). All scripts `setwd()` into it.
- SUFFIX = "_sample" in sample mode, "" in full mode.

---

## E4_plots_claiming_distributions.R

- LANG: R
- PURPOSE: Diagnostic claiming-distribution plots (hazard & density by quarter/threshold/gender) and pension-schedule (replacement-rate) scatter. Stage E. Figures only — NO csv/table output consumed downstream.
- INPUTS:
  - FULL: `working/D3_cross_section.csv.gz` (filtered `!is.na(dist_claim_cutoff)`); `working/D4_panel_reform.csv.gz`.
  - SAMPLE: `data/dt_sampled_anon.csv`; `data/panel_sampled_anon.csv` (harmonizes `year_quarter`->`year_month`, adds `dist_reform_quarters` alias from `dist_reform`).
- OUTPUTS (all ggsave, NO SUFFIX applied — figures overwrite across modes):
  - `tmp/teste_plot.pdf` (scratch, overwritten 4x: L127,196,243,410)
  - `output/E/E4_claiming_haz_quarters.pdf` (L577)
  - `output/E/E4_claiming_haz_quarters_group.pdf` (L580)
  - `output/E/E4_claiming_haz_dist.pdf` (L583)
  - `output/E/E4_claiming_density.pdf` (L589)
  - `output/E/E4_claiming_density_women.pdf` (L592)
  - `output/E/E4_claiming_density_men.pdf` (L595)
  - `output/E/E4_pension_schedule_women.pdf` (L598)
  - `output/E/E4_pension_schedule_men.pdf` (L601)
  - (plot5 / E4_claiming_haz_dist_MWs.pdf is commented out, L586-587.)
- DEP-EDGES: consumes D-stage output (D3 cross-section + D4 panel). Produces only PDFs — NOT consumed by any later stage. Terminal/diagnostic node.
- KEY-NUMBERS: The claiming-distribution TABLE relevant to the deck is the relative-frequency/hazard built by `fn_distribution()` (L349-368) into df7_3/df8_3/df9_3 — used only for plots 7/8/9, never written to disk. The canonical claiming counts table is produced by the F-stage (gabriel/pure), not E4.
- FRAGILE-PATHS: `setwd(dir)` L37; absolute `F:/...directory_2025` L24, `U:/...directory_2025` L28, `C:/Users/tuca1/OneDrive/...` L32; `.libPaths('F:/docs/R-library')` L26,30; literal fread `working/D3_cross_section.csv.gz` L50, `working/D4_panel_reform.csv.gz` L52, `data/dt_sampled_anon.csv` L54, `data/panel_sampled_anon.csv` L56; ggsave `tmp/teste_plot.pdf` L127,196,243,410 and the 8 `output/E/*` literals L577-601. `set.seed(123)` L43.

---

## new_counterfactual_claiming3_gabriel.R  (UPSTREAM of pure; canonical F = pure.R)

- LANG: R
- PURPOSE: F-stage. Builds counterfactual claiming FREQUENCIES (actual N^a `claims` vs counterfactual N^c `claims_c`) per (t=dist_reform_quarters, p=points_norm) via cohort-recursive DD; emits the F counterfactual-count CSVs and the F4 claiming-hazard event-study figures.
- INPUTS:
  - FULL: `working/D3_cross_section.csv.gz` (L46); `working/D4_panel_reform.csv.gz` (L48); `output/F/F5_table_results.csv` (L83 AND L189 — read twice). For the event-study block: `working/D1_cross_section.csv.gz` (L477) + `working/D2_panel.csv.gz` (L479).
  - SAMPLE: `data/dt_sampled_anon.csv` (L51, renames `cpf_anon`->`indiv`); `data/panel_sampled_anon.csv` (L57, renames `cpf_anon`->`indiv`, `dist_reform`->`dist_reform_quarters`); `output/F/F5_table_results.csv` (L83/L189, NO suffix — see bug g-f5 below); event-study reload `data/dt_sampled_anon.csv` (L488) + `data/panel_sampled_anon.csv` (L491).
- OUTPUTS:
  - `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (L304) — **CANONICAL F count file consumed by I4 and I6.** Columns: t, p, claims, claims_c.
  - `tmp/claims_actual_counterfactual_t_p<SUFFIX>.csv` (L306) — trimmed copy (NON-PERSISTENT tmp/, see bug O1).
  - `output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p<SUFFIX>.csv` (L307) — **persistent copy read by pure.R (gabriel->pure handoff).**
  - `tmp/claims_distribution_actual_count_agg.pdf` (L445).
  - `output/new_counter_claiming/actual_reform_gabriel/claims_distribution_actual_count_<i>.pdf` for i in -13:13 (L449).
  - `output/new_counter_claiming/actual_reform_gabriel/claiming_hazard_eventstudy_<i><SUFFIX>.pdf` for i in 1:5 (L642-644).
- DEP-EDGES: consumes D3/D4 (+ D1/D2 for ES) and **F5_table_results.csv** (legacy-style F output — see bug g-f5). Produces the F count CSV consumed by pure.R (next), I4 (L130), I6 (L209). The pure schedules CSV is produced by pure.R, not here.
- KEY-NUMBERS: claiming-distribution table = `dt_save` (t,p,claims,claims_c) at L301-307. Postponement/bunching/anticipation masses b1,b2,b3 computed L321-323 (printed into plot_all annotations, not saved as table).
- FRAGILE-PATHS: `setwd(dir)` L31; absolute `U:/Documents/Paper/directory_2025` L18, `F:/...directory_2025` L22, `C:/Users/tuca1/OneDrive/...` L26; `.libPaths('F:/docs/R-library')` L20,24; `dir.create('tmp')` L42; fread literals `working/D3_cross_section.csv.gz` L46, `working/D4_panel_reform.csv.gz` L48, `output/F/F5_table_results.csv` L83,L189, `working/D1_cross_section.csv.gz` L477, `working/D2_panel.csv.gz` L479, `data/*` L51,57,488,491; fwrite literals L304,306,307; ggsave literals L445,449,642. `set.seed(123)` L37.

### CONFIRMED BUG O1 (gabriel write -> pure read via tmp/)
- gabriel WRITES the trimmed copy to a **relative** `tmp/` under the data root: `fwrite(dt_save, file = paste0('tmp/claims_actual_counterfactual_t_p', SUFFIX, '.csv'))` — **gabriel L306**. (Literal: `tmp/claims_actual_counterfactual_t_p_sample.csv` in sample mode.) NOT absolute `/tmp/`; it is `<data_root>/tmp/...`, created by `dir.create('tmp')` at L42.
- gabriel ALSO writes a persistent copy: `output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p<SUFFIX>.csv` — **gabriel L307**.
- pure.R READS, preferring the persistent path first then falling back to tmp/: `gabriel_path <- paste0("output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p", SUFFIX, ".csv")` — **pure L136**; fallback `gabriel_path <- paste0("tmp/claims_actual_counterfactual_t_p", SUFFIX, ".csv")` — **pure L138**; `dt_final <- fread(gabriel_path)` — **pure L143**.
- VERDICT: The primary handoff path (L307 -> L136) is persistent under `output/`, so the handoff is robust IF gabriel ran. The `tmp/` copy (L306) is the non-persistent fallback (L138). `tmp/` is created fresh each gabriel run; if gabriel is NOT rerun and tmp/ was cleared, only the `output/` copy survives. This is the documented O1 seam.

### CONFIRMED BUG g-f5 (gabriel reads F5_table_results.csv with NO suffix)
- `results <- fread('output/F/F5_table_results.csv')` — **gabriel L83** and **gabriel L189**. This is a LEGACY-style F output filename (F5), read with NO `<SUFFIX>`, so sample mode reads the same `F5_table_results.csv` as full mode. F5 is the OLD F method (F1-F7 are LEGACY per CLAUDE.md). gabriel's count-construction (claims/claims_c) depends on `ch_empirical`, `change_ch_perc`, `freq_count`, `freq`, `change_ch_pp` columns from F5. This is the documented "lingering reference to a LEGACY F output" inside the new-F producer. (Distinct from I4/G5/H3 — those don't read F5, but gabriel — the upstream of canonical F — does.)

---

## new_counterfactual_claiming3_pure.R  (CANONICAL F)

- LANG: R
- PURPOSE: F-stage canonical. Imports gabriel's actual/counterfactual counts and builds the PURE LEVEL (claims_L / N^L) and PURE SLOPE (claims_S / N^S) reform claiming frequencies via the postponement-bunching reallocation (g_pta, PA, PB) following the deck. In full mode it ALSO re-derives the gabriel block (L43-129) but that branch's dt_final is discarded — the canonical path always reloads gabriel's CSV (L143).
- INPUTS:
  - FULL: `working/D3_cross_section.csv.gz` (L45); `working/D4_panel_reform.csv.gz` (L48); `output/F/F5_table_results.csv` (L67, inside the full-only block); then gabriel handoff CSV (L136/138).
  - SAMPLE: skips the full-only D/F5 block entirely (L43-129 is `if (DATA_MODE=="full")`); reads ONLY the gabriel handoff CSV.
  - BOTH modes: gabriel handoff `output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p<SUFFIX>.csv` (L136, primary) OR `tmp/claims_actual_counterfactual_t_p<SUFFIX>.csv` (L138, fallback). `stop()` if neither exists (L141).
- OUTPUTS:
  - `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv` (L356) — **CANONICAL pure-schedules count file consumed by G5 (L610) and I6 (g_pta fallback L491-495).** Columns include t,p,claims,claims_c,claims_L,claims_S,g_pta,PB_pt,PA_ta,Xt,t_arrival, etc.
  - Pure-Level frequency figures: `output/new_counter_claiming/new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_<YYYY_Qn>.pdf` (L359-373, 15 files, NO SUFFIX).
  - Pure-Slope frequency figures: `output/new_counter_claiming/new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_<YYYY_Qn>.pdf` (L377-391, 15 files, NO SUFFIX).
- DEP-EDGES: consumes gabriel's count CSV (F handoff). Produces the pure-schedules CSV consumed by G5 (which merges claims_L/claims_S and g_pta) and I6 (g_pta fallback). NOTE the `_3` suffix in the filename is part of the literal, not the data SUFFIX.
- KEY-NUMBERS: pure-reform claiming counts table = `dt_final` written at L356. The postponement estimator g_pta (L172) and bunching PB_pt (L207) are the load-bearing intermediates carried into G5/I6.
- FRAGILE-PATHS: `setwd(dir)` L31; absolute `F:/...directory_2025` L18, `U:/Documents/Paper/directory_2025` L22, `C:/Users/tuca1/OneDrive/...` L26; `.libPaths('F:/docs/R-library')` L20,24; fread literals `working/D3...` L45, `working/D4...` L48, `output/F/F5_table_results.csv` L67, gabriel paths L136,138, `output/F/new_counterfactual_claim_counts_with_pure_schedules_3...` L610(read-back inside? no — that read is in G5); fwrite literal L356; 30 ggsave literals L359-391. `set.seed(123)` L37.

### gabriel -> pure handoff (explicit)
- OBJECT passed: data.table `dt_save` / `dt_final` with columns {t, p, claims, claims_c}.
- PATH: gabriel writes L307 (persistent) + L306 (tmp); pure reads L136 (persistent first) / L138 (tmp fallback) -> `fread` L143.
- pure then ENRICHES it with t_arrival, Xt, postponers, PA_ta, g_pta, PB_pt, claims_L, claims_S and writes the enriched table to `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv` (L356), which G5 consumes.

---

## G5_effect_average_benefit_freq_bL_and_bS.R  (CANONICAL G)

- LANG: R
- PURPOSE: Stage G. DD event-studies of the reform's effect on average (lifetime-PV) benefits under actual new/old schedules AND under the counterfactual pure-Level (bL) and pure-Slope (bS) schedules; assembles MECH/BEHAV/CNTRF expenditure flows per quarter and computes per-quarter WMVPF_L/WMVPF_S (WVMVPF_L/S). Emits G4-named event-study figures and the G5 contrafactual-reforms benefits table consumed by I6.
- INPUTS:
  - FULL: `working/D1_cross_section.csv.gz` (L41 — see bug g5-d1); `extra/Expectativa_Vida_IBGE.xlsx` (L45, life-expectancy merge).
  - SAMPLE: `data/dt_sampled_anon.csv` (L82, life-expectancy + points_norm + dist_reform pre-computed; no Excel, no D-file).
  - BOTH: `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv` (L610 — reads pure.R output to get claims_L/claims_S/claims_c per (p,t)).
- OUTPUTS:
  - `output/G/G5_table_results_selection<SUFFIX>.csv` (L974) — selection (new/old avg-benefit DD) table.
  - `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv` (L979) — **CANONICAL G output consumed by I6 (L405/418) and I7 (L164/166).** This is `DT_With_avg_benefits`: per (points_norm,dist_reform) with claims, claims_c, claims_L, claims_S, avg_benefits_bL/bS, avg_reform_benefits_pre_reform_choices_bL/bS, point_estimate_bL/bS, Beta_LP/SP/LA/SA, g_pta, delta_ben.
  - Event-study figures (G4-named): `output/G/G4_eventstudy_benefits_new<SUFFIX>.pdf` L982, `output/G/G4_eventstudy_benefits_old<SUFFIX>.pdf` L985, plus `output/G/G4_eventstudy_benegits_new_1..5.pdf` L988-997 and `output/G/G4_eventstudy_benegits_old_1..5.pdf` L999-1007 (NOTE: filename TYPO "benegits", NO suffix on the numbered ones).
  - Pure-reform replacement-rate schedules: `output/G/G5_pension_schedule_bL_women|bL_men|bS_women|bS_men<SUFFIX>.pdf` L1011-1018.
- DEP-EDGES: consumes D1 (full) / sample CS, life-expectancy Excel, and pure.R's pure-schedules CSV. Produces the contrafactual-reforms benefits CSV consumed by I6 and I7. NOTE: G5 does NOT read F5/legacy F outputs and does NOT read G2 in current code (G2 import was removed — see O5c).
- KEY-NUMBERS:
  - delta_bL (L368-369), delta_bS (L373-374), mean_benefit_in_T (L376-377) — pure-reform delta parameters.
  - WVMVPF_L (L780) and WVMVPF_S (L784) — per-quarter pure-reform welfare MVPFs (in `dt_results`, NOT written to a csv in G5 — they are computed but `dt_results` is not fwrite'd; the canonical WMVPF_bL/bS headline numbers come from I6). gamma=4, cons_inss=1536.4, cons_pop=1473.1 hardcoded L765-768 and L770-773.
  - Replacement-rate slopes/intercepts: women 0.69+0.021p (L336), men 0.82+0.025p (L337).

### CONFIRMED BUG g5-d1 (O5 / g5-d1): D1 instead of D3
- `dt <- fread('working/D1_cross_section.csv.gz')` — **G5 L41** (full mode). Canonical peers E4/I4/I6 read D3 (`working/D3_cross_section.csv.gz`). Acknowledged in an inline `[TODO:FUTURE]` comment at **L38-40**. Confirmed: canonical G reads D1 cross-section while canonical siblings use D3.

### O5a (MECH effect): uses claims_c, NOT claims_L/claims_S — FLAG STATUS: NOT A BUG AS DESCRIBED
- `MECH_by_qtr` at **G5 L618-621**: `MECH_L = sum(claims_c * avg_reform_benefits_pre_reform_choices_bL)`, `MECH_S = sum(claims_c * avg_reform_benefits_pre_reform_choices_bS)`. MECH (mechanical expenditure = counterfactual choices, no behavior) correctly uses **claims_c** (the counterfactual count), per spec. The BEHAV term (behavioral) at **L725-727** correctly uses claims_L / claims_S. So the prompt's O5a ("MECH uses claims_L/claims_S instead of claims_c") is NOT confirmed — current G5 uses claims_c for MECH and claims_L/S for BEHAV, which is the correct assignment. (Documenting as "checked, not present in current code" — the flag may describe a prior version. The line region given (~614) corresponds to L618-621.)

### CONFIRMED BUG O5b: WVMVPF parenthesization
- **G5 L780**: `WVMVPF_L=(MECH_L-CNTRF*gamma*(cons_inss-cons_pop)/cons_pop)/(BEHAV_L-CNTRF)`
- **G5 L784**: `WVMVPF_S=(MECH_S-CNTRF*gamma*(cons_inss-cons_pop)/cons_pop)/(BEHAV_S-CNTRF)`
- The welfare-weight factor `gamma*(cons_inss-cons_pop)/cons_pop` multiplies ONLY `CNTRF`, not the difference `(MECH-CNTRF)`. Numerator is `MECH - CNTRF*eta_term`, whereas the WE rows just above (L779 WE_L, L783 WE_S) apply the factor to the whole `(MECH-CNTRF)`. Inconsistent parenthesization between WE_* and WVMVPF_* numerators — CONFIRMED. (Compare to I6 which uses ME*ETA where ETA = 1 - gamma*(cons_inss-cons_pop)/cons_pop; the G5 WVMVPF numerator does not match that form.)

### O5c (delta_ben from G2): FLAG STATUS — FIXED IN CURRENT CODE
- The G2 density-based import was REMOVED. **G5 L737-738** are now COMMENTS documenting the old behavior: `# Previously: results_selection <- fread('output/G/G2_table_results.csv')` and `# aux1 <- results_selection[... delta_ben=(avg_benefits-point_estimate)*3]`. Current code (L739-749) builds `delta_ben = avg_pv_benefits_old - point_estimate` from G5's OWN dt_agg (PV lifetime units, L740-749), NOT from G2 and NOT multiplied by 3. So "reads delta_ben from G2 (density-based, x3)" is NO LONGER PRESENT — it was the documented fix (Juan Point 3). Documenting as resolved; no live G2 read remains in G5.

- FRAGILE-PATHS: `setwd(dir)` L25; absolute `F:/...directory_2025` L16, `C:/Users/tuca1/OneDrive/...` L20; `.libPaths('F:/docs/R-library')` L18; `read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx'))` L45; fread `working/D1_cross_section.csv.gz` L41, `data/dt_sampled_anon.csv` L82, `output/F/new_counterfactual_claim_counts_with_pure_schedules_3...` L610; fwrite L974,979; ggsave literals L982-1018. `set.seed(123)` L31. Hardcoded magic constants r_annual=0.06 L89, gamma=4 / cons_inss=1536.4 / cons_pop=1473.1 L765-773.

---

## H3_policy_elasticity.R  (CANONICAL H)

- LANG: R
- PURPOSE: Stage H. Estimates the policy elasticity / fiscal-externality inputs: IPW-weighted DD event-studies of employment and labor-tax collection around claiming/reform, comparing pre/post-reform claimants (treat = claimed after 2015-06-17). Emits H3 trend + event-study figures.
- INPUTS (FULL-MODE-ONLY — NO sample branch; see bug h3-nosample):
  - `working/D3_cross_section.csv.gz` (L28); `working/D4_panel_claim.csv.gz` (L30).
- OUTPUTS (all ggsave, NO SUFFIX):
  - `output/H/H3_trends_empl_claim.pdf` L301, `H3_trends_tax_claim.pdf` L302, `H3_trends_tax_claim_ipw.pdf` L303, `H3_trends_empl_reform.pdf` L304, `H3_trends_tax_reform.pdf` L305, `H3_trends_tax_reform_ipw.pdf` L306.
  - Event-study PDFs: `output/H/H3_1_empl_noipw_noyear.pdf` L358, `H3_2_empl_noipw_noyear.pdf` L365, `H3_1_empl_ipw_noyear.pdf` L373, `H3_2_empl_ipw_noyear.pdf` L381, `H3_1_tax_noipw_noyear.pdf` L388, `H3_2_tax_noipw_noyear.pdf` L395, `H3_1_tax_ipw_noyear.pdf` L403, `H3_2_tax_ipw_noyear.pdf` L411, `H3_1_tax_ipw_year.pdf` L419, `H3_2_tax_ipw_year.pdf` L427, `H3_1_empl_ipw_year.pdf` L435, `H3_1_tax_ipw_year_full.pdf` L444, `H3_1_empl_ipw_year_full.pdf` L452.
  - **NO csv/table written.** H3 produces ONLY figures. It does NOT write `H2_table_results.csv` (that is H2, a different file). The elasticity point estimates live in `list_did[[...]]` in-memory only.
- DEP-EDGES: consumes D3 cross-section + D4 panel_claim. Produces only figures. CRITICAL: I4 (L136) and I6 (L216) consume `output/H/H2_table_results.csv` — produced by **H2_policy_elasticity_MW.R**, NOT by H3. So the canonical H elasticity TABLE that flows into the WMVPF is the H2 output, while H3 (the canonical figure producer) emits no table. See bug i4-g4h2.
- KEY-NUMBERS (policy elasticity H3): the elasticity DD coefficients are in the feols models `list_did[['*_tax_ipw_year']]` etc (L414-452) and drawn via `iplot(...)$prms$estimate` inside `fn_estudy1` (L312-343). The scalar elasticity used downstream (multiplier 479609 in I4 L168 / I6 L251) comes from H2's `H2_table_results.csv`, not H3.
- FRAGILE-PATHS: `setwd(paste(dir))` L20; HARDCODED absolute `dir <- 'U:/Documents/Paper/directory_2025'` L19 (NO dir.exists() environment detection — unconditional U:/ path); `.libPaths('F:/docs/R-library')` L14 (unconditional, top of file); fread `working/D3_cross_section.csv.gz` L28, `working/D4_panel_claim.csv.gz` L30; ggsave literals L301-452. `set.seed(123)` L22.

### CONFIRMED BUG h3-nosample / h3-hardpath
- H3 has **NO `dir.exists()` mode detection and NO sample branch**: `dir <- 'U:/Documents/Paper/directory_2025'` is set unconditionally at **L19**, `.libPaths('F:/docs/R-library')` unconditionally at **L14**. On the sample machine these paths don't exist; `setwd(paste(dir))` (L20) will error. H3 is therefore FULL-MODE / server-only and CANNOT run in sample mode — it is NOT in the sample parity set. (All other ANALYSIS files have the 3-way dir.exists() block; H3 is the lone exception.) Also uses old `indiv` identifier throughout (L49,56,112,...) with no cpf_anon rename.

---

## I4_wmvpf_no_pure_reforms_freq.R  (CANONICAL I)

- LANG: R
- PURPOSE: Stage I. WMVPF of the ACTUAL reform (no pure decomposition), using FREQUENCIES. Combines actual benefit payments b'(x'), counterfactual benefits b(x), mechanical benefits b'(x), tax revenue changes, and welfare weight into the WMVPF. Emits the I4 results figure + wmvpf table.
- INPUTS:
  - FULL: `working/D3_cross_section.csv.gz` (L40); `working/D2_panel.csv.gz` (L71); `extra/Expectativa_Vida_IBGE.xlsx` (L47).
  - SAMPLE: `data/dt_sampled_anon.csv` (L108, rename cpf_anon->indiv); `data/panel_sampled_anon.csv` (L113, rename cpf_anon->indiv).
  - BOTH: `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (L130 — the NEW/canonical F counts, suffix-aware: CORRECT, this is gabriel's output not legacy F5); `output/G/G4_table_results.csv` (L134 — NO SUFFIX, see bug i4-g4h2); `output/H/H2_table_results.csv` (L136 — NO SUFFIX, see bug i4-g4h2).
- OUTPUTS:
  - `output/I/I4_plot_results<SUFFIX>.pdf` (L281).
  - `output/I/I4_table_wmvpf<SUFFIX>.csv` (L284) — the I4 WMVPF table (per-quarter b'(x'), b(x), b'(x), net_cost, mech_cost, fiscal_ext, welfare).
- DEP-EDGES: consumes F new-counts (gabriel), G4 table, H2 table, D2/D3 + Excel. Produces I4 wmvpf table + figure (terminal).
- KEY-NUMBERS:
  - WMVPF_actual: `wmvpf = sum(dt_wmvpf$welfare)/sum(dt_wmvpf$net_cost)` — **I4 L218**, printed L219. NOT written as a scalar to disk; recoverable from `output/I/I4_table_wmvpf<SUFFIX>.csv` (welfare & net_cost columns) but the ratio itself is console-only. (I4 has NO bL/bS — those are I6.)
  - welfare weight: applied inline at **L216** as `(1 - gamma*(cons_inss-cons_pop)/cons_pop)`, gamma=4, cons_inss=1536.4, cons_pop=1473.1 (L191-194). eta ~ 0.828 is this term; not separately named in I4 (named ETA in I6 L61).
  - tax multiplier 479609 at **L168** (`cumsum(point_estimate*479609)`); commented alt 559369/0.7931 at L164-165.
- FRAGILE-PATHS: `setwd(dir)` L27; absolute `F:/...directory_2025` L17, `C:/Users/tuca1/OneDrive/...` L21; `.libPaths('F:/docs/R-library')` L20; `read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx'))` L47; fread `working/D3_cross_section.csv.gz` L40, `working/D2_panel.csv.gz` L71, `data/dt_sampled_anon.csv` L108, `data/panel_sampled_anon.csv` L113, `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` L130, `output/G/G4_table_results.csv` L134, `output/H/H2_table_results.csv` L136; fwrite L284, ggsave L281. `set.seed(123)` L33. Magic constants L89-90,191-194; discount constants L208,210,212,216.

### CONFIRMED BUG i4-g4h2: I4 reads G4 / H2 outputs (not G5 / H3), with NO suffix
- `results_selection <- fread('output/G/G4_table_results.csv')` — **I4 L134**.
- `results_taxes <- fread('output/H/H2_table_results.csv')` — **I4 L136**.
- Canonical G is G5 and canonical H is H3, but I4 reads **G4** and **H2** table outputs. Additionally both are read with NO `<SUFFIX>`, so sample mode reads the full-mode (or whatever exists) `G4_table_results.csv` / `H2_table_results.csv` — i.e. these two inputs are NOT suffix-aware while the F counts (L130) and all I4 outputs ARE. CONFIRMED. (Note: I6 at L213/L216 reads the SAME G4/H2 files but WITH `<SUFFIX>` — so I6 fixed the suffix half but kept the G4/H2 (vs G5/H3) reference. The G4/H2 read is arguably intentional: G5 does NOT emit a `period in {old,new}` selection table in the I4 schema — G5 emits `G5_table_results_selection` and `G5_table_results_contrafactual...`. But per the convention "canonical = highest number," reading G4/H2 is a stale-reference smell and is flagged.)

### CONFIRMED BUG i4-discount: cost vs welfare discount factors not reciprocal-identical
- net_cost / mech_cost / fiscal_ext discount: `/((1.005^(3))^dist_reform)` — **I4 L208, L210, L212**.
- welfare discount: `(0.995^(3*dist_reform))` — **I4 L216**.
- `1/1.005 = 0.99502...` ≠ `0.995`. So the cost series is discounted by 1.005^(3t) while welfare is discounted by 0.995^(3t); these are NOT exact reciprocals (1.005^-1 ≈ 0.995025, not 0.995). The WMVPF ratio therefore carries a small systematic discount asymmetry between numerator (welfare) and denominator (net_cost). CONFIRMED. (Same asymmetry was REFACTORED in I6: I6 uses a single `disc_t = (1.005^3)^(-t)` for cumulative cost AND `ETA` without a separate 0.995 welfare factor — see I6 L656,307. So I4 retains the old asymmetric discount; I6 does not.)

### Legacy-F check (I4): CLEAN
- I4 reads `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (L130) = the NEW F (gabriel) — CORRECT, NOT legacy F5. No reference to F1-F7 / output/F/F5_* in I4. (The only stale-reference smell is G4/H2 above, which are G/H stage not F.)

---

## I6_wmvpf_with_pure_reforms_freq.R  (WMVPF with pure reforms — canonical pure-decomposition)

- LANG: R
- PURPOSE: Stage I (pure). PART 1 replicates I4's actual-reform WMVPF; PART 2 builds Pure-Level (bL) and Pure-Slope (bS) WMVPF via expenditure-reallocation (E^a, E^c, E^P postponement with g_pta); PART 3 summary + outputs. Reports WMVPF_actual, WMVPF_bL, WMVPF_bS (per-quarter and cumulative).
- INPUTS:
  - FULL: `working/D3_cross_section.csv.gz` (L99); `working/D2_panel.csv.gz` (L130); `extra/Expectativa_Vida_IBGE.xlsx` (L105).
  - SAMPLE: `data/dt_sampled_anon.csv` (L92, rename cpf_anon->indiv); `data/panel_sampled_anon.csv` (L94, rename cpf_anon->indiv).
  - BOTH (suffix-aware): `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (L209); `output/G/G4_table_results<SUFFIX>.csv` (L213); `output/H/H2_table_results<SUFFIX>.csv` (L216); `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv` (L405/418); fallback g_pta from `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv` (L491-495).
- OUTPUTS (written under REPO_TRANS/output in sample mode via setwd at L935, else under data dir):
  - `output/I/I6_wmvpf_actual<SUFFIX>.csv` L941; `output/I/I6_table_wmvpf<SUFFIX>.csv` L945 (I4-format compat); `output/I/I6_wmvpf_pure_L<SUFFIX>.csv` L950; `output/I/I6_wmvpf_pure_S<SUFFIX>.csv` L955; `output/I/I6_summary<SUFFIX>.csv` L960.
  - Plots: `I6_plot_actual_reform<SUFFIX>.pdf` L965; `I6_plot_pure_L_reform<SUFFIX>.pdf` L971; `I6_plot_pure_S_reform<SUFFIX>.pdf` L978; `I6_plot_pure_L_reform_per_qtr<SUFFIX>.pdf` L986; `I6_plot_pure_S_reform_per_qtr<SUFFIX>.pdf` L993; `I6_plot_cumsum_actual_reform_multby20<SUFFIX>.pdf` L1041; `I6_plot_pure_L_reform_multby20<SUFFIX>.pdf` L1074; `I6_plot_pure_S_reform_multby20<SUFFIX>.pdf` L1107.
- DEP-EDGES: consumes F new-counts, G4 table, H2 table, **G5 contrafactual-reforms benefits CSV** (the key pure input, L418), pure-schedules CSV (g_pta fallback), D2/D3 + Excel. Produces the I6 WMVPF tables/summary/plots (terminal). I6 is the only file that consumes G5's `G5_table_results_contrafactual_reforms_and_benefits_freq`.
- KEY-NUMBERS:
  - WMVPF_actual: `wmvpf_actual <- sum(dt_wmvpf$welfare)/sum(dt_wmvpf$net_cost)` — **I6 L311**, message L313. In summary_dt (L899) and written to `I6_summary<SUFFIX>.csv` (L960).
  - WMVPF_bL: `wmvpf_bL <- wmvpf_bL_cum` — **I6 L701** (cumulative, from `dt_pure_L[dist_reform==MAX_HORIZON, WMVPF_L_cum]` L696). Per-quarter `wmvpf_bL_T` L695. In summary_dt L900/902 -> `I6_summary<SUFFIX>.csv`. Per-quarter detail in `I6_wmvpf_pure_L<SUFFIX>.csv` (WMVPF_L_t, WMVPF_L_cum columns).
  - WMVPF_bS: `wmvpf_bS <- wmvpf_bS_cum` — **I6 L702** (cumulative, L698). Per-quarter `wmvpf_bS_T` L697. summary_dt L901/903 + `I6_wmvpf_pure_S<SUFFIX>.csv`.
  - eta / welfare weight ~0.828: `ETA <- 1 - GAMMA_BASELINE*(CONS_INSS - CONS_POP)/CONS_POP` — **I6 L61** (GAMMA=4 L53, CONS_INSS=1536.4 L54, CONS_POP=1473.1 L55). Written to summary_dt L904 ("Welfare weight eta") -> `I6_summary<SUFFIX>.csv`. **This is the canonical eta≈0.828 emitter.**
  - bS>bL direction check L915-925.
- DEP/REFERENCE: I6 reads G4/H2 (L213,216) WITH suffix — same stale G4/H2-vs-G5/H3 reference as I4 but suffix-aware. I6 reads G5's contrafactual CSV (good — current G stage). NO legacy F5 reference.
- DISCOUNT: I6 PART 1 (actual) STILL uses the I4-style asymmetric discount: net_cost `/((1.005^3)^dist_reform)` L299 and welfare `(0.995^(3*dist_reform))` L307 — SAME i4-discount asymmetry carried into PART 1. PART 2 (pure) uses the unified `disc_t=(1.005^3)^(-t)` L656 + ETA (no 0.995). So the asymmetry persists in I6 PART 1 but not PART 2.
- FRAGILE-PATHS: `REPO_TRANS <- file.path(getwd(),"trans_retirement")` L68 (depends on launch CWD being repo root); `setwd(dir)` L83 and `setwd(REPO_TRANS)` L935 (double setwd — output redirect); absolute `F:/...directory_2025` L70, `C:/Users/tuca1/OneDrive/...` L74; `.libPaths('F:/docs/R-library')` L73; `read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx'))` L105; fread literals L92,94,99,130,209,213,216,418,494; fwrite L941,945,950,955,960; ggsave L965-1107. `set.seed(20260512L)` L85.

---

## I7_diagnostic_juan_about_I6.R  (diagnostic; NOT a parity/DAG node)

- LANG: R
- PURPOSE: Diagnostic-only (Juan's 3 concerns about I6's pure-benefit pipeline: N^c magnitudes, b_bar_c==b_bar_S for p<0, and the quarterly-vs-PV unit mismatch). Replicates G5 micro benefit computations and cross-tabulates against the G5 CSV. Note header says "I6_diagnostic_juan.R" (stale internal name) but file is I7.
- INPUTS:
  - FULL: `working/D3_cross_section.csv.gz` (L63).
  - SAMPLE: `data/dt_sampled_anon.csv` (L59, rename cpf_anon->indiv).
  - BOTH (suffix-aware): `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv` (L164/166); `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (L320); `output/G/G4_table_results<SUFFIX>.csv` (L322).
- OUTPUTS:
  - `output/I/I7_diagnostic_cntrf_by_points_norm<SUFFIX>.csv` (L340-341).
  - `output/I/I7_diagnostic_by_points_norm<SUFFIX>.csv` (L348,351).
  - `output/I/I7_diagnostic_g5_cells<SUFFIX>.csv` (L349,352).
- DEP-EDGES: consumes G5 contrafactual CSV, F new-counts, G4 table. Produces I7 diagnostic CSVs (terminal). NOT consumed by any stage — pure diagnostic, NOT in DAG/parity set.
- KEY-NUMBERS: replicates G5's benefits_bL/bS (L105-118 — NOTE: I7 uses `pv_benefits_new` as the base for bL/bS, whereas G5 uses `pv_benefits_old` (G5 L351-361) — a base-schedule discrepancy between the diagnostic and G5; documenting, since I7 is diagnostic-only this does not affect canonical outputs). RR women 0.69+0.021p L101, men 0.82+0.025p L102.
- FRAGILE-PATHS: `setwd(dir)` L49; absolute `F:/...directory_2025` L37, `C:/Users/tuca1/OneDrive/...` L41; `.libPaths('F:/docs/R-library')` L39; fread `working/D3_cross_section.csv.gz` L63, `data/dt_sampled_anon.csv` L59, G5 CSV L166, F CSV L320, G4 CSV L322; fwrite L341,351,352. No set.seed (diagnostic, no randomization).

---

## DAG summary (ANALYSIS area edges)

- D3/D4 -> E4 (figures, terminal)
- D3/D4 + F5_table_results.csv -> gabriel -> `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (+ tmp/ + actual_reform_gabriel copies)
- gabriel count CSV -> pure -> `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv`
- D1(full)/sample CS + Excel + pure pure-schedules CSV -> G5 -> `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv` (+ selection csv + G4-named figures)
- D3 + D4_panel_claim -> H3 (figures only, FULL-MODE ONLY, no table)
- F new-counts + G4_table_results.csv + H2_table_results.csv + D2/D3 + Excel -> I4 -> `output/I/I4_table_wmvpf<SUFFIX>.csv` (WMVPF_actual)
- F new-counts + G4 + H2 + G5 contrafactual CSV + pure-schedules CSV + D2/D3 + Excel -> I6 -> I6_wmvpf_actual/pure_L/pure_S/summary csv (WMVPF_actual, WMVPF_bL, WMVPF_bS, eta)
- G5 contrafactual CSV + F new-counts + G4 + D3 -> I7 (diagnostic csv, terminal)

## Parity set (sample-runnable) within ANALYSIS
- RUNNABLE in sample: E4, gabriel, pure, G5, I4, I6, I7 (all have dir.exists() sample branch).
- NOT runnable in sample: H3 (hardcoded U:/ path, no sample branch — full/server only).
- Upstream table NOT produced in-area: `output/H/H2_table_results.csv` (from H2_policy_elasticity_MW.R) and `output/G/G4_table_results.csv` (from G4) are consumed by I4/I6/I7 but produced OUTSIDE this area / by non-canonical siblings.
