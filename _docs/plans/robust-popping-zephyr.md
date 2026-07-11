# Plan: Relocate pipeline outputs into a repo-internal `analysis/output/`

**Status:** ✅ EXECUTED & VERIFIED (plumbing-only) — awaiting user review of before/after decks; NOT committed
**Branch:** `code-and-data` (never touch `main`)
**Date:** 2026-07-09

**Result:** Sample pipeline rerun end-to-end. Outputs now land in-repo (`analysis/output`). BEFORE vs AFTER
deck = **142/142 pages pixel-identical, 0 changed**. WMVPF_actual = 0.2126 (unchanged); regenerated G4/H2
`_sample` tables **byte-identical** to the external originals; I4/I6 tables byte-identical. Git shows only
the 12 intended code/doc edits — **no confidential CSV/PDF staged**; `analysis/output` gitignored.
Before/after PDFs: `paper/_relocation_check/deck_{BEFORE,AFTER}.pdf` (gitignored).

---

## Context

Today the pipeline writes ALL outputs (figures, tables, temp) into an **external data root**
(`DATA_ROOT` = the OneDrive `transfer_may_retirement` folder in sample mode, `F:/…` in full mode).
The presentation layer, which is built *inside* the repo, therefore has to reach *outside* the repo
to collect figures. The user wants the figure handoff to be **self-sustaining**: every output lands in
one **repo-internal** folder (`analysis/output/`, gitignored so it never pollutes git but is fully
regenerable), so the deck reads figures from a single in-repo location. **Data INPUTS stay external**
(the confidential 5% sample CSVs and the full-data build intermediates are not touched).

Nothing confidential should enter git. Investigation established the split cleanly (see
"Prerequisite tables" below): the figure PDFs and the two `_sample` prereq tables are safe; the three
**full-data-derived** aggregate tables must stay gitignored.

### Design goals (unchanged from the restructure)
Safe (a move never silently changes a number) · Clear (run order legible from the tree) ·
Reproducible (one command per phase) · Portable (no machine-specific paths in stage code).

### Decisions already taken (user)
- **Scope = plumbing-only.** Relocate outputs + regenerate G4/H2; F5 + full-data G4/H2 read as external
  inputs. No number-changing work (i4-g4h2 fix + sample-F5 producer deferred) so before/after slides
  should be identical.
- **Both modes** write outputs in-repo (sample AND full/server). *(Full-mode = static-check only from here.)*
- **Modernize G4/H2 now**; defer the 10 build scripts (A1–D3) + I7b to a follow-up.
- **Regenerate prereqs from the pipeline** wherever the sample can (G4/H2); read the rest as external
  inputs. No `stage_seeds` copy step, nothing confidential committed (see §2).
- **Verify by before/after slide comparison** — rerun the whole sample analysis + rebuild the deck, and
  diff the deck against a pre-change snapshot (see Verification).

---

## What changes

### 1. Keystone — `config/paths.R` (the only file that relocates the writes)
Because every canonical stage already writes via `file.path(PATHS$output_*, …)`, repointing the keys
relocates all of E4/gabriel/pure/G5/I4/I6 with **zero stage-script edits**.

- Add, after the `DATA_ROOT` block (~line 58):
  ```r
  REPO_OUTPUT <- file.path(PROJECT_ROOT, "analysis", "output")   # in-repo, gitignored, regenerable
  REPO_TEMP   <- file.path(PROJECT_ROOT, "analysis", "temp")
  ```
- Repoint the `.out()` helper (line 61) to resolve under `REPO_OUTPUT` instead of `DATA_ROOT`.
  This cascades to `output_E/F/G/H/I` and `output_new_counter` (lines 74–79).
- Repoint `analysis_output` (73) → `REPO_OUTPUT`, `analysis_temp` (80) → `REPO_TEMP`.
- **Leave unchanged (inputs):** `DATA_ROOT`, `sample_data`, `extra`, `build_working`/`build_output`/
  `build_temp`, and the whole `DATA_MODE` resolution. Inputs stay external; only outputs move.
- Mode-independent: `REPO_OUTPUT` is the same in both modes (that is the point).

