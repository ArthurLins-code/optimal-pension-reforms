# MVPF Domain Review: I4_wmvpf_no_pure_reforms_freq.R

**Date:** 2026-05-11
**Reviewer:** Claude (Opus) — static analysis only (no sample data)
**Canonical reference:** `Retirement_Presentations (old strat reverted).pdf`
**Phase:** 3 (Domain Review)

---

## Summary

- **Overall:** MINOR ISSUES (no formula-breaking bugs found; several documentation gaps)
- **Issues:** 0 critical, 3 major, 5 minor
- **Canonical deck alignment:** ALIGNED (core formulas match slides 37-41/56)
- **Runtime status:** Script should execute without errors (no undefined variables)

---

## Lens 1: Assumption Audit

### A1 (Deterministic point accrual): SATISFIED
- Line 32: `points_d := floor(points_claim)` — flooring is consistent with
  integer point accumulation assumption.
- Line 33: `dist_reform := 4*(claim_quarter - 2015.25)` — quarterly time
  variable centered at Q2 2015 (reform effective ~June 2015). ✓

### A2 (Perfect attention): NOT TESTED IN I4
- I4 doesn't test this directly — it's an upstream assumption (E4 diagnostics).

### A3 (Bunching window W=4): NOT USED IN I4
- I4 is the WMVPF *without* pure-reform decomposition. The bunching window
  is relevant for the F-stage counterfactual (which I4 consumes as input).
  I4 doesn't parameterize W itself. ✓

### A4 (Proportional mixing): NOT USED IN I4
- Same as A3 — consumed via F-stage counterfactual inputs.

### Welfare-weight specification: PARTIALLY ADDRESSED
- **Line 211:** `gamma = 4` ✓ (matches constants.R, slide 38/56)
- **Line 212-213:** `cons_inss = 1536.4, cons_pop = 1473.1` — hardcoded
  consumption values. **No slide citation.** Should be documented.
- **No sensitivity to gamma** computed in I4. Sensitivity analysis (gamma ∈ {2,3,5,6})
  may exist elsewhere or be planned.

### DiD reference: CONFIRMED
- Line 200 (via G4 results): Selection correction uses DiD with ref point
  inherited from G4 estimation. I4 itself doesn't run DiD — it consumes
  G4's point estimates.

---

## Lens 2: Derivation Check

### WMVPF decomposition (lines 216-237): SOUND WITH CAVEATS

**Net cost (line 227):**
```r
net_cost := ((total_benefits_payment - counterfactual_benefits)) / ((1.005^(3))^dist_reform)
```
- `total_benefits_payment - counterfactual_benefits` = `b'(x') - b(x)` ✓
- Discount factor: `1.005^3 ≈ 1.01508` per quarter. Annually: ~6.14%.
- Note: The commented-out line 225 previously subtracted `change_taxes` from
  net cost. The active formula does NOT include the tax externality in
  net cost. Fiscal externality is computed separately (line 231).

**Welfare (line 235):**
```r
welfare := (0.995^(3*dist_reform)) * (1 - gamma * (cons_inss - cons_pop)/cons_pop)
           * (counterfactual_benefits_new - counterfactual_benefits)
```
- Welfare weight `η = 1 - γ(c_b - c_pop)/c_pop ≈ 1 - 4(0.043) = 0.828`. This
  is a **linear approximation** of CRRA: `(c_pop/c_b)^γ = (1473.1/1536.4)^4 ≈ 0.845`.
  Approximation error ~2pp. Acceptable for the paper's purposes but should be noted.
- Discount factor: `0.995^3 ≈ 0.98507` per quarter.

**[MAJOR-1] Discount factor inconsistency:**
- Cost discounting: `1/(1.005^3) ≈ 0.98512`
- Welfare discounting: `0.995^3 ≈ 0.98507`
- These are NOT identical: `1/1.005 ≈ 0.99502 ≠ 0.995`. Difference is ~0.005%
  per period, cumulative ~0.06% over 12 quarters. Economically negligible but
  mathematically incoherent. Should use a single discount factor.

