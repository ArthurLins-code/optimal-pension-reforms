# ******************************************************************************
# I6_diagnostic_juan.R
#
# Diagnostic tables requested by Juan (WhatsApp, 2026-05-23) to debug the
# pure-reform benefit pipeline.  Three concerns:
#
#   1) N^c seems too small (frequency graphs show N^c_{-6,0} > 2000)
#   2) b_bar_c should equal b_bar_S for p < 0 (schedule S = counterfactual there)
#   3) b_bar_c ~ R$6,700 vs b_bar_S ~ R$300k-500k -- unit mismatch?
#      Hypothesis: b_bar_c is quarterly, b_bar_S is lifetime PV.
#      Test: if mean(benefits_bS) / mean(benefits_old) ~ 3 * ann_factor_q,
#            then the difference is purely a unit issue.
#
# Outputs:
#   - output/I/I6_diagnostic_by_points_norm[_sample].csv
#   - output/I/I6_diagnostic_g5_cells[_sample].csv
#   - Console printout of key diagnostics
#
# ******************************************************************************

# --- Setup -------------------------------------------------------------------

pkgs <- c('data.table', 'dplyr')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- Config layer (restructure: paths + constants) ---------------------------
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))
dir <- PATHS$data_root
if (DATA_MODE == "full") .libPaths(Sys.getenv("PENSION_R_LIBPATH", unset = "F:/docs/R-library"))
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""

# --- Constants (same as G5 / I6) ---------------------------------------------

R_ANNUAL       <- 0.06
R_Q            <- (1 + R_ANNUAL)^(1/4) - 1
REFORM_QUARTER <- 2015.25

# --- Directory (same as I6) --------------------------------------------------