### 2. Prerequisite tables — regenerate what the sample can, read the rest as external inputs
The pipeline needs five prereq tables. **Correction to the earlier "stage_seeds" idea:** only two can
be regenerated from the sample; the other three cannot, so nothing "regenerates all five."

| File | Regenerable on sample? | Handling |
|---|---|---|
| `G4_table_results_sample.csv` | ✅ yes (add G4 to master) | **Produced by the run** (§3 modernization) |
| `H2_table_results_sample.csv` | ✅ yes (add H2 to master) | **Produced by the run** |
| `F5_table_results.csv` | ❌ no — legacy/full-data producer only, no `_sample` variant | **External read-only INPUT** |
| `G4_table_results.csv` (no suffix) | ❌ no — full-data | **External read-only INPUT** (I4 via `i4-g4h2`) |
| `H2_table_results.csv` (no suffix) | ❌ no — full-data | **External read-only INPUT** (I4 via `i4-g4h2`) |

- **Regenerated (G4/H2 `_sample`):** add `G4`/`H2` to `analysis_all.R` *before* I4/I6 so the run
  produces them into `PATHS$output_G/H` (repo-internal). Requires the §3 path-modernization.
- **External inputs (F5 + the two no-suffix full-data tables):** these are genuinely INPUTS to the
  sample analysis (derived from the confidential full data). Read them from the external
  `DATA_ROOT/output/{F,G,H}` — where they already live — via **dedicated input-path keys** in
  `paths.R` (e.g. `PATHS$prereq_root <- file.path(DATA_ROOT, "output")`), kept separate from the
  relocated in-repo `output_*` write keys. Point the four reader lines at them: gabriel (`:72,:178`),
  pure (`:56`) for F5; I4 (`:127,:129`) for full G4/H2. Nothing confidential is committed; no copy step.
- The **existing prereq gate** (`analysis_all.R:13–28`) stays — it fails loud if F5 / the full-data
  tables are absent from the external root, and now also confirms G4/H2 `_sample` were produced.

> Consistent with the whole design: **outputs → in-repo; inputs (incl. F5 and the full-data tables) →
> external.** Making F5 regenerable (a sample-F5 producer) or removing I4's full-data dependency
> (fixing `i4-g4h2`) are number-changing and left as follow-ups (see "Out of scope").

### 3. Modernize G4 and H2 path handling (chosen scope)
`G4_effect_average_benefit_freq.R` and `H2_policy_elasticity_MW.R` still use `setwd(dir)` + relative
`'output/…'` writes, so they would *not* follow the `paths.R` relocation.
- Remove `setwd()`; source `config/paths.R`; route their writes through `PATHS$output_G` / `PATHS$output_H`.
- **Path plumbing only — no estimation logic touched.** Verify by re-running on the sample and diffing
  the produced `G4_/H2_…_sample.csv` byte-for-byte against the current external copies.
- Defer A1–D3 (build, server-only) and I7b (diagnostic) to a separate follow-up.

### 4. Collector + deck (mostly already wired)
- `collector.py` already rewrites manifest `trans_retirement/output/…` → `analysis/output/…` for its
  "repo" root (`_strip_repo_prefix`, lines 69–70). **No collector edit.**
- Deck `\graphicspath` already searches `from_code/` + `static/`. **No `.tex` or `manifest.csv` edit.**
  (Monstrous code-output names are kept exactly, per user.)
- `presentation/build_deck.R` (lines 18–20): **drop the `--sample-root` argument** — with outputs
  always in-repo, the collector reads `analysis/output/` directly.

### 5. Golden-baseline parity harness
`quality_reports/baseline/stage3_recompute.py` reads outputs from the external root via its `EXT`
variable (~line 24). **Repoint `EXT` to the repo `analysis/output/`** so parity re-checks the new
location. (Numbers must still match — content is identical, only the path changed.)

### 6. `.gitignore` + scaffolding
- Keep `analysis/output/*` and `analysis/temp/*` ignored (with `.gitkeep`). Create the `E/F/G/H/I/
  new_counter_claiming` subdirs (via `.gitkeep` or the stage `dir.create`s).
- Add `analysis/seeds/` as a **tracked** dir; ignore the three full-data filenames within it if they
  are ever copied there locally (belt-and-suspenders against an accidental `git add`).

