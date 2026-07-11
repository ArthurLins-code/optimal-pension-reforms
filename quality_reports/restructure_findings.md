# Restructure Findings — OPEN bugs (live workflow)

Econometric/methodology issues are **flagged, not fixed** (CLAUDE.md). The bugs below are the ones that — as
re-verified on **2026-06-23** (6-agent per-file re-check) — are **still present in the current code AND sit in the
live canonical workflow**: build `A4/B4/C6/D4`; analysis `E4/gabriel/pure/G5/I4/I6`; live deps `G4/H2`; the collector
tools + the English deck. Each is the professors' call. Line numbers are **current** (re-located after Stage-2 shifted them).

- Bugs in **non-workflow files** (the superseded `H3`, the off-pipeline Portuguese deck) → [`legacy_bugs.md`](legacy_bugs.md).
- Bugs that were **corrected or proved false** (O5a, O5c, O3) → [`legacy_bugs.md`](legacy_bugs.md) › *Closed*.

## Open bugs — verified present 2026-06-23

| id | file:line (current) | sev | description | disposition |
|----|---------------------|-----|-------------|-------------|
| **g-f5** | `analysis/code/new_counterfactual_claiming3_gabriel.R:72, 178` | MAJOR | The canonical new-F producer reads the **legacy** `output/F/F5_table_results.csv` (no suffix) — a live file depending on a quarantined-strategy table. | FLAG |
| **g5-d1** | `analysis/code/G5_…bL_and_bS.R:34` (full); sidestepped at `:75` (sample) | MAJOR | Full-mode reads `working/D1_cross_section.csv.gz` while canonical peers read D3 (explicit `[TODO:FUTURE]`). | FLAG |
| **O5b-wvmvpf-paren** | `analysis/code/G5_…bL_and_bS.R:773, 777` | MINOR | WVMVPF_L/S welfare factor multiplies only `CNTRF`, not `(MECH−CNTRF)` (inconsistent with the WE_L/WE_S rows above). **Non-load-bearing:** the `dt_results` holding WVMVPF is never persisted — it reaches no output/deck (the headline WMVPF comes from I6). | FLAG (low priority) |
| **i4-discount** | `analysis/code/I4_…freq.R:201/203/205 vs 209` | MAJOR | Cost discounts by `/(1.005^3)^t`, welfare by `0.995^(3t)`; `1/1.005 = 0.995025 ≠ 0.995`. (Same asymmetry in I6 PART 1.) | FLAG |
| **h2-vs-h3** | `H2_policy_elasticity_MW.R:482, 484-492` vs `H3_policy_elasticity.R` | MAJOR | `CLAUDE.md` designates **H3** the canonical H stage, but **H2** is the live one: it writes `H2_table_results*.csv` (read by I4/I6) + the deck's elasticity figures, while H3 is full-only/figures-only/on-no-master. Per Arthur: H2 is the real one — reconcile the `CLAUDE.md` label. | FLAG |
| **O11-uvf-split** | `config/paths.R:31-34` | MINOR | Full-data **build** root `U:/…` ≠ full-data **analysis** root `F:/…`. Centralized as `FULL_BUILD_ROOT`/`FULL_ANALYSIS_ROOT`; reconcile on the server. | FLAG |
| **manifest-benegits-typo** | `presentation/figures_central_folder/manifest.csv:56-65` | MINOR | G5 rows carry the `benegits` misspelling — must stay **byte-matched** to G5's `ggsave` names (collector copies by exact filename). A naming constraint, **not** a fixable bug: do not "fix" it or the deck silently drops the figure. | FLAG (leave as-is) |

## Fixed after the restructure — ECONOMETRIC (per RA instruction; needs professor review)

- **i4-g4h2** — **FIXED 2026-07-11** (per Arthur, explicit instruction). I4 now reads the **suffix-aware**
  G4/H2 (`I4:130,132`) — the `_sample` tables the G4/H2 stages regenerate in-repo — exactly like I6,
  instead of the full-data no-suffix tables. (Previously, in sample mode I4 mixed sample claim-counts with
  full-data benefits/taxes.)
  - **Moves a reported number:** I4 sample `WMVPF_actual` **0.2126 → 0.2106** (welfare lastrow
    463.06M → 438.08M; net_cost 1.899B → 1.925B). **I6 unaffected** (already suffix-aware:
    0.2126 / bL 1.5591 / bS −2.4306). Deck **content-identical** (I4's table/plot are not in the deck —
    verified by a footer-masked deck diff: 141/142 pages identical, the 1 diff is the title-slide date).
  - **Cascade:** the sample run's external prereqs collapse to **F5 only** (`analysis_all.R` gate simplified;
    G4/H2 are now produced in-repo). The `g-f5` flag stays open — F5 has no sample producer.
  - **NEEDS PROFESSOR REVIEW** — this is normally a flag-not-fix item; done on the RA's explicit call. The
    golden-baseline I4 pins (`quality_reports/baseline/baseline_numbers.csv`) now intentionally predate this
    and should be re-baselined if the fix is accepted.

## Plumbing fixes applied during the restructure (record — IO only, never econ)

- **O1** — gabriel→pure `/tmp` hand-off routed to `PATHS$analysis_temp` (persistent), consistent on both sides.
- **update_deck-hardpath** — hardcoded OneDrive dir → `PENSION_SAMPLE_ROOT` env.
- Removed every `setwd`; routed all I/O through `config/paths.R`; repathed `collector.py` for the new layout.
- **FINDING-1** (Stage 3) — 30 relative `ggsave` paths in `pure.R` → `PATHS$output_new_counter`; parity re-confirmed.

## Provenance

Verified 2026-06-23. Companions: [`legacy_bugs.md`](legacy_bugs.md) (non-workflow + closed bugs),
`_docs/restructure/MAP_after.md`, `quality_reports/restructure_parity.md`, `guides/RESTRUCTURE_EXPLAINER.html`.
The post-restructure usage audit (archival of 11 superseded `analysis/code` files → `legacy/superseded/`) is recorded in
`MAP_after.md` + the session log.
