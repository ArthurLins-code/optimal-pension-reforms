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

### [LEARN:g5-merge-fix] G5 Step 4 merge variable naming fixed (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 620)
**Severity:** CRITICAL (partial fix)
**Description:** Three variable references existed for the merge result:
`_merge` suffix, `_left` suffix, and unsuffixed. User clarified: `_left` join
was redundant, `oi` object was debugging artifact. Renamed `_merge` to unsuffixed
`dt_origin_of_pstpnmnt_merged_w_lookup` matching downstream code.
**Resolution:** FIXED in commit 2210c2e. NOTE: `dt_merged_with_betas` (line 650)
remains undefined — G5 still crashes at that point. Awaiting professor input.

### [LEARN:i6-created] I6 created as canonical I-stage with pure reform WMVPF (2026-05-11)
**Stage:** I
**File:** I6_wmvpf_with_pure_reforms_freq.R (NEW)
**Severity:** N/A (new file)
**Description:** Created to fill the gap left by I5 (LEGACY). Combines I4's actual
reform WMVPF with pure reform WMVPF_bL/WMVPF_bS consuming G5 outputs. Validated
on sample data — runs end-to-end. Three bugs caught and fixed during validation:
(1) directory path resolution, (2) cost discount factor formula, (3) G5 column merge.
**Resolution:** COMPLETE — committed in 116fef7 + 2ff4bdb. Sample run produces
WMVPF_actual=-0.19 (sample×full-data mismatch) and reversed bL>bS ordering
(consistent with G5 bS decimal error).

### [LEARN:i6-discount] I6 cost discount was identical to welfare discount (2026-05-11)
**Stage:** I
**File:** I6_wmvpf_with_pure_reforms_freq.R (line 256)
**Severity:** MAJOR
**Description:** Original formula `1/(1/DISCOUNT_Q)^(3*t)` simplifies to
`DISCOUNT_Q^(3*t)`, making cost and welfare discounting identical. Should be
`(1/DISCOUNT_Q)^(3*t)` to match I4 convention where costs accumulate at interest rate.
**Resolution:** FIXED in commit 2ff4bdb.

### [LEARN:g5-bS-decimal-fix] G5 bS decimal error fixed: 0.082→0.82, 0.069→0.69 (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (lines 322-323), G3 (lines 272-273)
**Severity:** CRITICAL
**Description:** Confirmed against canonical slides (slide 10/56, slide 25/57):
Pure Slope reform uses RR_pbar = 0.82 (men), 0.69 (women). Code had 0.082/0.069
(off by factor of 10). Fixed in both G5 and G3.
**Resolution:** FIXED — changed 0.082→0.82 and 0.069→0.69 in G5 and G3.

### [LEARN:g5-merged-betas-fix] G5 Step 4.5: created missing dt_merged_with_betas (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (after line 644)
**Severity:** CRITICAL
**Description:** Step 4.7 used `dt_merged_with_betas` but it was never created. The
object should be `dt_merged` enriched with Beta_LP and Beta_SP from `dt_beta`. Fix:
collapse dt_beta to unique (points_norm, dist_reform) pairs, then merge into dt_merged.
This was the missing Step 4.5 that the comments referenced but never implemented.
**Resolution:** FIXED — added Step 4.5 code to collapse and merge.

### [LEARN:g5-models-bS-fix] G5 bS models stored in correct list (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 407)
**Severity:** MAJOR
**Description:** bS loop stored models in `models_bL` instead of `models_bS`.
Worked by accident via c(models_bL, models_bS) concatenation.
**Resolution:** FIXED — changed `models_bL[[...]]` to `models_bS[[...]]`.

### [LEARN:g5-bL-formula-assumption] bL/bS division by replacement_rate documented (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (lines 319-326)
**Severity:** MAJOR (documented as assumption)
**Description:** Both bL and bS formulas divide by `replacement_rate`, producing
`pv_benefits_new * RR_reform / RR_pre` instead of `pv_benefits_new * RR_reform`.
This ratio-based approach is a potentially problematic assumption — the extra
1/RR_pre factor varies by points_norm and could bias DD coefficients across groups.
**Resolution:** DOCUMENTED as [ASSUMPTION] in code comments. Not changed per user
instruction — needs professor derivation verification.

