# =============================================================================
# config/paths.R — single source of truth for every path + DATA_MODE
# =============================================================================
#
# Source this at the top of every stage script and master:
#     source(here::here("config", "paths.R"))      # defines PROJECT_ROOT, DATA_MODE, PATHS, run_stage(), clear_dirs()
#     source(here::here("config", "constants.R"))  # defines the economic primitives
#
# Design (binding spec REPO_STRUCTURE_GUIDELINES.md §5.1):
#   - Find the project root WITHOUT setwd(), via rprojroot keyed on the `.here` sentinel.
#   - Resolve DATA_MODE LOUDLY: env override first, else detect by existing roots, else stop().
#   - Centralize every machine-specific data root here and ONLY here.
#   - Expose ONE `PATHS` list so a folder move changes this file, not forty scripts.
#
# NOTE (Phase: restructure): call-sites are wired in during Stage 2. Stage scripts still
# contain their own setwd()/dir.exists() blocks until then; this file is the target they migrate to.
# =============================================================================

# --- Project root (no setwd; keyed on the .here sentinel) --------------------
if (!requireNamespace("rprojroot", quietly = TRUE))
  stop("config/paths.R needs the 'rprojroot' package. install.packages('rprojroot').")
PROJECT_ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))

# --- Machine-specific DATA ROOTS (override via env vars; edit defaults here only) ----
# Sample = 5% anonymized CPF-level data (NEVER committed). Full = restricted server.
SAMPLE_ROOT <- Sys.getenv("PENSION_SAMPLE_ROOT",
  unset = "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")
# FLAG (open issue O11): the full-data BUILD scripts (A4/B4/C6/D4) use a U:/ root while the
# full-data ANALYSIS scripts (G5/I4/I6) use an F:/ root. Kept separate here, surfaced for the
# professors to reconcile on the server — NOT silently merged.
FULL_ANALYSIS_ROOT <- Sys.getenv("PENSION_FULL_ROOT",
  unset = "F:/Users/tucalins/Documents/transf_11_11/directory_2025")
FULL_BUILD_ROOT <- Sys.getenv("PENSION_FULL_BUILD_ROOT",
  unset = "U:/Documents/Paper/directory_2025")

# --- DATA_MODE: env override → existence detection → loud stop() --------------
.mode_env <- Sys.getenv("PENSION_DATA_MODE", unset = "")
if (.mode_env %in% c("full", "sample")) {
  DATA_MODE <- .mode_env
} else if (dir.exists(SAMPLE_ROOT)) {
  DATA_MODE <- "sample"
} else if (dir.exists(FULL_ANALYSIS_ROOT) || dir.exists(FULL_BUILD_ROOT)) {
  DATA_MODE <- "full"
} else {
  stop(
    "config/paths.R: could not resolve DATA_MODE.\n",
    "  Set env PENSION_DATA_MODE to 'full' or 'sample', or make one of these roots exist:\n",
    "    sample : ", SAMPLE_ROOT, "\n",
    "    full   : ", FULL_ANALYSIS_ROOT, "  (analysis)\n",
    "    full   : ", FULL_BUILD_ROOT, "  (build)\n",
    "  No silent fallback to a wrong path."
  )
}

# Active analysis data root (build master overrides to FULL_BUILD_ROOT in full mode).
DATA_ROOT <- if (DATA_MODE == "sample") SAMPLE_ROOT else FULL_ANALYSIS_ROOT
if (!dir.exists(DATA_ROOT))
  stop("config/paths.R: DATA_MODE='", DATA_MODE, "' but its root does not exist: ", DATA_ROOT)

# --- Repo-internal output roots (relocation: outputs live in the repo, gitignored) -----------
# Outputs are regeneratable and non-confidential-by-construction, so they live INSIDE the repo
# (analysis/output, analysis/temp) in BOTH modes. Confidential/large INPUTS stay external (DATA_ROOT).
REPO_OUTPUT <- file.path(PROJECT_ROOT, "analysis", "output")
REPO_TEMP   <- file.path(PROJECT_ROOT, "analysis", "temp")

