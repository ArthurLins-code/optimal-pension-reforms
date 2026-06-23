# Legacy / Non-Workflow Bugs

Bugs still present in the code but in files **outside the current canonical workflow** (the superseded `H3` stage; the
off-pipeline Portuguese deck), plus items that were **corrected or proved false** during the restructure. Kept for the
record; **none affects the live pipeline**. Open workflow bugs are in [`restructure_findings.md`](restructure_findings.md).
Re-verified 2026-06-23 (6-agent per-file re-check).

## Still present, but off the live workflow (low priority)

| id | file:line (current) | description | why off-workflow |
|----|---------------------|-------------|------------------|
| **h3-nosample** | `analysis/code/H3_policy_elasticity.R:20` (guard); `indiv` at H3:52/54/59/86/115-123/146/359 | H3 has **no sample branch** — Stage-2 added a config preamble + a `stop()` unless `DATA_MODE=='full'` — and still uses the old `indiv` identifier (no `cpf_anon`). | H3 is full-data-only, on **no master**, and **effectively superseded by H2** (which supplies the live elasticity table + deck figure — see `h2-vs-h3` in `restructure_findings.md`). If H3 is retired in favour of H2 this becomes moot. |
| **apresentacao-graphicspath** | `presentation/latex/apresentacao/_main.tex:3` | The Portuguese deck uses `\graphicspath{{../figures/}}` (legacy `latex/figures/`), so shared `E3_`/`F4_` figure names can resolve to **stale legacy images** rather than the collector-routed canonical ones. | The PT deck is **off the collector/manifest pipeline**; the live deck is the English `presentation/latex/presentation/`, built by `build_deck.R`. The PT deck is not built by the workflow. |

## Closed — corrected or false positive (no longer tracked)

| id | file | verdict (re-verified 2026-06-23) |
|----|------|----------------------------------|
| **O5c** | G5 (`delta_ben`) | **CORRECTED** — the G2 import was removed; `delta_ben` is computed once from G5's own `dt_agg`/`results` (G5:732-742), not read ×3 from `G2_table_results`. Only a comment documenting the removal remains. |
| **O5a** | G5 (MECH) | **FALSE POSITIVE** — MECH uses `claims_c` correctly (G5:611-614); the `claims_L/claims_S` usage is the (correct) BEHAV term (G5:718-719). |
| **O3** | D4 (~L249) | **FALSE POSITIVE** — parens balance (D4:247-250); the file parses. There is no stray `)`. |
