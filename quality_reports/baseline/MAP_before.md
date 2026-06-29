# MAP_before.md — Consolidated repository cartography (pre-restructure baseline)

> Conciliator reconciliation of map_BUILD.md + map_ANALYSIS.md + map_PRESENTATION.md.
> MVPF/WMVPF of Brazil's 2015 pension reform (Lei 13.183/2015). Read-only baseline snapshot.
> Every load-bearing fact below was re-verified against source at file:line (see "Verified" notes).

## Data modes (recap; orchestrator-verified)

- **FULL** root `F:/Users/tucalins/Documents/transf_11_11/directory_2025` (also `U:/Documents/Paper/directory_2025`
  and `U:/Documents/transf_11_11/directory_2025` variants) — NOT present on this machine. Reads `working/*.csv.gz`
  + `extra/*`; writes `working/` + `output/`.
- **SAMPLE** root `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement` — EXISTS. Scripts `setwd()`
  in. Reads `data/dt_sampled_anon.csv` + `data/panel_sampled_anon.csv`. NO `working/`, NO `extra/`.
  SUFFIX = `"_sample"` on many output names.
- Auto-select via `dir.exists()` — present in E4/gabriel/pure/G5/I4/I6/I7; **ABSENT in all BUILD files and in H3**.

---

## Per-stage consolidated table

