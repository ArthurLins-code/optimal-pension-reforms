# MVPF Domain Review: G5_effect_average_benefit_freq_bL_and_bS.R

**Date:** 2026-05-11
**Reviewer:** Claude (Opus) — static analysis only (no sample data)
**Canonical reference:** `Retirement_Presentations (old strat reverted).pdf`
**Phase:** 3 (Domain Review)

---

## Summary

- **Overall:** MAJOR ISSUES (runtime crash in Step 4; formula questions)
- **Issues:** 2 critical, 4 major, 5 minor
- **Canonical deck alignment:** PARTIAL DRIFT DETECTED (bS formula, WMVPF_L)
- **Runtime status:** Script will CRASH at line 625 (undefined variable)

---

## Lens 1: Assumption Audit

### A1 (Deterministic point accrual): SATISFIED
- Line 76: `points_norm := ifelse(male == 0, points_d - 85, points_d - 95)` ✓
  Matches P_BAR_WOMEN=85, P_BAR_MEN=95 (constants.R, slide 12/56).

### A3 (Bunching window): IMPLICITLY USED
- Line 84-85: Points winsorized at [-15, 15]. The bunching window W=4 isn't
  parameterized here — it's consumed via F-stage counterfactual inputs.
  Winsorization range should be documented with rationale.

### A4 (Proportional mixing): USED IN STEP 4
- Lines 596-634 implement the postponement-origin calculation using A4.
  The code traces cohort trajectories backward using `origin_t = dist_reform - 2*(x + points_norm)`,
  which implements the deterministic path from A1 combined with the mixing
  from A4. Conceptually correct but **has runtime errors** (see CRITICAL-1).

### Welfare-weight specification:
- Lines 700-710: `gamma = 4`, `cons_inss = 1536.4`, `cons_pop = 1473.1`.
  Same values as I4. ✓
- No gamma sensitivity analysis in G5.

---

## Lens 2: Derivation Check

### Replacement rate formulas (lines 312-313): CORRECT
```r
dt[male==0, replacement_rate := 0.69 + (0.021 * (points_norm))]
dt[male==1, replacement_rate := 0.82 + (0.025 * (points_norm))]
```
Matches constants.R and slide 10/56. ✓

### Pure Level benefit (benefits_bL, lines 319-320): FORMULA QUESTION

**Code (men, p≥0):**
```r
benefits_bL := pv_benefits_new * (1 + (1-0.82) / replacement_rate)
             = pv_benefits_new * (1 + 0.025*p) / (0.82 + 0.025*p)
             = SB * ann * RR_PL / RR_pre
```

**Expected (Pure Level = level at 1, keep slope):**
```
RR_PL(p) = 1 + bS * p
pv_bL = SB * (1 + bS * p) * ann = SB * ann * RR_PL
```

**Discrepancy:** Code has an extra `/ RR_pre` factor. This means
`benefits_bL = pv_benefits_new * RR_PL / RR_pre` instead of
`pv_benefits_new * RR_PL`.

**[MAJOR-1] Possible explanation:** The formula may be computing the benefit
adjustment relative to the pre-reform schedule rather than in absolute terms.
If this is intentional (a ratio-based approach), it should be documented.
If not, the bL benefit is overstated at the threshold (where RR_pre < 1)
and understated far above (where RR_pre > 1).

**Impact on DD:** Since `1/RR_pre` varies only by points_norm (not by
dist_reform), the points_norm FE in the DD absorbs the level effect.
However, the DD coefficient captures `beta * f(points_norm)` where
`f = 1/RR_pre`, which varies across treatment groups. This could bias
the DD estimates for the counterfactual benefit decomposition.

**Recommendation:** Flag for professor review. Ask for the derivation
connecting the code formula to the canonical deck slides.

### [CRITICAL-1] Pure Slope benefit (benefits_bS, lines 322-323): LIKELY DECIMAL ERROR

**Code (men, p≥0):**
```r
benefits_bS := pv_benefits_new * (0.082 / replacement_rate)
```

**The value `0.082` appears suspicious.** Under Pure Slope reform, the level
stays at RR_pbar (0.82 for men), and the slope goes to 0. Expected:
```
RR_PS(p) = 0.82 (men) or 0.69 (women)
pv_bS = SB * RR_pbar * ann = pv_benefits_new * RR_pbar
```

The code uses `0.082` (one-tenth of `0.82`) and `0.069` (one-tenth of `0.69`).

**Evidence this is a decimal error:**
- `0.082 = 0.82 / 10` and `0.069 = 0.69 / 10` — exact factor-of-10 relationship.
- Same values appear in G3 (predecessor) at identical lines — error propagated.
- Same values in legacy G6 — consistently inherited.
- No economic rationale for dividing RR_pbar by 10 in the bS formula.

**Impact:** At p=0 (threshold): `benefits_bS = pv_benefits_new * 0.082/0.82 =
pv_benefits_new * 0.1`. This means the Pure Slope benefit is computed as
10% of the full-replacement benefit, instead of 82% (men) or 69% (women).
**All downstream pure slope computations are affected**, including MECH_S,
BEHAV_S, and WMVPF_bS.

