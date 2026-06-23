# Restructure Findings — bugs FLAGGED (never silently fixed)

Econometric/methodology issues are **flagged, not fixed** (CLAUDE.md). Plumbing/IO is repathed.
Each flag: `id · file:line · severity · description · disposition`. Stage-2 agents append per-file confirmations below.

## Confirmed real flags (from Stage-0 cartography; file:line verified)

| id | file:line | sev | description | disposition |
|----|-----------|-----|-------------|-------------|
| **O5b-wvmvpf-paren** | `analysis/code/G5_…bL_and_bS.R:780,784` | MAJOR | WVMVPF_L/S welfare factor multiplies only `CNTRF`, not `(MECH−CNTRF)`; inconsistent with WE_L/WE_S (L779/783). G5's WVMVPF is **not persisted** (headline WMVPF comes from I6), so no downstream numeric impact today. | FLAG — professor review |
| **g5-d1** | `analysis/code/G5_…bL_and_bS.R:41` | MAJOR | Full-mode reads `working/D1_cross_section.csv.gz` while peers (D4/E4/H3/I4/I6) read D3. Explicit `[TODO:FUTURE]` L38-40. Sample mode sidesteps via `data/dt_sampled_anon`. | FLAG — professor review |
| **g-f5** | `analysis/code/new_counterfactual_claiming3_gabriel.R:83,189` | MAJOR | New-F producer reads **legacy** `output/F/F5_table_results.csv` (no suffix). Live dependency on a quarantined-strategy output. | FLAG — professor review |
| **i4-g4h2** | `analysis/code/I4_wmvpf_no_pure_reforms_freq.R:134,136` | MAJOR | Reads `G4_table_results.csv` + `H2_table_results.csv` (non-canonical G4/H2, not G5/H3) **with no `_sample` suffix** even in sample mode. I6 reads the same tables but suffix-aware. | FLAG — professor review |
| **i4-discount** | `analysis/code/I4_…freq.R:208,210,212 vs 216` | MAJOR | Cost discounts by `/(1.005^3)^t`, welfare by `0.995^(3t)`; `1/1.005=0.995025 ≠ 0.995` → asymmetric ratio. Persists in I6 PART1 (L299/307); refactored out in I6 PART2. | FLAG — harmonize (professor) |
| **h3-nosample** | `analysis/code/H3_policy_elasticity.R:14,19,20` | MAJOR | No `dir.exists()`/SUFFIX; unconditional `.libPaths('F:/…')` + `dir<-'U:/…'` + `setwd`; uses `indiv` (no `cpf_anon`). Full/server-only → excluded from sample parity. Path-centralization is in-scope; adding a sample branch is NOT (a feature). | FLAG + repath full-mode paths only |
| **O11-uvf-split** | `build/code/*` vs `analysis/code/G5,I4,I6` | MINOR | Build scripts use `U:/Documents/Paper/directory_2025`; analysis full-mode uses `F:/…/directory_2025`. Centralized in `config/paths.R` as two roots; reconciliation is a server decision. | FLAG — professor review |
| **manifest-benegits-typo** | `presentation/figures_central_folder/manifest.csv` (G5 rows) | MINOR | `G4_eventstudy_benegits_*` misspelling must stay **byte-matched** to G5's ggsave names — collector copies by exact filename. **Do NOT "fix"** or the collector silently drops the figure. | FLAG — leave as-is (intentional) |
| **apresentacao-graphicspath** | `presentation/latex/apresentacao/_main.tex:3` | MINOR | PT deck uses `\graphicspath{{../figures/}}`, off the collector/manifest pipeline → same E3_/F4_ names can resolve to stale legacy images vs the canonical from_code/ ones. Not covered by verify_deck.py. | FLAG — PT deck out of parity scope |

## Plumbing fixes APPLIED in Stage 2 (IO/portability only — never econ)

| id | file | change |
|----|------|--------|
| O1-tmp-handoff | gabriel/pure | route the `tmp/` fallback hand-off to `PATHS$analysis_temp` (persistent), keep the persistent primary path |
| update_deck-hardpath | update_deck.py:44 | hardcoded OneDrive sample dir → `PENSION_SAMPLE_ROOT` env / config |
| setwd/absolute-paths | all stage scripts | remove every `setwd`; route I/O through `PATHS`; `source(config/paths.R)+constants.R` |
| collector source dirs | collector.py | repath repo-side figure sources to the new `presentation/`/`build`/`analysis` layout |

## Investigated and NOT bugs (the open-issues list was partly stale)

| id | finding |
|----|---------|
| **O3** (D4 stray `)`) | **FALSE POSITIVE** — `build/code/D4_create_panel.R` L245 `by='indiv') %>%` closes the L237 join; parens balance; file parses. |
| **O5a** (G5 MECH `claims_L/S`) | **NOT PRESENT** — MECH (G5:618-620) uses `claims_c` correctly; the `claims_L/S` at L725-727 is the *behavioral* term (correct). |
| **O5c** (G5 `delta_ben` ×3 from G2) | **ALREADY FIXED** — G2 import removed (G5:737-738); `delta_ben` now PV from G5's own `dt_agg` (L739-749). |

