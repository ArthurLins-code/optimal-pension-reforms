# Repository Structure Guidelines — `optimal-pension-reforms`

**Status:** DRAFT for review · **Author:** prepared for Arthur · **Date:** 2026-06-19
**Source material:** Gentzkow & Shapiro (2014), *Code and Data for the Social Sciences: A Practitioner's Guide* (`CodeAndData.pdf`), adapted to this project, plus Arthur's brief: maximize clarity, safety (low bug/confusion risk for newcomers and experts), and an *economic* way of organizing the work; and add an R master script researchers can `source()` to run the pipeline without opening every file.

> **How to use this file.** This is the *specification* for the restructuring. The companion file `CLAUDE_CODE_RESTRUCTURE_PROMPT.md` is the executable brief that drives a Claude Code multi-agent session to carry it out. Read this first; the prompt references it as the source of truth.

---

## 0. Design goals (in priority order)

1. **Safe** — moving a folder must never silently change a number. The structure should make breakage *loud* (a `stop()` with a clear message), never *silent* (a wrong-but-runnable path).
2. **Clear** — a newcomer should reconstruct the economic argument and the run order from the directory tree alone, without reading code.
3. **Reproducible** — one command (`source()` a master script) rebuilds everything downstream of the available data.
4. **Portable** — no machine-specific absolute paths anywhere in stage code; one place to point at data.
5. **Economic** — the layout mirrors the paper's logic and the code obeys cost-benefit reasoning about compute, storage, and automation.

---

## 1. The seven Gentzkow–Shapiro principles, translated to this project

The guide is short and its rules are blunt. Here is each rule and what it concretely means *here*.

### 1.1 Automation — *"Automate everything; write one script that runs everything end to end."*
The project currently has **no** master script (confirmed: no `Makefile`, `*.Rproj`, or `run_all`). Stages A–I are run by hand. We add two master scripts (see §5). The master clears `temp/` and `output/` first, so output can never be a stale artifact of old code.

### 1.2 Version control — *"Everything under version control; run the whole directory before checking in."*
Already on Git (branch `code-and-data`). The missing half is the discipline: **run the relevant master script on the 5% sample before committing**, so each checked-in revision is known to execute. Add a `.gitattributes` (`* text=auto`) to kill the CRLF/LF phantom diff (181 files currently show as "modified" purely from line endings — never commit those).

### 1.3 Directories — *"Separate by function; separate inputs from outputs; make directories portable."*
This is the heart of the restructure (§4). Today, code/output/intermediate files are mixed and addressed by absolute paths. We split by **function** (build → analysis → presentation), and inside each by **role** (`input/ code/ output/ temp/`), and we make every directory portable through one path-config file (§5).

### 1.4 Keys — *"Cleaned data in tables with unique, non-missing keys; stay normalized until the last merge."*
Applied incrementally (§7). The individual key is `cpf_anon`; the panel key is `cpf_anon × claim_quarter`. Reconcile the legacy `indiv` identifier per-file (per `CLAUDE.md` rule 5), never project-wide.

### 1.5 Abstraction — *"Abstract to remove redundancy and improve clarity; otherwise don't."*
Collapse the duplicated RAIS openers (`fn_open_rais_*`, four near-copies in B4) and the scattered path strings into single definitions. Do **not** over-abstract one-off code.

### 1.6 Documentation — *"Don't write docs you won't maintain; code should be self-documenting."*
The elasticity lesson: never store the same fact twice. `gamma = 4` and the replacement-rate formulas live in **one** place (`config/constants.R`), referenced everywhere — so a comment can never contradict the code.

### 1.7 Management — *"Use a task system; email isn't one."*
Already satisfied by `_docs/` (plans, session logs, memory) and the task list. Keep it.

---

## 2. The "economic way of thinking" baked into the structure

Arthur's distinctive ask. Three concrete commitments:

**(a) The tree narrates the economics.** Reading top to bottom should reproduce the paper's argument:

> administrative records (SUIBE, RAIS) → eligible-worker sample & contribution histories → claiming behaviour and the **counterfactual under pure reforms** (bL = level, bS = slope) → **DiD on average benefits** → **policy elasticity** → **MVPF / WMVPF** welfare evaluation → presentation.

Stage folders keep their A–I identity but are grouped so this storyline is legible.

**(b) Marginal cost vs. marginal benefit governs engineering choices** — the guide's own logic, made explicit:
- *Automate* a step when the expected cost of repeating it by hand exceeds the one-time cost of the tool. (You will run every step more times than you expect.)
- *Store "too much" output* from slow code. Estimation (F, G, H, I) is expensive; persist full estimate objects, not just the one number you need today.
- *Separate slow code from fast code.* Estimation should not re-run every time you re-format a table or restyle a figure. This is why `analysis/` keeps estimation outputs in `output/` that the presentation layer merely *reads*.

