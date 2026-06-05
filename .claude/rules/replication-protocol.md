---
paths:
  - "trans_retirement/code/**"
---

# Replication-First Protocol

**Core principle:** Before modifying a canonical script, run it on sample data
and record gold-standard outputs. After changes, re-run and compare.

---

## Phase 1: Record Gold Standard

Before modifying any canonical script (A4, B4, C6, D4, E4, F-new, G5, H3, I4),
run it on the 5% sample and record key outputs in a comment block at the script header:

```r
# == GOLD STANDARD (sample run YYYY-MM-DD) ==
# N_obs_after_filter: 12345
# mean_benefit: 2345.67
# ATT_coefficient: 0.0456
# WMVPF_estimate: 0.18
# == END GOLD STANDARD ==
```

For Stata scripts (B1-B3, C3):

```stata
/* == GOLD STANDARD (sample run YYYY-MM-DD) ==
   N_obs_after_filter: 12345
   mean_wage: 3456.78
   contrib_years_mean: 22.3
   == END GOLD STANDARD == */
```

### What to Record

| Stage | Key Metrics |
|-------|------------|
| A4 | N identified, N unidentified, balance p-values |
| B4 | N claimants with features, mean wage, mean tenure |
| C6 | N observations, mean contrib_time_cont, R-squared |
| D4 | N panel cells, N treated, N control |
| E4 | (Plots only — record N observations per plot) |
| F-new | N counterfactual claims (Pure L), N counterfactual claims (Pure S) |
| G5 | ATT on avg benefit (bL component), ATT on avg benefit (bS component) |
| H3 | Policy elasticity estimate, SE |
| I4 | MVPF, WMVPF, welfare weight eta |

---

## Phase 2: Modify & Re-Run

After making changes:

1. Re-run the script on the same 5% sample.
2. Compare outputs to gold-standard block.

### Tolerance Thresholds

| Type | Tolerance | Rationale |
|------|-----------|-----------|
| Integers (N, counts) | Exact match | No reason for difference |
| Point estimates (ATT, MVPF) | < 0.01 | Floating-point rounding |
| Standard errors | < 0.05 | Numerical precision |
| P-values | Same significance level | Exact p may differ slightly |
| Percentages / rates | < 0.1pp | Display rounding |

### If Mismatch Exceeds Tolerance

**Do NOT proceed.** Isolate which change introduced the difference:

1. Revert to pre-change version, re-run, confirm gold standard matches.
2. Apply changes one at a time, re-run after each.
3. Document the investigation in `_docs/quality_reports/`.
4. If unresolved, flag for professor review.

---

## Phase 3: Update Gold Standard

After verified changes:

1. Update the gold-standard block with new values.
2. Record the date and reason for change.
3. Commit with message referencing the change:
   `"Update gold standard for [stage] after [change description]"`

---

## Stata to R Translation Pitfalls

| Stata | R | Trap |
|-------|---|------|
| `reg y x, cluster(id)` | `feols(y ~ x, cluster = ~id)` | Stata clusters df-adjust differently |
| `areg y x, absorb(id)` | `feols(y ~ x \| id)` | Check demeaning method matches |
| `probit` for PS | `glm(family=binomial(link="probit"))` | R default logit != Stata default |
| `merge 1:1` | `merge(..., by=..., all=FALSE)` | Check _merge patterns match |
| `egen mean(x), by(g)` | `dt[, mean(x), by = g]` | NA handling differs |
| `gen x = .` | `x <- NA_real_` | Stata missing (.) vs R NA |

---

## Sample Validation vs. Paper Replication

**Important distinction for this project:**

- The 5% sample is for **validation** — confirming the code runs correctly
  and produces sensible outputs (right signs, right magnitudes, no NaN/NA).
- It is NOT for **replication** of the paper's exact numbers.
- Do NOT flag "sample MVPF != paper MVPF" as a bug.
- DO flag: NaN/NA in outputs, wrong signs, formula mismatches vs canonical deck,
  orders-of-magnitude errors, monotonicity violations.

---

## Enforcement

This protocol is enforced by the `/replicate-check` skill, which:
1. Parses the gold-standard block from the script header.
2. Runs the script on sample data.
3. Compares key outputs against gold-standard with tolerance thresholds.
4. Reports PASS/FAIL per metric.