### [LEARN:g5-g2-ref-documented] G5 reads G2 output: flagged as potential error source (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 705)
**Severity:** MAJOR (documented)
**Description:** G5 reads `output/G/G2_table_results.csv` for counterfactual benefit
outlays. G5 is a frequency-based upgrade from G2 (density-based) and should not
reference earlier G-stage outputs. This inconsistency could introduce errors.
**Resolution:** DOCUMENTED as [TODO:REVISE] in code comments. Not changed — needs
further investigation to determine correct source.

### [LEARN:g5-d1-documented] G5 D1 data source kept, documented for future revision (2026-05-11)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 27)
**Severity:** MAJOR (documented)
**Description:** G5 uses D1 while most canonical files use D3. Keeping D1 for now
since the pipeline has been working with it.
**Resolution:** DOCUMENTED as [TODO:FUTURE] in code comments. To be updated to D3
in a future revision with result verification.

### [LEARN:g5-sample-mode] G5 sample-mode environment detection added (2026-05-12)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (lines 14-22)
**Severity:** N/A (enhancement)
**Description:** Added dual-environment detection matching I6 pattern. Full mode uses
server F:/ path + D1 + life expectancy merge. Sample mode loads dt_sampled_anon.csv
(5% D1 sample with pre-merged columns) and skips redundant merge steps.
**Resolution:** COMPLETE — G5 runs end-to-end on sample data.

### [LEARN:g5-step2-merge] G5 Step 2 merge had mismatched group types (2026-05-12)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 579)
**Severity:** CRITICAL
**Description:** The merge creating `data_counterfactual_reforms_step_2` set
`group = points_norm` (integer) on left side and `as.numeric(group)` on right
(converting string '[-6,-3]' to NA). The merge always produced zero rows, making
all downstream pure reform computations (MECH, BEHAV, CNTRF) empty.
This bug was hidden because G5 crashed at Step 4 before reaching Step 2's merge.
**Resolution:** FIXED — use string `group` column from dt_agg on both sides; keep
points_norm as separate column.

### [LEARN:g5-dt-agg-overwrite] G5 dt_agg overwritten with different column names (2026-05-12)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (lines 130, 380, 773)
**Severity:** MAJOR
**Description:** `dt_agg` created at line 130 with `avg_benefits_new_pv` is overwritten
at line 380 with `avg_pv_benefits_new`. The SAVING section (line 773) references the
old column name, causing a crash. Pre-existing bug, hidden by earlier crashes.
**Resolution:** FIXED — updated line 773 to use current column names from the second dt_agg.

### [LEARN:g5-knitr-removed] G5 knitr removed from package list (2026-05-12)
**Stage:** G
**File:** G5_effect_average_benefit_freq_bL_and_bS.R (line 11)
**Severity:** MINOR
**Description:** `knitr` was in the package list but never used in G5. It failed to
load due to xfun incompatibility on Arthur's laptop R 4.2.2 installation.
**Resolution:** FIXED — removed knitr from package list.

### [LEARN:i4-sample-mode] I4 sample-mode environment detection added (2026-05-12)
**Stage:** I
**File:** I4_wmvpf_no_pure_reforms_freq.R (lines 17-116)
**Severity:** N/A (enhancement)
**Description:** Added dual-environment detection matching G5/I6 pattern. Full mode
preserves original D3 + life expectancy merge + panel join + benefit/PDV calculations.
Sample mode loads pre-computed dt_sampled_anon.csv and panel_sampled_anon.csv with
cpf_anon→indiv rename. Also removed unused knitr and deduplicated lubridate.
**Resolution:** COMPLETE — I4 runs end-to-end on sample data (54,338 cross-section +
4,129,688 panel obs). WMVPF_actual on sample = -0.19 (expected sample artifact).

### [LEARN:i4-knitr-removed] I4 knitr removed and lubridate deduplicated (2026-05-12)
**Stage:** I
**File:** I4_wmvpf_no_pure_reforms_freq.R (line 11)
**Severity:** MINOR
**Description:** `knitr` was in the package list but never used. `lubridate` appeared
twice. Same xfun incompatibility as G5.
**Resolution:** FIXED — removed knitr, deduplicated lubridate.
