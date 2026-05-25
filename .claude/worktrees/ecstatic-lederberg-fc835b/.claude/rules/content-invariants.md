---
paths:
  - "scripts/R/**/*.R"
  - "scripts/stata/**/*.do"
  - "code/**/*"
---

# Content Invariants (INV-1 through INV-4)

Numbered non-negotiable rules for content produced in this repository. Reviewer agents and audit agents should cite invariants by number (e.g., "violates INV-2") when flagging issues.

## R script invariants

- **INV-1: `set.seed()` once at top.** Every R script that uses randomness must call `set.seed(N)` exactly once, at the top of the script, before any stochastic code. Never inside loops or functions.
- **INV-2: Relative paths only.** No absolute paths (`/Users/...`, `C:\...`, `~` expansion). All paths relative to the repository root. Use `file.path()` for cross-platform compatibility.
- **INV-3: Project theme on all plots.** Every ggplot figure must use the project's custom theme (if one exists). No default ggplot2 gray backgrounds should appear in any committed figure.
- **INV-4: Single bibliography.** If a `.bib` file exists in the project, it is canonical. No per-script or per-analysis `.bib` files. All citations must resolve against this one file.
