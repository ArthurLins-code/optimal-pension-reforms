# dependency_graph.md — Canonical runnable DAG (edge list)

> Each edge: `producer -> consumer  [scope]`. Scope = **full-only** (needs `working/`+`extra/` on the
> restricted server) or **sample-runnable** (executes on the 5% sample via the `dir.exists()` branch).
> Verified against source at the file:line cited in MAP_before.md / the partials.

## BUILD subgraph (ALL full-only — not in sample parity set)

```
A1/A2/A3_suibe            -> A4_balance_check.R            [full-only]   (standalone diagnostic; no pipeline consumer)
A3 + B2(.do) + B3(.do)    -> B4_create_clean_candidates    [full-only]
B4_<y> -> C-stage(C1..C5) -> C5_restricted_sample          [full-only]
C5_restricted_sample      -> C6_estimate_continuous_contrib [full-only]
C5 + C6                   -> D1_create_cross_section -> working/D1_cross_section.csv.gz  [full-only]
C5 + C6                   -> D3_create_cross_section -> working/D3_cross_section.csv.gz  [full-only]
D3_cross_section + C3_filtered_rais -> D4_create_panel -> working/D4_panel_reform.csv.gz, working/D4_panel_claim.csv.gz  [full-only]
```

On the sample, the BUILD outputs are pre-supplied as:
`data/dt_sampled_anon.csv` (= D3 cross-section substitute) and `data/panel_sampled_anon.csv` (= D4 panel substitute).

## ANALYSIS subgraph

```
# --- E (diagnostic figures, terminal) ---
D3_cross_section + D4_panel_reform        -> E4_plots_claiming_distributions  [full-only inputs]
data/dt_sampled_anon + data/panel_sampled -> E4_plots_claiming_distributions  [sample-runnable]
E4 -> output/E/E4_*.pdf (terminal; consumed only by collector.py)

# --- F (counterfactual claim counts) ---
F5_table_results.csv (LEGACY F)           -> gabriel.R                         [BUG g-f5; both modes]
D3 + D4_panel_reform (+ D1 + D2 for ES)   -> gabriel.R                         [full-only inputs]
data/dt_sampled_anon + data/panel_sampled -> gabriel.R                         [sample-runnable]
gabriel.R -> output/F/new_counterfactual_claim_counts<SUFFIX>.csv             (consumed by I4, I6, I7)
gabriel.R -> output/new_counter_claiming/actual_reform_gabriel/claims_actual_counterfactual_t_p<SUFFIX>.csv  (persistent handoff)
gabriel.R -> tmp/claims_actual_counterfactual_t_p<SUFFIX>.csv                 (tmp fallback handoff; seam O1)

gabriel handoff CSV (persistent, tmp fallback) -> pure.R                       [sample-runnable]
pure.R -> output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv   (consumed by G5, I6)

# --- G (avg-benefit DD + contrafactual benefits) ---
D1_cross_section (+ IBGE xlsx)            -> G5                                [full-only inputs; BUG g5-d1 = reads D1 not D3]
data/dt_sampled_anon                      -> G5                                [sample-runnable]
pure-schedules CSV (output/F/...with_pure_schedules_3<SUFFIX>.csv) -> G5       [both modes]
G5 -> output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv  (consumed by I6, I7)
G5 -> output/G/G5_table_results_selection<SUFFIX>.csv + G4-named ES figs + pension-schedule figs

# --- H (elasticity) ---
D3_cross_section + D4_panel_claim         -> H3_policy_elasticity              [FULL-ONLY; hardcoded U:/ path, NO sample branch — BUG h3-nosample]
H3 -> output/H/H3_*.pdf (figures only; NO table)
# NOTE: the elasticity TABLE consumed downstream is output/H/H2_table_results.csv, produced by the
# NON-CANONICAL sibling H2_policy_elasticity_MW.R, NOT by H3.

# --- I (WMVPF) ---
F new-counts<SUFFIX> + G4_table_results.csv(NO suffix) + H2_table_results.csv(NO suffix) + D2/D3 + IBGE -> I4   [BUG i4-g4h2; sample-runnable]
I4 -> output/I/I4_table_wmvpf<SUFFIX>.csv + plot   (WMVPF_actual)

F new-counts<SUFFIX> + G4_table_results<SUFFIX>.csv + H2_table_results<SUFFIX>.csv + G5 contrafactual CSV + pure-schedules CSV(g_pta fallback) + D2/D3 + IBGE -> I6   [sample-runnable]
I6 -> output/I/I6_{wmvpf_actual,wmvpf_pure_L,wmvpf_pure_S,summary,table_wmvpf}<SUFFIX>.csv + 8 plots
      (WMVPF_actual, WMVPF_bL, WMVPF_bS, eta)

G5 contrafactual CSV + F new-counts + G4 table + D3 -> I7   [diagnostic, terminal, NOT in DAG/parity decision; sample-runnable]
```

