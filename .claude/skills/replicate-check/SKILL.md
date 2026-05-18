---
name: replicate-check
description: Run a pipeline script on sample data and compare outputs against the gold-standard block in the script header. Reports PASS/FAIL per metric with tolerance thresholds.
argument-hint: "<stage-letter or script-path>"
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Replicate Check

Run a pipeline script on the 5% sample and compare key outputs against the
gold-standard block recorded in the script header.

## Canonical File Mapping

| Stage | Canonical Script |
|-------|-----------------|
| A | `A4_balance_check.R` |
| B | `B4_create_clean_candidates_cross.R` |
| C | `C6_estimate_continuous_contrib.R` |
| D | `D4_create_panel.R` |
| E | `E4_plots_claiming_distributions.R` |
| F | `new_counterfactual_claiming3_pure.R` |
| G | `G5_effect_average_benefit_freq_bL_and_bS.R` |
| H | `H3_policy_elasticity.R` |
| I | `I4_wmvpf_no_pure_reforms_freq.R` |

**SKIP list (LEGACY):** F1, F2, F3, F4, F5, F6, F7, G6, I5.

## Steps

### Step 1: Resolve Script

If `$ARGUMENTS` is a single letter (A-I), map to canonical script above.
If `$ARGUMENTS` is a path, use it directly.

Find the script in `trans_retirement/code/`.

### Step 2: Parse Gold Standard

Read the script header and extract the gold-standard block:

```
# == GOLD STANDARD (sample run YYYY-MM-DD) ==
# key: value
# == END GOLD STANDARD ==
```

If no gold-standard block exists:
- Report: "No gold standard recorded. Run the script first to establish baseline."
- Offer to run the script and record the gold standard.

### Step 3: Run Script

```bash
# R scripts
Rscript trans_retirement/code/<script>.R

# Stata scripts (B1-B3, C3)
stata-mp -b do trans_retirement/code/<script>.do
```

If sample data is not available, report:
"Sample data not found. Cannot run replicate check. Static analysis only."

### Step 4: Extract Key Outputs

After the script runs, extract the same metrics that appear in the
gold-standard block. Sources:
- stdout/stderr from the script run
- Output files in `trans_retirement/output/`
- .RData or .rds files loaded and inspected

### Step 5: Compare

Apply tolerance thresholds from `.claude/rules/replication-protocol.md`:

| Type | Tolerance |
|------|-----------|
| Integers (N, counts) | Exact match |
| Point estimates | < 0.01 |
| Standard errors | < 0.05 |
| P-values | Same significance level |

### Step 6: Report

```markdown
# Replicate Check: [script_name]
**Date:** [YYYY-MM-DD]
**Gold standard from:** [date in gold standard block]

## Results

| Metric | Gold Standard | Current | Diff | Status |
|--------|--------------|---------|------|--------|
| N_obs  | 12345        | 12345   | 0    | PASS   |
| ATT    | 0.0456       | 0.0461  | 0.005| PASS   |

## Overall: [PASS / FAIL]
[If FAIL: which metrics exceeded tolerance and by how much]
```

## Important

- Do NOT flag number differences within tolerance as failures.
- Do NOT flag sampling noise (sample != full data).
- DO flag: NaN/NA in outputs, wrong signs, infinite values, zero obs counts.
- If the gold-standard block is outdated (script has been modified since),
  warn and suggest re-establishing the baseline.