**(c) Economic objects are named once and defined once.** Every quantity that appears in the paper's math — `gamma` (CRRA), `eta` (welfare weight ≈ 0.828), the replacement-rate schedules `RR_w = 0.69 + 0.021·p`, `RR_m = 0.82 + 0.025·p`, thresholds `p_bar = 85 (women) / 95 (men)`, the bunching window `W = 4`, the DiD reference period `−2` — is a named constant in `config/constants.R`, so the mapping between LaTeX and code is one-to-one and auditable.

---

## 3. What we are starting from (current state, summarized)

- **Pipeline** in `trans_retirement/code/` — canonical files: `A4`, `B4`, `C6`, `D4`, `E4`, F = `new_counterfactual_claiming3_pure.R` (upstream `…gabriel.R`), `G5`, `H3`, `I4`; plus recent `I6`/`I7` (WMVPF + diagnostics). Legacy `F1–F7`, `G6`, `I5` in `legacy/`; Stata predecessors in `old/`; helpers in `aux_codes_RAIS/`. `constants.R` exists but is **not yet wired in**.
- **Outputs** in `trans_retirement/output/{A,C,E,F,G,H,I,…}` — gitignored.
- **Figures** flow: stage scripts `ggsave` → `output/{stage}/` → `figures_central_folder/{collector,update_deck,verify_deck}.py` + `manifest.csv` → `figures_central_folder/from_code/` → deck via `\graphicspath`.
- **Decks:** `latex/presentation/` (English; `\graphicspath{{../../figures_central_folder/from_code/}{../../figures_central_folder/static/}}`) is the **live, buildable** deck. `latex/apresentacao/` (Portuguese; `\graphicspath{{../figures/}}`). The methodology source-of-truth reference remains the PDF `Retirement_Presentations (old strat reverted).pdf` in `versões do artigo/Presentations/`.
- **Top fragilities:** absolute paths (`F:/`, `U:/`, `C:/…/OneDrive/…`) in every full-data script; a `/tmp/` hand-off from `gabriel.R` → `pure.R` (open issue O1); brittle three-way `DATA_MODE` detection; possible `D1/D2/D3/D4` input inconsistency across G5/H3/I4; an old-`F5` reference lingering in I4. These are **flag-don't-silently-fix** items.

---

## 4. Target folder structure (functional + stage-preserving)

Top-level directories separate by **function**; each functional area separates by **role** (`input / code / output / temp`). Stage letters A–I are preserved inside.

```
optimal-pension-reforms/
│
├── config/                       # ── PORTABILITY LAYER (new) ──
│   ├── paths.R                   #   single source of truth for every path + DATA_MODE
│   └── constants.R               #   every magic number / economic primitive (moved & wired in)
│
├── build/                        # ── DATA CONSTRUCTION (needs restricted server data) ──
│   ├── input/                    #   pointers/links to raw SUIBE & RAIS (NEVER committed)
│   ├── code/                     #   A4, B4, C6, D4 (+ aux_codes_RAIS/)
│   ├── output/                   #   analysis-ready panel & cross-section (gitignored)
│   ├── temp/                     #   intermediates, cleared by master (gitignored)
│   └── build_all.R               #   master: sources A → D in order (full-data only)
│
├── analysis/                     # ── ESTIMATION & RESULTS (runs on 5% sample) ──
│   ├── input/                    #   link to build/output (the panel)
│   ├── code/                     #   E4, F (gabriel→pure), G5, H3, I4, I6, I7
│   ├── output/                   #   figures, tables, estimates (gitignored)
│   ├── temp/                     #   intermediates incl. the former /tmp hand-off (gitignored)
│   └── analysis_all.R            #   master: sources E → I in order (sample-runnable)
│
├── presentation/                 # ── RESULTS → DECK ──
│   ├── figures_central_folder/   #   manifest.csv + collector/update/verify + from_code/ + static/
│   ├── latex/                    #   presentation/ (EN, live build) + apresentacao/ (PT)
│   └── build_deck.(R|sh)         #   collect figures → compile latex/presentation → PDF
│
├── legacy/                       # ── QUARANTINE (guarded, never run) ──
│   └── …                         #   F1–F7, G6, I5, old/ B1–B2; each guarded by stop()
│
├── _docs/                        # knowledge base, plans, session logs, memory (unchanged)
├── quality_reports/              # specs, reviews, parity reports (unchanged)
├── Surrogate Indices/            # future tax-externality (τ^PDV) work
├── versões do artigo/            # paper drafts + canonical reference decks (gitignored)
├── .gitattributes                #   `* text=auto`  (kills CRLF/LF phantom diff)
├── CLAUDE.md                     # updated: new pipeline table + paths
└── README.md                     # updated: the tree + "how to run" (source the masters)
```

