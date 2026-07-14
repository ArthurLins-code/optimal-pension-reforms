# build/code — full-data build lineage (stages A–D)

Reconstructs the analysis-ready panel from raw SUIBE/RAIS. **Server / full-data only** (`build/build_all.R`
stops unless `DATA_MODE=full`). The master runs the four canonical heads; **every other file here is a live
upstream step or a cross-stage dependency — there is no dead code in this folder**, so nothing was archived.

⚠ "Highest number = canonical" applies *only to the four HEADS*. A1–A3, B1–B3, C1/C3–C5 are distinct earlier
**steps** (not stale versions), and **D1/D2 are a live "old pair"** that G5 / gabriel / I4 / I6 still read for
quarterly fields the new D3/D4 panel does not carry — do **not** retire them.

| File(s) | Role |
|---------|------|
| `A4_balance_check.R` · `B4_create_clean_candidates_cross.R` · `C6_estimate_continuous_contrib.R` · `D4_create_panel.R` | 🟢 **canonical heads** — run by `build_all.R` |
| `D1_create_cross_section.R` · `D2_create_panel.R` | 🔵 **live cross-stage deps** — old-pair cross-section/panel read by G5, gabriel, I4, I6 |
| `A1 A2 A3` · `B1 B2 B3` · `C1 C3 C4 C5` · `D3` | ⚙ **lineage-upstream** — produce the `working/` intermediates the heads consume |
| `C2_balance_check.R` | 🟣 **report-only diagnostic** — emits balance tables, no code consumer |
| `aux_codes_RAIS/` | RAIS helper bundle (data pulls + CBO occupation mappings) |
