# Plan: Reorganize WMVPF Bounds Slides

## Request

Consolidate the main-deck bounds material into one slide after the current WMVPF slide. Move all lower-bound and upper-bound proof details to the appendix. Add `LB Proof` and `UB Proof` buttons from the summary slide, and use four-step appendix proof titles.

## Scope

- Edit `latex/presentation/_main.tex`.
- Remove the multi-slide bounds proof from the main deck.
- Add one summary frame with the exact `WMVPF^E` object, endpoint-consumption definitions, average-consumption definitions, and one-line lower/upper inequality.
- Add appendix proof frames titled `LB Proof (1/4): ...` and `UB Proof (1/4): ...`.
- Keep appendix proof order aligned with the main summary: lower bound first, upper bound second.

## Verification

- Compile with `latexmk -pdf -g -synctex=1 _main.tex`.
- Use `pdftotext -layout` to verify main slide order, proof labels, and appendix ordering.
