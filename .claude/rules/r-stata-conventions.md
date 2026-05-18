---
paths:
  - "**/*.R"
  - "**/*.do"
  - "trans_retirement/code/**"
---

# R & Stata Coding Conventions

Standards for the Optimal Pension Reforms pipeline (stages A-I).

---

## Stage Naming Convention

- Each pipeline stage has a letter (A-I) and a version number.
- **Highest number = canonical** for most stages: A4, B4, C6, D4, E4, H3.
- **Exceptions:**
  - **G:** G5 is canonical. G6 is LEGACY (expenditures path abandoned).
  - **I:** I4 is canonical. I5 is LEGACY (pure reforms under abandoned strategy).
  - **F:** F1-F7 are ALL LEGACY. Canonical = `new_counterfactual_claiming3_pure.R`.
- Legacy files should be moved to `trans_retirement/code/legacy/` in Phase 2.

---

## R Conventions

### Setup
- `set.seed()` called ONCE at the top of the script (never inside loops/functions).
- All packages loaded at top via `library()` (not `require()`).
- Use `renv` lockfile for version pinning when possible.

### Paths
- All paths relative to repository root or a single base path variable.
- No `setwd()` — ever.
- Output directories created with `dir.create(..., recursive = TRUE, showWarnings = FALSE)`.
- No hardcoded absolute paths in committed code.
  - `U:/` and `F:/` paths are acceptable ONLY in scripts that run exclusively on the restricted-access server. Document at script header.
- Use `file.path()` for cross-platform path construction.

### Output Convention
- Stage outputs go to `trans_retirement/output/<stage_letter>/`.
- Intermediate RData/RDS go to `trans_retirement/output/rdata/`.
- Figures go to `trans_retirement/output/figures/`.
- Tables go to `trans_retirement/output/tables/`.

### Data Handling
- Identifier variable: `cpf_anon` (anonymized CPF: id_0000001, id_0000002, ...).
- Old code may use `indiv` — reconcile per-file via semantic search, NOT project-wide find-replace (`indiv` may appear in non-CPF contexts).
- Always check for NA propagation: explicit `na.rm = TRUE` or `na.rm = FALSE` on every `mean()`, `sum()`, `var()`, `sd()`.
- After every filter/merge, report observation count: `message("After filter: ", nrow(df), " obs")`.

### Style
- 2-space indentation, no tabs.
- Lines under 100 characters where possible (EXCEPT documented math formulas).
- `snake_case` for variables and functions.
- Pipe style: use `|>` (base R) for new code; `%>%` acceptable in existing code.
- `TRUE`/`FALSE` always (never `T`/`F`).

### Packages (core stack)
- `data.table` for large-data manipulation.
- `fixest` (`feols`) for fixed-effects estimation.
- `ggplot2` for figures.
- `haven` for Stata file I/O (`read_dta`, `write_dta`).

---

## Stata Conventions

### Setup
- First line: `version 16` (or the version used in the project).
- `set seed <number>` at the top if any randomization used.
- `cap log close` at the very top (defensive).
- `set more off` at the top.

### Paths
- No `cd` in scripts — use full relative paths from a single root global.
- Define root path once: `global root "F:/Users/tucalins/Documents/..."`.
- All subsequent paths via `"${root}/subdir/file.dta"`.
- No mixing of `U:/` and `F:/` within the same script.

### Variable Discipline
- Use `local` for loop-scoped values, `global` only for cross-script paths.
- Use `tempfile` and `tempvar` for intermediates.
- No `clear all` mid-pipeline (destroys globals needed by downstream).
- `compress` before `save` (reduces .dta file sizes).
- `label data` and `label var` on all created datasets and variables.

### Merge & Append Safety
- `assert` after every merge: `assert _merge == 3` (or the expected pattern).
- Report observation counts: `count` after every filter or merge.
- Always specify merge type: `merge 1:1`, `merge m:1`, etc.

### B-stage and C-stage
- B1-B3 are `.do` files (upstream of B4). Must run before B4.
- C3 is a `.do` file (upstream of C4-C6). Must run before C4.

---

## Cross-Language Rules

### Consistency
- Same variable names across R and Stata for the same concept.
- Same sample restrictions applied in same order.
- Same seed values for any bootstrap/simulation.

### Handoff Points
- Stata produces `.dta` files consumed by R via `haven::read_dta()`.
- R produces `.rds` or `.RData` files — NOT consumed by Stata (one-way flow).
- At handoff points, document: variable names, sample size, key summary stats.

---

## Anti-Patterns (flag as bugs)

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| `setwd()` in R | Breaks on other machines | Use relative paths |
| `clear all` mid-pipeline in Stata | Destroys globals | Use `clear` (not `all`) or scope with `preserve`/`restore` |
| Missing `na.rm` on aggregation | Silent NA propagation | Always explicit |
| `require()` in R | Silent failure | Use `library()` |
| `T`/`F` instead of `TRUE`/`FALSE` | Can be overwritten | Spell out |
| Absolute paths in committed code | Non-portable | Use relative + base variable |
| `print()` for status messages | Clutters output | Use `message()` |
| Growing vectors in loops | O(n^2) performance | Pre-allocate |
| F7/G6/I5 referenced as canonical | Strategy reverted | Use F-new/G5/I4 |
