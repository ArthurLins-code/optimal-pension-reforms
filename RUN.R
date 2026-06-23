# =============================================================================
# RUN.R — single front door. Documents the pipeline and dispatches to the three
# functional masters. By default this does NOTHING destructive: uncomment the
# line you want, or source the master directly.
# =============================================================================
#
#   Build the analysis-ready panel from raw SUIBE/RAIS  (SERVER / FULL DATA ONLY):
#       source(here::here("build", "build_all.R"))
#
#   Run the analysis pipeline on the 5% sample  (panel → figures, tables, WMVPF):
#       source(here::here("analysis", "analysis_all.R"))
#
#   Collect figures and compile the English deck:
#       source(here::here("presentation", "build_deck.R"))
#
message("RUN.R is a signpost — uncomment a source() line above, or run a master directly. ",
        "See README.md → 'How to run'.")
