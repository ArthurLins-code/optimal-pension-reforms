# =============================================================================
# presentation/build_deck.R — figures → compiled English deck (one command).
# Wraps the existing Python tools + latexmk. Run AFTER analysis/analysis_all.R.
# (collector.py's internal source dirs are repathed to the new layout in Stage 2.)
# =============================================================================
source(here::here("config", "paths.R"))

fig_dir  <- PATHS$figures_central        # presentation/figures_central_folder (tools + manifest)
deck_tex <- file.path(PATHS$deck_dir, "_main.tex")
py       <- Sys.getenv("PENSION_PYTHON", unset = "python")

run <- function(cmd) {
  message("\n$ ", cmd)
  status <- system(cmd)
  if (status != 0) stop("build_deck.R: command failed (status ", status, "): ", cmd)
}

# 1) collect pipeline figures into latex/figures/from_code/ (from the in-repo analysis/output)
run(paste(shQuote(py), shQuote(file.path(fig_dir, "collector.py"))))
# 2) compile the English deck (-cd: latexmk chdirs into the .tex's own dir; no setwd here)
run(paste("latexmk -cd -g -pdf -interaction=nonstopmode", shQuote(deck_tex)))
# 3) verify every \includegraphics resolves under latex/figures/from_code/ + static/
run(paste(shQuote(py), shQuote(file.path(fig_dir, "verify_deck.py"))))

message("DECK built → ", file.path(PATHS$deck_dir, "_main.pdf"))