| Stage | Canonical file | Lang | Inputs (sample-mode / full-mode) | Outputs | Produces (figures / numbers) | Runs on sample? |
|---|---|---|---|---|---|---|
| A | A4_balance_check.R | R | full only: `working/A1_suibe_semi.csv.gz`, `A2_suibe_unid.csv.gz`, `A3_merged_suibe.csv.gz` | `output/A/A4_balance_check.{csv,tex}` | SUIBE balance table (paper, not pipeline) | NO (full-only, no sample branch) |
| B | B4_create_clean_candidates_cross.R | R | full only: `working/A3_merged_suibe.csv.gz`, `working/B2_full_candidates_cross.dta`, `working/B3_full_candidates_panel/B3_<y>.csv`, `extra/inpc`, `extra/conversao_cnae_cbo/*`, `extra/microrregioes.dta` | `working/B4_clean_candidates_cross/B4_<y>.csv.gz` (y=2010:2019) | RAIS feature cross-sections | NO (full-only) |
| C | C6_estimate_continuous_contrib.R | R | full only: `working/C5_restricted_sample.csv.gz`, `extra/Expectativa_Vida_IBGE.xlsx` | `working/C6_estimated_contrib_time.csv.gz` | imputed continuous contribution time | NO (full-only) |
| D | D4_create_panel.R | R | full only: `working/D3_cross_section.csv.gz`, `working/C3_filtered_rais/C3_<y>.csv`, `extra/{inpc,conversao,microrregioes}` | `working/D4_panel_reform.csv.gz`, `working/D4_panel_claim.csv.gz` | SUIBE-RAIS quarterly panel | NO (full-only; panel is an *input* on sample) |
| (D1) | D1_create_cross_section.R | R | full only: C5 + C6 + IBGE xlsx | `working/D1_cross_section.csv.gz` | cross-section; **consumed by G5 only** | NO (full-only) |
| (D3) | D3_create_cross_section.R | R | full only: C5 + C6 + IBGE xlsx | `working/D3_cross_section.csv.gz` | cross-section + `points_norm`/`expec_ibge`; **consumed by D4, E4, H3, I4, I6, I7** | NO (full-only) |
| E | E4_plots_claiming_distributions.R | R | sample: `data/dt_sampled_anon.csv`, `data/panel_sampled_anon.csv` / full: `working/D3_cross_section.csv.gz`, `working/D4_panel_reform.csv.gz` | `output/E/E4_*.pdf` (8 figs) + `tmp/teste_plot.pdf` | claiming-hazard/density + pension-schedule figures (NO csv) | YES |
| F (upstream) | new_counterfactual_claiming3_gabriel.R | R | sample: `data/dt_sampled_anon.csv`, `data/panel_sampled_anon.csv`, `output/F/F5_table_results.csv` / full: `working/D3,D4_panel_reform,D1,D2` + `output/F/F5_table_results.csv` | `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` + `tmp/...` + `output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p<SUFFIX>.csv` + claiming-hazard ES + count figs | actual N^a vs counterfactual N^c claim counts per (t,p); F4 event-study figs | YES |
| F (canonical) | new_counterfactual_claiming3_pure.R | R | both: gabriel handoff `output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p<SUFFIX>.csv` (tmp fallback). full-only block also reads D3/D4/F5 (discarded) | `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv` + 30 pure-Level/Slope freq figs | pure-Level/Slope claim counts, `g_pta`, `PB_pt`, `PA_ta` | YES |
| G | G5_effect_average_benefit_freq_bL_and_bS.R | R | sample: `data/dt_sampled_anon.csv` / full: `working/D1_cross_section.csv.gz` + `extra/Expectativa_Vida_IBGE.xlsx`; both: pure-schedules CSV (L610) | `output/G/G5_table_results_selection<SUFFIX>.csv`, `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv` + G4-named ES figs + pension-schedule figs | avg-benefit DD; per-quarter WVMVPF_L/S (in-memory, not csv); contrafactual benefits table | YES |
| H | H3_policy_elasticity.R | R | **full only (HARDCODED U:/ path, no sample branch):** `working/D3_cross_section.csv.gz`, `working/D4_panel_claim.csv.gz` | `output/H/H3_*.pdf` (trends + event-study; NO csv/table) | IPW-DD employment/tax elasticity figures only | NO (h3-nosample; cannot run on sample) |
| I (actual) | I4_wmvpf_no_pure_reforms_freq.R | R | sample: `data/dt_sampled_anon.csv`, `data/panel_sampled_anon.csv` / full: `working/D3`, `working/D2_panel.csv.gz`, IBGE xlsx; both: `output/F/new_counterfactual_claim_counts<SUFFIX>.csv` (suffix), `output/G/G4_table_results.csv` (NO suffix), `output/H/H2_table_results.csv` (NO suffix) | `output/I/I4_table_wmvpf<SUFFIX>.csv`, `output/I/I4_plot_results<SUFFIX>.pdf` | WMVPF_actual (console scalar; table per-quarter) | YES |
| I (pure) | I6_wmvpf_with_pure_reforms_freq.R | R | sample: `data/*` / full: `working/D3`, `D2`, IBGE; both: F counts (suffix), `output/G/G4_table_results<SUFFIX>.csv`, `output/H/H2_table_results<SUFFIX>.csv`, G5 contrafactual CSV (L418), pure-schedules CSV (g_pta fallback L494) | `output/I/I6_wmvpf_actual/pure_L/pure_S/summary<SUFFIX>.csv`, `I6_table_wmvpf<SUFFIX>.csv` + 8 plots | **WMVPF_actual, WMVPF_bL, WMVPF_bS, eta≈0.828** (canonical headline numbers) | YES |
| I (diag) | I7_diagnostic_juan_about_I6.R | R | sample: `data/dt_sampled_anon.csv` / full: `working/D3`; both: G5 contrafactual CSV, F counts, G4 table | `output/I/I7_diagnostic_*<SUFFIX>.csv` (3) | Juan diagnostics (terminal, NOT in DAG) | YES |

### Cross-section read split (verified)

- **G5 reads D1** — `fread('working/D1_cross_section.csv.gz')` at **G5_effect_average_benefit_freq_bL_and_bS.R:41**, with an explicit `[TODO:FUTURE]` at L38-40 acknowledging it should be D3.
- **D4, E4, H3, I4, I6, I7 read D3.** This is the one inconsistency in cross-section sourcing; D1 lacks the in-cross-section `points_norm`/`expec_ibge` that D3 carries. Likely benign (G5 re-derives normalized points) but not single-source.

---

## Storyline: raw -> panel -> estimates -> figures -> deck -> PDF

