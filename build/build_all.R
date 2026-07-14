# =============================================================================
# build/build_all.R — reconstruct the analysis-ready panel from raw SUIBE/RAIS.
# SERVER / FULL DATA ONLY. On the 5% sample the panel (data/panel_sampled_anon.csv)
# is an INPUT, not something you rebuild here.
# =============================================================================
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))

if (DATA_MODE != "full")
  stop("build_all.R needs the full server data (DATA_MODE='full'). ",
       "On the 5% sample the panel is an *input*, not something you rebuild. ",
       "Set PENSION_DATA_MODE=full on the restricted server.")

clear_dirs(PATHS$build_temp, PATHS$build_output)   # G-S: clear before you build (full rebuild only)

# Canonical stage heads (highest number = canonical). A from-scratch build also needs the
# upstream lineage that produces working/ intermediates — A1-A3, B1-B3, C1-C5, D1-D3 — which
# live alongside these in build/code/. Run them first on the server if rebuilding from raw.
run_stage("A4_balance_check.R",                 PATHS$build_code)
run_stage("B4_create_clean_candidates_cross.R", PATHS$build_code)
run_stage("C6_estimate_continuous_contrib.R",   PATHS$build_code)
run_stage("D4_create_panel.R",                  PATHS$build_code)

message("BUILD complete → ", PATHS$build_output)
