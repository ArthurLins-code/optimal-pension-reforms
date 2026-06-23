# MAP_after.md — Realized cartography of the restructured repo

> Stage-4 re-map of `optimal-pension-reforms` after the functional restructuring.
> Read-only snapshot. Every load-bearing claim below was re-verified against source
> (file:line, grep counts). Companion baseline: `baseline/MAP_before.md`,
> `baseline/dependency_graph.md`. Binding spec: `_docs/restructure/REPO_STRUCTURE_GUIDELINES.md`.

---

## 1. Realized tree (top level + one level into the functional areas)

```
optimal-pension-reforms/
│
├── config/                         # ── PORTABILITY LAYER (new) ──
│   ├── paths.R                     #   single source of truth: PROJECT_ROOT (.here sentinel),
│   │                               #     DATA_MODE (env override → detect → stop), ONE PATHS list,
│   │                               #     run_stage(), clear_dirs()
│   └── constants.R                 #   economic primitives: gamma=4, ETA (derived), RR schedules,
│                                   #     p_bar 85/95, W=4, DiD ref −2, reform cutoff, discount factors
│
├── build/                          # ── DATA CONSTRUCTION (restricted server / full data only) ──
│   ├── code/                       #   A1-A4, B1-B4 (B1-B3 .do), C1-C6 (C3 .do), D1-D4, aux_codes_RAIS/
│   ├── input/                      #   raw SUIBE/RAIS pointers — .gitkept, contents gitignored
│   ├── output/                     #   analysis-ready panel/cross-section — .gitkept, gitignored
│   ├── temp/                       #   intermediates, cleared by master — .gitkept, gitignored
│   └── build_all.R                 #   master: A4 → B4 → C6 → D4 (full-data only; stop() if not full)
│
├── analysis/                       # ── ESTIMATION & RESULTS (runs on 5% sample) ──
│   ├── code/                       #   E1-E4, new_counterfactual_claiming{2,3_gabriel,3_pure},
│   │                               #     G1-G5, H1-H3, I1-I4, I6, I7, I7b, new_counterfactual2
│   ├── input/                      #   link to build/output (the panel) — .gitkept, gitignored
│   ├── output/                     #   figures/tables/estimates — .gitkept, gitignored
│   ├── temp/                       #   intermediates incl. former /tmp hand-off — .gitkept, gitignored
│   └── analysis_all.R              #   master: E4 → gabriel → pure → G5 → I4 → I6 (sample-runnable)
│
├── presentation/                   # ── RESULTS → DECK ──
│   ├── figures_central_folder/     #   collector.py, update_deck.py, verify_deck.py, deck_compare.py,
│   │                               #     manifest.csv, from_code/ (gitignored), static/ (tracked), _diffs/
│   ├── latex/                      #   presentation/ (EN, live build), apresentacao/ (PT), figures/ (legacy)
│   └── build_deck.R                #   master: collector.py → latexmk EN deck → verify_deck.py
│
├── legacy/                         # ── QUARANTINE (each file guarded by loud stop()) ──
│   ├── F1-F7, G6, I5               #   old F method / expenditures G / abandoned-strategy WMVPF
│   ├── old/                        #   B1-B2 Stata predecessors
│   └── README.md                   #   why each file is legacy + archival date
│
├── RUN.R                           # root front door — signpost; dispatches to the three masters
├── .here                           # rprojroot sentinel (existence only; no code reads contents)
├── .gitattributes                  # `* text=auto` + binary rules (kills CRLF/LF phantom diff)
├── config/ build/ analysis/ presentation/ legacy/   (above)
├── _docs/                          # knowledge base, plans, logs, memory, restructure/, doc templates, references/
│     ├── pedro_hc_santanna_templates_for_projects/   # doc templates used by the .claude skills/rules
│     └── references/               # CodeAndData.pdf, transition instructions, meeting-notes PDF
├── baseline/                       # pre-restructure golden baseline + Stage-3 parity artifacts
├── quality_reports/                # specs, reviews, parity reports, restructure_findings + legacy_bugs
├── scripts/                        # quality tooling (quality_score.py)
├── Surrogate Indices/              # future tax-externality work
├── versões do artigo/              # paper drafts + canonical reference decks (gitignored)
└── trans_retirement/               # legacy project namespace (pre-move; superseded by build/analysis)
```

