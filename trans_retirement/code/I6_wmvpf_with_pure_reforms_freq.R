# ******************************************************************************
# I6_wmvpf_with_pure_reforms_freq.R
#
# WMVPF Estimation: Actual Reform + Pure Reform Decomposition (bL/bS)
# Uses frequencies (not densities) -- canonical approach post-strategy reversion.
#
# Structure:
#   PART 1: Actual Reform WMVPF (exact replication of I4)
#   PART 2: Pure Level (bL) and Pure Slope (bS) WMVPF
#   PART 3: Summary, comparison, and saving
#
# Inputs:
#   - working/D3_cross_section.csv.gz   OR  data/dt_sampled_anon.csv
#   - working/D2_panel.csv.gz           OR  data/panel_sampled_anon.csv
#   - output/F/new_counterfactual_claim_counts[_sample].csv
#   - output/G/G4_table_results.csv                           (full-data, scale-indep)
#   - output/G/G5_table_results_contrafactual_reforms_and_benefits_freq[_sample].csv
#   - output/H/H2_table_results.csv                           (full-data, scale-indep)
#   - extra/Expectativa_Vida_IBGE.xlsx                        (full mode only)
#
# Outputs:
#   - output/I/I6_wmvpf_actual[_sample].csv
#   - output/I/I6_wmvpf_pure_L[_sample].csv
#   - output/I/I6_wmvpf_pure_S[_sample].csv
#   - output/I/I6_summary[_sample].csv
#   - output/I/I6_table_wmvpf[_sample].csv        (I4-format backward compat)
#   - output/I/I6_plot_actual_reform[_sample].pdf
#   - output/I/I6_plot_pure_L_reform[_sample].pdf
#   - output/I/I6_plot_pure_S_reform[_sample].pdf
#
# References:
#   - Canonical deck: Retirement_Presentations (old strat reverted).pdf
#   - Slides 37-41/56 (WMVPF framework)
#   - Slides 46-52/56 (Pure reforms decomposition)
#
# ******************************************************************************

# --- Setup -------------------------------------------------------------------

pkgs <- c('scales', 'zoo', 'readxl', 'fixest', 'tidyr', 'stringr',
          'data.table', 'dplyr', 'lubridate', 'haven', 'ggplot2',
          'grid', 'RColorBrewer', 'ggpubr')

for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- Constants ---------------------------------------------------------------
P_BAR_WOMEN    <- 85L
P_BAR_MEN      <- 95L
GAMMA_BASELINE <- 4L
CONS_INSS      <- 1536.4
CONS_POP       <- 1473.1
R_ANNUAL       <- 0.06
REFORM_QUARTER <- 2015.25
MAX_HORIZON    <- 12L

R_Q <- (1 + R_ANNUAL)^(1/4) - 1
ETA <- 1 - GAMMA_BASELINE * (CONS_INSS - CONS_POP) / CONS_POP

# --- Directory ---------------------------------------------------------------
if (dir.exists("F:/Users/tucalins/Documents/transf_11_11/directory_2025")) {
  dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"
  DATA_MODE <- "full"
  .libPaths('F:/docs/R-library')
} else if (dir.exists("C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")) {
  dir <- "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement"
  DATA_MODE <- "sample"
} else {
  stop("No data directory found. Set 'dir' manually.")
}

message("I6: Data mode = ", DATA_MODE, " | dir = ", dir)
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""
setwd(dir)

set.seed(20260512L)

dir.create('output/I', recursive = TRUE, showWarnings = FALSE)

# --- Data Loading ------------------------------------------------------------

