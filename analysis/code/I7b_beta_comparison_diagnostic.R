# ******************************************************************************
# I7b_beta_comparison_diagnostic.R
#
# Tests whether harmonizing the G4 and G5 DD specifications makes the betas
# converge for p < 0. Runs on sample data.
#
# The two differences identified between G4 and G5:
#   1) G4 has no dist_reform cap; G5 caps at <= 15
#   2) G4 aggregates avg_benefits_old_pv without na.rm; G5 uses na.rm=TRUE
#
# This script runs 4 DD regressions:
#   A) G4-style: avg_pv_benefits_old, no dist_reform cap, no na.rm
#   B) G5-style: avg_benefits_bS, dist_reform <= 15, na.rm=TRUE
#   C) Fixed G4: avg_pv_benefits_old, dist_reform <= 15, na.rm=TRUE
#   D) Cross-check: avg_benefits_bS, no dist_reform cap, na.rm=TRUE
#
# If A != B but C == B, the fix works.
# ******************************************************************************

pkgs <- c('data.table', 'dplyr', 'fixest')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- Constants ---------------------------------------------------------------
P_BAR_WOMEN    <- 85L
P_BAR_MEN      <- 95L
R_ANNUAL       <- 0.06
R_Q            <- (1 + R_ANNUAL)^(1/4) - 1
REFORM_QUARTER <- 2015.25

# --- Directory ---------------------------------------------------------------
if (dir.exists("C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")) {
  dir <- "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement"
  DATA_MODE <- "sample"
} else if (dir.exists("F:/Users/tucalins/Documents/transf_11_11/directory_2025")) {
  dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"
  DATA_MODE <- "full"
  .libPaths('F:/docs/R-library')
} else {
  stop("No data directory found.")
}
setwd(dir)
message("Running in ", DATA_MODE, " mode from: ", dir)