### 7. Docs sync (standing habit)
Update to "outputs are repo-internal in both modes; inputs remain external":
`CLAUDE.md` (the "stage I/O lives in the external sample root" line) · `_docs/restructure/MAP_after.md`
(§4 figure→deck flow) · `guides/RESTRUCTURE_EXPLAINER.html` · `guides/HOW_TO_RUN_THE_FULL_PROJECT.html`
· note the parity-harness repoint in `quality_reports/restructure_parity.md`.

---

## Explicitly OUT of scope (noted follow-ups)
- **`i4-g4h2` fix** (make I4 read `_sample` like I6). Would let a bare clone run I4 too, but it *shifts
  I4's sample numbers* → methodology call for the professors. Left flagged.
- **A sample F5 producer** (would make F5 regenerable). Big; legacy F is full-data only.
- **Modernizing A1–D3 + I7b** (server-only; static-check only).
- **Committing the full-data trio** (would need data-owner sign-off; deliberately avoided by gitignoring).

---

## Verification (sample, end-to-end)

### Before/after slide comparison (user-requested — the primary acceptance check)
The whole point is to prove the relocation changed **no slides**. So, bracketing the change:
0. **BEFORE** — *before any edit*, run the current pipeline + deck on the sample and save the compiled
   deck aside as `_main_BEFORE.pdf` (and snapshot the `from_code/` figures).
6. **AFTER** — after the change, rerun the FULL analysis (`analysis_all.R`, now regenerating G4/H2 and
   everything downstream) + `build_deck.R`; save `_main_AFTER.pdf`.
7. **COMPARE** — run `presentation/figures_central_folder/deck_compare.py` (BEFORE vs AFTER) for an
   automated page-by-page diff, AND hand both PDFs to the user for manual side-by-side review.
   **Expectation: identical.** Any page that differs is a real finding to resolve *before* committing.

### Mechanical checks
1. `Rscript analysis/analysis_all.R` → EXIT 0; confirm outputs now appear under **`analysis/output/{E,F,G,H,I,new_counter_claiming}`** (and nothing new written to the external root).
2. `Rscript presentation/build_deck.R` → collector routes via the repo root; `verify_deck.py` all includes resolve; deck compiles (~142 pages).
3. **Parity:** figure hashes + `I4_/I6_` table numbers match the golden baseline (`quality_reports/baseline/`) — content unchanged, only location moved. WMVPF_actual and η identical.
4. `git status` shows ONLY the intended tracked additions (code/doc edits) — **no confidential CSV staged**. Grep the diff for `F5_table_results.csv`, `G4_table_results.csv`, `H2_table_results.csv` (no suffix) to be sure.
5. G4/H2 modernization: the regenerated `_sample` tables should match the pre-change external copies byte-for-byte (if they differ, the pre-supplied ones were stale — surface it, it may explain any slide diff).

---

## Multi-agent execution decomposition
**Phase 1 — serial keystone (one careful pass, main loop):** `config/paths.R` repoint · `analysis_all.R`
`stage_seeds()` + gate · `analysis/seeds/` (dirs, README, 2 tracked CSVs) · `.gitignore` · `build_deck.R`
`--sample-root` drop · parity-harness `EXT` repoint. *(Tightly coupled — not parallelized.)*
→ **barrier**
**Phase 2 — parallel fan-out:**
- G4 path-modernization (1 agent) ‖ H2 path-modernization (1 agent) — different files, no conflict.
- Docs sync — 1 agent per doc (CLAUDE.md, MAP_after.md, the two guides HTML).
→ **barrier**
**Phase 3 — serial verification agent:** run the sample master + `build_deck.R`; confirm outputs land
in `analysis/output/`; deck compiles; parity matches baseline; `git status` clean of confidential files.

---

## Risks / tripwires
- **Silent parity break:** if a stage were missed and still wrote external, the deck could pull a stale
  figure. Verification step 1 (grep external root for new writes) catches it.
- **Confidential leak:** an accidental `git add` of the full-data trio. Mitigated by gitignoring those
  filenames + verification step 4.
- **Seed-copy overwrites a fresh run:** `stage_seeds()` must be *fill-if-absent*, never clobber.
- **`clear_dirs`:** keep clearing only `analysis_temp` — never `analysis/output` (holds the staged seeds).
