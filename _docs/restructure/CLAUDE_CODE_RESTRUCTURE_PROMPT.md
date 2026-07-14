# Claude Code session prompt — restructure `optimal-pension-reforms`

> **How to use.** Open Claude Code at the repo root on branch `code-and-data`. Paste everything in the box below as your first message. It is written to drive an `ultrathink` multi-agent run. It treats `_docs/restructure/REPO_STRUCTURE_GUIDELINES.md` as the binding spec. It will **plan and pause for your approval before moving any file.**

---

```text
ultrathink. ultracode. You are the ORCHESTRATOR of a multi-agent repository restructuring of
optimal-pension-reforms (Gentzkow–Shapiro-style code/data hygiene for a Brazilian
pension-reform MVPF/WMVPF project). Read these before doing anything:

  1. CLAUDE.md (root) and .claude/rules/*.md — obey every project rule, especially:
     plan-first-workflow, orchestrator-protocol, session-logging, cross-artifact-review.
  2. _docs/restructure/REPO_STRUCTURE_GUIDELINES.md — THIS IS THE BINDING SPEC for the
     target structure, the config/paths.R + config/constants.R layer, the two master
     scripts, the safety rules, and the code-style checklist. Do not invent a different
     structure; implement that one.
  3. _docs/memory/01..10 (esp. 07_open_issues.md and 10_corrections_log.md).

NON-NEGOTIABLE GUARDRAILS (these override any convenience):
  • Branch: work on code-and-data (or a feature branch off it). Never touch main. Never
    force-push. Commit per the CLAUDE.md contract (WHY + stage ref + "Made by: Claude
    (model: <model>)"; user reasons verbatim). Use `git mv` so history is preserved.
  • Confidential data NEVER moves into the repo and is NEVER committed (no data_local/,
    no CPF-bearing file). build/input/ holds only pointers/links to the restricted server.
  • Run and verify on the 5% SAMPLE only. Do NOT attempt full-data build stages.
  • SAMPLE = VALIDATION (CLAUDE.md rule 4): do not report sampling-noise number
    differences as failures. Parity is measured on the SAME sample before and after, so a
    real difference is attributable to the restructure, not to sampling.
  • LEGACY is never run or resurrected: I5, G6, F1–F7, old/ B1–B2. Canonical files only:
    A4, B4, C6, D4, E4, F=new_counterfactual_claiming3_pure.R (upstream …gabriel.R), G5,
    H3, I4, plus I6/I7. Confirm the exact runnable set in Stage 0.
  • FLAG substantive/econometric bugs — never silently "fix" methodology. Path/IO
    plumbing you may change; estimation logic you may not. Record flags in a findings file.
  • PLAN-FIRST: no file is moved or renamed until I approve the written plan (gate below).
  • Use sub-agents for fan-out; keep the dependency graph and the plan in your own context.
    Cap review-fix loops at 5 rounds (orchestrator-protocol). Pause-friendly: checkpoint at
    every stage boundary and tell me token budget status.

WHY STAGE-0 CARTOGRAPHY IS A TEAM OF DELEGATED AGENTS, NOT THE ORCHESTRATOR:
  Mapping is a *producing* role; orchestration is a *control* role (hold the plan, gate on
  approval, sequence stages, run loops) — keep them separate. And one agent cannot line-level
  map ~20 scripts (several 1,000+ lines) AND run the sample pipeline well: too much context,
  and it mixes static reading with live execution (different tools, different failures). So
  Stage 0 is SPLIT into parallel area-mappers + a conciliator + a baseline runner. YOU
  orchestrate; they produce. The same mapper team is reused to re-map after the move.

══════════════════════════════════════════════════════════════════════════════════
STAGE 0 — MAP + GOLDEN BASELINE   (a TEAM of sub-agents; ALL on model claude-opus-4-8)
══════════════════════════════════════════════════════════════════════════════════
Run EVERY Stage-0 sub-agent on opus 4.8 (claude-opus-4-8) — cartography quality drives every
later decision. Three steps: parallel mappers → conciliator → baseline runner.

0A — AREA MAPPERS  (3 parallel sub-agents, READ-ONLY; one per part of the code). Each maps
  ITS files fully: per-file language + one-line purpose + INPUTS (paths read) + OUTPUTS (paths
  written) + local dependency edges, AND a fragile-path inventory for its files (setwd, here,
  absolute F:/ U:/ C:/OneDrive, /tmp/, read/load/fread/ggsave literals, source() chains,
  \graphicspath, \input). Each writes baseline/partials/map_<area>.md and
  baseline/partials/paths_<area>.csv (file,line,literal). The three areas:
    • Mapper-BUILD         → A4, B4, C6, D4, aux_codes_RAIS/  (note old/ exists; don't deep-map)
    • Mapper-ANALYSIS      → E4, gabriel, pure, G5, H3, I4, I6, I7
    • Mapper-PRESENTATION  → collector.py, update_deck.py, verify_deck.py, deck_compare.py,
                             manifest.csv, latex/presentation/ + latex/apresentacao/ (graphicspath, \input)
  Legacy I5/G6/F1–F7 are NOT mapped beyond noting they exist and stay quarantined.

0B — CONCILIATOR  (1 sub-agent). Ingest the three partials and reconcile them into ONE picture:
  stitch cross-area edges into the canonical runnable DAG (raw → panel → estimates → figures →
  figures_central_folder/from_code → latex/presentation/_main.tex → PDF); dedupe + globalize the
  path inventory; flag contradictions between partials (e.g., a D1/D2/D3/D4 input mismatch, a
  lingering old-F5 reference). Decide the PARITY SET (which stages actually run on the 5% sample).
  Write baseline/MAP_before.md, baseline/dependency_graph.md, baseline/path_inventory.csv. Report
  the consolidated map + DAG + parity set back to the orchestrator.

0C — BASELINE RUNNER  (1 sub-agent; runs on the sample, writes to baseline/). Using the conciled
  DAG + parity set, capture the GOLDEN BASELINE before anything moves:
        – run the analysis stages that emit deck figures (per the DAG), then
          collector.py → update_deck.py, then compile latex/presentation/_main.tex → PDF;
        – record SHA-256 of every figure in figures_central_folder/from_code/, of the compiled
          PDF, AND of the key numbers (WMVPF actual; WMVPF_bL; WMVPF_bS; eta; the policy
          elasticity; the claiming-distribution tables). Strip volatile PDF metadata
          (CreationDate/ModDate) before hashing.
      Write baseline/baseline_manifest.csv (path,sha256) and baseline/baseline_numbers.csv
      (quantity,value,source_file). If a stage can't run on the sample, record WHY and exclude
      it from the parity set (do not guess). baseline/ is a NEW top-level folder OUTSIDE
      everything that will move.

Orchestrator holds the consolidated map + baseline, then proceeds to the GATE.

══════════════════════════════════════════════════════════════════════════════════
GATE — PLAN + MY APPROVAL   (orchestrator; plan-first-workflow.md)
══════════════════════════════════════════════════════════════════════════════════
Using the guidelines + the Stage-0 map, write a concrete plan to
quality_reports/plans/YYYY-MM-DD_repo-restructure.md containing:
  • the exact target tree (resolve the one open choice from the guidelines §4: elevate
    build/analysis/presentation to root, OR nest under trans_retirement/ — RECOMMEND one
    and ask me to confirm);
  • the full `git mv` move-map (every source path → destination path);
  • the planned config/paths.R variables and the config/constants.R contents (which magic
    numbers move, from which files);
  • the generated stage list for build_all.R and analysis_all.R (from the DAG);
  • the list of bugs you will FLAG (not fix), with file:line.
STOP and present this plan. Do not move, rename, or delete anything until I reply "approved".

══════════════════════════════════════════════════════════════════════════════════
STAGE 1 — RESTRUCTURE + SCAFFOLD   (orchestrator)   [only after approval]
══════════════════════════════════════════════════════════════════════════════════
  • Create the new directories; `git mv` files per the approved move-map (preserve history).
  • Create config/paths.R (project-root via here/rprojroot — NO setwd; explicit DATA_MODE
    with env override PENSION_DATA_MODE and a stop() if no data root is found; one PATHS
    list centralizing all roots and input/output/temp/figure dirs).
  • Move constants.R → config/constants.R (do NOT wire call-sites yet — that's Stage 2).
  • Create legacy/ and prepend each legacy file with:
      stop("LEGACY — do not run. Canonical: <file>. See _docs/memory.")
  • Add .gitattributes (`* text=auto`); update .gitignore for the new output/temp/baseline
    paths; do NOT commit line-ending-only churn.
  • Do NOT edit any stage's internal path references yet. Move + scaffold only.
  • Commit: "restructure: move to functional dirs + add config layer (Phase: restructure)".

══════════════════════════════════════════════════════════════════════════════════
STAGE 2 — ADAPT CODE I/O   (parallel per-stage sub-agents; orchestrator fans out)
══════════════════════════════════════════════════════════════════════════════════
Dispatch ONE sub-agent per unit: A4, B4, C6, D4, E4, gabriel, pure, G5, H3, I4, I6, I7,
aux_codes_RAIS, the three figure .py tools + manifest.csv, and the latex graphicspath.
Each sub-agent does ONLY plumbing + flagging:
  • Replace every hardcoded/absolute/setwd/tmp path with config/paths.R variables and
    here::here(); add the two source(config/...) lines at the top.
  • Route inputs/outputs/intermediates to the new input/output/temp dirs. Specifically fix
    the gabriel.R → pure.R hand-off (open issue O1) to a persistent analysis/temp path,
    not /tmp/.
  • Update source() chains; update collector.py / update_deck.py / manifest.csv relative
    paths and the latex \graphicspath if the figures folder moved.
  • Static-check only (parse with `Rscript -e 'parse(...)'` / `R CMD`; py: `python -m
    py_compile`). Do NOT run heavy compute in this stage.
  • FLAG, do not fix: D4 stray ')' (O3); G5 MECH claims_L/S vs claims_c (O5a), WMVPF
    parenthesization (O5b), delta_ben ×3 from G2 (O5c); any D1/D2/D3/D4 input
    inconsistency; any lingering old-F5 reference in I4. Append to
    quality_reports/restructure_findings.md with file:line and a one-line description.
  • Return a short report: paths changed + bugs flagged. The orchestrator merges reports,
    resolves cross-file conflicts (e.g., a shared PATHS key), and commits per stage-group.

══════════════════════════════════════════════════════════════════════════════════
STAGE 3 — RERUN + PARITY VERIFICATION   (verification sub-agents; orchestrator loops)
══════════════════════════════════════════════════════════════════════════════════
  • Re-run the analysis pipeline on the 5% sample THROUGH THE NEW STRUCTURE via
    analysis/analysis_all.R; then presentation/build_deck.R (collector → update_deck →
    compile latex/presentation/_main.tex).
  • Recompute figure hashes + key numbers; diff against baseline/ (Stage 0). Reuse the
    existing verify_deck.py / deck_compare.py where useful.
  • PARITY RULE (figure + numeric, ignore cosmetic): figures and key numeric outputs must
    match the baseline within tolerance; IGNORE timestamps, footer build-date, and PDF
    metadata. Compare figure PDFs after stripping CreationDate/ModDate (and/or render to
    PNG and image-diff). Numeric tolerance: relative diff < 1e-6 for recomputed-from-same-
    inputs quantities.
  • Write quality_reports/restructure_parity.md: PASS/FAIL per figure and per number.
  • If a real difference appears: diagnose. If the restructure caused it (wrong path,
    wrong file picked, broken source order) → FIX the plumbing and re-verify (loop, max 5
    rounds). If it reveals a pre-existing bug → FLAG it (do not fix) and note it can't be
    a parity blocker since baseline had it too. Cosmetic-only diffs → PASS.

══════════════════════════════════════════════════════════════════════════════════
STAGE 4 — RE-MAP + DOCS + HANDOFF   (mapper team pass 2 + orchestrator)
══════════════════════════════════════════════════════════════════════════════════
  • Re-map the NEW structure on opus 4.8 — reuse the 0A area-mappers + 0B conciliator (the
    clean tree is smaller, so one mapper may suffice) → _docs/restructure/MAP_after.md.
  • Update CLAUDE.md (pipeline table + paths), README.md (the tree + "how to run": source
    the masters), and _docs/memory as needed.
  • Write a session log (_docs/session_logs or quality_reports/session_logs) summarizing:
    moves made, paths centralized, the two master scripts, bugs flagged (with file:line),
    and the parity result.
  • Final commit on code-and-data. Then STOP and present a summary. Do NOT open a PR or
    merge to main — leave that to me.

DELIVERABLES CHECKLIST (report at the end):
  [ ] New tree implemented per guidelines; history preserved (git mv)
  [ ] config/paths.R + config/constants.R created and wired into every canonical stage
  [ ] build/build_all.R + analysis/analysis_all.R + presentation/build_deck.R working on sample
  [ ] legacy/ guarded; .gitattributes added; .gitignore updated; no confidential data moved
  [ ] restructure_findings.md (bugs flagged, file:line) — nothing silently changed in econ logic
  [ ] restructure_parity.md = PASS (figures + numbers match baseline, cosmetic ignored)
  [ ] MAP_after.md + CLAUDE.md/README updated + session log written
  [ ] Summary presented; main untouched; awaiting my review
```