# --- Load data ---------------------------------------------------------------
if (DATA_MODE == "sample") {
  dt <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv')) %>%
    .[!is.na(dist_claim_cutoff)]
  setnames(dt, 'cpf_anon', 'indiv', skip_absent = TRUE)
} else {
  dt <- fread('working/D1_cross_section.csv.gz') %>%
    .[!is.na(dist_claim_cutoff)]
  dt[, points_d := floor(points_claim)]
  dt[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  dt[, dist_reform := 4 * (claim_quarter - REFORM_QUARTER)]
}
message("Loaded: ", nrow(dt), " obs")

# --- Annuity factor ----------------------------------------------------------
dt[, quarters_remaining_of_life := pmax(round(4 * expec_ibge), 0)]
dt[, ann_factor_q := fifelse(
  quarters_remaining_of_life >= 0,
  (1 - (1 + R_Q)^(-quarters_remaining_of_life)) / R_Q,
  0
)]

# --- Winsorize ---------------------------------------------------------------
dt[points_norm < -15, points_norm := -15]
dt[points_norm >  15, points_norm :=  15]

# --- Benefits ----------------------------------------------------------------
# New schedule
dt[d_claim_post_reform == 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm < 0,  benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm >= 0 & fp_est <  1, benefits_new := benef_size / fp_est]

# Old schedule
dt[d_claim_post_reform == 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm < 0,  benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm >= 0 & fp_est <  1, benefits_old := benef_size * fp_est]

# PV
dt[, pv_benefits_old := 3 * benefits_old * ann_factor_q]
dt[, pv_benefits_new := 3 * benefits_new * ann_factor_q]

# Pure reforms (bL, bS) -- same as G5
dt[male == 0, replacement_rate := 0.69 + (0.021 * points_norm)]
dt[male == 1, replacement_rate := 0.82 + (0.025 * points_norm)]

dt[male == 1, benefits_bL := fifelse(points_norm < 0, pv_benefits_new,
  pv_benefits_new * (1 + (1 - 0.82) / replacement_rate))]
dt[male == 0, benefits_bL := fifelse(points_norm < 0, pv_benefits_new,
  pv_benefits_new * (1 + (1 - 0.69) / replacement_rate))]

dt[male == 1, benefits_bS := fifelse(points_norm < 0, pv_benefits_new,
  pv_benefits_new * (0.82 / replacement_rate))]
dt[male == 0, benefits_bS := fifelse(points_norm < 0, pv_benefits_new,
  pv_benefits_new * (0.69 / replacement_rate))]

# ==============================================================================
# Verify: for p < 0, are the individual-level values identical?
# ==============================================================================

message("\n=== VERIFICATION: Individual-level identity for p < 0 ===")
neg_check <- dt[points_norm < 0, .(
  same_old_new   = all(abs(pv_benefits_old - pv_benefits_new) < 0.01, na.rm = TRUE),
  same_old_bS    = all(abs(pv_benefits_old - benefits_bS) < 0.01, na.rm = TRUE),
  same_bL_bS     = all(abs(benefits_bL - benefits_bS) < 0.01, na.rm = TRUE),
  n_na_old       = sum(is.na(pv_benefits_old)),
  n_na_bS        = sum(is.na(benefits_bS)),
  n_total        = .N
)]
print(neg_check)

# ==============================================================================
# Build 4 aggregations to test each specification
# ==============================================================================

# Spec A: G4-style (no na.rm for old)
agg_A <- dt[, .(
  Y_old = mean(pv_benefits_old),                     # NO na.rm (G4 original)
  Y_bS  = mean(benefits_bS, na.rm = TRUE)            # with na.rm (G5 style)
), by = .(points_norm, dist_reform)]

# Spec C: Fixed G4 (na.rm for old)
agg_C <- dt[, .(
  Y_old = mean(pv_benefits_old, na.rm = TRUE),        # WITH na.rm (harmonized)
  Y_bS  = mean(benefits_bS, na.rm = TRUE)
), by = .(points_norm, dist_reform)]

# Check: are cell means identical for p < 0 when both use na.rm?
cell_check <- merge(
  agg_C[points_norm < 0, .(points_norm, dist_reform, Y_old_C = Y_old)],
  agg_C[points_norm < 0, .(points_norm, dist_reform, Y_bS_C = Y_bS)],
  by = c('points_norm', 'dist_reform')
)
cell_check[, diff := Y_old_C - Y_bS_C]
message("\n=== Cell-level check: Y_old vs Y_bS for p < 0 (both na.rm=TRUE) ===")
message("Max absolute difference: ", max(abs(cell_check$diff), na.rm = TRUE))
message("Mean absolute difference: ", mean(abs(cell_check$diff), na.rm = TRUE))

# Also check agg_A (no na.rm for old)
cell_check_A <- merge(
  agg_A[points_norm < 0, .(points_norm, dist_reform, Y_old_A = Y_old)],
  agg_A[points_norm < 0, .(points_norm, dist_reform, Y_bS_A = Y_bS)],
  by = c('points_norm', 'dist_reform')
)
cell_check_A[, diff := Y_old_A - Y_bS_A]
message("\n=== Cell-level check: Y_old (no na.rm) vs Y_bS (na.rm) for p < 0 ===")
message("Max absolute difference: ", max(abs(cell_check_A$diff), na.rm = TRUE))
message("Any NAs in Y_old_A: ", any(is.na(cell_check_A$Y_old_A)))
n_na_cells <- sum(is.na(cell_check_A$Y_old_A))
message("Number of NA cells in Y_old_A: ", n_na_cells)

# ==============================================================================
# Run DD regressions
# ==============================================================================

# Group variable
for (agg in list(agg_A, agg_C)) {
  agg[points_norm %in% -15:-7, group := '[-15,-7]']
  agg[points_norm %in% -6:-3, group := '[-6,-3]']
  agg[points_norm %in% -2:-1, group := '[-2,-1]']
  agg[points_norm %in%   0:1, group := '[0,1]']
  agg[points_norm %in%   2:6, group := '[2,6]']
  agg[points_norm %in%  7:15, group := '[7,15]']

  for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
    agg[group == '[-15,-7]', paste0('treat_',g) := 0]
    agg[group == g, paste0('treat_',g) := 1]
  }
}