**Notes & the one open structural choice.**
- The build/analysis boundary is the **analysis-ready panel** (`D4` output): A–D *make* it, E–I *consume* it. F (counterfactual) is analysis because it reads the panel.
- *Alternative to confirm at planning time:* keep the project namespace by nesting `build/` and `analysis/` under `trans_retirement/` instead of elevating them to the root. Same logic, less churn. The Claude Code session must surface this and get your pick before moving anything.
- Moves use `git mv` to preserve history.

---

## 5. The portability layer (the single most important fix)

### 5.1 `config/paths.R` — one place for every path
Every stage script starts with exactly two lines:

```r
source(here::here("config", "paths.R"))      # defines PATHS + DATA_MODE
source(here::here("config", "constants.R"))  # defines economic primitives
```

`paths.R` responsibilities:
- **Find the project root with no `setwd`** — via `here::here()` / `rprojroot` keyed on a sentinel (`.here` file or the `.Rproj`). Stage code never hard-codes a root.
- **Resolve `DATA_MODE` explicitly and loudly.** Order: (1) honor an env-var override `PENSION_DATA_MODE ∈ {full, sample}`; (2) else detect by existence of known data roots; (3) else `stop()` with a message listing the roots it looked for. No silent fallback to a wrong path.
- **Expose a single `PATHS` list** — `PATHS$raw_suibe`, `PATHS$raw_rais`, `PATHS$build_output`, `PATHS$analysis_input`, `PATHS$analysis_output`, `PATHS$temp`, `PATHS$figures_from_code`, `PATHS$figures_static`, … — so a folder move changes **one** file, not forty scripts.
- **Centralize the data roots** (`F:/…`, `U:/…`, `C:/…/OneDrive/…`) here and **only** here.

This single file implements three guide chapters at once: Directories (portable), Documentation (self-documenting, no duplicated path strings), and the "tape over the switch" safety idea (a missing data root throws, instead of running on the wrong file).

### 5.2 `config/constants.R` — one place for every number
Move the existing `constants.R` here and **actually wire it in**. It holds `gamma`, `eta`, the `RR_w`/`RR_m` schedules, `p_bar_w`/`p_bar_m`, `W`, the DiD reference period, the reform cutoff (Jun/2015), consumption parameters, etc. Derived quantities are *computed from primitives* (the elasticity lesson), never re-typed.

---

## 6. The master sourcing scripts (Arthur's `source()` requirement)

Two entry points (your choice: *two separate masters*), each idempotent and self-announcing. So researchers still have **one obvious place to look**, add a thin top-level signpost — a root `RUN.R` (or a short "How to run" block in `README.md`) that does nothing but document and dispatch to the two masters:

```r
# RUN.R — single entry point. Pick what you need:
# source(here::here("build",    "build_all.R"))     # full server data only
  source(here::here("analysis", "analysis_all.R"))  # 5% sample: panel → results
  source(here::here("presentation", "build_deck.R"))# figures → compiled deck
```

This keeps the Gentzkow–Shapiro "one run-script per functional directory" pattern *and* gives newcomers a single front door.

### 6.1 `build/build_all.R` (full data only)
```r
# Reconstructs the analysis-ready panel from raw SUIBE/RAIS. SERVER/FULL DATA ONLY.
source(here::here("config", "paths.R"))
if (DATA_MODE != "full")
  stop("build_all.R needs the full server data (DATA_MODE='full'). ",
       "On the 5% sample the panel is an *input*, not something you rebuild.")
clear_dirs(PATHS$build_temp, PATHS$build_output)        # G-S: clear before building
run_stage("A4_balance_check.R")
run_stage("B4_create_clean_candidates_cross.R")
run_stage("C6_estimate_continuous_contrib.R")
run_stage("D4_create_panel.R")
message("BUILD complete → ", PATHS$build_output)
```

### 6.2 `analysis/analysis_all.R` (sample-runnable; the one researchers use most)
```r
# Panel → figures, tables, estimates → deck inputs. Runs on the 5% sample.
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))
clear_dirs(PATHS$analysis_temp, PATHS$analysis_output)  # but NOT figures_central_folder/static
run_stage("E4_plots_claiming_distributions.R")
run_stage("new_counterfactual_claiming3_gabriel.R")     # upstream of pure
run_stage("new_counterfactual_claiming3_pure.R")        # canonical F
run_stage("G5_effect_average_benefit_freq_bL_and_bS.R")
run_stage("H3_policy_elasticity.R")
run_stage("I4_wmvpf_no_pure_reforms_freq.R")
run_stage("I6_wmvpf_with_pure_reforms_freq.R")          # + I7 diagnostics if desired
message("ANALYSIS complete → ", PATHS$analysis_output)
```

