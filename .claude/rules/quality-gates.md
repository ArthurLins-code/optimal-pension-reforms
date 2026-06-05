---
paths:
  - "**/*.R"
  - "**/*.do"
---

# Quality Review & Scoring Rubrics

> **Framing:** Thresholds are **advisory at the harness level**. The `/commit`
> skill runs quality checks and halts on failure until the user fixes or
> explicitly overrides. There is no git pre-commit hook that blocks a direct
> `git commit` — if you bypass the skill, you bypass the review. "Gate" in
> this file means "checkpoint enforced by a specific skill," not "repo-wide block."

## Thresholds

- **80/100 = Commit** -- good enough to save
- **90/100 = PR** -- ready for review by professors
- **95/100 = Excellence** -- publication-ready replication package

## R Scripts (.R)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Syntax error / won't run | -100 |
| Critical | Silent NA propagation (mean/sum without na.rm check) | -20 |
| Critical | Code-paper drift (formula doesn't match canonical deck) | -15 |
| Critical | Unreproducible seed (missing or inside loop) | -15 |
| Major | Missing obs count after filter step | -10 |
| Major | Hardcoded absolute paths (in committed code) | -10 |
| Major | Stale reference to legacy outputs (F1-F7, G6, I5) | -10 |
| Major | Wrong estimand (expenditures instead of avg benefits) | -10 |
| Minor | Uncommented magic numbers | -5 |
| Minor | Missing version pin (renv lockfile) | -5 |
| Minor | Long lines in non-mathematical code (>100 chars) | -1 |
| Minor | Missing header block (title, purpose, inputs, outputs) | -3 |

## Stata Scripts (.do)

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Syntax error / won't run | -100 |
| Critical | Missing `version` directive | -15 |
| Critical | Missing `set seed` when randomization used | -15 |
| Critical | `clear all` mid-pipeline (destroys globals) | -10 |
| Major | Missing `assert` after merge | -10 |
| Major | Hardcoded absolute paths without root global | -10 |
| Major | Missing obs count after filter | -10 |
| Minor | Missing `compress` before `save` | -3 |
| Minor | Missing `label var` on created variables | -3 |
| Minor | Unlabeled dataset | -2 |

## Cross-Language Issues

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Variable name mismatch at handoff (e.g., `indiv` vs `cpf_anon`) | -15 |
| Critical | Sample restriction inconsistency between R and Stata | -15 |
| Major | Missing documentation at handoff point | -10 |
| Minor | Inconsistent naming convention across languages | -5 |

## Enforcement (by the /commit skill only)

- **Score < 80:** Halt within `/commit`. List blocking issues. User may override
  with an explicit natural-language signal ("commit anyway" / "skip quality gate")
  and a reason — the override is logged in the commit body.
- **Score < 90:** Allow commit within `/commit`, warn. List recommendations.
- **Direct `git commit`** (bypassing the skill): no enforcement.

## Tolerance Thresholds (Research)

| Quantity | Tolerance | Rationale |
|----------|-----------|-----------|
| Integers (N, counts) | Exact match | No reason for difference |
| Point estimates (ATT, MVPF) | < 0.01 | Floating-point rounding |
| Standard errors | < 0.05 | Numerical precision |
| P-values | Same significance level | Exact p may differ |
| Replacement rates | < 0.001 | Known formula |

## Quality Reports

Generated **only at merge time**. Save to `_docs/quality_reports/`.