1. **Raw -> cross-section/panel (BUILD, FULL-DATA ONLY).** On the restricted server, SUIBE (A1-A3) and RAIS
   (B/C-stage) are cleaned into the C5 restricted sample; C6 imputes continuous contribution time; D1/D3 build the
   final cross-sections and D4 builds the `D4_panel_{reform,claim}` quarterly panels. None of A4/B4/C6/D4/D1/D3 run
   on the sample — they hardcode `U:/...` + read `working/`. On the sample machine, `data/dt_sampled_anon.csv` and
   `data/panel_sampled_anon.csv` are the *substitutes* for the D3 cross-section and D4 panel, produced upstream.

2. **Panel -> estimates (ANALYSIS, sample-runnable except H3).** E4 draws diagnostic claiming figures.
   gabriel.R builds actual/counterfactual claim counts (reading the LEGACY `F5_table_results.csv` — bug g-f5) and
   hands a `{t,p,claims,claims_c}` table to pure.R (via persistent `output/new_counter_claiming/.../...csv`, tmp
   fallback — seam O1). pure.R enriches it into pure-Level/Slope schedules with `g_pta`. G5 runs avg-benefit DD,
   merges the pure schedules, and emits the contrafactual-benefits table. H3 produces elasticity figures
   (full-only; the elasticity *table* consumed downstream is `H2_table_results.csv` from the non-canonical
   `H2_policy_elasticity_MW.R`). I4 computes WMVPF_actual; I6 computes WMVPF_actual + WMVPF_bL + WMVPF_bS + eta.

3. **Estimates/figures -> deck (PRESENTATION).** Each stage writes PDFs into
   `trans_retirement/output/<stage>/` (and the sample working dir). `collector.py` reads `manifest.csv` (72 data
   rows: 66 routable + 6 NONE/static), resolves each code output as the **newest of {sample-root, repo-root}** by
   mtime (collector.py:71-73,136), copies+renames into `figures_central_folder/from_code/`, and renders E3->E4
   diffs. `update_deck.py` is the one-shot driver (Rscript stage(s) -> collector -> latexmk). Its STAGES map runs
   E4, G5, H2, F(pure), Fg(gabriel), I6 — **not I4, not H3**.

4. **Deck -> PDF.** `latex/presentation/_main.tex` (ENGLISH deck) has
   `\graphicspath{{../../figures_central_folder/from_code/}{../../figures_central_folder/static/}}` and ~38 active
   `\includegraphics`; `latexmk -g -pdf` (cwd = deck dir) compiles `_main.pdf`. `verify_deck.py` checks every
   active include resolves under from_code/ or static/. The **Portuguese** deck `latex/apresentacao/_main.tex`
   uses `\graphicspath{{../figures/}}` (legacy `latex/figures/`) and is NOT on the collector pipeline — parity
   hazard (same E3_*/F4_* names can resolve to stale images).

---

## Legacy / quarantine list (DO NOT deep-map; keep quarantined)

- `trans_retirement/code/legacy/`: F1-F7, G6, I5 (OLD F method; old G; old WMVPF). Never rerun, never review as current.
- `trans_retirement/code/old/`: B1, B2.
- Non-canonical siblings (existence noted, not mapped unless a canonical file reads their OUTPUT):
  A1-A3, B1-B3 (.do), C1-C5, D2, E1-E3, G1-G4, H1-H2, I1-I3, `new_counterfactual_claiming2.R`,
  `H2_policy_elasticity_MW.R`, I7b_beta_comparison_diagnostic.R.
  - **Exceptions where a canonical file DOES read a sibling's output (so they are live dependencies):**
    `output/G/G4_table_results.csv` (G4 sibling) consumed by I4/I6/I7; `output/H/H2_table_results.csv`
    (H2_policy_elasticity_MW.R sibling) consumed by I4/I6; `output/F/F5_table_results.csv` (LEGACY F5) consumed
    by gabriel.R; `working/D1_cross_section.csv.gz` (D1) consumed by G5; `working/D2_panel.csv.gz` (D2) consumed
    by I4/I6 (full mode) and gabriel ES block.
- `aux_codes_RAIS/*` (Stata/R RAIS-extraction helpers): server-only, upstream of A/B. Inventory only.
