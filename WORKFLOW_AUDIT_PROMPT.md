# Role

You are acting as a senior academic economist and a software/project manager
for an empirical public-economics research project on pension/retirement reform.
You collaborate with other researchers through git, so every decision must be
legible, reviewable, and communicable to human collaborators who did not write
the code.

# Task

Working on the branch `claude/magical-borg-18ac72` (worktree at
`.claude/worktrees/magical-borg-18ac72`), deeply understand this repository and
its surrounding workflow, then deliver (1) a committed markdown report analyzing
the current state and (2) a concrete reorganization plan. After I approve the
plan, execute the approved changes on this branch.

Repository root: `C:\Users\tuca1\OneDrive\Documentos\Pesquisa\RA- Prev- JR-GG-GL`

**Authoritative source of truth:** the `claude/magical-borg-18ac72` worktree.
Sibling worktrees/branches exist and carry their own divergent copies of the
same scripts — `claude/naughty-bardeen-3342ff`,
`.claude/worktrees/ecstatic-lederberg-fc835b`,
`.claude/worktrees/stupefied-nightingale-3dbe65`. **Ignore them** unless I ask
you to compare. Do not splice content from multiple worktrees together. Where
the branch diverges from `main`, treat the branch as current and note the diff.

# Context

Over many sessions I made extensive changes and decisions about three things:

1. Which code files and which slides are the *base* for the "pure reforms"
   computation and its underlying math.
2. Which slides are *canonical*, and how you should use them both to write code
   and to verify that code against them.
3. Where the *outputs* of these codes should be stored.

The result is messy. Many scripts were modified — especially **G5**
(`trans_retirement/code/G5_effect_average_benefit_freq_bL_and_bS.R`) and **I6**
(`trans_retirement/code/I6_wmvpf_with_pure_reforms_freq.R`). I no longer
understand what the "pure reforms" portion of I6 actually runs.

**Important — I6 only exists on this branch.** On `main`, `trans_retirement/code/`
stops at I5; `I6_*` and the reorganized layout (e.g. a `legacy/` subfolder
holding F6/F7/I5) exist only inside the `claude/magical-borg-18ac72` worktree.
"Understand this repository" therefore means the branch worktree, not `main`.

## The three-location data boundary (resolve this explicitly — it is the core confusion)

There are three distinct locations whose relationship I have lost track of, and
two of them are named almost identically:

1. `trans_retirement/` — **inside** this repo. Its `code/` is git-tracked; its
   `output/` is **gitignored** (`.gitignore`: `trans_retirement/output/`).
2. `transfer_may_retirement` — **outside** this repo, a sibling folder at
   `C:\Users\tuca1\OneDrive\Documentos\Pesquisa\transfer_may_retirement`. This is
   the real external data directory; it appears only as a *fallback* path inside
   I6 (around line 64).
3. `F:/Users/tucalins/Documents/transf_11_11/directory_2025` — the **original
   server** path, still hardcoded in some scripts (e.g. G5 line 18).

Scripts typically `setwd(dir)` and then read/write paths *relative to `dir`*
(e.g. `output/G/...`), so outputs land inside whichever of (2)/(3) is active —
**not** necessarily inside the repo's `trans_retirement/output/`. Document
exactly what each script reads, what it writes, and to which of these three
locations, and explain the relationship between the external output dir and the
gitignored in-repo `trans_retirement/output/` copy.

# Inputs (read before doing anything — take as long as you need)

Treat the following as authoritative source material, in this priority order:

- The branch worktree contents (all code, notebooks, configs, scripts).
- **Existing knowledge-transfer docs — read and RECONCILE against the code first,
  do not rewrite from scratch:** `_docs/memory/` (especially
  `02_pipeline.md`, `03_pure_reforms_math.md`, `06_reorg_notes.md`,
  `07_open_issues.md`), `_docs/REORG_SUGGESTIONS.md`, `_docs/for_juan/`, and the
  worktree's `quality_reports/pure_reforms_step_by_step_report.md`. Much of the
  analysis I'm asking for may already exist here — your job is to find where
  these docs are correct, stale, or contradict the current code.
- `Instructions for transition into Claude Code from server.docx` (root) — this
  explains the server → repo → external-folder history.
- **Note:** the root `CLAUDE.md` is an unedited template for a Beamer/Quarto
  *teaching-slides* project (it has `[YOUR PROJECT NAME]` placeholders, a
  `HelloWorld` sample, and references `Slides/`, `Quarto/`, `docs/`,
  `scripts/R/`, `sync_to_docs.sh` — none of which exist here). Do **not** treat
  it as a description of this project. Rewriting CLAUDE.md to describe the actual
  R pension pipeline is in scope for the reorg.
- The canonical slides. Candidate canonical/reference artifacts:
  `latex/apresentacao/_main.tex` (+ `Table_*.tex` includes), root
  `CodeAndData.pdf`, and `Cálculos Juan Reunião 05032026….pdf`. I have **not**
  pinned which is canonical — propose this and list it under Open Questions.
- Git history and current state of `claude/magical-borg-18ac72` (commits, diffs
  vs. `main`, uncommitted changes, stashes) to reconstruct what changed and why.
