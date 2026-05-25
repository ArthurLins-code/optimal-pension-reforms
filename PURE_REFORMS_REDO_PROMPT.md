# Task — Redo the pure-reforms computation, spec-first, against the canonical slides

You are a senior empirical public-economics researcher and careful software
collaborator. We are redoing the "pure reforms" welfare computation because the
current implementation drifted away from the economically-correct procedure. The
authoritative specification is now the slide deck (see "Canonical spec" below).
Work on branch `claude/magical-borg-18ac72` (worktree
`.claude/worktrees/magical-borg-18ac72`). Do NOT branch off it and do NOT touch
other worktrees. Every change is its own git commit citing the slide it
implements and the reason for the change.

## Canonical spec (cite these — do not invent math)

The renewed, economically-correct slides are `latex/presentation/_main.tex`
(compiled `_main.pdf`, "Optimal Pension Reforms", dated May 20 2026).

**Slide-citation convention:** the deck has two footer-numbered sections — the
main presentation (footer `k/52`, PDF pp.1–101) and the appendix (footer `k/47`,
PDF pp.102–150). Always cite slides in that footer form so it is clear whether a
claim rests on a main slide or an appendix slide. Every citation below is `/52`
(main presentation).

The pure-reforms procedure is the **5-step "Disentangling Responses" recipe**,
frame 42/52 = PDF p.64 (identical copies at pp.79, 94, 95):

1. Estimate frequencies under the **pure-Level (pure-L) reform**, redistributing
   the postponement *missing mass* to future bunching regions.
2. Estimate frequencies under the **pure-Slope (pure-S) reform**, removing the
   postponement found in (1) from the actual bunching.
3. Estimate **mechanical expenditures** under both reforms *without behavioral
   responses*, correcting for all selection.
4. Estimate **expenditures** under each reform, correcting *only* for
   anticipation (postponement) selection.
5. Compute **welfare effects and total costs** from (1)–(4) and the **WMVPFs**.

Supporting notation and definitions you must respect (cite by frame/page):

- Welfare + government budget constraint; counterfactual vs actual benefit
  schedules `b^c(·)` / `b^a(·)` and choice vectors `x^c_{it}` / `x^a_{it}` —
  frame 14/52, p.19.
- Mechanical effect = WTP via the envelope theorem; you can recover
  `Σ_t b^a(x^a)/(1+r)^t` and `Σ_t b^c(x^a)/(1+r)^t` but must separately estimate
  (i) counterfactual benefits `Σ_t b^c(x^c)/(1+r)^t` and (ii) mechanical benefits
  `Σ_t b^a(x^c)/(1+r)^t` — frame 25/52, p.46.
- Average counterfactual benefits and the DiD identification assumption
  (`b̄^{c,a}_{p,t}` parallel for `p≥−6` vs `p<−6`), estimator `β^{c,a}_{k,p}` —
  frame 26/52, p.47.
- Cost of the reform, net-of-tax, *ignoring fiscal externalities on tax
  collection for now* — frame 33/52, p.54.
- Optimal reform depends on welfare effects of `Δb_S(·)` and `Δb_L(·)` (WPIC
  logic; postponement in response to `Δb_L`, anticipation in response to
  `Δb_S`) — frame 40/52, p.62.
- Counterfactual claiming distribution masses (postponement ≈ 40.9k, bunching
  ≈ 60.3k, anticipation ≈ 6.5k) — frame 41/52, p.63. Use these as a sanity
  check on step (1)/(2) frequencies.
- Pure-Level frequency targets `N^a_{p,t}`, `N^c_{p,t}`, `N^L_{p,t}` — pp.66–78.
- Pure-Slope frequency targets — pp.81–93. **Flag, do not silently fix:** the
  pure-Slope frequency plots label the third series `N^L_{p,t}` (superscript L)
  even though they are slope-reform frequencies; verify whether this is a slide
  typo for `N^S_{p,t}` before mapping it in code.

## Code in scope (verify the full set yourself first)

Pure-reforms logic currently spans (under `trans_retirement/code/`):
`F6`, `F7`, `new_counterfactual_claiming3_pure.R` (frequencies / steps 1–2);
`G3`, `G5`, `G6` (average counterfactual & mechanical benefits / expenditures,
steps 3–4); `I3`, `I4`, `I5`, `I6` (WMVPF assembly, step 5). Confirm this list
by grepping for `pure` and the slide notation before assuming it is complete.
Outputs land under the active data dir's `output/F`, `output/G`, `output/I`
(note the three-location data boundary documented in `_docs/WORKFLOW_PLAN.md`).

## Procedure — spec-first, in this order

1. **Inventory & confirm.** List every pure-reforms script and its current
   inputs/outputs. Confirm `latex/presentation/_main.tex` is the canonical deck
   (flag if `latex/apresentacao/_main.tex` differs materially).
2. **Write the spec down before touching code.** Produce
   `_docs/pure_reforms_spec.md`: restate steps 1–5 and every equation above in
   plain language, each line citing its slide/frame/page. Commit this first.
3. **Diff spec vs. current I6 (and G5).** Identify exactly where the existing
   code departs from the 5-step recipe — which step is wrong, missing, or
   mis-ordered. Write this as a short "divergence report" and show it to me
   before reimplementing. State plainly what the current I6 pure-reforms block
   actually computes vs. what step 5 requires.
4. **Archive the wrong version, labeled.** Tag current HEAD
   (`git tag pure-reforms-v1-superseded`) and move the superseded scripts into
   the existing `trans_retirement/code/legacy/` folder with a dated note in its
   `README.md`. This preserves the v1↔v2 diff target.
5. **Reimplement** against the spec, one step per commit where feasible.
6. **Verify two ways and report how:** (a) re-derive at least one quantity (e.g.
   a pure-L frequency mass or an average counterfactual benefit) by hand from the
   slide and confirm the code reproduces it; (b) diff v2 outputs against archived
   v1 and confirm *only* the intended quantities moved. If the required input
   data / sample fixtures are not present on this machine, verify by static
   reading of the dependency chain and say so explicitly — do not claim numerical
   reproducibility you could not test.

## Constraints

- Do not invent math or slide content; every behavioral claim cites a file/line
  or a slide frame/page. Flag anything you cannot verify (including the possible
  `N^L`/`N^S` slide-label issue above).
- Atomic commits, clear messages ("implements step 2, pure-S frequencies, slide
  frame 44/52 p.79; v1 omitted the postponement removal"). No force-push, no
  rebase of shared history, no other branches.
- Stop after step 3 (the divergence report) and wait for my confirmation before
  reimplementing.