# --- The one PATHS list ------------------------------------------------------
.out <- function(...) file.path(REPO_OUTPUT, ...)
PATHS <- list(
  project_root        = PROJECT_ROOT,
  data_mode           = DATA_MODE,
  data_root           = DATA_ROOT,

  # data inputs
  sample_data         = file.path(SAMPLE_ROOT, "data"),       # dt_sampled_anon.csv, panel_sampled_anon.csv
  build_working       = file.path(FULL_BUILD_ROOT, "working"),# full-mode A-D intermediates
  extra               = file.path(DATA_ROOT, "extra"),         # IBGE life-expectancy etc. (full mode)
  prereq_root         = file.path(DATA_ROOT, "output"),        # external pre-supplied INPUTS: F5 + full-data G4/H2 (read-only)

  # analysis outputs (relocated INTO the repo: gitignored & regenerable — see REPO_OUTPUT)
  analysis_output     = REPO_OUTPUT,
  output_E            = .out("E"),
  output_F            = .out("F"),
  output_G            = .out("G"),
  output_H            = .out("H"),
  output_I            = .out("I"),
  output_new_counter  = .out("new_counter_claiming"),
  analysis_temp       = REPO_TEMP,                             # persistent temp; gabriel->pure handoff seam

  # build (full data / server only)
  build_output        = file.path(FULL_BUILD_ROOT, "output"),
  build_temp          = file.path(FULL_BUILD_ROOT, "tmp"),

  # raw roots (exposed for reference / build/input pointers)
  sample_root         = SAMPLE_ROOT,
  full_analysis_root  = FULL_ANALYSIS_ROOT,
  full_build_root     = FULL_BUILD_ROOT,

  # repo-internal presentation dirs
  figures_central     = file.path(PROJECT_ROOT, "presentation", "figures_central_folder"),
  figures_from_code   = file.path(PROJECT_ROOT, "latex", "figures", "from_code"),
  figures_static      = file.path(PROJECT_ROOT, "latex", "figures", "static"),
  deck_dir            = file.path(PROJECT_ROOT, "latex", "presentation"),

  # repo-internal code dirs (run_stage targets)
  build_code          = file.path(PROJECT_ROOT, "build", "code"),
  analysis_code       = file.path(PROJECT_ROOT, "analysis", "code")
)

# --- helpers for the master scripts -----------------------------------------
# run_stage(): source one stage file from its functional code/ dir, timed + logged.
#   local=TRUE keeps each stage's variables from leaking into the next ("shy functions").
#   fresh=TRUE runs it in a clean R process via callr (closest to G-S "delete + rebuild").
run_stage <- function(file, code_dir = PATHS$analysis_code, echo = FALSE, fresh = FALSE) {
  path <- file.path(code_dir, file)
  if (!file.exists(path)) stop("run_stage(): stage file not found: ", path)
  message("\n========== RUN ", file, "  [", DATA_MODE, "] ==========")
  t0 <- Sys.time()
  if (isTRUE(fresh)) {
    if (!requireNamespace("callr", quietly = TRUE)) stop("run_stage(fresh=TRUE) needs the 'callr' package.")
    callr::rscript(path, show = TRUE)
  } else {
    source(path, local = TRUE, echo = echo)
  }
  message("========== DONE ", file, " in ",
          round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s ==========\n")
  invisible(TRUE)
}

# clear_dirs(): wipe + recreate dirs before a build (G-S "clear before you build").
# SAFETY: never call this on a dir that holds pre-supplied inputs. In sample mode the external
# output/ dir holds the pre-supplied prereq tables (F5/G4/H2) — do NOT clear it (see masters).
clear_dirs <- function(...) {
  for (d in c(...)) {
    if (dir.exists(d)) unlink(list.files(d, full.names = TRUE, recursive = TRUE), recursive = TRUE, force = TRUE)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(TRUE)
}

message("config/paths.R loaded — DATA_MODE=", DATA_MODE, " | root=", DATA_ROOT)
