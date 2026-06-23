# map_PRESENTATION — figures -> deck pipeline

AREA owner: Mapper-PRESENTATION. Read-only cartography.

## Figure-flow overview (the whole point)

```
pipeline code (trans_retirement/output/<stage>/*.pdf)            latex/figures/  (OLD copies,
   AND sample working dir (OneDrive .../transfer_may_retirement/output/...)   diff source only)
                    │  (newest of {sample, repo} wins)                 │
                    ▼                                                  │
        collector.py  ──reads manifest.csv, copies+renames──►  figures_central_folder/from_code/<deck_name>
        (6 NONE rows verified to already sit in)            ──►  figures_central_folder/static/<deck_name>
                    │                                                  ▲
                    ▼  (_diffs/ side-by-side E3 vs E4)                  │
        latex/presentation/_main.tex
            \graphicspath{{../../figures_central_folder/from_code/}{../../figures_central_folder/static/}}
                    │  latexmk -g -pdf
                    ▼
        latex/presentation/_main.pdf   (the compiled English deck)

   latex/apresentacao/_main.tex  ── \graphicspath{{../figures/}} ──►  latex/figures/  (Portuguese deck;
                                                                      NOT fed by collector/manifest)
```

Source-of-truth chain: a generating R stage writes a PDF -> manifest.csv row maps that code output to a
deck filename -> collector.py copies/renames it into `from_code/` -> the deck's `\graphicspath` resolves
the name. `update_deck.py` is the one-shot driver (run stage -> collect -> compile).

---

## figures_central_folder/collector.py
- LANG: Python 3
- PURPOSE: Route pipeline figure outputs into `from_code/` per manifest.csv (copy + rename); render E3->E4 visual diffs; verify NONE rows already in `static/`; emit a summary and exit nonzero on any unresolved routable row.
- INPUTS:
  - `figures_central_folder/manifest.csv` (default `--manifest`; HERE/manifest.csv).
  - For each non-NONE row, the code output at `<root>/<code_output_path>/<code_output_name>`, resolved across roots = the NEWEST existing of:
    * SAMPLE root (only when `--sample-root` given): `<sample_root>/<relpath with leading 'trans_retirement/' stripped>` — i.e. `<sample_root>/output/<stage>/...` and `<sample_root>/output/new_counter_claiming/...`. Sample root passed by update_deck.py = `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement`.
    * REPO root (always): `<repo>/trans_retirement/output/<stage>/<name>`.
  - UPSTREAM-CANONICAL rows: first tries the `prefer=` path (pure F-new output under `trans_retirement/output/new_counter_claiming/...`), falls back to the primary gabriel path.
  - For diffs: OLD = `latex/figures/<deck_name>` (`LATEX_FIGURES = ROOT/latex/figures`); NEW = the just-resolved primary source. Uses PyMuPDF (`import fitz`).
  - NONE rows: checks `static/<deck_name>` exists (does not read content).
- OUTPUTS:
  - `figures_central_folder/from_code/<deck_name>` via `shutil.copy2` (line 187) for each resolved non-NONE row.
  - `figures_central_folder/_diffs/<stem>__OLD-E3_vs_NEW-E4.pdf` via PyMuPDF `out.save` (line 117 in make_side_by_side, invoked ~line 212) for rows tagged `diff=E3->E4`.
  - Deletes a stale `from_code/<deck_name>` when the row is NONE (line 166 `stale.unlink()`) so static/ is not shadowed.
  - stdout summary table only; process exit 1 on missing/static_missing.
- DEP-EDGES:
  - CONSUMES the OUTPUT of stages E4 (output/E), G5 (output/G), H2 legacy (output/H), I6 (output/I), F-new pure + gabriel (output/new_counter_claiming), per manifest.
  - ITS OUTPUT (`from_code/`) is consumed by `latex/presentation/_main.tex` (via \graphicspath) and validated by `verify_deck.py`.
- FRAGILE-PATHS:
  - `HERE = Path(__file__).resolve().parent` (line 33), `ROOT = HERE.parent` (34) — relies on script living at `<repo>/figures_central_folder/`.
  - `LATEX_FIGURES = ROOT/"latex"/"figures"` (39) — hardcoded OLD-diff source.
  - `import fitz` (PyMuPDF) lazy imports (82, 94, 207) — optional dep; diffs skipped if absent.
  - The `_strip_repo_prefix` (56-62) only strips literal leading `trans_retirement/` for the `"sample"` label — coupling to that exact prefix.
  - No absolute literals inside collector.py itself; the absolute sample root is injected from update_deck.py (see below).

