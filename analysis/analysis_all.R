# =============================================================================
# analysis/analysis_all.R — panel → figures, tables, estimates → deck inputs.
# Runs on the 5% SAMPLE (the entry point researchers use most). Stage list is
# generated from the validated DAG (baseline/dependency_graph.md).
# =============================================================================
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))

# Clear the persistent temp (safe). Do NOT wipe analysis_output: in sample mode it holds the
# pre-supplied prerequisite tables (legacy F5, sibling G4/H2) that gabriel/I4/I6 consume.
clear_dirs(PATHS$analysis_temp)

# --- prerequisite tables (FLAGS g-f5, i4-g4h2) — fail LOUDLY if absent; never run on missing ---
.suffix  <- if (DATA_MODE == "sample") "_sample" else ""
.prereqs <- c(
  file.path(PATHS$output_F, "F5_table_results.csv"),                      # gabriel reads legacy F5 (no suffix)
  file.path(PATHS$output_G, "G4_table_results.csv"),                      # I4 (no suffix)
  file.path(PATHS$output_G, paste0("G4_table_results", .suffix, ".csv")), # I6 (suffix-aware)
  file.path(PATHS$output_H, "H2_table_results.csv"),                      # I4 (no suffix)
  file.path(PATHS$output_H, paste0("H2_table_results", .suffix, ".csv"))  # I6 (suffix-aware)
)
.missing <- unique(.prereqs[!file.exists(.prereqs)])
if (length(.missing))
  stop("analysis_all.R: missing prerequisite table(s) the canonical stages consume:\n  ",
       paste(.missing, collapse = "\n  "),
       "\nThese come from non-canonical/legacy producers (G4, H2_policy_elasticity_MW, legacy F5).\n",
       "See quality_reports/restructure_findings.md (flags g-f5, i4-g4h2). Produce them first; ",
       "do not run the pipeline on missing inputs.")

run_stage("E4_plots_claiming_distributions.R")          # claiming-distribution figures (terminal)
run_stage("new_counterfactual_claiming3_gabriel.R")     # F counterfactual claim counts (upstream of pure)
run_stage("new_counterfactual_claiming3_pure.R")        # canonical F: pure L/S schedules
run_stage("G5_effect_average_benefit_freq_bL_and_bS.R") # DD on avg benefits + contrafactual benefits
run_stage("I4_wmvpf_no_pure_reforms_freq.R")            # WMVPF (actual reform)
run_stage("I6_wmvpf_with_pure_reforms_freq.R")          # WMVPF + pure L/S decomposition (headline numbers)
# EXCLUDED: H3_policy_elasticity.R is full-data only (no sample branch — flag h3-nosample).
#           I7 / I7b are diagnostics — run manually when needed.

message("ANALYSIS complete → ", PATHS$analysis_output)
