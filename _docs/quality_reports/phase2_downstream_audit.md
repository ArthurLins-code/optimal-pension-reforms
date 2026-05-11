# Phase 2 Downstream Audit Report

**Date:** 2026-05-11
**Reviewer:** Claude (Opus)
**Purpose:** Verify that canonical downstream files (G5, H3, I4) do NOT
reference legacy F-stage outputs (F1-F7), confirming safe archival of legacy files.

---

## Methodology

Grepped every canonical downstream file for:
- `load(`, `readRDS(`, `source(`, `fread(`, `read_dta(`, `read_excel(`
- Any string matching F1-F7 filenames, G6, I5
- Any reference to `new_counterfactual` outputs

---

## Results by File

### G5_effect_average_benefit_freq_bL_and_bS.R

| Line | Code | Source |
|------|------|--------|
| 27 | `fread('working/D1_cross_section.csv.gz')` | D-stage output |
| 31 | `read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx'))` | Life expectancy table |
| 569 | `fread("output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv")` | **NEW counterfactual** |

- **Legacy F1-F7 references:** NONE
- **Status:** CLEAN

### H3_policy_elasticity.R

| Line | Code | Source |
|------|------|--------|
| 28 | `fread('working/D3_cross_section.csv.gz')` | D-stage output |
| 30 | `fread('working/D4_panel_claim.csv.gz')` | D-stage panel |

- **Legacy F1-F7 references:** NONE
- **Counterfactual references:** NONE (H3 does not load F-stage outputs)
- **Status:** CLEAN
- **Note:** Filename typo on line 411: `noyearr.pdf` (doubled 'r')

### I4_wmvpf_no_pure_reforms_freq.R

| Line | Code | Source |
|------|------|--------|
| 29 | `fread('working/D3_cross_section.csv.gz')` | D-stage output |
| 36 | `read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx'))` | Life expectancy table |
| 149 | `fread('output/F/new_counterfactual_claim_counts.csv')` | **NEW counterfactual** |
| 153 | `fread('output/G/G4_table_results.csv')` | **G4 output (see flag below)** |
| 155 | `fread('output/H/H2_table_results.csv')` | **H2 output (see flag below)** |

- **Legacy F1-F7 references:** NONE
- **Status:** CLEAN (for F-stage)

---

## Flags

### FLAG 1: I4 references G4 and H2, not G5 and H3

I4 loads `output/G/G4_table_results.csv` (line 153) and `output/H/H2_table_results.csv`
(line 155). The canonical files are G5 and H3.

**Possible explanations:**
- G4 and H2 produce summary tables in a format I4 expects, while G5/H3 are
  updated analysis scripts that may produce different output schemas.
- Stale references that should be updated to G5/H3 outputs.

**Action:** Flag for professor review. Do NOT change without confirmation.

### FLAG 2: gabriel.R uses relative `tmp/` directory

`new_counterfactual_claiming3_gabriel.R` (line 262) saves to `tmp/claims_actual_counterfactual_t_p.csv`.

- This is a **relative** path (`tmp/`), not system `/tmp/`.
- The `_docs/memory/02_pipeline.md` previously stated it was `/tmp/` (system) — corrected.
- Still fragile: depends on the working directory being set correctly.
- `new_counterfactual_claiming3_pure.R` does NOT read from `tmp/` — it produces
  its own outputs to `output/F/`.

**Action:** Defer to future session requiring Gabriel coordination.

---

## Conclusion

**Safe to archive F1-F7, G6, I5 to legacy/.** No canonical downstream file
references any of these legacy scripts or their outputs. All counterfactual
data flows through `new_counterfactual_claiming3_pure.R` → `output/F/`.
