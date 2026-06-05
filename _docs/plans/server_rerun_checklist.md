# Server Rerun Checklist

**Purpose:** Step-by-step guide for re-running the corrected pipeline on full data.
**When:** After merging PR #1 (branch `claude/magical-borg-18ac72`).

---

## Pre-Flight

1. `git pull` or `git checkout claude/magical-borg-18ac72`
2. Verify `DATA_MODE` will be `"full"` (check that `F:/Users/tucalins/...` exists)
3. Confirm `constants.R` is in `trans_retirement/code/`

---

## Rerun Order

### 1. G5 (canonical G-stage)

```bash
Rscript trans_retirement/code/G5_effect_average_benefit_freq_bL_and_bS.R
```

**What changed (Phase 3-4):**
- bS decimal: 0.082 → 0.82 (men), 0.069 → 0.69 (women) — lines 322-323
- Step 4.5 created: collapses dt_beta, merges Beta_LP/Beta_SP into dt_merged
- Step 2 merge fix: group type mismatch (string vs integer)
- dt_agg column name fix in SAVING section
- models_bS list assignment fix (line 407)
- Sample-mode detection added (transparent in full mode)

**Verify:**
- [ ] Script completes Steps 1-6 without crashing
- [ ] `output/G/G5_table_results_selection.csv` created
- [ ] `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq.csv` created
- [ ] No NaN/Inf in outputs
- [ ] bS benefits are ~82%/69% of full replacement (not ~8.2%/6.9%)

### 2. H3 (canonical H-stage) — unchanged

```bash
Rscript trans_retirement/code/H3_policy_elasticity.R
```

Only a filename typo was fixed (noyearr → noyear). No functional changes.

### 3. I4 (canonical I-stage, actual reform WMVPF)

```bash
Rscript trans_retirement/code/I4_wmvpf_no_pure_reforms_freq.R
```

**What changed (Phase 4):**
- Sample-mode detection added (transparent in full mode)
- Removed unused knitr, deduplicated lubridate

**Verify:**
- [ ] Script completes without errors
- [ ] `output/I/I4_table_wmvpf.csv` created
- [ ] WMVPF in (0, 1) range — expected ~0.18 on full data
- [ ] No NaN/Inf in outputs

### 4. I6 (NEW — combined actual + pure reform WMVPF)

```bash
Rscript trans_retirement/code/I6_wmvpf_with_pure_reforms_freq.R
```

**This is a new file** created in Phase 3. Combines I4's actual reform WMVPF
with G5's pure reform decomposition.

**Verify:**
- [ ] Script completes Parts 1-3 without errors
- [ ] All 7 outputs created (3 CSVs, 1 summary, 3 PDFs)
- [ ] **WMVPF_bS > WMVPF_bL** (key test — should be restored after bS fix)
- [ ] Welfare weight eta ≈ 0.828
- [ ] WMVPF_actual in (0, 1) range
- [ ] No NaN/Inf in outputs

---

## Expected Results (full data)

| Metric | Expected | Sample (5%) |
|--------|----------|-------------|
| WMVPF (actual) | ~0.18 | -0.19 (sample artifact) |
| WMVPF_bL | TBD | 0.82 |
| WMVPF_bS | TBD (> bL) | 1.92 |
| eta | ~0.828 | 0.828 |
| CRRA gamma | 4 | 4 |
| bS > bL? | YES | YES (after fix) |

**Note:** Sample WMVPF_actual is negative because 5% sample counts (N_a)
are mixed with full-data counterfactual frequencies (N^c), creating a ~20×
magnitude mismatch. This is expected and not a bug.

---

## Record Gold Standard

After successful rerun, add gold-standard block to each script header:

```r
# == GOLD STANDARD (server run YYYY-MM-DD) ==
# <key metrics>
# == END GOLD STANDARD ==
```

See `_docs/memory/10_corrections_log.md` for the full list of changes made.

---

## Open Questions for Professors

1. I4 loads G4/H2 — should these be G5/H3?
2. bL/bS formula: division by `replacement_rate` — intentional?
3. Consumption parameters source (cons_inss=1536.4, cons_pop=1473.1)?
4. Tax externality removed from I6 WMVPF — intentional?
5. G5 reads G2 output for selection correction — should use G4/G5?
6. D1 → D3 migration timeline for G5?