message("Diagnostic: Data mode = ", DATA_MODE, " | dir = ", dir)
dir.create(PATHS$output_I, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# PART 1: Micro-level benefit computations (replicating G5 lines 88-356)
# ==============================================================================

message("\n--- Loading micro data ---")

if (DATA_MODE == "sample") {
  dt <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv')) %>%
    .[!is.na(dist_claim_cutoff)]
  setnames(dt, 'cpf_anon', 'indiv', skip_absent = TRUE)
} else {
  dt <- fread(file.path(PATHS$build_working, "D3_cross_section.csv.gz"))
  gc()
  dt[, points_d := floor(points_claim)]
  dt[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  dt[, dist_reform := 4 * (claim_quarter - REFORM_QUARTER)]
}

message("Micro data: ", nrow(dt), " obs")

# --- Annuity factor (G5 lines 92-102) ----------------------------------------

dt[, quarters_remaining_of_life := pmax(round(4 * expec_ibge), 0)]
dt[, ann_factor_q := fifelse(
  quarters_remaining_of_life >= 0,
  (1 - (1 + R_Q)^(-quarters_remaining_of_life)) / R_Q,
  0
)]

# --- Benefits under new/old schedule (G5 lines 111-126) ----------------------

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

# PV of benefits (G5 lines 124-126)
dt[, pv_benefits_old := 3 * benefits_old * ann_factor_q]
dt[, pv_benefits_new := 3 * benefits_new * ann_factor_q]

# --- Replacement rate + benefits_bL / benefits_bS (G5 lines 334-356) ---------

dt[male == 0, replacement_rate := RR_INTERCEPT_WOMEN + (RR_SLOPE_WOMEN * points_norm)]
dt[male == 1, replacement_rate := RR_INTERCEPT_MEN + (RR_SLOPE_MEN * points_norm)]

# Pure Level (bL)
dt[male == 1, benefits_bL := fifelse(
  points_norm < 0, pv_benefits_new,
  pv_benefits_new * (1 + (1 - RR_INTERCEPT_MEN) / replacement_rate))]
dt[male == 0, benefits_bL := fifelse(
  points_norm < 0, pv_benefits_new,
  pv_benefits_new * (1 + (1 - RR_INTERCEPT_WOMEN) / replacement_rate))]

# Pure Slope (bS)
dt[male == 1, benefits_bS := fifelse(
  points_norm < 0, pv_benefits_new,
  pv_benefits_new * (RR_INTERCEPT_MEN / replacement_rate))]
dt[male == 0, benefits_bS := fifelse(
  points_norm < 0, pv_benefits_new,
  pv_benefits_new * (RR_INTERCEPT_WOMEN / replacement_rate))]

# --- Restrict points_norm range (G5 lines 106-107) ---------------------------

dt[points_norm < -15, points_norm := -15]
dt[points_norm >  15, points_norm :=  15]

# ==============================================================================
# PART 2: Table 1 -- Micro-level aggregation by points_norm (Juan's request)
# ==============================================================================

message("\n--- Building Table 1: micro-level means by points_norm ---")

tbl_micro <- dt[, .(
  N              = .N,
  mean_benefits_old     = mean(benefits_old,     na.rm = TRUE),
  mean_benefits_new     = mean(benefits_new,     na.rm = TRUE),
  mean_pv_benefits_old  = mean(pv_benefits_old,  na.rm = TRUE),
  mean_pv_benefits_new  = mean(pv_benefits_new,  na.rm = TRUE),
  mean_benefits_bL      = mean(benefits_bL,      na.rm = TRUE),
  mean_benefits_bS      = mean(benefits_bS,      na.rm = TRUE),
  mean_ann_factor_q     = mean(ann_factor_q,     na.rm = TRUE),
  mean_replacement_rate = mean(replacement_rate,  na.rm = TRUE)
), by = points_norm][order(points_norm)]

# Juan's ratio test: benefits_bS / benefits_old vs 3 * ann_factor_q
tbl_micro[, ratio_bS_over_old := mean_benefits_bS / mean_benefits_old]
tbl_micro[, three_ann_factor   := 3 * mean_ann_factor_q]
tbl_micro[, ratio_vs_3ann      := ratio_bS_over_old / three_ann_factor]

message("\nTable 1: Micro-level means by points_norm")
message("=========================================")
print(tbl_micro, digits = 4)

# Highlight Juan's test
message("\n--- Juan's unit test: ratio_bS_over_old vs 3 * ann_factor_q ---")
message("If ratio_vs_3ann ~ 1.0 across points_norm, the difference is purely a unit issue.")
message("Summary of ratio_vs_3ann:")
print(summary(tbl_micro$ratio_vs_3ann))

# ==============================================================================
# PART 3: Table 2 -- G5 cell-level data by points_norm
# ==============================================================================

message("\n--- Loading G5 CSV ---")

g5_file <- file.path(PATHS$output_G,
  paste0('G5_table_results_contrafactual_reforms_and_benefits_freq', SUFFIX, '.csv'))
g5 <- fread(g5_file)
message("G5 data: ", nrow(g5), " cells (", uniqueN(g5$points_norm), " points_norm x ",
        uniqueN(g5$dist_reform), " dist_reform)")

# --- Table 2a: G5 aggregated by points_norm ----------------------------------

tbl_g5 <- g5[, .(
  N_c_total                = sum(claims_c, na.rm = TRUE),
  N_a_total                = sum(claims,   na.rm = TRUE),
  mean_avg_benefits_bL     = mean(avg_benefits_bL, na.rm = TRUE),
  mean_avg_benefits_bS     = mean(avg_benefits_bS, na.rm = TRUE),
  mean_avg_reform_bL       = mean(avg_reform_benefits_pre_reform_choices_bL, na.rm = TRUE),
  mean_avg_reform_bS       = mean(avg_reform_benefits_pre_reform_choices_bS, na.rm = TRUE),
  mean_Beta_LP             = mean(Beta_LP, na.rm = TRUE),
  mean_Beta_SP             = mean(Beta_SP, na.rm = TRUE),
  mean_Beta_LA             = mean(Beta_LA, na.rm = TRUE),
  mean_Beta_SA             = mean(Beta_SA, na.rm = TRUE)
), by = points_norm][order(points_norm)]

message("\nTable 2a: G5 means by points_norm")
message("==================================")
print(tbl_g5, digits = 4)

# --- Table 2b: G5 at t = 0 (first post-reform quarter) -----------------------

tbl_g5_t0 <- g5[dist_reform == 0, .(
  points_norm,
  N_c_t0      = claims_c,
  N_a_t0      = claims,
  avg_bL_t0   = avg_benefits_bL,
  avg_bS_t0   = avg_benefits_bS,
  avg_reform_bL_t0 = avg_reform_benefits_pre_reform_choices_bL,
  avg_reform_bS_t0 = avg_reform_benefits_pre_reform_choices_bS,
  Beta_LP_t0  = Beta_LP,
  Beta_SP_t0  = Beta_SP,
  Beta_LA_t0  = Beta_LA,
  Beta_SA_t0  = Beta_SA
)][order(points_norm)]

message("\nTable 2b: G5 at t=0 by points_norm")
message("====================================")
print(tbl_g5_t0, digits = 4)

# ==============================================================================
# PART 4: Juan's Issue 1 -- N^c check
# ==============================================================================

message("\n--- Issue 1: N^c check ---")
message("Juan says N^c_{-6,0} should be > 2000 in frequency graphs.")
message("G5 claims_c by points_norm (summed over all dist_reform):")

nc_check <- g5[points_norm >= -6 & points_norm <= 0,
               .(N_c_total = sum(claims_c, na.rm = TRUE)),
               by = points_norm][order(points_norm)]
print(nc_check)

message("\nG5 claims_c at t=0 (single quarter):")
nc_t0 <- g5[dist_reform == 0 & points_norm >= -6 & points_norm <= 0,
            .(points_norm, claims_c)][order(points_norm)]
print(nc_t0)

# ==============================================================================
# PART 5: Juan's Issue 2 -- b_bar_c vs b_bar_S for p < 0
# ==============================================================================

message("\n--- Issue 2: b_bar_c should equal b_bar_S for p < 0 ---")
message("For p < 0, schedule S = counterfactual, so b_bar_c(x_a) = b_bar_S(x_a)")
message("and the DD betas should also be equal.\n")

compare_neg <- g5[points_norm < 0 & dist_reform == 0, .(
  points_norm,
  avg_reform_bL = avg_reform_benefits_pre_reform_choices_bL,
  avg_reform_bS = avg_reform_benefits_pre_reform_choices_bS,
  diff_reform   = avg_reform_benefits_pre_reform_choices_bL -
                  avg_reform_benefits_pre_reform_choices_bS,
  avg_bL = avg_benefits_bL,
  avg_bS = avg_benefits_bS,
  diff_bLS = avg_benefits_bL - avg_benefits_bS
)][order(points_norm)]

message("Comparison at t=0 for p < 0:")
print(compare_neg, digits = 6)

# Also from micro data: benefits_bL vs benefits_bS for p < 0
micro_neg <- dt[points_norm < 0, .(
  mean_bL = mean(benefits_bL, na.rm = TRUE),
  mean_bS = mean(benefits_bS, na.rm = TRUE),
  diff    = mean(benefits_bL, na.rm = TRUE) - mean(benefits_bS, na.rm = TRUE)
), by = points_norm][order(points_norm)]

message("\nMicro-level benefits_bL vs benefits_bS for p < 0:")
print(micro_neg, digits = 6)

# ==============================================================================
# PART 6: Juan's Issue 3 -- Unit mismatch diagnostic
# ==============================================================================

message("\n--- Issue 3: Unit mismatch b_bar_c vs b_bar_S ---")
message("b_bar_c ~ R$6,700 (quarterly?) vs b_bar_S ~ R$300k-500k (PV?)")
message("avg_reform_benefits_pre_reform_choices = b_bar_c (counterfactual benefits)")
message("avg_benefits_bS = b_bar_S (pure-slope reform benefits)\n")

# Show magnitudes from G5 for representative cells
mag_check <- g5[dist_reform == 0 & points_norm %in% -6:6, .(
  points_norm,
  b_bar_c_bL  = avg_reform_benefits_pre_reform_choices_bL,
  b_bar_c_bS  = avg_reform_benefits_pre_reform_choices_bS,
  b_bar_S     = avg_benefits_bS,
  b_bar_L     = avg_benefits_bL,
  ratio_bS_over_c_bS = avg_benefits_bS / avg_reform_benefits_pre_reform_choices_bS
)][order(points_norm)]

message("Magnitudes at t=0:")
print(mag_check, digits = 4)

message("\nIf ratio_bS_over_c_bS ~ 3 * ann_factor_q (around ",
        round(3 * mean(dt$ann_factor_q, na.rm = TRUE), 1),
        "), then the difference is a unit issue.")

# --- delta_ben check: THIS is likely Juan's R$6,700 ---
# G5 carries a 'delta_ben' column computed from G2 (density-based) with *3.
# It is in QUARTERLY units, while all other benefit columns are in PV.
if ("delta_ben" %in% names(g5)) {
  message("\n--- delta_ben column found in G5 CSV (likely Juan's R$6,700) ---")
  delta_check <- g5[dist_reform == 0 & points_norm %in% -6:6, .(
    points_norm,
    delta_ben,
    avg_reform_bS = avg_reform_benefits_pre_reform_choices_bS,
    ratio_PV_over_qtr = avg_reform_benefits_pre_reform_choices_bS / delta_ben
  )][order(points_norm)]
  message("delta_ben (quarterly) vs avg_reform_bS (PV) at t=0:")
  print(delta_check, digits = 4)
  message("\nRatio PV/quarterly ~ ann_factor_q. Mean ratio: ",
          round(mean(delta_check$ratio_PV_over_qtr, na.rm = TRUE), 1),
          "  |  Mean 3*ann_factor_q: ",
          round(3 * mean(dt$ann_factor_q, na.rm = TRUE), 1))
}

# ==============================================================================
# PART 7: Counterfactual benefits b(x) by points_norm (I6 "show Juan" table)
#
# Lifted from I6 PART 1, Step D.  I6 computes b(x)_t = cumsum_t( sum_p
# delta_ben * claims_c ); here the inner sum is broken out BY points_norm at a
# fixed quarter (dist_reform == 9) so Juan can see how the counterfactual
# benefit distributes across points_norm.
#   delta_ben        = avg_benefits_pv - point_estimate   (G4, period = 'old')
#   num_claims_count = claims_c                            (F-stage counts)
# ==============================================================================

message("\n--- PART 7: counterfactual b(x) by points_norm (I6 Step D table) ---")

MAX_HORIZON <- 13L   # same horizon as I6

# F-stage counterfactual counts + G4 selection-corrected benefits (sample-aware)
cf_counts <- fread(file.path(PATHS$output_F,
  paste0('new_counterfactual_claim_counts', SUFFIX, '.csv')))
setnames(cf_counts, c("t", "p"), c("dist_reform", "points_norm"), skip_absent = TRUE)
results_selection <- fread(file.path(PATHS$output_G,
  paste0('G4_table_results', SUFFIX, '.csv')))

aux1 <- results_selection[period == 'old' & dist_reform >= 0 & dist_reform <= MAX_HORIZON,
  .(dist_reform, points_norm, delta_ben = (avg_benefits_pv - point_estimate))]

aux2 <- cf_counts[dist_reform %in% 0:MAX_HORIZON,
  .(dist_reform, points_norm, num_claims_count = claims_c)]

aux3_provisory <- full_join(aux1, aux2, by = c('dist_reform', 'points_norm')) %>%
  .[, prod := delta_ben * num_claims_count] %>%
  .[, .(counterfactual_benefits_t = sum(prod, na.rm = TRUE)),
    by = c("dist_reform", "points_norm")]

tabela_cntrf <- aux3_provisory[dist_reform == 9 & points_norm <= 15 & points_norm >= -6]

message("\nCounterfactual b(x) by points_norm at dist_reform = 9:")
print(tabela_cntrf[order(points_norm)], digits = 6)

out_cntrf <- file.path(PATHS$output_I,
  paste0('I7_diagnostic_cntrf_by_points_norm', SUFFIX, '.csv'))
fwrite(tabela_cntrf[order(points_norm)], out_cntrf)
message("Saved: ", out_cntrf)

# ==============================================================================
# PART 8: Save outputs
# ==============================================================================

out_micro <- file.path(PATHS$output_I, paste0('I7_diagnostic_by_points_norm', SUFFIX, '.csv'))
out_g5    <- file.path(PATHS$output_I, paste0('I7_diagnostic_g5_cells', SUFFIX, '.csv'))

fwrite(tbl_micro, out_micro)
fwrite(tbl_g5,    out_g5)

message("\n--- Saved ---")
message("  ", out_micro)
message("  ", out_g5)
message("\nDiagnostic complete.")