- The external `transfer_may_retirement` folder and how the repo reads/writes it.

Read deeply and exhaustively before forming conclusions. Where two sources
conflict (e.g. a memory doc vs. the actual script), **surface the conflict**
rather than silently picking one.

## Scope of "pure reforms"

Do not assume pure reforms = G5 + I6 only. The computation spans at least: F6,
F7, I3, I4, I5, G3, G5, G6, `new_counterfactual_claiming3_pure.R`, and the
`I6_wmvpf_*` set, with outputs under `output/F/`, `output/G/`, and `output/I/`.
**Enumerate the full set of pure-reform files yourself** as your first step and
report it; G5 and I6 are the focus, not the boundary.

# Constraints

- Phase 1 (Analysis + Plan) is READ-ONLY. Do not modify, move, rename, or delete
  any file until I explicitly approve the plan.
- Phase 2 (Execution) happens only after my approval, only on
  `claude/magical-borg-18ac72`, in small, reviewable, atomically-committed steps
  with clear commit messages. Never force-push, never rebase shared history,
  never touch other branches or worktrees.
- Per the project rule, every change is its own git commit with a description of
  the change and the reason I gave for it (if I gave one).
- Optimize for human + AI knowledge transmission: a collaborator (or a future AI
  session) should understand the workflow from the docs and structure alone,
  without reverse-engineering scripts.
- Be explicit about the three-location boundary above: document exactly what is
  read, what is written, where it lands, and recommend whether/how to formalize
  the interface (e.g. a documented data contract, or bringing inputs under DVC /
  git-lfs / a manifest).
- For G5 and I6 specifically, explain in plain language what each script does,
  what the "pure reforms" computation consists of, its inputs/outputs and their
  locations, and where the logic is unclear or possibly broken. Note concretely
  that root G5 hardcodes the `F:` server path with no fallback (won't run off the
  server), whereas I6 has dir-detection plus a sample-data mode — explain the
  implication.
- Do not invent facts about the math or the slides; cite the specific file,
  line/cell, or slide that supports each claim. Flag anything you cannot verify.

## Reproducibility / verification — read carefully

I do not know whether the external `transfer_may_retirement` data or the sample
fixtures (`data/dt_sampled_anon.csv`, `data/panel_sampled_anon.csv`) are present
on this machine. **Default to static (read-only) verification: trace the
input→output dependency chain by reading code, do not execute.** Before claiming
anything is "reproducible," check whether the required inputs actually exist; if
they don't, say so and verify by reading only. If sample fixtures *are* present,
you may run the sample-data path and report what you ran. Either way, state
explicitly which mode you used. Do not assert reproducibility you could not test.

# Output format

**Phase 1 — write a markdown report committed to the repo at
`_docs/WORKFLOW_PLAN.md`** (note: `_docs/`, not `docs/` — the latter doesn't
exist; this also keeps it beside the existing memory docs it reconciles).

Reorder the work so the report is delta-focused, not encyclopedic: first
inventory the existing `_docs/memory/` docs and cross-check them against the
current code, then report mainly the conflicts, stale claims, and gaps. Sections:

1. Executive summary (≤1 page) — current state, key problems, headline
   recommendations.
2. Workflow map — end-to-end data flow from raw inputs → code → outputs,
   including the three-location boundary (a text/mermaid diagram is welcome).
3. Code audit — what each relevant script does, with a dedicated subsection for
   G5 and I6 and the "pure reforms" computation; mark unclear or risky areas.
4. Doc ↔ code reconciliation — where `_docs/memory/`,
   `REORG_SUGGESTIONS.md`, and `for_juan/` agree with, contradict, or omit what
   the code actually does.
5. Canonical slides ↔ code mapping — which slides are canonical (propose if
   unpinned), which code implements/checks them, and any gaps or mismatches.
6. Problems & risks — ranked, each with evidence (file/line/slide reference).
7. Reorganization plan — proposed target structure (folders, naming, output
   locations, the data-contract for `transfer_may_retirement`, and a rewritten
   CLAUDE.md describing the real pipeline), as a concrete file-by-file,
   step-by-step plan with proposed git commits. Note breaking changes and
   migration steps.
8. Open questions for me — anything blocking that needs my decision (must
   include: which artifact is canonical, and whether the external data / sample
   fixtures are available for execution).

Then STOP and ask for my approval of the reorganization plan.

**Phase 2 — after approval,** execute the plan in ordered, atomic commits,
reporting progress and any deviations, and update `_docs/WORKFLOW_PLAN.md` to
reflect the final state.

# Acceptance criteria

- The report is committed on `claude/magical-borg-18ac72` and readable by a
  collaborator with no prior context.
- Every claim about behavior, math, or slides cites a specific source.
- G5, I6, and the "pure reforms" computation are explained in plain language,
  including the full file set, not just G5 and I6.
- All three locations (`trans_retirement/`, `transfer_may_retirement`, the `F:`
  server path) and their read/write/output relationships are fully documented.
- The reorganization plan is concrete enough to execute file-by-file and states
  exactly how reproducibility was verified (static read vs. sample run).
- No files were changed before my explicit approval.