**WMVPF (line 237):**
```r
wmvpf = sum(dt_wmvpf$welfare) / sum(dt_wmvpf$net_cost)
```
- Ratio of discounted sums. Standard WMVPF aggregation. ✓

### Mechanical vs fiscal decomposition (lines 227-231): SOUND
- `net_cost = b'(x') - b(x)` (total benefit change, discounted)
- `mech_cost = b'(x) - b(x)` (mechanical: new schedule on old choices, discounted)
- `fiscal_ext = b'(x') - b'(x)` (behavioral: actual vs mechanical, discounted)
- Identity: `net_cost = mech_cost + fiscal_ext` ✓

### Replacement rate formulas: NOT IN I4
- I4 does not implement RR formulas directly. These are in G5. ✓

---

## Lens 3: Citation Fidelity

- **Hendren & Sprung-Keyser (2020):** WMVPF framework correctly applied
  (WTP / Net Cost structure). ✓
- **No explicit citations in code.** All formula sources should be annotated
  with canonical deck slide numbers. (Minor documentation issue.)

---

## Lens 4: Code-Theory Alignment

### Correct estimand: CONFIRMED
- I4 computes WMVPF on **average benefits** (not expenditures). The header
  says "Mechanical expenditures" but the actual computation uses average benefit
  PVs (`avg_benefits_pv`, `benefits_new_pv`, `benefits_old_pv`). ✓
