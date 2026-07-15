# FIGURES_TODO — open items for the presentation figures

> **What this is.** The to-do register for presentation figures (formerly `NEEDS_REGENERATION.md`,
> renamed 2026-06-12 when the last frozen figures were unfrozen). As of **2026-06-12** every
> non-static deck figure is **generated locally on the 5% sample** (Juan's directive): the old
> freezes were lifted after the generating scripts got **data-driven plot dimensions** (the
> hardcoded full-data axis limits were the blocker). What remains below is the **server (full-data)
> obligation** and a few known caveats.
>
> History: the 2026-06-08 version of this file listed 36 frozen figures; those rows were unfrozen
> on 2026-06-12 (manifest restored from commit `65c293d` + dimension fixes in the four scripts).

## A. Server rerun obligation (full data) — applies to ALL code-routed figures

Sample figures are correctly scaled but noisy (5% data; SEs ~4.5× wider). On the next
restricted-server session, rerun the figure stages full-data and re-collect. The dimension fixes
are **data-driven**, so the same code auto-adapts to full-data magnitudes — no further edits needed.

Stages to rerun: `new_counterfactual_claiming3_gabriel.R` → `new_counterfactual_claiming3_pure.R`
→ `G5_…bL_and_bS.R` → `H2_policy_elasticity_MW.R` (then `collector.py` without `--sample-root`).

**Manifest flips needed after the server run** (sample-suffixed rows → full-mode names):
| Deck figure(s) | Now routes | Flip to |
|---|---|---|
| `H2_dd_tax_collection_1.pdf` | `H2_dd_tax_collection_1_sample.pdf` (mode=sample) | `H2_dd_tax_collection_1.pdf` (mode=full/any) |
| `F4_eventstudy_agg_1–5.pdf` | `claiming_hazard_eventstudy_<n>_sample.pdf` (mode=sample) | `claiming_hazard_eventstudy_<n>.pdf` |
| `I6_plot_cumsum_actual_reform_multby20_sample.pdf` | sample I6 output | full-data I6 output (drop `_sample`) |

## B. Static-checked-only code paths (verify on the server)

- **gabriel.R claiming-hazard event-study block, FULL mode** (added 2026-06-12; block starts ~line 453):
  loads `working/D1_cross_section.csv.gz` + `working/D2_panel.csv.gz` (D4_panel_reform lacks
  quarterly `claim_haz`) and recomputes `points_norm` per legacy F4. Correct by construction,
  **never executed locally** — verify on first server run.
- All four dimension fixes run identically in full mode (data-driven limits); expect frames close to
  the old hardcoded ones (gabriel echo predicts ~0–8400 vs the old 0–8000).

## C. Known caveats (open, registered)

- **G5 estimation bugs O5a–O5c** (`_docs/memory/07_open_issues.md`): the benefit event-study values
  may be wrong even on full data until fixed. The dimension work deliberately did NOT touch estimation.
- **`frequenciesLQ/SQ` caption off-by-one**: deck captions read ~1 quarter ahead of the mapped files
  (manifest maps LQk/SQk → 2015_Q2+k). Label fix pending.
- **`frequenciesQ*` `prefer=` directive**: the manifest still prefers a (nonexistent) pure-script
  actual/cntf output and falls back to gabriel — extending pure.R remains a later prompt; the
  gabriel fallback is now dimension-fixed and saves outside `tmp/`, so it is a sound source.
- **Static-by-nature figures (6)** — no generating code, in `latex/figures/static/`: `image37.png`,
  `schedule_{women,men}_new.pdf`, `plot_expenditures_groups.pdf`, `ELSI.jpg`, `morRef2The.png`.
  Scripting them is optional future work.
- The 36 previously-frozen full-data images still sit in `latex/figures/static/` as references/rollback; they are
  shadowed by `from_code/` (graphicspath order). Optional cleanup after the team signs off.