Notes:
- `build/code/` and `analysis/code/` hold the **full version lineage** (A1-A4, …, I1-I7b), not only
  the canonical heads. Highest number = canonical (A4/B4/C6/D4 in build; E4/G5/H3/I4 + I6/I7 in analysis).
  The masters source only the canonical heads.
- `trans_retirement/` still exists at root as the pre-move namespace; the restructure elevated
  `build/` and `analysis/` to the root (the §4 "root-level" option), so `trans_retirement/` is now vestigial.

---

## 2. Portability layer — how every stage resolves paths

**Single mechanism.** Every canonical stage starts with the two-line config preamble (verified in
`A4_balance_check.R:13-14`, `G5_…:17-18`, `I4_…`):

```r
source(here::here("config", "paths.R"))      # PROJECT_ROOT, DATA_MODE, PATHS, run_stage(), clear_dirs()
source(here::here("config", "constants.R"))  # economic primitives
```

**`config/paths.R` (verified):**
- `PROJECT_ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))` — root found via the `.here`
  sentinel, **no `setwd`** (paths.R:22).
- `DATA_MODE` resolved loudly: env `PENSION_DATA_MODE ∈ {full,sample}` → existence detection of
  `SAMPLE_ROOT`/`FULL_*_ROOT` → `stop()` with the roots it looked for (paths.R:37-53). No silent fallback.
- Data roots are env-overridable and defined here **only**: `PENSION_SAMPLE_ROOT`, `PENSION_FULL_ROOT`
  (analysis), `PENSION_FULL_BUILD_ROOT` (build) (paths.R:26-34). Open issue **O11** (U:/ build root vs
  F:/ analysis root) is surfaced in a comment, kept separate, **not silently merged**.
- One `PATHS` list (paths.R:62-100). Keys: `project_root, data_mode, data_root, sample_data,
  build_working, extra, analysis_output, output_E/F/G/H/I, output_new_counter, analysis_temp,
  build_output, build_temp, sample_root, full_analysis_root, full_build_root, figures_central,
  figures_from_code, figures_static, deck_dir, build_code, analysis_code`.
- Helpers: `run_stage(file, code_dir, echo, fresh)` — sources one stage timed + logged, `local=TRUE`
  ("shy functions"), optional fresh R process via `callr` (paths.R:106-120). `clear_dirs(...)` — wipe +
  recreate (paths.R:125-131), with a safety note never to clear a dir holding pre-supplied inputs.

**`setwd()` grep — VERIFIED COUNT:**
- **Canonical build stages (A4, B4, C6, D4): 0 `setwd()`.**
- **Canonical analysis stages (E4, gabriel, pure, G5, H3, I4, I6, I7): 0 `setwd()`.**
- Non-canonical siblings still carry legacy `setwd(paste(dir))` lines (10 in `build/code`: A1-A3,
  C1-C5, D1-D3; 14 in `analysis/code`: E1-E3, G1-G4, H1-H2, I1-I3, I7b, new_counterfactual2). These are
  not on any master's run list and are inventory-only.
- **Legacy: 9 `setwd()` across F1-F7/G6/I5 — quarantined behind the line-1 `stop()` guard, never reached.**

Net: every script the masters actually run is `setwd`-free and resolves paths through `PATHS$*`.

---

## 3. The canonical runnable DAG (sample) + the three masters

**Sample-runnable DAG** (from `analysis/analysis_all.R`, generated from `baseline/dependency_graph.md`):

```
E4 ─(terminal: claiming figures)
gabriel ──► pure ──► G5 ──► I4 ──► I6
   (F counterfactual: claim counts → pure L/S schedules → DD on avg benefits → WMVPF → WMVPF+pure decomp)
```
- **Sample-runnable:** E4, gabriel, pure, G5, I4, I6.
- **Full-only (excluded from the sample master):** A4-D4 (build); **H3** (no sample branch — flag
  `h3-nosample`). I7/I7b are diagnostics, run manually.