---
*Seeded from Stage-0 (`baseline/MAP_before.md`, `baseline/dependency_graph.md`). Stage-2 per-file confirmations appended below.*

## Stage-2 per-file confirmations

**Analysis (parity-critical: E4, gabriel, pure, G5, I4, I6; + H3 full-only, I7 diagnostic):** `setwd` removed (0
remaining); `source(config/paths.R)+constants.R` added; every bare-relative I/O routed through `PATHS$*`; all parse OK.
- **O1 hand-off fixed (plumbing):** gabriel writes `PATHS$analysis_temp` (L295) + `PATHS$output_new_counter/actual_reform_gabriel` (L296);
  pure reads persistent-first (L125) then the temp fallback (L127) — same `PATHS` keys both sides; `/tmp` fragility gone.
- **Parity-guarded constant substitution** (identical values): `P_BAR_*`, `RR_INTERCEPT/SLOPE_*`, `GAMMA_BASELINE`, `CONS_INSS/POP`, `ETA`
  (G5: 11 refs, I6: 13, I4: 3). **`i4-discount` literals `1.005`/`0.995` left VERBATIM** (6 occurrences in I4) — flagged, not fixed.
- **H3:** `setwd` removed, `DATA_MODE != "full"` guard added, `working/` → `PATHS$build_working`; remains full-only (flag `h3-nosample`).

**Build (A4, B4, C6, D4) + aux:** `setwd` removed; full-only guard (`stop()` unless `DATA_MODE=full`); `working/extra/output` →
`PATHS$build_*`. Static-checked (full-data only; not parity-tested). `O11` U:/-vs-F:/ split centralized in `config/paths.R`, flagged.

**Presentation `.py` (collector, update_deck, verify_deck, deck_compare):** repathed for the new layout (extra `presentation/`
level): repo-root refs now hop two dirs up; `latex/presentation` → `presentation/latex/presentation`; `latex/figures` →
`presentation/latex/figures`. The load-bearing `--sample-root` resolution (newest-of {sample,repo}, sample-label strip) is
**byte-preserved**. `manifest.csv` NOT edited — instead `collector._strip_repo_prefix` translates the legacy `trans_retirement/output`
prefix → `analysis/output` at resolve time (note: if the manifest is ever regenerated to `analysis/output`, that branch becomes a
harmless no-op). All 4 `python -m py_compile` clean.
- **Caught during recovery:** the ESC-interrupted run had left `update_deck.py` with a dangling unused `import os` and the
  OneDrive sample dir still hardcoded; completed to `os.environ.get("PENSION_SAMPLE_ROOT", <literal>)`. (`update_deck-hardpath` resolved.)

**LaTeX:** EN deck `presentation/latex/presentation/_main.tex:3` `\graphicspath{{../../figures_central_folder/from_code/}{…/static/}}`
**INTACT, no edit** (latex/ + figures_central_folder/ moved together → `../../` offset preserved). PT deck `apresentacao` graphicspath
flagged (`apresentacao-graphicspath`), unchanged.

> Static-check only this stage; **Stage 3 re-runs the pipeline on the 5% sample to prove figure+number parity vs `baseline/`.**
> Note: ESC interrupted the first Stage-2 batch after 13/14 units (committed `1ea2dd8`); a focused recovery workflow finished the
> presentation `.py` tools (committed in part-2).

---

## Post-restructure usage audit (2026-06-23)

A 2-agent audit traced every file's output consumers to classify `build/code/` and `analysis/code/` as
canonical / live-dependency / lineage-upstream / manual-diagnostic / dead-superseded.

**New flag:**

| id | file:line | sev | description | disposition |
|----|-----------|-----|-------------|-------------|
| **h2-vs-h3** | `analysis/code/H3_policy_elasticity.R` vs `H2_policy_elasticity_MW.R` | MAJOR | `CLAUDE.md` designates **H3** the canonical H stage, but in practice **H2** is the live one: H2 produces `output/H/H2_table_results*.csv` (read by I4 & I6) **and** the elasticity figure the deck pulls, while H3 is full-data-only (no sample branch), figures-only, and on no master. So the "canonical H" label and the actual data flow disagree. Per Arthur (2026-06-23): **H2 is the real H stage**; reconcile the `CLAUDE.md` designation. H3 kept in place (not archived) pending that call. | FLAG — professor/Arthur decision |

**Archival (not a bug — a cleanliness fix, approved by Arthur):** 11 confirmed-dead version-predecessors in `analysis/code/`
(`E1 E2 E3 · G1 G2 G3 · H1 · I1 I2 I3 · new_counterfactual_claiming2`) were `git mv`'d to `legacy/superseded/` and guarded with
`stop()`. Each was verified to have **no** consumer among the masters, canonical files, or the deck (a closed island of
mutually-referencing dead files). `build/code/` had **zero** dead files (all live lineage / deps) — nothing archived there.
`code/README.md` manifests were added to both `build/code/` and `analysis/code/` so the folders are legible without `CLAUDE.md`.
**Parity unaffected** — none of the moved files is on any master or read by a canonical stage (re-confirmed by sample re-run).