**Even if corrected to 0.82:** The formula still has the `/ replacement_rate`
issue from MAJOR-1. With 0.82: `benefits_bS = pv_benefits_new * 0.82/RR_pre`.
At p=0: = pv_benefits_new * 1.0 (full replacement). Expected: pv_benefits_new * 0.82.
So even with the decimal fix, the formula produces the wrong magnitude.

**Recommendation:** CRITICAL priority. Verify the bS formula derivation against
the canonical deck appendix slides 25/57. The decimal values 0.082/0.069 are
almost certainly 0.82/0.69 with misplaced decimals, AND the overall formula
structure (`RR_pbar / replacement_rate` vs `RR_pbar`) needs verification.

### [MAJOR-2] bS model stored in wrong list (line 396):
```r
models_bL[[paste0('treat_bS_',g)]] <- feols(...)
```
Should be `models_bS[[...]]`. The bS models are accidentally stored in the
`models_bL` list. **Works by accident** because `c(models_bL, models_bS)` on
line 405 still finds all named elements (bS entries are in models_bL, and
models_bS is empty). But this is fragile and confusing.

### [CRITICAL-2] Undefined variables in Step 4 (lines 620-670):

The postponement-origin calculation has multiple undefined variable references:

1. **Line 625:** `oi <- dt_origin_of_pstpnmnt_merged_w_lookup[...]` — variable
   `dt_origin_of_pstpnmnt_merged_w_lookup` does not exist. Lines 620-624 create
   `..._merge` and `..._left` suffixed versions, but the unsuffixed name is used.

2. **Line 628:** `as.data.frame(dt_origin_of_pstpnmnt_merged_w_lookup)` — same
   undefined variable.

3. **Line 650:** `dt_merged_with_betas <- as.data.table(dt_merged_with_betas)` —
   `dt_merged_with_betas` is never created. It's used on lines 650-688 but no
   assignment creates it.

**Impact:** The script CRASHES at line 625. Everything from Step 4 onward
(Beta^{L,P}, Beta^{S,P}, post-pure-reform benefits, behavioral expenditures,
WMVPF_bL, WMVPF_bS) is unreachable.

**This means:** The pure-reform WMVPF computation in G5 (lines 693-721) has
**never been successfully executed** in its current form. The earlier parts
(DD on benefits, mechanical expenditures through Step 3) do complete.

### [MAJOR-3] WMVPF_L formula (line 716): OPERATOR PRECEDENCE ISSUE

```r
WVMVPF_L = (MECH_L - CNTRF * gamma * (cons_inss-cons_pop)/cons_pop) / (BEHAV_L - CNTRF)
```

The numerator is: `MECH_L - (CNTRF * gamma * (...))`.

But standard WMVPF = η * ME / TC = `(1 - delta) * (MECH_L - CNTRF) / (BEHAV_L - CNTRF)`.

Expanding: `((MECH_L - CNTRF) - delta*(MECH_L - CNTRF)) / (BEHAV_L - CNTRF)`.

The code computes: `(MECH_L - delta*CNTRF) / (BEHAV_L - CNTRF)`.

These differ by `delta * MECH_L` in the numerator. Unless the derivation in the
canonical deck differs from the standard WMVPF definition, this is a formula error.

**Note:** Since CRITICAL-2 makes this code unreachable, this hasn't produced
wrong results in practice. But it will need fixing before the pure-reform
WMVPF can be computed.

### [MAJOR-4] G5 reads G2_table_results.csv (line 683):

In the counterfactual benefit outlays section (line 683):
```r
results_selection <- fread('output/G/G2_table_results.csv')
```

G2 is an earlier version of the average benefit DD (using densities, not
frequencies). G5 should use its own results or G4's (frequency-based).
The selection correction from G2 may be inconsistent with the frequency-based
approach used in the rest of G5.

---

## Lens 3: Citation Fidelity

- **No explicit slide citations in code.** Key formulas (RR, bL, bS, WMVPF)
  should reference specific canonical deck slides.
- The Step 4 comments reference "Juan's definitions on the slides" (line 584)
  but don't cite specific slide numbers.

---

## Lens 4: Code-Theory Alignment

### Correct estimand: CONFIRMED (with caveat)
- G5 computes DD on **average benefits** (not expenditures). ✓
- The dependent variable is `avg_benefits_new_pv` / `avg_benefits_old_pv`
  (present value of average benefits). ✓
- However, the pure reform section (Steps 4-6) is unreachable due to CRITICAL-2.

### F-stage output: CORRECT
- Line 569: `fread("output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv")`.
  This is the NEW F-stage output with pure reform frequencies. ✓

### Data source: D1 (not D3)
- Line 27: `fread('working/D1_cross_section.csv.gz')` — uses D1.
- I4 uses D3. E4 uses D3. H3 uses D3. G5 is the only canonical file
  still using D1. This may produce inconsistencies.
- **Cross-reference with I4 review:** I4 uses D3 but reads G4 (which also
  uses D1). The G-stage pipeline hasn't been updated to D3.

