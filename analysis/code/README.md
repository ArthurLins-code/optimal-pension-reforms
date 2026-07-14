# analysis/code — what runs, and what each file is for

Estimation & results (stages E–I). **The master `analysis/analysis_all.R` runs only the canonical chain**
(`E4 → gabriel → pure → G5 → I4 → I6`). Superseded version-predecessors were archived to
[`../../legacy/superseded/`](../../legacy/superseded/) on 2026-06-23 (usage audit). Note: the `CLAUDE.md`
"highest number = canonical" rule does **not** hold cleanly for the H stage — see the H3 row.

| File | Role | In the current workflow? |
|------|------|--------------------------|
| `E4_plots_claiming_distributions.R` | 🟢 canonical (E) — claiming-distribution figures | **Yes** — `analysis_all.R` |
| `new_counterfactual_claiming3_gabriel.R` | 🟢 canonical (F, upstream) — counterfactual claim counts | **Yes** — `analysis_all.R` |
| `new_counterfactual_claiming3_pure.R` | 🟢 canonical (F) — pure L/S schedules | **Yes** — `analysis_all.R` |
| `G5_effect_average_benefit_freq_bL_and_bS.R` | 🟢 canonical (G) — DD on average benefits | **Yes** — `analysis_all.R` |
| `I4_wmvpf_no_pure_reforms_freq.R` | 🟢 canonical (I) — WMVPF (actual reform) | **Yes** — `analysis_all.R` |
| `I6_wmvpf_with_pure_reforms_freq.R` | 🟢 canonical (I) — WMVPF + pure L/S, η (headline) | **Yes** — `analysis_all.R` |
| `G4_effect_average_benefit_freq.R` | 🔵 live dependency — produces `output/G/G4_table_results*.csv` | **Yes** — read by I4 & I6 |
| `H2_policy_elasticity_MW.R` | 🔵 live dependency — produces `output/H/H2_table_results*.csv` + the live elasticity deck figure | **Yes** — read by I4 & I6 |
| `H3_policy_elasticity.R` | 🟠 doc-"canonical" H head, but full-data-only & figures-only; **H2 supplies the live table + figure** — flagged `h2-vs-h3` in `quality_reports/restructure_findings.md` | Not on any master |
| `I7_diagnostic_juan_about_I6.R` | 🟣 manual diagnostic | run by hand |
| `I7b_beta_comparison_diagnostic.R` | 🟣 manual diagnostic | run by hand |

**Archived as superseded** (in `../../legacy/superseded/`, each guarded with `stop()`):
E1, E2, E3, G1, G2, G3, H1, I1, I2, I3, `new_counterfactual_claiming2`.