if (DATA_MODE == "sample") {
  dt_cs <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv'))
  setnames(dt_cs, 'cpf_anon', 'indiv')
  panel  <- fread(file.path(dir, 'data', 'panel_sampled_anon.csv'))
  setnames(panel, 'cpf_anon', 'indiv')
  message("Loaded sample data: ", nrow(dt_cs), " cross-section obs, ",
          nrow(panel), " panel obs")
} else {
  dt_cs <- fread('working/D3_cross_section.csv.gz')
  gc()
  dt_cs[, points_d := floor(points_claim)] %>%
    .[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  dt_cs[, dist_reform := 4 * (claim_quarter - REFORM_QUARTER)]

  expectativa <- read_excel(paste0(dir, '/extra/Expectativa_Vida_IBGE.xlsx')) %>%
    setDT() %>%
    setnames(c('Ano','Idade','Expectativa'), c('table_year', 'age_disc', 'expec_ibge'))

  aux_expectativa <- cross_join(
    data.table(claim_year = unique(expectativa$table_year)),
    data.table(claim_month = seq(1L, 12L, 1L))
  ) %>%
    cross_join(data.table(age_disc = unique(expectativa$age_disc))) %>%
    setDT()

  aux_expectativa[claim_month < 12L, table_year := claim_year - 1L]
  aux_expectativa[claim_month == 12L, table_year := claim_year]

  aux_expectativa <- left_join(aux_expectativa, expectativa,
                               by = c('table_year','age_disc')) %>%
    arrange(age_disc, claim_year, claim_month) %>%
    na.omit()

  dt_cs[, claim_month := month(as.Date(claim_date))]
  dt_cs[, age_disc := floor(age_claim)]
  dt_cs <- left_join(dt_cs, aux_expectativa,
                     by = c('claim_year','claim_month','age_disc'))
  gc()

  panel <- fread('working/D2_panel.csv.gz')
  gc()
  panel[, 'benefits' := NULL]
  panel <- left_join(panel, dt_cs[,.(indiv, benef_size, expec_ibge, fp_est, points_norm)],
                     by = 'indiv')

  panel[d_claim_post_reform == 1, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm < 0, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est < 1, benefits_new_claim := benef_size / fp_est]

  panel[d_claim_post_reform == 0, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm < 0, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est < 1, benefits_old_claim := benef_size * fp_est]

  panel[, quarters_remaining_at_claim := pmax(round(4 * expec_ibge), 0L)]
  panel[, quarters_elapsed := pmax(dist_claim, 0L)]
  panel[, quarters_remaining_of_life := pmax(quarters_remaining_at_claim - quarters_elapsed, 0L)]
  panel[, ann_factor_q := fifelse(
    quarters_remaining_of_life >= 0L,
    (1 - (1 + R_Q)^(-quarters_remaining_of_life)) / R_Q,
    0
  )]

  panel[, benefits := fifelse(dist_claim >= 0L, 3 * benef_size * ann_factor_q, 0)]
  panel[, benefits_old_pv := fifelse(dist_claim >= 0L, 3 * benefits_old_claim * ann_factor_q, 0)]
  panel[, benefits_new_pv := fifelse(dist_claim >= 0L, 3 * benefits_new_claim * ann_factor_q, 0)]

  panel[, points_d := floor(points_quarter)]
  panel[, points_norm := ifelse(male == 0L, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  panel[, dist_reform := 4 * (year_quarter - REFORM_QUARTER)]
}

gc()
message("Panel: ", nrow(panel), " rows | Cross-section: ", nrow(dt_cs), " rows")


# ########################################################################
# ########################################################################
#
#                    PART 1: ACTUAL REFORM WMVPF
#          (Exact replication of I4 -- do NOT modify independently)
#
# ########################################################################
# ########################################################################

message("\n=== PART 1: Actual Reform WMVPF (I4 replication) ===")

# --- Step A: b'(x') = actual expenditure from panel -------------------------
# Individual-level sum of PDV benefits for all post-reform claimants, by quarter.
# This is naturally cumulative because the panel includes all prior cohorts.

tot_ben_period <- panel[d_claim_post_reform == 1 & claim_quarter <= 2018.25,
  .(total_benefits_payment = sum(benefits_new_pv, na.rm = TRUE)),
  by = .(dist_reform)]

message("Step A: total_benefits_payment computed for ",
        nrow(tot_ben_period[dist_reform >= 0 & dist_reform <= MAX_HORIZON]),
        " quarters")

# --- Step B: Number of claims per cell ---------------------------------------

n_claims <- dt_cs[d_claim_post_reform == 1 & claim_quarter <= 2018.25,
  .(num_claims = .N), by = .(dist_reform, points_norm)]

# --- Step C: External files --------------------------------------------------
# F-stage counterfactual counts (sample-aware via SUFFIX)
cf_counts <- fread(paste0('output/F/new_counterfactual_claim_counts', SUFFIX, '.csv'))
setnames(cf_counts, c("t","p"), c("dist_reform","points_norm"), skip_absent = TRUE)

# G4: selection-corrected average benefits (full data -- scale-independent)
results_selection <- fread('output/G/G4_table_results.csv')

# H2: tax elasticity DD estimates (full data -- scale-independent)
results_taxes <- fread('output/H/H2_table_results.csv')

message("Step C: Loaded cf_counts (", nrow(cf_counts), " rows), ",
        "G4 (", nrow(results_selection), " rows), ",
        "H2 (", nrow(results_taxes), " rows)")

# --- Step D: b(x) = counterfactual benefits (old schedule, old choices) ------
# delta_ben = selection-corrected average benefit PDV
# b(x)_t = cumsum of sum_p(delta_ben * claims_c)

aux1 <- results_selection[period == 'old' & dist_reform >= 0 & dist_reform <= MAX_HORIZON,
  .(dist_reform, points_norm, delta_ben = (avg_benefits_pv - point_estimate))]

aux2 <- cf_counts[dist_reform %in% 0:MAX_HORIZON,
  .(dist_reform, points_norm, num_claims_count = claims_c)]

aux3 <- full_join(aux1, aux2, by = c('dist_reform','points_norm')) %>%
  .[, prod := delta_ben * num_claims_count] %>%
  .[, .(counterfactual_benefits_t = sum(prod, na.rm = TRUE)), by = dist_reform] %>%
  arrange(dist_reform) %>%
  .[, counterfactual_benefits := cumsum(counterfactual_benefits_t)]

message("Step D: b(x) computed. Range: ",
        round(min(aux3$counterfactual_benefits, na.rm = TRUE)/1e6, 1), "M to ",
        round(max(aux3$counterfactual_benefits, na.rm = TRUE)/1e6, 1), "M")

# --- Step E: Benefit changes merge -------------------------------------------

dt_benefit_changes <- full_join(
  tot_ben_period[dist_reform >= 0 & dist_reform <= MAX_HORIZON],
  aux3, by = 'dist_reform')

# --- Step F: Revenue changes -------------------------------------------------

aux4 <- results_taxes[estimator == 'DD' & year >= 0] %>%
  .[, change_taxes := cumsum(point_estimate * 479609)]

dt_revenue_changes <- left_join(
  data.table(dist_reform = seq(0, MAX_HORIZON)) %>%
    .[dist_reform %in% c(0,1,2), year := 0] %>%
    .[dist_reform %in% c(3,4,5,6), year := 1] %>%
    .[dist_reform %in% c(7,8,9,10), year := 2] %>%
    .[dist_reform %in% c(11,12), year := 3],
  aux4[,.(year, change_taxes)], by = 'year') %>%
  .[,.(dist_reform, change_taxes = case_when(
    year == 0 ~ change_taxes/3,
    year != 0 ~ change_taxes/4))]

# --- Step G: b'(x) = mechanical benefits (new schedule, old choices) ---------
# Same structure as Step D but using period='new' from G4

aux5 <- results_selection[period == 'new' & dist_reform >= 0 & dist_reform <= MAX_HORIZON,
  .(dist_reform, points_norm, delta_ben = (avg_benefits_pv - point_estimate))]

aux6 <- cf_counts[dist_reform %in% 0:MAX_HORIZON,
  .(dist_reform, points_norm, num_claims_count = claims_c)]

aux7 <- full_join(aux5, aux6, by = c('dist_reform','points_norm')) %>%
  .[, prod := delta_ben * num_claims_count] %>%
  .[, .(counterfactual_benefits_new_t = sum(prod, na.rm = TRUE)), by = dist_reform] %>%
  arrange(dist_reform) %>%
  .[, counterfactual_benefits_new := cumsum(counterfactual_benefits_new_t)]

message("Step G: b'(x) computed. Range: ",
        round(min(aux7$counterfactual_benefits_new, na.rm = TRUE)/1e6, 1), "M to ",
        round(max(aux7$counterfactual_benefits_new, na.rm = TRUE)/1e6, 1), "M")

# --- Step H: Welfare and WMVPF computation -----------------------------------

dt_welfare_actual <- full_join(aux7,
  data.table(dist_reform = seq(0, MAX_HORIZON, 1),
             gamma = GAMMA_BASELINE,
             cons_inss = CONS_INSS,
             cons_pop = CONS_POP),
  by = 'dist_reform')

dt_wmvpf <- merge(dt_benefit_changes, dt_revenue_changes, by = 'dist_reform') %>%
  merge(dt_welfare_actual, by = 'dist_reform')
dt_wmvpf[, c('counterfactual_benefits_t','counterfactual_benefits_new_t') := NULL]

# WMVPF formulas (Slides 37-41/56)
# Discount: (1.005^3)^t for costs; 0.995^(3t) for welfare
dt_wmvpf[, net_cost := (total_benefits_payment - counterfactual_benefits) /
                        ((1.005^3)^dist_reform)]

dt_wmvpf[, mech_cost := (counterfactual_benefits_new - counterfactual_benefits) /
                         ((1.005^3)^dist_reform)]

dt_wmvpf[, fiscal_ext := (total_benefits_payment - counterfactual_benefits_new) /
                          ((1.005^3)^dist_reform)]

dt_wmvpf[, welfare := (0.995^(3 * dist_reform)) *
  (1 - gamma * (cons_inss - cons_pop) / cons_pop) *
  (counterfactual_benefits_new - counterfactual_benefits)]

wmvpf_actual <- sum(dt_wmvpf$welfare) / sum(dt_wmvpf$net_cost)

message(">>> WMVPF (actual reform) = ", round(wmvpf_actual, 4))
message("    sum(welfare)  = ", round(sum(dt_wmvpf$welfare)/1e6, 2), "M")
message("    sum(net_cost) = ", round(sum(dt_wmvpf$net_cost)/1e6, 2), "M")

# --- Part 1 output table (I4 format) ----------------------------------------

out_actual <- dt_wmvpf[, .(
  dist_reform  = REFORM_QUARTER + dist_reform / 4,
  `b_prime_x_prime` = total_benefits_payment,
  `b_x`             = counterfactual_benefits,
  `b_prime_x`       = counterfactual_benefits_new,
  `ME` = counterfactual_benefits_new - counterfactual_benefits,
  `TC` = total_benefits_payment - counterfactual_benefits,
  `FE` = total_benefits_payment - counterfactual_benefits_new,
  net_cost, mech_cost, fiscal_ext, welfare
)]

out_actual[, (names(out_actual)[names(out_actual) != 'dist_reform']) :=
  lapply(.SD, function(x) round(x / 1e6, 2)),
  .SDcols = names(out_actual)[names(out_actual) != 'dist_reform']
]

# --- Part 1 plot (I4 style) --------------------------------------------------

p_actual <- ggplot(out_actual, aes(x = dist_reform)) +
  geom_line(aes(y = mech_cost, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
  geom_line(aes(y = net_cost, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
  geom_line(aes(y = welfare, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
  geom_point(aes(y = mech_cost, color = factor(1)), shape = 17) +
  geom_point(aes(y = net_cost, color = factor(2)), shape = 17) +
  geom_point(aes(y = welfare, color = factor(3)), shape = 17) +
  scale_x_continuous(breaks = seq(2015, 2019, 1),
                     minor_breaks = seq(2015, 2019.25, 0.25),
                     guide = guide_axis(minor.ticks = TRUE)) +
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
  scale_color_brewer(palette = 'Set1',
                     labels = c('1' = 'Mechanical Effect',
                                '2' = 'Total Cost',
                                '3' = 'Welfare Effect')) +
  theme_classic() +
  guides(color = guide_legend(nrow = 3, order = 1)) +
  theme(axis.title.x = element_text(family = 'serif'),
        axis.title.y = element_text(family = 'serif'),
        axis.text.x  = element_text(family = 'serif'),
        axis.text.y  = element_text(family = 'serif'),
        axis.line     = element_line(linewidth = 0.3),
        axis.ticks    = element_line(linewidth = 0.3),
        plot.title    = element_text(hjust = 0.5, family = 'serif', size = 12),
        panel.grid.minor   = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = 0.3),
        legend.position      = c(0, 1),
        legend.justification = c(0, 1),
        legend.direction     = 'horizontal',
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width  = unit(0, units = 'mm'),
        legend.spacing    = unit(0, units = 'mm'),
        legend.title      = element_blank(),
        legend.text       = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2)) +
  xlab('Quarter') +
  ylab(NULL) +
  ggtitle(paste0('Actual Reform: WMVPF = ', round(wmvpf_actual, 3)))

p_actual
# ########################################################################
# ########################################################################
#
#                    PART 2: PURE REFORM WMVPF (bL / bS)
#          (Same mathematical structure as Part 1 -- I4's framework)
#
# ########################################################################
# ########################################################################

message("\n=== PART 2: Pure Reform WMVPF (bL / bS decomposition) ===")

# --- Load G5 pure reform data -----------------------------------------------
# G5 output has: claims_c, claims_L, claims_S, avg_benefits_bL, avg_benefits_bS,
#   avg_reform_benefits_pre_reform_choices_bL/bS (mechanical benefits),
#   avg_post_pure_reform_benefits_bL/bS (behavioral benefits),
#   point_estimate_bL/bS, Beta_LP/SP/LA/SA, delta_ben (from G2)

g5_pure_path <- paste0('output/G/G5_table_results_contrafactual_reforms_and_benefits_freq',
                       SUFFIX, '.csv')

if (!file.exists(g5_pure_path)) {
  message("WARNING: G5 pure reform output not found at: ", g5_pure_path)
  message("Run G5 successfully first. Skipping pure reform section.")
  PURE_REFORM_AVAILABLE <- FALSE
} else {
  PURE_REFORM_AVAILABLE <- TRUE
}

if (PURE_REFORM_AVAILABLE) {

  g5_data <- fread(g5_pure_path)
  message("Loaded G5 data: ", nrow(g5_data), " rows, ",
          ncol(g5_data), " columns")

  # Filter to analysis horizon
  g5_data <- g5_data[dist_reform %in% 0:MAX_HORIZON]
  message("After horizon filter: ", nrow(g5_data), " rows")

  # --- NA fallback for behavioral benefits ---
  # avg_post_pure_reform_benefits_bL can be NA for p=0-3 where Beta_LA is
  # unavailable. Fall back to mechanical (avg_reform_benefits_pre_reform_choices).

  na_bL <- sum(is.na(g5_data$avg_post_pure_reform_benefits_bL))
  if (na_bL > 0) {
    g5_data[is.na(avg_post_pure_reform_benefits_bL),
      avg_post_pure_reform_benefits_bL := avg_reform_benefits_pre_reform_choices_bL]
    message("Filled ", na_bL, " NA cells in avg_post_pure_reform_benefits_bL ",
            "(mechanical fallback)")
  }

  na_bS <- sum(is.na(g5_data$avg_post_pure_reform_benefits_bS))
  if (na_bS > 0) {
    g5_data[is.na(avg_post_pure_reform_benefits_bS),
      avg_post_pure_reform_benefits_bS := avg_reform_benefits_pre_reform_choices_bS]
    message("Filled ", na_bS, " NA cells in avg_post_pure_reform_benefits_bS ",
            "(mechanical fallback)")
  }

  # ======================================================================
  #                      PURE LEVEL REFORM (bL)
  # ======================================================================
  message("\n--- Pure Level Reform (bL) ---")

  # b(x) baseline: REUSE Part 1's counterfactual_benefits from aux3.
  # b(x) = "what would have happened with no reform" -- same for all reforms.

  # b'_L(x): mechanical (Pure L schedule, old choices = claims_c)
  mech_L <- g5_data[,
    .(mech_L_t = sum(avg_reform_benefits_pre_reform_choices_bL * claims_c,
                     na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]
  mech_L[, mech_L_cumsum := cumsum(mech_L_t)]

  # b'_L(x'): behavioral (Pure L schedule, new choices = claims_L)
  behav_L <- g5_data[,
    .(behav_L_t = sum(avg_post_pure_reform_benefits_bL * claims_L,
                      na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]
  behav_L[, behav_L_cumsum := cumsum(behav_L_t)]

  # Merge with b(x) baseline from Part 1
  dt_wmvpf_L <- merge(
    aux3[, .(dist_reform, counterfactual_benefits)],
    mech_L[, .(dist_reform, mech_L_cumsum)],
    by = 'dist_reform') %>%
    merge(behav_L[, .(dist_reform, behav_L_cumsum)], by = 'dist_reform')

  # WMVPF_bL formulas (same structure as Part 1)
  dt_wmvpf_L[, net_cost_L := (behav_L_cumsum - counterfactual_benefits) /
                              ((1.005^3)^dist_reform)]

  dt_wmvpf_L[, mech_cost_L := (mech_L_cumsum - counterfactual_benefits) /
                               ((1.005^3)^dist_reform)]

  dt_wmvpf_L[, fiscal_ext_L := (behav_L_cumsum - mech_L_cumsum) /
                                ((1.005^3)^dist_reform)]

  dt_wmvpf_L[, welfare_L := (0.995^(3 * dist_reform)) *
    (1 - GAMMA_BASELINE * (CONS_INSS - CONS_POP) / CONS_POP) *
    (mech_L_cumsum - counterfactual_benefits)]

  wmvpf_bL <- sum(dt_wmvpf_L$welfare_L, na.rm = TRUE) /
              sum(dt_wmvpf_L$net_cost_L, na.rm = TRUE)

  message(">>> WMVPF_bL (Pure Level) = ", round(wmvpf_bL, 4))
  message("    sum(welfare_L)  = ", round(sum(dt_wmvpf_L$welfare_L, na.rm = TRUE)/1e6, 2), "M")
  message("    sum(net_cost_L) = ", round(sum(dt_wmvpf_L$net_cost_L, na.rm = TRUE)/1e6, 2), "M")

  # ======================================================================
  #                      PURE SLOPE REFORM (bS)
  # ======================================================================
  message("\n--- Pure Slope Reform (bS) ---")

  # b'_S(x): mechanical (Pure S schedule, old choices = claims_c)
  mech_S <- g5_data[,
    .(mech_S_t = sum(avg_reform_benefits_pre_reform_choices_bS * claims_c,
                     na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]
  mech_S[, mech_S_cumsum := cumsum(mech_S_t)]

  # b'_S(x'): behavioral (Pure S schedule, new choices = claims_S)
  behav_S <- g5_data[,
    .(behav_S_t = sum(avg_post_pure_reform_benefits_bS * claims_S,
                      na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]
  behav_S[, behav_S_cumsum := cumsum(behav_S_t)]

  # Merge with b(x) baseline from Part 1
  dt_wmvpf_S <- merge(
    aux3[, .(dist_reform, counterfactual_benefits)],
    mech_S[, .(dist_reform, mech_S_cumsum)],
    by = 'dist_reform') %>%
    merge(behav_S[, .(dist_reform, behav_S_cumsum)], by = 'dist_reform')

  # WMVPF_bS formulas (same structure as Part 1)
  dt_wmvpf_S[, net_cost_S := (behav_S_cumsum - counterfactual_benefits) /
                              ((1.005^3)^dist_reform)]

  dt_wmvpf_S[, mech_cost_S := (mech_S_cumsum - counterfactual_benefits) /
                               ((1.005^3)^dist_reform)]

  dt_wmvpf_S[, fiscal_ext_S := (behav_S_cumsum - mech_S_cumsum) /
                                ((1.005^3)^dist_reform)]

  dt_wmvpf_S[, welfare_S := (0.995^(3 * dist_reform)) *
    (1 - GAMMA_BASELINE * (CONS_INSS - CONS_POP) / CONS_POP) *
    (mech_S_cumsum - counterfactual_benefits)]

  wmvpf_bS <- sum(dt_wmvpf_S$welfare_S, na.rm = TRUE) /
              sum(dt_wmvpf_S$net_cost_S, na.rm = TRUE)

  message(">>> WMVPF_bS (Pure Slope) = ", round(wmvpf_bS, 4))
  message("    sum(welfare_S)  = ", round(sum(dt_wmvpf_S$welfare_S, na.rm = TRUE)/1e6, 2), "M")
  message("    sum(net_cost_S) = ", round(sum(dt_wmvpf_S$net_cost_S, na.rm = TRUE)/1e6, 2), "M")

  # --- Pure reform output tables (in millions) --------------------------------

  out_L <- dt_wmvpf_L[, .(
    dist_reform = REFORM_QUARTER + dist_reform / 4,
    b_x       = counterfactual_benefits,
    b_prime_L_x  = mech_L_cumsum,
    b_prime_L_x_prime = behav_L_cumsum,
    ME_L = mech_L_cumsum - counterfactual_benefits,
    TC_L = behav_L_cumsum - counterfactual_benefits,
    FE_L = behav_L_cumsum - mech_L_cumsum,
    net_cost_L, mech_cost_L, fiscal_ext_L, welfare_L
  )]
  out_L[, (names(out_L)[names(out_L) != 'dist_reform']) :=
    lapply(.SD, function(x) round(x / 1e6, 2)),
    .SDcols = names(out_L)[names(out_L) != 'dist_reform']
  ]

  out_S <- dt_wmvpf_S[, .(
    dist_reform = REFORM_QUARTER + dist_reform / 4,
    b_x       = counterfactual_benefits,
    b_prime_S_x  = mech_S_cumsum,
    b_prime_S_x_prime = behav_S_cumsum,
    ME_S = mech_S_cumsum - counterfactual_benefits,
    TC_S = behav_S_cumsum - counterfactual_benefits,
    FE_S = behav_S_cumsum - mech_S_cumsum,
    net_cost_S, mech_cost_S, fiscal_ext_S, welfare_S
  )]
  out_S[, (names(out_S)[names(out_S) != 'dist_reform']) :=
    lapply(.SD, function(x) round(x / 1e6, 2)),
    .SDcols = names(out_S)[names(out_S) != 'dist_reform']
  ]

  # --- Pure reform plots (same style as Part 1) --------------------------------

  p_pure_L <- ggplot(out_L, aes(x = dist_reform)) +
    geom_line(aes(y = mech_cost_L, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = net_cost_L, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = welfare_L, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = mech_cost_L, color = factor(1)), shape = 17) +
    geom_point(aes(y = net_cost_L, color = factor(2)), shape = 17) +
    geom_point(aes(y = welfare_L, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
    scale_color_brewer(palette = 'Set1',
                       labels = c('1' = 'Mechanical Effect',
                                  '2' = 'Total Cost',
                                  '3' = 'Welfare Effect')) +
    theme_classic() +
    guides(color = guide_legend(nrow = 3, order = 1)) +
    theme(axis.title.x = element_text(family = 'serif'),
          axis.title.y = element_text(family = 'serif'),
          axis.text.x  = element_text(family = 'serif'),
          axis.text.y  = element_text(family = 'serif'),
          axis.line     = element_line(linewidth = 0.3),
          axis.ticks    = element_line(linewidth = 0.3),
          plot.title    = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor   = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position      = c(0, 1),
          legend.justification = c(0, 1),
          legend.direction     = 'horizontal',
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width  = unit(0, units = 'mm'),
          legend.spacing    = unit(0, units = 'mm'),
          legend.title      = element_blank(),
          legend.text       = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2)) +
    xlab('Quarter') +
    ylab(NULL) +
    ggtitle(paste0('Pure Level: WMVPF_bL = ', round(wmvpf_bL, 3)))

  p_pure_S <- ggplot(out_S, aes(x = dist_reform)) +
    geom_line(aes(y = mech_cost_S, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = net_cost_S, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = welfare_S, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = mech_cost_S, color = factor(1)), shape = 17) +
    geom_point(aes(y = net_cost_S, color = factor(2)), shape = 17) +
    geom_point(aes(y = welfare_S, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
    scale_color_brewer(palette = 'Set1',
                       labels = c('1' = 'Mechanical Effect',
                                  '2' = 'Total Cost',
                                  '3' = 'Welfare Effect')) +
    theme_classic() +
    guides(color = guide_legend(nrow = 3, order = 1)) +
    theme(axis.title.x = element_text(family = 'serif'),
          axis.title.y = element_text(family = 'serif'),
          axis.text.x  = element_text(family = 'serif'),
          axis.text.y  = element_text(family = 'serif'),
          axis.line     = element_line(linewidth = 0.3),
          axis.ticks    = element_line(linewidth = 0.3),
          plot.title    = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor   = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position      = c(0, 1),
          legend.justification = c(0, 1),
          legend.direction     = 'horizontal',
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width  = unit(0, units = 'mm'),
          legend.spacing    = unit(0, units = 'mm'),
          legend.title      = element_blank(),
          legend.text       = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2)) +
    xlab('Quarter') +
    ylab(NULL) +
    ggtitle(paste0('Pure Slope: WMVPF_bS = ', round(wmvpf_bS, 3)))

} else {
  wmvpf_bL <- NA_real_
  wmvpf_bS <- NA_real_
  message("Pure reform section skipped -- missing upstream data.")
}

p_pure_L
p_pure_S
# ########################################################################
# ########################################################################
#
#                    PART 3: SUMMARY & OUTPUTS
#
# ########################################################################
# ########################################################################

message("\n=== PART 3: Summary ===")

# --- Summary table -----------------------------------------------------------

summary_dt <- data.table(
  Metric = c(
    "WMVPF (actual reform)",
    "WMVPF_bL (Pure Level)",
    "WMVPF_bS (Pure Slope)",
    "Welfare weight eta",
    "CRRA gamma",
    "Consumption beneficiaries",
    "Consumption population",
    "Data mode",
    "Quarters analyzed"
  ),
  Value = c(
    round(wmvpf_actual, 4),
    round(wmvpf_bL, 4),
    round(wmvpf_bS, 4),
    round(ETA, 4),
    GAMMA_BASELINE,
    CONS_INSS,
    CONS_POP,
    DATA_MODE,
    MAX_HORIZON
  )
)

print(summary_dt)

if (!is.na(wmvpf_bL) && !is.na(wmvpf_bS)) {
  if (wmvpf_bS > wmvpf_bL) {
    message("\n>>> WMVPF_bS > WMVPF_bL => Optimal direction: ",
            "INCREASE slope (bS), DECREASE level (bL)")
    message(">>> The 2015 reform went in the OPPOSITE direction ",
            "(increased bL, decreased bS)")
  } else {
    message("\n>>> WMVPF_bL >= WMVPF_bS => Optimal direction: ",
            "INCREASE level (bL)")
  }
}

# --- Saving outputs ----------------------------------------------------------

message("\n=== Saving outputs ===")

# Actual reform
fwrite(out_actual, file = paste0('output/I/I6_wmvpf_actual', SUFFIX, '.csv'))
message("Saved: output/I/I6_wmvpf_actual", SUFFIX, ".csv")

# I4-format backward compatibility (same columns as I4_table_wmvpf)
fwrite(dt_wmvpf, file = paste0('output/I/I6_table_wmvpf', SUFFIX, '.csv'))
message("Saved: output/I/I6_table_wmvpf", SUFFIX, ".csv")

# Pure reforms
if (PURE_REFORM_AVAILABLE && exists("out_L")) {
  fwrite(out_L, file = paste0('output/I/I6_wmvpf_pure_L', SUFFIX, '.csv'))
  message("Saved: output/I/I6_wmvpf_pure_L", SUFFIX, ".csv")
}

if (PURE_REFORM_AVAILABLE && exists("out_S")) {
  fwrite(out_S, file = paste0('output/I/I6_wmvpf_pure_S', SUFFIX, '.csv'))
  message("Saved: output/I/I6_wmvpf_pure_S", SUFFIX, ".csv")
}

# Summary
fwrite(summary_dt, file = paste0('output/I/I6_summary', SUFFIX, '.csv'))
message("Saved: output/I/I6_summary", SUFFIX, ".csv")

# Plots
ggsave(p_actual,
       filename = paste0('output/I/I6_plot_actual_reform', SUFFIX, '.pdf'),
       height = 2.8, width = 4.2)
message("Saved: output/I/I6_plot_actual_reform", SUFFIX, ".pdf")

if (PURE_REFORM_AVAILABLE && exists("p_pure_L")) {
  ggsave(p_pure_L,
         filename = paste0('output/I/I6_plot_pure_L_reform', SUFFIX, '.pdf'),
         height = 2.8, width = 4.2)
  message("Saved: output/I/I6_plot_pure_L_reform", SUFFIX, ".pdf")
}

if (PURE_REFORM_AVAILABLE && exists("p_pure_S")) {
  ggsave(p_pure_S,
         filename = paste0('output/I/I6_plot_pure_S_reform', SUFFIX, '.pdf'),
         height = 2.8, width = 4.2)
  message("Saved: output/I/I6_plot_pure_S_reform", SUFFIX, ".pdf")
}

# --- Final summary -----------------------------------------------------------

message("\n=== I6 complete ===")
message("WMVPF actual = ", round(wmvpf_actual, 4))
if (!is.na(wmvpf_bL)) message("WMVPF_bL     = ", round(wmvpf_bL, 4))
if (!is.na(wmvpf_bS)) message("WMVPF_bS     = ", round(wmvpf_bS, 4))
if (!is.na(wmvpf_bL) && !is.na(wmvpf_bS)) {
  message("bS > bL?     = ", wmvpf_bS > wmvpf_bL)
}