# Function to extract DD betas from feols interaction model
extract_betas <- function(agg_dt, dep_var, filter_dist = NULL, label = "") {
  results <- list()
  for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
    fml <- as.formula(paste0(dep_var, ' ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
    subset_dt <- agg_dt[!is.na(get(paste0('treat_', g)))]
    if (!is.null(filter_dist)) {
      subset_dt <- subset_dt[dist_reform <= filter_dist]
    }
    # Drop NA rows for the dependent variable to avoid feols errors
    subset_dt <- subset_dt[!is.na(get(dep_var))]

    model <- tryCatch(
      feols(data = subset_dt, fml = fml, cluster = 'points_norm'),
      error = function(e) { message("  feols error for group ", g, ": ", e$message); NULL }
    )
    if (is.null(model)) next

    # Extract coefficients directly from the model
    cf <- coeftable(model)
    # Coefficient names look like: "dist_reform::0:treat_[-6,-3]"
    coef_names <- rownames(cf)
    # Parse dist_reform values from coefficient names
    t_vals <- as.integer(gsub(".*::([-]?[0-9]+):.*", "\\1", coef_names))

    results[[g]] <- data.table(
      spec    = label,
      group   = g,
      t       = t_vals,
      beta    = cf[, 1]
    )
  }
  rbindlist(results)
}

message("\n=== Running DD regressions ===")

# Spec A: G4-original: Y_old, no dist_reform cap
betas_A <- extract_betas(agg_A, 'Y_old', filter_dist = NULL, label = 'A: G4-original (old, no cap, no na.rm)')

# Spec B: G5-style: Y_bS, dist_reform <= 15
betas_B <- extract_betas(agg_A, 'Y_bS', filter_dist = 15, label = 'B: G5-style (bS, cap 15, na.rm)')

# Spec C: Fixed G4: Y_old, dist_reform <= 15, na.rm=TRUE
betas_C <- extract_betas(agg_C, 'Y_old', filter_dist = 15, label = 'C: G4-fixed (old, cap 15, na.rm)')

# Spec D: Cross-check: Y_bS, no dist_reform cap
betas_D <- extract_betas(agg_A, 'Y_bS', filter_dist = NULL, label = 'D: bS, no cap, na.rm')

# ==============================================================================
# Compare results for p < 0 groups
# ==============================================================================

message("\n=== COMPARISON: DD betas for p < 0 groups ===")
message("Only showing t = 0, 1, 2, 3 for clarity\n")

neg_groups <- c('[-6,-3]', '[-2,-1]')

compare <- merge(
  betas_A[group %in% neg_groups, .(group, t, beta_A = beta)],
  betas_B[group %in% neg_groups, .(group, t, beta_B = beta)],
  by = c('group', 't')
)
compare <- merge(compare,
  betas_C[group %in% neg_groups, .(group, t, beta_C = beta)],
  by = c('group', 't')
)
compare <- merge(compare,
  betas_D[group %in% neg_groups, .(group, t, beta_D = beta)],
  by = c('group', 't')
)

compare[, diff_AB := beta_A - beta_B]  # Original discrepancy
compare[, diff_CB := beta_C - beta_B]  # After fix: should be ~0

# Show t = 0, 1, 2, 3
compare_show <- compare[t %in% 0:3][order(group, t)]
message("Columns:")
message("  beta_A = G4-original (Y_old, no cap, no na.rm)")
message("  beta_B = G5-style (Y_bS, cap 15, na.rm)")
message("  beta_C = G4-FIXED (Y_old, cap 15, na.rm)")
message("  beta_D = Y_bS without cap")
message("  diff_AB = original discrepancy (A - B)")
message("  diff_CB = after fix (C - B) -- should be ~0 if fix works")
message("")
print(compare_show, digits = 4)

# Summary
message("\n=== SUMMARY ===")
message("Original discrepancy (A vs B):")
message("  Mean |diff_AB| for t in 0:3: ", round(mean(abs(compare_show$diff_AB)), 2))
message("  Max  |diff_AB| for t in 0:3: ", round(max(abs(compare_show$diff_AB)), 2))
message("\nAfter fix (C vs B):")
message("  Mean |diff_CB| for t in 0:3: ", round(mean(abs(compare_show$diff_CB)), 2))
message("  Max  |diff_CB| for t in 0:3: ", round(max(abs(compare_show$diff_CB)), 2))

fix_works <- max(abs(compare_show$diff_CB)) < 1  # tolerance R$1
message("\nFix resolves the discrepancy: ", fix_works)

# Also check: is the cap the main driver, or the na.rm?
message("\n=== DECOMPOSITION: cap vs na.rm ===")
# D = bS without cap (same dep var as B, but no cap)
compare_BD <- merge(
  betas_B[group %in% neg_groups, .(group, t, beta_B = beta)],
  betas_D[group %in% neg_groups, .(group, t, beta_D = beta)],
  by = c('group', 't')
)
compare_BD[, diff_BD := beta_B - beta_D]
message("Effect of dist_reform cap alone (B vs D, both use Y_bS):")
message("  Mean |diff_BD| for t in 0:3: ", round(mean(abs(compare_BD[t %in% 0:3]$diff_BD)), 2))
message("  Max  |diff_BD| for t in 0:3: ", round(max(abs(compare_BD[t %in% 0:3]$diff_BD)), 2))

message("\nDiagnostic complete.")
