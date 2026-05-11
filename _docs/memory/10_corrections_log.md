# Corrections Log

Structured log for discoveries, bug fixes, and methodology clarifications.
Use `[LEARN:tag]` entries. Append, never overwrite.

## Format

```
### [LEARN:tag] Short title (YYYY-MM-DD)
**Stage:** A/B/C/D/E/F/G/H/I
**File:** filename.R or filename.do
**Severity:** CRITICAL / MAJOR / MINOR
**Description:** What was found
**Resolution:** What was done (or "OPEN — awaiting professor review")
```

---

## Entries

### [LEARN:g5-crash] G5 Step 4 has undefined variables — pure reform WMVPF unreachable (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R
**Severity:** CRITICAL
**Description:** Lines 625, 628 reference `dt_origin_of_pstpnmnt_merged_w_lookup` (no suffix),
but lines 620-624 create `_merge` and `_left` suffixed variants. Line 650 references
`dt_merged_with_betas` which is never assigned. All code from Step 4 onward crashes.
This means the pure-reform WMVPF_bL / WMVPF_bS has never been computed from G5.
**Resolution:** OPEN — awaiting professor review. Need working version of Step 4+ code.

### [LEARN:g5-bS-decimal] G5 bS formula uses 0.082/0.069 instead of 0.82/0.69 (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (lines 322-323)
**Severity:** CRITICAL
**Description:** `benefits_bS` for men uses `0.082/replacement_rate` and for women
`0.069/replacement_rate`. Values 0.082 and 0.069 are exactly 1/10 of RR_pbar (0.82, 0.69).
Same decimal error present in G3 (lines 272-273) and legacy G6 (lines 322-323).
The pure slope benefit is computed as ~10% of full replacement instead of ~82%/69%.
**Resolution:** OPEN — awaiting professor confirmation that 0.082/0.069 should be 0.82/0.69.

### [LEARN:g5-bL-formula] G5 bL/bS formulas have extra /RR_pre factor (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (lines 319-323)
**Severity:** MAJOR
**Description:** Both bL and bS benefit formulas multiply by `(factor/replacement_rate)`,
producing `pv_benefits_new * RR_reform / RR_pre` instead of `pv_benefits_new * RR_reform`.
The extra 1/RR_pre division lacks clear economic interpretation in standard Pure L/S framework.
May be an intentional ratio-based adjustment or a formula error.
**Resolution:** OPEN — awaiting professor derivation.

### [LEARN:g5-models-bS-list] G5 bS models stored in models_bL list (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 396)
**Severity:** MAJOR
**Description:** `models_bL[[paste0('treat_bS_',g)]]` should be `models_bS[[...]]`.
Works by accident because `c(models_bL, models_bS)` concatenates both lists and
the bS models are found by name. But `models_bS` is empty.
**Resolution:** OPEN — straightforward fix, but deferring to Phase 4 testing.

### [LEARN:i4-g4h2] I4 loads G4/H2 outputs instead of G5/H3 (2026-05-11)
**Stage:** I
**File:** I4_wmvpf_no_pure_reforms_freq.R (lines 153, 155)
**Severity:** MAJOR
**Description:** I4 loads `output/G/G4_table_results.csv` and `output/H/H2_table_results.csv`.
G5 and H3 are canonical. G4 may be intentional (I4 only needs selection correction,
not pure reform decomposition). H2 (MW-based) vs H3 (IPW-DD) is more likely stale.
**Resolution:** OPEN — awaiting professor confirmation.

### [LEARN:i4-discount] I4 uses inconsistent discount factors (2026-05-11)
**Stage:** I
**File:** I4_wmvpf_no_pure_reforms_freq.R (lines 227, 235)
**Severity:** MAJOR
**Description:** Cost discounting uses `1.005^3` per quarter, welfare uses `0.995^3`.
These are approximately equal (~6% annual) but not mathematically identical
(`1/1.005 ≈ 0.99502 ≠ 0.995`). Cumulative difference ~0.06% over 12 quarters.
**Resolution:** OPEN — minor in magnitude but should be harmonized.

### [LEARN:g5-d1] G5 uses D1 cross-section while other canonical files use D3 (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 27)
**Severity:** MAJOR
**Description:** G5 loads `working/D1_cross_section.csv.gz`. I4, E4, H3, and F-new
all use D3. G1-G4 also use D1, so G5 inherited this from predecessors. D3 is the
updated cross-section that D4 (canonical) builds the panel from.
**Resolution:** OPEN — should be updated to D3 in Phase 4, with verification.

### [LEARN:g5-g2-ref] G5 reads G2_table_results for selection correction (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 683)
**Severity:** MAJOR
**Description:** The counterfactual benefit outlays section reads `output/G/G2_table_results.csv`
(density-based estimates from G2), despite G5 using a frequency-based approach. Should
use G4 or G5's own selection correction estimates for consistency.
**Resolution:** OPEN — awaiting professor review.