**`run_stage()` design choices** (document in the file):
- Default: `source(here::here("analysis","code", f), local = TRUE, echo = FALSE)` — `local=TRUE` keeps each stage's variables from leaking into the next ("shy functions").
- Robust upgrade (recommended, optional): run each stage in a **fresh R process** via `callr::rscript()` so a crash or a stray object can't contaminate later stages — closest to the guide's "delete outputs and rebuild" guarantee.
- Each call is timed and logged; a stage failure aborts with the stage name.
- The exact stage list is **generated from the validated dependency graph** in Stage 0 of the restructuring (the canonical runnable DAG), not assumed.

### 6.3 `presentation/build_deck.R`
Wraps the existing Python tools: run `collector.py` → `update_deck.py` → compile `latex/presentation/_main.tex` → optionally `verify_deck.py`/`deck_compare.py`. Gives "figures → PDF" one command too.

---

## 7. Keys & data normalization (apply incrementally)
- Each cleaned table has a **unique, non-missing key**: individual tables keyed on `cpf_anon`; the panel on `cpf_anon × claim_quarter`. A key column never has missing or duplicated values.
- Keep tables **normalized** (attributes stored at their natural level) until the final merge into the estimation matrix; do transformations (logs, ranks) only while normalized.
- Reconcile `indiv` → `cpf_anon` **per file** with confirmation, never a global find-replace (`indiv` may appear in non-CPF contexts).

---

## 8. Safety rules (the "minimize risk" requirement)

1. **Confidential data never enters the repo.** No `data_local/`, no CPF-bearing file, ever committed. `build/input/` holds only links/pointers to the restricted server. `.gitignore` enforces it.
2. **Legacy is quarantined and guarded.** Every file in `legacy/` begins with
   `stop("LEGACY — do not run. Canonical replacement: <file>. See _docs/memory.")`
   so an accidental run fails immediately ("tape over the switch"). Per `CLAUDE.md`, I5/G6/F1–F7 are never rerun or reviewed as current.
3. **Build clears before it builds.** Masters wipe `temp/` and `output/` first; no result can be a leftover of deleted code.
4. **Loud, not silent.** Missing data root, wrong `DATA_MODE`, or absent input → `stop()` with a helpful message, never a guess.
5. **Portability is mandatory.** No `setwd`, no absolute paths in stage code — all through `config/paths.R`.
6. **Version-control discipline.** Run the relevant master on the sample before committing; commit on `code-and-data`; follow the `CLAUDE.md` commit contract (WHY + stage ref + "Made by: Claude (model: …)"; user reasons verbatim). Never touch `main` directly. Add `.gitattributes` (`* text=auto`); never mass-commit line-ending-only diffs.
7. **Parity baseline before any move.** Capture the current deck + figure hashes + key numbers (on the 5% sample) so the restructure can be *proven* not to change results (§ companion prompt, Stage 0/3).
8. **Sample = validation.** Number differences that are sampling noise are not bugs (`CLAUDE.md` rule 4). Because parity is measured on the *same* sample before and after, any real difference is attributable to the restructure, not to sampling.

---

## 9. Code-style checklist (from the guide's appendix)

- Lines ≤ ~100 chars; functions ≤ ~80 lines; scripts ≤ a few hundred. Over-long ⇒ rethink structure.
- **Shy functions:** explicit, minimal inputs/outputs; operate on locals; avoid globals.
- Order functions for linear top-to-bottom reading.
- **Descriptive names** that replace comments; avoid `x`/`xx`, `…analysis`/`…analysisb`.
- Make logical switches read like what they mean (`all(x == 0)`, not `max(x) == 0`).
- Be internally consistent (indentation, naming) within a file.
- **Error-check for robustness/clarity:** prefer a thrown error to a "don't do X" comment; factor repeated validation into one `is_valid_*()` helper.
- **Unit-test reusable functions** — especially the MVPF/WMVPF/elasticity computations and any shared helper.
- Profile slow code; store "too much" output; separate slow (estimation) from fast (tables/plots).

---

## 10. Migration principles (execution lives in the companion prompt)
1. **Map and snapshot before touching anything** (golden baseline).
2. **Plan the exact move + new files, then get Arthur's approval** before any `git mv`.
3. **Move and scaffold first; repath second; verify third.** Never interleave a folder move with a logic edit.
4. **Flag substantive/econometric bugs; never silently "fix" methodology.**
5. **Re-run on the sample and prove figure+numeric parity** against the baseline before declaring done.

---

*End of guidelines. Companion: `CLAUDE_CODE_RESTRUCTURE_PROMPT.md`.*