## PRESENTATION subgraph (figures -> deck -> PDF)

```
output/E/E4_*.pdf                                            -> collector.py   [manifest rows]
output/G/G5_*.pdf + G4-named ES figs                         -> collector.py
output/H/H2_*.pdf (LEGACY H2, sample)                        -> collector.py
output/I/I6_*.pdf                                            -> collector.py
output/new_counter_claiming/ (pure F + gabriel)             -> collector.py
   collector.py resolves NEWEST of {sample-root, repo-root} by mtime (collector.py:71-73,136)
collector.py -> figures_central_folder/from_code/<deck_name>   (66 routable rows; shutil.copy2 L187)
collector.py -> figures_central_folder/_diffs/<stem>__OLD-E3_vs_NEW-E4.pdf  (E3->E4 diff rows)
figures_central_folder/static/<deck_name>                   (6 NONE rows; manual/external, not code-produced)

figures_central_folder/from_code/ + static/ -> latex/presentation/_main.tex (\graphicspath, from_code shadows static)
latex/presentation/_main.tex -> latexmk -g -pdf (cwd=latex/presentation) -> latex/presentation/_main.pdf   (ENGLISH deck)
verify_deck.py validates _main.tex includes resolve under from_code/ + static/

# Portuguese deck — OFF the collector pipeline (parity hazard)
latex/figures/ (legacy 182 files) -> latex/apresentacao/_main.tex (\graphicspath{{../figures/}}) -> its own _main.pdf
```

`update_deck.py` STAGES map (the driver): E4, G5, H2, F=pure, Fg=gabriel, I6 — **does NOT run I4 or H3**.

## Compact edge list (canonical runnable spine)

```
gabriel            -> pure                                 [sample-runnable]
pure               -> G5                                   [sample-runnable]
pure               -> I6                                   [sample-runnable]
G5                 -> I6                                   [sample-runnable]
G5                 -> I7                                   [sample-runnable]
gabriel (F counts) -> I4                                   [sample-runnable]
gabriel (F counts) -> I6                                   [sample-runnable]
gabriel (F counts) -> I7                                   [sample-runnable]
D4_panel           -> E4                                   [full-only input; sample uses data/panel_sampled_anon]
D3/D4_panel_claim  -> H3                                   [full-only]
E4 figs            -> collector.py -> from_code/ -> _main.tex -> _main.pdf   [sample-runnable figs]
G5 figs            -> collector.py -> from_code/ -> _main.tex -> _main.pdf   [sample-runnable figs]
I6 figs            -> collector.py -> from_code/ -> _main.tex -> _main.pdf   [sample-runnable figs]
F (pure/gabriel) figs -> collector.py -> from_code/ -> _main.tex -> _main.pdf [sample-runnable figs]
H2 figs (legacy)   -> collector.py -> from_code/ -> _main.tex -> _main.pdf   [sample fig present in manifest]
```

## Off-DAG live dependencies (non-canonical siblings whose OUTPUT a canonical file reads)

```
G4 sibling -> output/G/G4_table_results[<SUFFIX>].csv   -> I4 (no suffix), I6 (suffix), I7 (suffix)
H2_policy_elasticity_MW.R -> output/H/H2_table_results[<SUFFIX>].csv -> I4 (no suffix), I6 (suffix)
LEGACY F5  -> output/F/F5_table_results.csv             -> gabriel.R (no suffix)
D1         -> working/D1_cross_section.csv.gz           -> G5
D2         -> working/D2_panel.csv.gz                   -> I4, I6 (full mode), gabriel ES block
```