**Three masters + front door (verified):**
- **`build/build_all.R`** — `source` config; `stop()` unless `DATA_MODE=='full'`;
  `clear_dirs(build_temp, build_output)`; `run_stage(A4, B4, C6, D4, code_dir=build_code)`.
- **`analysis/analysis_all.R`** — `source` config; `clear_dirs(analysis_temp)` **only** (does NOT wipe
  `analysis_output` — in sample mode it holds pre-supplied prereq tables F5/G4/H2); a **loud prereq
  check** that `stop()`s if `F5/G4/H2` tables are missing (flags `g-f5`, `i4-g4h2`); then
  `run_stage(E4, gabriel, pure, G5, I4, I6)`. H3 explicitly excluded; I7/I7b manual.
- **`presentation/build_deck.R`** — `source` config; (1) `collector.py --sample-root <SAMPLE_ROOT>`,
  (2) `latexmk -cd -g -pdf` on `deck_dir/_main.tex` (the `-cd` chdir replaces any `setwd`),
  (3) `verify_deck.py`. Emits `_main.pdf`.
- **`RUN.R`** — non-destructive signpost; documents the three `source(here::here(...))` lines and
  points to README "How to run". Running it does nothing but print guidance.

> Deviation from §6 draft (intentional refinement): the draft `analysis_all.R` cleared
> `analysis_output` and ran H3. The realized master clears only `analysis_temp` (the §8.2 safety note —
> `analysis_output` holds pre-supplied tables in sample mode) and excludes H3 (full-only). This is the
> safer, correct behavior, not a regression.

---

## 4. Figure → deck flow

```
analysis stages (E4, pure, G5, I6, …) ──ggsave──► external analysis output/ (PATHS$output_*, outside repo)
        │
        ▼
presentation/figures_central_folder/collector.py --sample-root <SAMPLE_ROOT>
        │   reads manifest.csv; for each row resolves the output as the NEWEST of {sample-root, repo}
        ▼
presentation/figures_central_folder/from_code/      (gitignored — regeneratable, 5%-sample-derived)
        │   + static/ (tracked: irreproducible manual assets, e.g. ELSI.jpg, frequenciesLQ*.pdf)
        ▼
presentation/latex/presentation/_main.tex
        \graphicspath{{../../figures_central_folder/from_code/}{../../figures_central_folder/static/}}
        │   latexmk -cd -g -pdf
        ▼
presentation/latex/presentation/_main.pdf
        │   verify_deck.py confirms every \includegraphics resolves under from_code/ + static/
```

- The **English** deck (`latex/presentation/`) is the live, collector-fed build.
- The **Portuguese** deck (`latex/apresentacao/`, `\graphicspath{{../figures/}}` → legacy
  `latex/figures/`) is NOT on the collector pipeline — same parity hazard noted in MAP_before.
- `update_deck.py` (one-shot Rscript-stages → collector → latexmk driver) and `deck_compare.py`
  (deck-vs-deck diff) remain available alongside the masters.

---

## 5. How to run

```bash
# 1) Analysis pipeline on the 5% sample (the common path: panel → figures, tables, WMVPF)
Rscript analysis/analysis_all.R

# 2) Collect figures and compile the English deck
Rscript presentation/build_deck.R

# 3) Full-data build (restricted server only)
PENSION_DATA_MODE=full Rscript build/build_all.R
```

Environment overrides (resolved in `config/paths.R`):
- `PENSION_DATA_MODE` = `full` | `sample` — force the data mode (else auto-detected by root existence).
- `PENSION_SAMPLE_ROOT` — path to the 5% sample tree (default OneDrive `transfer_may_retirement`).
- `PENSION_FULL_ROOT` (analysis, F:/) and `PENSION_FULL_BUILD_ROOT` (build, U:/) — full-data roots.
- `PENSION_PYTHON` (build_deck.R) and `PENSION_R_LIBPATH` (server `.libPaths`) — tool overrides.

`RUN.R` is a signpost only; `source()` the master you want, or run the `Rscript` commands above.