---

## Why the prompt is shaped this way (quick rationale for Arthur)

- **A pre-change golden baseline is the keystone.** You can't prove "the presentation is still the same" without snapshotting it *before* moving anything. Stage 0 captures figure hashes, the compiled deck, and the key numbers (WMVPF, bL/bS, η, elasticity) on the 5% sample. Because before/after use the same sample, sampling noise cancels and any real difference is the restructure's fault — which is exactly what we want to catch.
- **Plan-and-approve gate** matches your `plan-first-workflow.md` and keeps the blast radius under your control: nothing moves until you say so, and you pick the one open structural choice (root-level vs. nested under `trans_retirement/`).
- **Move first, repath second, verify third** — never interleaved — so a parity failure has exactly one possible cause at a time.
- **Flag-don't-fix** honors `CLAUDE.md`: the agents clean plumbing but never touch econometrics; the known bugs (O1 `/tmp` hand-off, O3 D4 syntax, O5a–c G5) are surfaced with file:line for you to decide on.
- **Stage 0 = a team (area-mappers + conciliator + baseline runner), all on Opus 4.8; orchestrator = the main thread.** One agent can't line-level-map ~20 long scripts *and* run the sample pipeline well — too much context, and it mixes reading with execution. Splitting by code area with a conciliator that reports back to the orchestrator keeps each agent focused; the orchestrator only controls, never produces. (You raised this; it's the right call.)
