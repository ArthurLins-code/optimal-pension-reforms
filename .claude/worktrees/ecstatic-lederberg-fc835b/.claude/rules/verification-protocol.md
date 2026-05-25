---
paths:
  - "scripts/R/**/*.R"
  - "scripts/stata/**/*.do"
  - "paper/**/*.tex"
---

# Task Completion Verification Protocol

**At the end of EVERY task, Claude MUST verify the output works correctly.** This is non-negotiable.

## For R Scripts:
1. Run `Rscript scripts/R/filename.R`
2. Verify output files (PDF, PNG, RDS, CSV, .tex tables) were created with non-zero size
3. Spot-check estimates for reasonable magnitude

## For Stata Do-Files:
1. Run `stata-mp -b do scripts/stata/filename.do`
2. Check log file for errors
3. Verify output files were created with non-zero size

## For LaTeX Manuscripts:
1. Compile with xelatex and check for errors
2. Check for undefined citations
3. Verify PDF was generated

## Common Pitfalls:
- **Missing output directories**: Check that `output/` subdirectories exist before running scripts
- **Assuming success**: Always verify output files exist AND contain correct content
- **Hardcoded paths**: All paths should be relative to the repository root
- **Package dependencies**: Check that required R/Stata packages are available

## Verification Checklist:
```
[ ] Output file created successfully
[ ] No execution errors
[ ] Output file sizes > 0
[ ] Spot-checked key results for plausibility
[ ] Reported results to user
```
