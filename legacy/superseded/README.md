# legacy/superseded — archived version-predecessors (do not run)

These 11 files were superseded by a higher-numbered canonical version of the **same** analysis step and are no
longer used by any master script, the deck, or any live file — verified by output-consumer tracing in the
2026-06-23 usage audit. Each begins with a `stop()` naming its canonical replacement.

This is distinct from the parent [`../`](../) folder, which holds the **strategy-reverted** legacy (F1–F7, G6, I5)
from the abandoned "expenditures" path. Here the files are simply *older versions of a step that still exists*.

| Archived file(s) | Superseded by |
|------------------|---------------|
| `E1_plots_claiming_distributions.R`, `E3_plots_claiming_distributions.R`, `E2_frictions.R` | `analysis/code/E4_plots_claiming_distributions.R` |
| `G1_effect_average_benefit.R`, `G2_effect_average_benefit.R`, `G3_effect_average_benefit_bL_and_bS.R` | `analysis/code/G5_effect_average_benefit_freq_bL_and_bS.R` |
| `H1_policy_elasticity_MW.R` | `analysis/code/H2_policy_elasticity_MW.R` |
| `I1_wmvpf.R`, `I2_wmvpf.R` | `analysis/code/I4_wmvpf_no_pure_reforms_freq.R` |
| `I3_wmvpf_pure_reforms.R` | `analysis/code/I6_wmvpf_with_pure_reforms_freq.R` |
| `new_counterfactual_claiming2.R` | `analysis/code/new_counterfactual_claiming3_pure.R` |

To restore one: `git mv legacy/superseded/<file> analysis/code/<file>` and delete the `stop()` guard line.
