# baseline/run_stage_fallback.R — Stage-3 PARITY fallback runner.
#
# WHY: the analysis master (analysis/analysis_all.R) crashes at pure.R because
# pure.R's 30 ggsave() calls use the LEGACY RELATIVE path 'output/new_counter_claiming/...'
# with NO setwd(), so they only resolve when cwd == external sample root. The restructure
# removed setwd but left these relative paths (RESTRUCTURE-CAUSED finding). The collector
# pulls canonical figures from ABSOLUTE PATHS$ dirs, so these relative diagnostic figures
# are not in the deck/parity set — but the crash still aborts the stage.
#
# This wrapper reproduces the PRE-restructure runtime contract WITHOUT editing any pipeline
# file: it pins here::here() to the repo root (cached on first call from repo root), then
# setwd() into the external sample dir so the legacy relative paths resolve, then sources the
# requested stage. config/paths.R still resolves all absolute PATHS$ correctly (rprojroot
# root already cached). No repo file is modified; only the external (gitignored-irrelevant,
# outside-repo) output dir + the in-repo gitignored from_code/_main.pdf are written.
#
# Usage: Rscript baseline/run_stage_fallback.R <stage_file.R>   (run from repo root)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: run_stage_fallback.R <stage_file.R>")
stage_file <- args[[1]]

# 1) Pin here::here() to the repo root while cwd is still the repo root.
repo_root <- normalizePath(getwd(), winslash = "/")
suppressMessages(library(here))
here::i_am(".here")                         # caches repo_root as the here() root
cat("[fallback] here root pinned to:", here::here(), "\n")

# 2) Locate the external sample root the same way config/paths.R does.
sample_root <- Sys.getenv("PENSION_SAMPLE_ROOT",
  unset = "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")
if (!dir.exists(sample_root)) stop("external sample root missing: ", sample_root)

# 3) setwd() into the external dir so legacy relative 'output/...' paths resolve there,
#    exactly as the pre-restructure standalone runs did.
setwd(sample_root)
cat("[fallback] cwd set to external sample root:", getwd(), "\n")

stage_path <- file.path(repo_root, "analysis", "code", stage_file)
if (!file.exists(stage_path)) stop("stage file not found: ", stage_path)
cat("[fallback] sourcing stage:", stage_path, "\n")

# 4) Run the stage. here::here() inside it uses the cached repo root; absolute PATHS$ all
#    point at the external dir; relative output/ paths resolve under the (now external) cwd.
source(stage_path, echo = FALSE)
cat("[fallback] DONE", stage_file, "\n")
