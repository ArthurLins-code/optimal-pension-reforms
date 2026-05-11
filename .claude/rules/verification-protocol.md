---
paths:
  - "**/*.R"
  - "**/*.do"
---

# Verification Protocol

**After any edit to a pipeline script, verify before committing.**

---

## Verification Steps

### 1. Static Checks (always)

Before running, verify:

- [ ] No syntax errors (parse the file: `parse("script.R")` in R, or `do "script.do"` dry-run).
- [ ] No new hardcoded absolute paths introduced.
- [ ] No references to LEGACY files (F1-F7, G6, I5) as canonical.
- [ ] Variable names consistent (`cpf_anon` not `indiv` in new code).
- [ ] Formula matches canonical deck (cite slide number).
- [ ] No `NA`/`NaN` producing operations without guards.

### 2. Sample Run (when data available)

If the 5% sample data is available in `data_local/` or `transfer_may_retirement/data/`:

```bash
# R scripts
Rscript trans_retirement/code/<script>.R

# Stata scripts
stata-mp -b do trans_retirement/code/<script>.do
```

After running:
- [ ] Exit code = 0 (no errors).
- [ ] No new warnings in stderr (compare to baseline).
- [ ] No `NaN`/`NA`/`Inf` in key output variables.
- [ ] Observation counts reasonable (not zero, not duplicated).
- [ ] Output files created in expected locations.
- [ ] Compare to gold-standard block (per replication-protocol.md).

### 3. When Data is NOT Available

If sample data is not accessible (e.g., working on laptop without data_local/):

State explicitly in the commit message:
```
Static-checked only — sample data not available on this machine.
Reason: [working on laptop / data_local/ not mounted / etc.]
```

Still perform all static checks from Step 1.

---

## Verification Checklist by Stage

| Stage | Key Verification |
|-------|-----------------|
| A4 | Balance table has no NA cells; N_id + N_unid ~ expected total |
| B4 | Feature matrix complete (no all-NA columns); N claimants > 0 |
| C6 | contrib_time_cont has no NA for linked CPFs; R-sq > 0 |
| D4 | Panel is balanced or documented unbalanced; points_norm centered at 0 |
| E4 | All plots generated as PDF; no empty plots |
| F-new | Counterfactual frequencies > 0 for all cells; no NaN in hazard |
| G5 | ATT coefficients have expected signs; SEs finite |
| H3 | Elasticity estimate finite; IPW weights bounded |
| I4 | MVPF in (0, 1); WMVPF in (0, 1); welfare weights sum to ~1 |

---

## Downstream Impact Check

When modifying an upstream script, verify downstream consumers are unaffected:

```
A4 -> (standalone)
B4 -> C6, D4
C6 -> D4
D4 -> E4, F-new, G5, H3
F-new -> G5, H3, I4
G5 -> I4
H3 -> I4
```

If your change alters the output schema (column names, types, dimensions),
check ALL downstream scripts that consume the output.

---

## Reporting

After verification, add a line to the commit message:

```
Verified: [sample-run / static-only]
Stage: [letter]
Downstream: [checked / not-applicable / needs-check]
```