---

## 6. What changed vs MAP_before (diff)

**Config layer added (new):** `config/paths.R` + `config/constants.R`. Previously path strings and
magic numbers were scattered across ~40 scripts with hardcoded `F:/`, `U:/`, `C:/…/OneDrive/…` roots
and per-file `setwd()` + `dir.exists()` mode detection. Now one `PATHS` list and one loud `DATA_MODE`
resolver; `constants.R` holds gamma/ETA/RR/thresholds once.

**Files moved by functional area (root-elevated):**
- `trans_retirement/code/{A,B,C,D}*` → **`build/code/`** (+ `aux_codes_RAIS/`).
- `trans_retirement/code/{E,G,H,I}*` + `new_counterfactual_claiming*` → **`analysis/code/`**.
- `figures_central_folder/` + `latex/` → **`presentation/`**; added `presentation/build_deck.R`.
- `trans_retirement/code/legacy/` + `old/` → **`legacy/`** (F1-F7, G6, I5, old/B1-B2).
- Added role dirs `input/ output/ temp/` under build/ and analysis/, each `.gitkept` and gitignored.

**Paths centralized:** canonical stages converted from `setwd(paste(dir))` + inline absolute roots to
`source(config/paths.R)` + `PATHS$*`. Canonical `setwd()` count went from "every full-data script" to **0**.

**Legacy guarded:** every `legacy/*.R` now opens with
`stop("LEGACY — do not run. Canonical replacement: …")` on line 1 (verified F1; 9 quarantined files).

**Masters + front door added:** `build_all.R`, `analysis_all.R`, `build_deck.R`, and root `RUN.R` —
the "one `source()` runs the pipeline" requirement (G-S Automation) that MAP_before noted was absent.

**Portability hygiene:** root `.here` sentinel + `.gitattributes` (`* text=auto`, kills the CRLF/LF
phantom diff that previously showed 181 files as modified).

---

## 7. Conformance to REPO_STRUCTURE_GUIDELINES §4

**Realized layout matches §4 (the root-level option).** The §4 "one open structural choice" (line 120)
offered nesting `build/`/`analysis/` under `trans_retirement/` vs elevating to root; the restructure took
the **root-level** path — `build/`, `analysis/`, `presentation/`, `config/`, `legacy/` all sit at the repo
root exactly as the §4 diagram (lines 81-116) draws them.

Per-element conformance:
- `config/{paths.R, constants.R}` — present, wired into canonical stages. ✔ (§4, §5)
- `build/{input,code,output,temp,build_all.R}` — present; role dirs `.gitkept`+gitignored. ✔
- `analysis/{input,code,output,temp,analysis_all.R}` — present. ✔
- `presentation/{figures_central_folder, latex, build_deck.R}` — present. ✔
- `legacy/` with stop()-guarded F1-F7/G6/I5 + `old/` B1-B2. ✔ (§4, §8.2)
- `.gitattributes` (`* text=auto`), `RUN.R` front door. ✔ (§4, §6)

**Minor deviations (all benign / safer than the draft):**
1. `build/code/` and `analysis/code/` retain the **full version lineage** (A1-A3, C1-C5, D1-D3, E1-E3,
   G1-G4, H1-H2, I1-I3, I7b, new_counterfactual2), not just the canonical heads the §4 comment lists.
   They are inventory-only (not on any master) and still carry legacy `setwd()`. Consistent with
   MAP_before keeping siblings as live-or-noted dependencies; canonical purity is preserved at the
   master level.
2. `analysis_all.R` clears only `temp/` (not `output/`) and **excludes H3** — diverging from the §6.2
   draft snippet but correctly honoring the §8.2 safety note (pre-supplied prereq tables) and the
   `h3-nosample` flag. Refinement, not regression.
3. `trans_retirement/` still exists at root as the pre-move namespace (vestigial). Not part of the §4
   target tree; candidate for removal in a later cleanup, but harmless (masters never reference it).

No structural deviation that breaks the §4 contract. The realized tree is a faithful, slightly
hardened implementation of the root-level option.
