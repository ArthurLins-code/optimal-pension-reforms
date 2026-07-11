# =============================================================================
# analysis/analysis_all.R — panel → figures, tables, estimates → deck inputs.
# Runs on the 5% SAMPLE (the entry point researchers use most). Stage list is
# generated from the validated DAG (baseline/dependency_graph.md).
# =============================================================================
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))

# Clear the persistent temp (safe). Do NOT wipe analysis_output: it now holds regenerated in-repo
# outputs (incl. the G4/H2 _sample tables produced this run that I6 consumes). Prereq INPUTS are
# external (PATHS$prereq_root) and are never touched here.
clear_dirs(PATHS$analysis_temp)

# --- external prerequisite INPUT (FLAG g-f5) — fail LOUDLY if absent ------------------------------
# F5 is the ONLY external input: it has no sample producer (legacy full-data F5/F6/F7 only) and is
# read by gabriel/pure. Everything else — including the G4/H2 _sample tables I4 and I6 now both read
# (i4-g4h2 fixed) — is PRODUCED in-repo by the stages below.
.prereqs <- c(
  file.path(PATHS$prereq_root, "F", "F5_table_results.csv")    # gabriel/pure read legacy F5 (full-data input)
)
.missing <- unique(.prereqs[!file.exists(.prereqs)])
if (length(.missing))
  stop("analysis_all.R: missing external prerequisite input:\n  ",
       paste(.missing, collapse = "\n  "),
       "\nF5 lives in the external data root (legacy full-data table; no sample producer). See ",
       "quality_reports/restructure_findings.md (flag g-f5). Stage it before running.")

run_stage("E4_plots_claiming_distributions.R")          # claiming-distribution figures (terminal)
run_stage("new_counterfactual_claiming3_gabriel.R")     # F counterfactual claim counts (upstream of pure)
run_stage("new_counterfactual_claiming3_pure.R")        # canonical F: pure L/S schedules
run_stage("G4_effect_average_benefit_freq.R")           # selection-corrected avg benefits -> G4 _sample (I6 input)
run_stage("G5_effect_average_benefit_freq_bL_and_bS.R") # DD on avg benefits + contrafactual benefits
run_stage("H2_policy_elasticity_MW.R")                  # tax/revenue elasticity -> H2 _sample (I6 input)
run_stage("I4_wmvpf_no_pure_reforms_freq.R")            # WMVPF (actual reform)
run_stage("I6_wmvpf_with_pure_reforms_freq.R")          # WMVPF + pure L/S decomposition (headline numbers)
# EXCLUDED: H3_policy_elasticity.R is full-data only (no sample branch — flag h3-nosample).
#           I7 / I7b are diagnostics — run manually when needed.

message("ANALYSIS complete → ", PATHS$analysis_output)
