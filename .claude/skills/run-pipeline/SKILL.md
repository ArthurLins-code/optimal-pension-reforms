---
name: run-pipeline
description: Run one or more stages of the canonical pipeline (A-I) in dependency order. Resolves stage letters to canonical scripts, checks prerequisites, and executes sequentially.
argument-hint: "<stage-letter(s)> [--from A --to I] [--dry-run]"
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Run Pipeline

Execute pipeline stages in the correct dependency order, using canonical scripts only.

## Canonical File Mapping

| Stage | Canonical Script | Language | Prerequisites |
|-------|-----------------|----------|---------------|
| A | `A4_balance_check.R` | R | (standalone) |
| B | `B4_create_clean_candidates_cross.R` | R | RAIS + SUIBE data; B1-B3.do first |
| C | `C6_estimate_continuous_contrib.R` | R | B4; C3.do first |
| D | `D4_create_panel.R` | R | C6 |
| E | `E4_plots_claiming_distributions.R` | R | D4 |
| F | `new_counterfactual_claiming3_pure.R` | R | D4, gabriel.R output |
| G | `G5_effect_average_benefit_freq_bL_and_bS.R` | R | D4, F-new |
| H | `H3_policy_elasticity.R` | R | D4, F-new |
| I | `I4_wmvpf_no_pure_reforms_freq.R` | R | F-new, G5, H3 |

### Stata Prerequisites

Before B4: run `B1.do`, `B2.do`, `B3.do` (in order).
Before C6: run `C3.do`.

### F-Stage Special Case

The F-stage has two scripts that must run in order:
1. `new_counterfactual_claiming3_gabriel.R` (upstream — generates intermediates)
2. `new_counterfactual_claiming3_pure.R` (downstream — decomposes Pure L/S)

**WARNING:** gabriel.R saves to `/tmp/` which is non-persistent. Both scripts
must run in the same session, or `/tmp/` outputs will be lost.

### SKIP List (LEGACY — never run)

- F1, F2, F3, F4, F5, F6, F7
- G6 (expenditures path — ABANDONED)
- I5 (pure reforms under abandoned strategy)

## Dependency Graph

```
A (standalone)
B1.do -> B2.do -> B3.do -> B4
C3.do -> C6 (depends on B4)
D4 (depends on C6)
E4 (depends on D4; terminal — no downstream)
gabriel.R (depends on D4) -> pure.R (depends on gabriel.R)
G5 (depends on D4, pure.R)
H3 (depends on D4, pure.R)
I4 (depends on pure.R, G5, H3)
```

## Usage

### Run a single stage
```
/run-pipeline G
```

### Run a range
```
/run-pipeline --from D --to I
```

### Dry run (show what would execute)
```
/run-pipeline --from A --to I --dry-run
```

## Steps

### Step 1: Parse Arguments

- Single letter: run that stage only.
- `--from X --to Y`: run all stages from X to Y inclusive.
- `--dry-run`: print execution plan without running.
- No arguments: print the full pipeline dependency graph.

### Step 2: Resolve Dependencies

For each requested stage, check that prerequisite outputs exist.
If not, warn and offer to run prerequisites first.

### Step 3: Execute

For each stage in dependency order:

```bash
# R scripts
Rscript trans_retirement/code/<script>.R

# Stata scripts
stata-mp -b do trans_retirement/code/<script>.do
```

After each stage:
- Check exit code (0 = success).
- Report: "Stage [X] completed. [N] seconds. Output in [path]."
- If failure: stop and report error. Do NOT continue to downstream stages.

### Step 4: Report

```markdown
# Pipeline Run Report
**Date:** [YYYY-MM-DD]
**Stages:** [list]

| Stage | Script | Status | Time | Notes |
|-------|--------|--------|------|-------|
| D | D4_create_panel.R | PASS | 45s | |
| F | gabriel.R + pure.R | PASS | 120s | |
| G | G5_effect_... | FAIL | 30s | Error at line 234 |

## Overall: [COMPLETE / PARTIAL — failed at stage X]
```

## Important

- NEVER run LEGACY scripts (F1-F7, G6, I5).
- Always run gabriel.R before pure.R (same session).
- Check for `/tmp/` persistence issue with gabriel.R outputs.
- If data is not available, report and stop.
