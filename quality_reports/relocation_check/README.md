# Relocation before/after deck check

Verification evidence for the **"outputs → in-repo `analysis/output`"** relocation
(plan: [`_docs/plans/robust-popping-zephyr.md`](../../_docs/plans/robust-popping-zephyr.md)).

The two PDFs in this folder are **gitignored** (heavy, regenerable binaries — same policy as
`quality_reports/baseline/figures_*`). This README is the tracked, durable record.

## The artifacts (gitignored)
- `deck_BEFORE.pdf` — deck built from the **pre-change** pipeline (outputs written to the external data root).
- `deck_AFTER.pdf`  — deck built from the **post-change** pipeline (outputs written in-repo to `analysis/output`).

## Result — 2026-07-09, 5% sample
`presentation/figures_central_folder/deck_compare.py deck_BEFORE.pdf deck_AFTER.pdf` →

```
Pages compared : 142
Identical      : 142
Changed        : 0
No visual differences — the two decks render identically.
```

Corroborating byte-level checks:
- `WMVPF_actual = 0.2126` (bL cum 1.5591, bS cum −2.4306) — unchanged before/after.
- Regenerated `G4_table_results_sample.csv` / `H2_table_results_sample.csv` — **byte-identical** to the external originals.
- `I4_table_wmvpf_sample.csv`, `I6_summary_sample.csv` — **byte-identical**.

**Conclusion:** the relocation is pure plumbing — it moved *where* outputs are written, not *what* they contain.

## How to regenerate
```bash
# BEFORE: git stash / checkout the pre-change commit, then:
Rscript analysis/analysis_all.R && Rscript presentation/build_deck.R
cp presentation/latex/presentation/_main.pdf quality_reports/relocation_check/deck_BEFORE.pdf
# AFTER: restore the change, rerun the two commands, copy _main.pdf -> deck_AFTER.pdf
python presentation/figures_central_folder/deck_compare.py \
  quality_reports/relocation_check/deck_BEFORE.pdf \
  quality_reports/relocation_check/deck_AFTER.pdf \
  quality_reports/relocation_check/_diff
```