- I4 does NOT include pure-reform decomposition (correct — that's G5/I5 territory). ✓

### F-stage output: CORRECT
- Line 149: `fread('output/F/new_counterfactual_claim_counts.csv')` — loads
  from the NEW F-stage counterfactual. No reference to legacy F1-F7. ✓

### [MAJOR-2] I4 loads G4 and H2 (not G5 and H3):
- Line 153: `fread('output/G/G4_table_results.csv')` — G4, not G5
- Line 155: `fread('output/H/H2_table_results.csv')` — H2, not H3
- **Previously flagged in Phase 2 audit.** Still unresolved.
- G4 is the frequency-based average benefit DD without pure reform decomposition.
  G5 extends G4 with bL/bS decomposition. I4 only needs the selection correction
  estimates (not the pure reform part), so G4 may be intentionally correct here.
- H2 is the MW-based elasticity. H3 is the IPW-DD elasticity (canonical).
  **H2 → I4 is more likely stale.** Needs professor confirmation.

### [MAJOR-3] I4 uses D3 cross-section while G5 uses D1:
- I4 line 29: `fread('working/D3_cross_section.csv.gz')` — uses D3 (newer)
- G5 line 27: `fread('working/D1_cross_section.csv.gz')` — uses D1 (older)
- D1 and D3 are different cross-section versions from the D-stage pipeline.
  D4 (canonical) creates the panel from D3, not D1. G5 should arguably use D3.
- This means I4 and G5 operate on different underlying data, which could cause
  inconsistencies in the WMVPF computation if/when G5's outputs feed into I4.

### Data source consistency:
- I4 uses D3 and D2 (newer pair). Consistent within I4. ✓

### Variable naming: `indiv` used (line 69)
- `left_join(panel, dt_gab[,.(indiv, ...)])` — uses `indiv` as join key.
- Per CLAUDE.md convention, identifier should be `cpf_anon`. However, this
  file predates the convention and `indiv` is the column name in the data.
  **Not a bug** — per-file reconciliation needed in Phase 4.

### Hardcoded paths:
- Line 15: `.libPaths('F:/docs/R-library')` — server-specific. Acceptable
  per convention (runs exclusively on restricted-access server).
- Line 20: `dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"` — same.
- Line 21: `setwd(paste(dir))` — anti-pattern per R conventions, but acceptable
  for legacy code running on a fixed server.

---

## Lens 5: Logic Chain (Backward Check)

### I4 dependency verification:

| Input | Source | Status |
|-------|--------|--------|
| `working/D3_cross_section.csv.gz` | D3 (upstream of D4) | ✓ exists |
| `working/D2_panel.csv.gz` | D2 (upstream of D4) | ✓ exists |
| `output/F/new_counterfactual_claim_counts.csv` | F-new (canonical) | ✓ correct source |
| `output/G/G4_table_results.csv` | G4 (not G5!) | ⚠️ see MAJOR-2 |
| `output/H/H2_table_results.csv` | H2 (not H3!) | ⚠️ see MAJOR-2 |
| `extra/Expectativa_Vida_IBGE.xlsx` | External (IBGE tables) | ✓ |

### Output verification:
- I4 produces the final WMVPF estimate (`wmvpf` variable, line 237-238)
  and a summary plot (`p1`), but does NOT save outputs to disk.
- **[MINOR-1] No `fwrite()` or `saveRDS()` call.** Results exist only in
  memory. For reproducibility, the WMVPF estimate should be saved.

---

## Minor Issues

### [MINOR-2] `r_annual = 0.06` (line 86) vs discount factors in WMVPF
- PDV calculations use 6% annual discount rate (line 86-88: `r_annual <- 0.06`).
- WMVPF discounting uses `0.995^3` (~6.0%) and `1.005^3` (~6.1%) per quarter.
- These are approximately consistent (~6% annual) but the relationship
  isn't documented. Should add comment explaining the choice.

### [MINOR-3] `na.rm = TRUE` missing on line 110 average
- Line 110: `mean(pv_benefits_old, na.rm = T)` — has na.rm ✓
- But line 110 aggregate in G5 (line 110): `mean(pv_benefits_old)` — no na.rm.
  Actually this is in G5, not I4. In I4, most aggregations use `na.rm = T`. ✓

### [MINOR-4] Commented-out code (lines 183-184, 225, 233)
- Several commented-out alternatives for the net_cost and revenue formulas.
  Should be cleaned up or annotated with why they were abandoned.

### [MINOR-5] `set.seed(123)` (line 23)
- Seed format should be YYYYMMDD per conventions. `123` is non-standard.
  However, no randomization occurs in I4 (no bootstrap, no simulation),
  so the seed is inoperative. Low priority.

---

## Critical Recommendations (Priority Order)

1. **Confirm G4/H2 vs G5/H3 references** (MAJOR-2): Ask professors whether
   I4 intentionally reads G4 and H2, or should be updated to G5 and H3.
   If stale, update paths and re-verify.

2. **Harmonize discount factors** (MAJOR-1): Use a single quarterly discount
   factor (either `0.995` or `1/1.005`, not both). Define in `constants.R`.

3. **Verify D-stage data source** (MAJOR-3): G5 uses D1, I4 uses D3. If these
   produce materially different results, the pipeline has an internal
   inconsistency. Clarify whether G5 should be updated to D3.

4. **Save WMVPF output** (MINOR-1): Add `fwrite(out, ...)` or `saveRDS()`
   at the end for reproducibility.

5. **Document consumption parameters** (MINOR-2): Add slide citation for
   `cons_inss = 1536.4` and `cons_pop = 1473.1`.

---

## Open Questions for Professors

1. **I4 → G4/H2:** Should I4 load G5/H3 outputs instead? Or are G4/H2
   intentionally the correct sources for the selection/tax estimates?

2. **Discount factor:** Is the 0.005/period discount intentional? The slight
   inconsistency between `1.005^3` (cost) and `0.995^3` (welfare) — is this
   by design or an oversight?

3. **Tax externality:** The commented-out code (line 225) subtracted `change_taxes`
   from net cost. The active code doesn't. Was the tax externality intentionally
   removed from the WMVPF, or is it planned for a future iteration
   (e.g., Surrogate Index for future tax revenues)?

4. **Consumption data source:** Where do `cons_inss = 1536.4` and
   `cons_pop = 1473.1` come from? ELSI? POF? Which year?