### Dead variable (line 62):
```r
dt[, ann_factor := 1-((1+r_q)^(-quarters_remaining_of_life))/r_q]
```
This computes the annuity factor INCORRECTLY (wrong parenthesization:
`1 - x/r` instead of `(1-x)/r`). However, the CORRECT version
`ann_factor_q` is computed on lines 67-71 and is what's actually used.
`ann_factor` is a dead variable. **Not a bug, but should be removed.**

### Output filenames use G4 prefix:
- Lines 737-763: `ggsave(... filename = 'output/G/G4_eventstudy_...')`.
  G5's plots are saved with G4 filenames. This overwrites G4's outputs
  if both scripts run. Should use G5 prefix.

### Typo in filenames: "benegits" (lines 743-763):
- `G4_eventstudy_benegits_new_1.pdf` — should be "benefits".
  Consistent typo across all individual plot filenames.

---

## Lens 5: Logic Chain (Backward Check)

### G5 dependency verification:

| Input | Source | Status |
|-------|--------|--------|
| `working/D1_cross_section.csv.gz` | D1 (not D3!) | ⚠️ older version |
| `output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv` | F-new | ✓ correct |
| `output/G/G2_table_results.csv` | G2 (not G4/G5!) | ⚠️ see MAJOR-4 |
| `extra/Expectativa_Vida_IBGE.xlsx` | External (IBGE) | ✓ |

### G5 output verification:

| Output | Consumers | Status |
|--------|-----------|--------|
| `output/G/G5_table_results_selection.csv` | None in current pipeline | ⚠️ orphan |
| `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq.csv` | None in current pipeline | ⚠️ orphan |
| `output/G/G4_eventstudy_*.pdf` | Presentations | ⚠️ G4 prefix collision |

**Neither G5 output file is consumed by I4 or any other canonical script.**
I4 reads G4_table_results.csv (produced by G4, not G5). This means G5's
pure reform estimates are currently **orphaned** — computed but not used
downstream. The WMVPF decomposition into bL/bS components would need to
be in a separate I-stage script (I5 was this, but it's LEGACY).

---

## Minor Issues

### [MINOR-1] `set.seed(123)` — non-standard format (should be YYYYMMDD).
No randomization in G5, so inoperative.

### [MINOR-2] `setwd()` (line 19) — anti-pattern, but acceptable for server.

### [MINOR-3] `na.rm` inconsistencies:
- Line 110: `mean(pv_benefits_old)` — missing `na.rm`.
  Adjacent line 109: `mean(pv_benefits_new, na.rm = T)` — has it.
  Inconsistent within the same aggregation. If any NAs exist in pv_benefits_old,
  the result will be NA.

### [MINOR-4] Duplicate `lubridate` in package list (line 14, already loaded line 12).
Harmless but sloppy.

### [MINOR-5] Portuguese comments mixed with English.
Lines 328, 333, 472, 478, 531, etc. use Portuguese comments while the rest
is in English. Minor consistency issue.

---

## Critical Recommendations (Priority Order)

1. **Fix undefined variables in Step 4** (CRITICAL-2): Decide between
   `_merge` and `_left` join variants; assign to the variable name used
   downstream. Create `dt_merged_with_betas` from the appropriate merge.
   **This blocks all pure-reform WMVPF computation.**

2. **Verify bS decimal values** (CRITICAL-1): Confirm whether `0.082`/`0.069`
   should be `0.82`/`0.69`. If confirmed as decimal error, fix in G5
   (and in G3 which has the same values).

3. **Verify bL and bS formula structure** (MAJOR-1): The `/ replacement_rate`
   factor in both benefit formulas needs theoretical justification or correction.
   Ask professors for the derivation.

4. **Fix bS model list assignment** (MAJOR-2): Line 396: change `models_bL`
   to `models_bS`. Works by accident now but fragile.

5. **Verify WMVPF_L formula** (MAJOR-3): Check operator precedence in the
   numerator. The current code computes something different from standard η*ME/TC.

6. **Update data source to D3** (MINOR but cross-cutting): Align G5 with
   the rest of the canonical pipeline that uses D3.

---

## Open Questions for Professors

1. **bL/bS benefit formulas:** What is the derivation connecting
   `benefits_bL = pv_benefits_new * (1 + (1-RR_pbar)/RR)` to the
   Pure Level reform definition? Is the division by `replacement_rate`
   intentional?

2. **0.082/0.069:** Are these the intended values for the bS formula,
   or should they be 0.82/0.69?

3. **Step 4 (Beta^{L,P} calculation):** The code has undefined variables
   and appears to be work-in-progress. Is there a working version of
   this section (possibly in a notebook or alternative file)?

4. **G5 output orphaning:** G5's outputs aren't consumed by I4 (which
   reads G4). Is there a planned I-stage script that will consume G5's
   pure-reform outputs for WMVPF_bL/WMVPF_bS estimation?

5. **G2 vs G4/G5 for selection correction:** Line 683 reads G2 results.
   Should this use G4 (frequency-based, consistent with G5's approach)?