## figures_central_folder/update_deck.py
- LANG: Python 3
- PURPOSE: One-command refresh: (1) optionally `Rscript` one or more pipeline stages, (2) run collector.py, (3) `latexmk` rebuild the deck.
- INPUTS:
  - Stage scripts under `ROOT/trans_retirement/code/` via the STAGES map (lines 33-40): E4, G5, H2 (`H2_policy_elasticity_MW.R`), F (`new_counterfactual_claiming3_pure.R`), Fg (`new_counterfactual_claiming3_gabriel.R`), I6 (`I6_wmvpf_with_pure_reforms_freq.R`). A bare path arg is also accepted.
  - Sample root auto-detected from `SAMPLE_DIR_CANDIDATES` (lines 43-45) = `["C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement"]`, overridable by `--sample-root`.
  - `latex/presentation/_main.log` read back (line 106) to count `"not found"` figure errors.
- OUTPUTS:
  - Side effects only: runs `Rscript <script>` (cwd=ROOT), `python collector.py --sample-root <root>`, `latexmk -g -pdf -interaction=nonstopmode _main.tex` (cwd=`latex/presentation`).
  - Final artifact = `latex/presentation/_main.pdf` (rebuilt by latexmk).
- DEP-EDGES: orchestrates the whole figures->deck chain; consumes nothing's output directly, drives collector + compile.
- FRAGILE-PATHS:
  - `ROOT = Path(__file__).resolve().parent.parent` (28); `CODE`, `DECK_DIR` derived from it.
  - HARDCODED ABSOLUTE sample dir `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement` (line 44) — machine-specific; OneDrive path.
  - Assumes `Rscript`, `latexmk`, `python` (via `sys.executable` for collector) on PATH.
  - `subprocess.run(cmd, cwd=DECK_DIR)` for latexmk — depends on cwd being the deck dir so `_main.tex` and relative `\graphicspath` resolve.

## figures_central_folder/verify_deck.py
- LANG: Python 3
- PURPOSE: Read-only check that every active (non-commented) `\includegraphics{...}` in the ENGLISH deck resolves under `from_code/` or `static/`. Exit 1 listing unresolved names.
- INPUTS:
  - `latex/presentation/_main.tex` (`DECK`, line 14). Strips `%`-comments (COMMENT regex line 18) before matching `\includegraphics[..]{name}` (INCLUDE regex line 19).
  - Existence checks against `figures_central_folder/from_code/` and `figures_central_folder/static/`.
- OUTPUTS: stdout report only; no files written.
- DEP-EDGES: consumes collector.py's `from_code/` output + manual `static/`; validates the deck's figure references. Reusable for Stage-3 parity (deck-reference resolvability check).
- FRAGILE-PATHS:
  - `ROOT = Path(__file__).resolve().parent.parent` (13); DECK/FROM_CODE/STATIC hardcoded under it.
  - ONLY checks `latex/presentation/_main.tex` — the Portuguese `apresentacao/_main.tex` is NOT verified.

## figures_central_folder/deck_compare.py
- LANG: Python 3
- PURPOSE: Page-by-page pixel diff of two compiled deck PDFs (OLD vs NEW); writes a side-by-side PDF of only the changed pages + console report.
- INPUTS:
  - `sys.argv[1]` OLD.pdf, `sys.argv[2]` NEW.pdf, `sys.argv[3]` OUTDIR (line 67). Requires PyMuPDF (`import fitz`, hard import line 19); numpy optional (HAVE_NP).
- OUTPUTS:
  - `<OUTDIR>/deck_changes_OLD_vs_NEW.pdf` (line 97-98) when any page differs.
  - stdout report (pages compared / identical / changed with diff %).
- DEP-EDGES: standalone QA tool; not in the auto loop. Reusable for Stage-3 deck parity (OLD vs NEW _main.pdf).
- FRAGILE-PATHS:
  - Hard `import fitz` at module top (19) — fails immediately if PyMuPDF absent (unlike collector's lazy import).
  - `TOL_BYTE=16`, `CHANGED_FRAC=0.001`, `ZOOM=2.0` (27-29) tunables.
  - The side_by_side labels hardcode "OLD (latex/figures)" / "NEW (figures_central_folder)" (lines 56-57) — assumes that comparison framing.

## figures_central_folder/manifest.csv
- LANG: CSV (data, not code)
- PURPOSE: The single routing table collector.py reads. One row per deck figure: how to find its code output and what to rename it to.
- COLUMNS (header line 1):
  `deck_name` (filename the deck's \includegraphics expects, i.e. dest under from_code/ or static/),
  `code_script` (producing R script, informational / used for LEGACY warning text),
  `code_output_path` (dir under the chosen root, e.g. `trans_retirement/output/E`),
  `code_output_name` (source filename to copy),
  `status` (OK | OK-RENAME | UPSTREAM-CANONICAL | LEGACY | NONE — drives routing),
  `mode` (any | sample | full | n/a — `sample` triggers the SAMPLE warning),
  `notes` (free text; also carries machine directives `prefer=...` and `diff=E3->E4`).
- ROW COUNTS: 66 non-NONE routable rows + 6 NONE (static) rows = 72 data rows. Confirmed 1:1: all 66 from_code files correspond to the 66 non-NONE rows (no orphans, no missing); the 6 NONE deck_names live in static/, none leak into from_code/.
- EXAMPLE source->dest mappings:
  * OK-RENAME: `output/E/E4_claiming_density.pdf` -> `from_code/E3_claiming_density.pdf` (canonical E4 output kept under legacy E3 deck name; `diff=E3->E4`).
  * OK: `output/E/E4_pension_schedule_men.pdf` -> `from_code/E4_pension_schedule_men.pdf` (name unchanged).
  * OK-RENAME: `output/new_counter_claiming/new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2015_Q2.pdf` -> `from_code/frequenciesLQ0.pdf` (pure-LEVEL freq; known caption off-by-one, declared out of scope).
  * UPSTREAM-CANONICAL: prefer `new_counterfactual_claiming3_pure_actual_reform_claiming_frequency_quarterly_tag0.pdf` else gabriel `actual_reform_gabriel/claims_distribution_actual_count_0.pdf` -> `from_code/frequenciesQ0.pdf`.
  * OK-RENAME (G5): `output/G/G4_eventstudy_benegits_old_1.pdf` -> `from_code/old-12.pdf` (note: source NAME is `G4_`-prefixed and contains the literal typo `benegits` — G5 re-saves these G4-named panels).
  * LEGACY: `output/H/H2_dd_tax_collection_1_sample.pdf` -> `from_code/H2_dd_tax_collection_1.pdf` (legacy H2; canonical H3 emits no DD-tax fig).
  * OK (sample): `output/new_counter_claiming/actual_reform_gabriel/claiming_hazard_eventstudy_1_sample.pdf` -> `from_code/F4_eventstudy_agg_1.pdf` (event-study block added to gabriel.R 2026-06-12; sample-suffixed).
  * OK (sample, I6): `output/I/I6_plot_cumsum_actual_reform_multby20_sample.pdf` -> same name in from_code/.
  * NONE (static, no code): `static/image37.png`, `static/schedule_women_new.pdf`, `static/schedule_men_new.pdf`, `static/plot_expenditures_groups.pdf`, `static/ELSI.jpg`, `static/morRef2The.png`.

### Which from_code figures are CODE-produced vs static/orphan
- CODE-produced (have a producing stage in manifest): all 66 from_code/*.pdf. By family:
  E3_*/E4_pension_schedule_* (E4.R); frequenciesLQ0-12 + frequenciesSQ0-12 (F-new pure.R); frequenciesQ-3..Q12 (F gabriel/pure); F4_eventstudy_agg_1..5 (gabriel.R, SAMPLE); old{-12,-3,0,4,13} + new{-12,-3,0,4,13} (G5.R); H2_dd_tax_collection_1 (LEGACY H2, sample); I6_plot_cumsum_actual_reform_multby20_sample (I6, sample).
- STATIC/orphan (NONE, no producing code — manual/external): image37.png, schedule_women_new.pdf, schedule_men_new.pdf, plot_expenditures_groups.pdf, ELSI.jpg, morRef2The.png. These live ONLY in static/.

## latex/presentation/_main.tex  (ENGLISH deck — the one wired to the central folder)
- LANG: LaTeX (Beamer)
- PURPOSE: The canonical English presentation; compiled to `_main.pdf`.
- INPUTS / KEY DIRECTIVES:
  - Line 1: `\input{_preamble.tex}` (the ONLY \input/\include in the deck — relative to the deck dir).
  - Line 3: `\graphicspath{{../../figures_central_folder/from_code/}{../../figures_central_folder/static/}}` — EXACTLY the two central-folder dirs, from_code first (so from_code shadows static on name clash — see collector's stale-unlink guard).
  - ~38 active `\includegraphics` references (frequenciesQ/LQ/SQ families packed into single \only<> lines at 345, 673, 1031). All resolve to from_code/ or static/ deck_names.
  - Tables `Table_MVPF.tex`, `Table_AIMVPF.tex`, `TableNSB.tex`, `Table1_new.tex`, `TableCCTUCTv2.tex` exist in the dir but are NOT \input into _main.tex (deck is figure-only; `\estinput` macro defined in preamble but unused here).
- OUTPUTS: compiled `_main.pdf` (+ aux/log/nav/etc., all gitignored via latex/.gitignore).
- DEP-EDGES: consumes collector's `from_code/` + `static/`. Build entry = `latexmk -g -pdf -interaction=nonstopmode _main.tex` (from update_deck.py, cwd=deck dir). No `.latexmkrc` anywhere in repo (search empty) — relies on default latexmk + system pdflatex.
- FRAGILE-PATHS:
  - `\graphicspath{{../../figures_central_folder/from_code/}{../../figures_central_folder/static/}}` (line 3) — relative `../../`, only correct when compiled from `latex/presentation/`.
  - `\input{_preamble.tex}` (line 1) — relative to deck dir.

## latex/presentation/_preamble.tex
- LANG: LaTeX
- PURPOSE: Beamer class + package + macro definitions for the English deck. No figure paths, no \input/\include of other files.
- INPUTS/OUTPUTS: none (pure macro/package definitions).
- FRAGILE-PATHS: none (defines `\estinput`/`\estwide` table macros but they are unused by _main.tex).

## latex/apresentacao/_main.tex  (PORTUGUESE deck — NOT on the central-folder pipeline)
- LANG: LaTeX (Beamer)
- PURPOSE: Portuguese-language presentation ("Reformas Ótimas da Previdência"). Compiled to its own `_main.pdf`.
- INPUTS / KEY DIRECTIVES:
  - Line 1: `\input{_preamble.tex}` (its own preamble, NOT shared with presentation/).
  - Line 3: `\graphicspath{{../figures/}}` — points at `latex/figures/` (the LEGACY central figure store, 182 files), NOT figures_central_folder. So the collector/manifest pipeline does NOT feed this deck; it draws from latex/figures/ directly.
  - Reuses the same deck_name figures (image37.png, E3_*, F4_*, old*/new*, ELSI.jpg, schedule_*_new.pdf) but resolves them from latex/figures/.
- OUTPUTS: its own `_main.pdf` (+ aux, gitignored).
- DEP-EDGES: depends on `latex/figures/` contents (which are also collector's OLD-E3 diff source). It is NOT verified by verify_deck.py and NOT recompiled by update_deck.py.
- FRAGILE-PATHS:
  - `\graphicspath{{../figures/}}` (line 3) — single legacy dir; divergence risk: English deck pulls canonical E4 (renamed to E3 names) from from_code/, while this deck pulls whatever sits in latex/figures/E3_*.pdf. The two decks can silently show different figures under the same E3 filename.

## latex/apresentacao/_preamble.tex
- LANG: LaTeX
- PURPOSE: Beamer preamble for the Portuguese deck (separate copy from presentation/_preamble.tex).
- FRAGILE-PATHS: none of note (package/macro definitions).

---

## Build entry summary
- English deck: `latexmk -g -pdf -interaction=nonstopmode _main.tex` run with cwd=`latex/presentation/` (update_deck.py line 103). `-g` forces rebuild so frozen/removed figures refresh. No `.latexmkrc` in repo.
- Portuguese deck: no automated build wired; compiled manually (graphicspath `../figures/`).

## Confirmed bugs / fragilities (file:line)
- update_deck.py:44 — hardcoded absolute OneDrive sample dir `C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement` (machine-specific; breaks on any other machine / the post-OneDrive-migration layout).
- latex/apresentacao/_main.tex:3 — `\graphicspath{{../figures/}}` diverges from the English deck's central folder; same E3_* / F4_* filenames can resolve to DIFFERENT (stale legacy) images than the collector-routed canonical ones. Parity hazard, not a hard error.
- manifest.csv:56-65 (G5 rows) — source code_output_name carries the literal misspelling `G4_eventstudy_benegits_old/new_*.pdf` ("benegits"); collector copies by exact name so this must stay byte-matched to G5's ggsave output. Confirmed for every G5 row.
- collector.py:39 + deck_compare.py uses — OLD-diff baseline is `latex/figures/`, the same dir the Portuguese deck still ships from; if latex/figures/ is ever pruned the E3->E4 diffs silently skip (collector reports "old E3 copy missing").
- verify_deck.py:14 — only validates `latex/presentation/_main.tex`; the Portuguese deck's figure references are never checked (no coverage for apresentacao).
