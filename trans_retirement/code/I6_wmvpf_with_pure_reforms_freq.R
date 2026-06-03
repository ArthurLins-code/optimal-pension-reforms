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
#   - output/I/I6_wmvpf_pure_L[_sample].csv        (per-quarter + cumulative columns)
#   - output/I/I6_wmvpf_pure_S[_sample].csv        (per-quarter + cumulative columns)
#   - output/I/I6_summary[_sample].csv
#   - output/I/I6_table_wmvpf[_sample].csv         (I4-format backward compat)
#   - output/I/I6_plot_actual_reform[_sample].pdf
#   - output/I/I6_plot_pure_L_reform[_sample].pdf   (cumulative)
#   - output/I/I6_plot_pure_S_reform[_sample].pdf   (cumulative)
#   - output/I/I6_plot_pure_L_reform_per_qtr[_sample].pdf
#   - output/I/I6_plot_pure_S_reform_per_qtr[_sample].pdf
#
# References:
#   - Canonical appendix: _docs/reference/appendix_pure_reform/ (frames 18-47/47)
#   - Spec: _docs/pure_reforms_spec.md
#   - PART 1: actual reform WMVPF (I4 replication, not modified)
#   - PART 2: pure reforms via expenditure reallocation (decision 7, 39-45/47)
#   - Locked decisions 1-8: see _docs/I6_rebuild_prompt.md
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
MAX_HORIZON    <- 13L

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
#
# MAX_CLAIM_QUARTER aligns the panel filter with the counterfactual horizon.
# Previously hardcoded to 2018.25, which excluded the t=13 (2018.50) cohort
# from b'(x') while counterfactual series (b(x), b'(x)) still included it —
# causing a truncation-artifact drop in TC at the rightmost quarter.
#
# NOTE: TC < 0 at t=0 is expected — postponement front-loads apparent savings
# because b'(x') is small (few claims under new schedule) while b(x) already
# includes a full cohort that would have claimed under the old schedule.

MAX_CLAIM_QUARTER <- REFORM_QUARTER + MAX_HORIZON / 4  # 2015.25 + 13/4 = 2018.50

tot_ben_period <- panel[d_claim_post_reform == 1 & claim_quarter <= MAX_CLAIM_QUARTER,
  .(total_benefits_payment = sum(benefits_new_pv, na.rm = TRUE)),
  by = .(dist_reform)]

message("Step A: total_benefits_payment computed for ",
        nrow(tot_ben_period[dist_reform >= 0 & dist_reform <= MAX_HORIZON]),
        " quarters (claim_quarter <= ", MAX_CLAIM_QUARTER, ")")

# --- Step B: Number of claims per cell ---------------------------------------

n_claims <- dt_cs[d_claim_post_reform == 1 & claim_quarter <= MAX_CLAIM_QUARTER,
  .(num_claims = .N), by = .(dist_reform, points_norm)]

# --- Step C: External files --------------------------------------------------
# F-stage counterfactual counts (sample-aware via SUFFIX)
cf_counts <- fread(paste0('output/F/new_counterfactual_claim_counts', SUFFIX, '.csv'))
setnames(cf_counts, c("t","p"), c("dist_reform","points_norm"), skip_absent = TRUE)

# G4: selection-corrected average benefits (sample-aware via SUFFIX)
results_selection <- fread(paste0('output/G/G4_table_results', SUFFIX, '.csv'))

# H2: tax elasticity DD estimates (sample-aware via SUFFIX)
results_taxes <- fread(paste0('output/H/H2_table_results', SUFFIX, '.csv'))

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
sum(dt_wmvpf$mech_cost)
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
  lapply(.SD, function(x) round(x / 1e9, 2)),
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
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' B')) +
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
#     Expenditure-reallocation approach (spec Step 4, appendix 39-45/47)
#     Replaces the old frequency-space Beta_LP/LA/SP/SA layer.
#     BEHAV built via g_pta postponement reallocation (decision 7).
#     Aggregate over ALL p including p<0 (decision 3).
#     Discount: (1.005^3)^(-t) (decision 6).
#     Output: both per-quarter and cumulative WMVPF.
#
# ########################################################################
# ########################################################################

message("\n=== PART 2: Pure Reform WMVPF (bL / bS decomposition) ===")

# --- Load G5 pure reform data -----------------------------------------------
# G5 output columns USED:
#   dist_reform, points_norm, claims (=N^a), claims_c (=N^c),
#   avg_benefits_bL/bS (= b̄^{q,a}, uncorrected avg benefit),
#   avg_reform_benefits_pre_reform_choices_bL/bS (= b̄ − β̂, for MECH and E^c),
#   g_pta (claiming probability from F-stage, for postponement reallocation)
# G5 columns NOT USED (old frequency-space layer, removed per decision 7):
#   avg_post_pure_reform_benefits_bL/bS, Beta_LP/SP/LA/SA,
#   claims_L, claims_S

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

  # Filter to analysis horizon (include t=-1 for postponement origin lookups)
  # Decision 7 reallocation references origin cells at t-2(x+p), which can be -1
  g5_data <- g5_data[dist_reform %in% -1:MAX_HORIZON]
  message("After horizon filter (incl. t=-1): ", nrow(g5_data), " rows")

  # ======================================================================
  #     §B: PER-CELL EXPENDITURES + MECH  (spec §0, 34/47; Step 3, 38/47)
  #
  #   Replaces the old NA-fallback block and the frequency-space BEHAV
  #   construction. Per-cell expenditures are the building blocks for
  #   the expenditure-reallocation approach (decision 7).
  #
  #   References:
  #     - Per-cell E^a, E^c: spec §0, appendix 34/47
  #     - Selection DD (avg-benefit route): spec Step 2, appendix 36/47
  #     - MECH = Σ_p E^{c,q}: spec Step 3, appendix 38/47
  #     - Decision 3: aggregate over ALL p (unrestricted Σ_p, incl. p<0)
  # ======================================================================
  message("\n--- §B: Per-cell expenditures + MECH ---")

  # --- Per-cell expenditures (spec §0, appendix 34/47) ---
  # E^{a,q}_{p,t} = N^a_{p,t} · b̄^{q,a}_{p,t}     (actual expenditure per cell)
  g5_data[, E_a_L := claims * avg_benefits_bL]
  g5_data[, E_a_S := claims * avg_benefits_bS]

  # E^{c,q}_{p,t} = N^c_{p,t} · (b̄^{q,a} − β̂^{b̄,q})  (mechanical expenditure)
  # avg_reform_benefits_pre_reform_choices = b̄ − β̂  (avg-benefit DD route, 36/47)
  g5_data[, E_c_L := claims_c * avg_reform_benefits_pre_reform_choices_bL]
  g5_data[, E_c_S := claims_c * avg_reform_benefits_pre_reform_choices_bS]

  message("  Per-cell expenditures built: E_a_L, E_c_L, E_a_S, E_c_S")

  # --- MECH^q_t = Σ_p E^{c,q}_{p,t}  (spec Step 3, appendix 38/47) ---
  # Aggregate over ALL p including p<0 (decision 3), for reform quarters t≥0
  mech_L <- g5_data[dist_reform >= 0,
    .(mech_L_t = sum(E_c_L, na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]

  mech_S <- g5_data[dist_reform >= 0,
    .(mech_S_t = sum(E_c_S, na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]

  message("  MECH_L range: ", round(min(mech_L$mech_L_t) / 1e6, 2), "M to ",
          round(max(mech_L$mech_L_t) / 1e6, 2), "M  (",
          nrow(mech_L), " quarters)")
  message("  MECH_S range: ", round(min(mech_S$mech_S_t) / 1e6, 2), "M to ",
          round(max(mech_S$mech_S_t) / 1e6, 2), "M  (",
          nrow(mech_S), " quarters)")

  # ======================================================================
  #   §C: POSTPONEMENT REALLOCATION (E^P) — THE CORE CHANGE
  #       (spec Step 4, appendix 39-41/47 pure-L, 44-45/47 pure-S)
  #       Decision 7: expenditure path with g_pta
  #       Decision 8: bunching range p ∈ [0,4)
  #
  #   Sign-convention seam (spec L234-238, verify carefully):
  #     Pure-L: E^{P,L}_{p≥0} = +g · Σ(−E^{P,L}_{origin})
  #             E^L = E^{c,L} + E^{P,L}      (add postponement to counterfactual)
  #     Pure-S: E^{P,S}_{p≥0} = −g · Σ(E^{P,S}_{origin})
  #             E^S = E^{a,S} − E^{P,S}      (subtract postponement from actual)
  #   Both reallocation formulas are algebraically identical:
  #     E^P = −g · Σ(E^P_origin) = g · Σ(−E^P_origin)
  #   The difference is ONLY in the assembly of E^L vs E^S.
  # ======================================================================
  message("\n--- §C: Postponement reallocation (E^P) ---")

  # --- Verify g_pta exists in G5 data ---
  if (!'g_pta' %in% names(g5_data)) {
    message("WARNING: g_pta not found in G5 CSV. Attempting F-stage load...")
    f_pure_path <- paste0('output/F/new_counterfactual_claim_counts_with_pure_schedules_3',
                          SUFFIX, '.csv')
    if (file.exists(f_pure_path)) {
      f_data <- fread(f_pure_path, select = c('dist_reform', 'points_norm', 'g_pta'))
      g5_data <- merge(g5_data, f_data, by = c('dist_reform', 'points_norm'), all.x = TRUE)
      message("  g_pta loaded from F-stage CSV: ", sum(!is.na(g5_data$g_pta)), " non-NA values")
    } else {
      stop("g_pta not found in G5 or F-stage CSV. Cannot proceed with decision 7.")
    }
  } else {
    message("  g_pta found in G5 CSV: ", sum(!is.na(g5_data$g_pta)), " non-NA values")
  }

  # -----------------------------------------------------------------------
  #   Pure-L postponement (appendix 39-41/47)
  # -----------------------------------------------------------------------
  message("  Building E^{P,L} (pure-L postponement)...")

  # Origin losses: E^{P,L}_{p,t} = E^{a,L} − E^{c,L}  for p < 0, t ≥ −1
  # These are negative (people leave p<0 under pure-L, so E^a < E^c at origins)
  g5_data[points_norm < 0, E_P_L := E_a_L - E_c_L]

  # Reallocation inflow: for p ∈ [0,4), t ≥ 0  (decision 8: p ∈ [0,4))
  # E^{P,L}_{p,t} = g_{p,t−2p} · Σ_{x=1}^{x̄} (−E^{P,L}_{−x, t−2(x+p)})
  # x̄_{t,p} = min( (t+1)/2 − p, 6 )  (appendix 41/47)
  # Loop t ascending so origin values at t−2(x+p) are already computed
  for (tt in 0:MAX_HORIZON) {
    for (pp in 0:3) {
      x_bar <- min(floor((tt + 1) / 2 - pp), 6)
      if (x_bar < 1) next

      # g_{p,t−2p}: claiming probability at (p, t−2p)
      g_val <- g5_data[points_norm == pp & dist_reform == (tt - 2 * pp), g_pta][1]
      if (is.na(g_val) || g_val == 0) next

      # Sum origin losses: Σ_{x=1}^{x̄} (−E^{P,L}_{−x, t−2(x+p)})
      origin_sum <- 0
      for (xx in 1:x_bar) {
        origin_t <- tt - 2 * (xx + pp)
        E_P_val <- g5_data[points_norm == -xx & dist_reform == origin_t, E_P_L][1]
        if (!is.na(E_P_val)) origin_sum <- origin_sum + (-E_P_val)
      }

      g5_data[points_norm == pp & dist_reform == tt, E_P_L := g_val * origin_sum]
    }
  }

  # p ≥ 4: no postponement inflow (implicit on 41/47)
  g5_data[points_norm >= 4, E_P_L := 0]
  g5_data[is.na(E_P_L), E_P_L := 0]
  
  # Assemble E^L (appendix 39/47):
  #   p < 0:             E^L = E^{a,L}  (actual, postponement already in E^P)
  #   p ≥ 0, t = −1:     E^L = E^{a,L}  (pre-reform, postponement in both worlds)
  #   p ≥ 0, t ≥ 0:      E^L = E^{c,L} + E^{P,L}  (counterfactual + postponement)
  g5_data[points_norm < 0, E_L := E_a_L]
  g5_data[points_norm >= 0 & dist_reform == -1, E_L := E_a_L]
  g5_data[points_norm >= 0 & dist_reform >= 0, E_L := E_c_L + E_P_L]

  message("  E^{P,L} built. At p<0: ", sum(!is.na(g5_data[points_norm < 0, E_P_L])),
          " cells. At p∈[0,4): ", sum(!is.na(g5_data[points_norm %in% 0:3 & dist_reform >= 0, E_P_L])),
          " cells.")

  # -----------------------------------------------------------------------
  #   Pure-S postponement (appendix 44-45/47)
  # -----------------------------------------------------------------------
  message("  Building E^{P,S} (pure-S postponement)...")

  # Origin losses: E^{P,S}_{p,t} = E^{a,S} − E^{c,S}  for p < 0
  g5_data[points_norm < 0, E_P_S := E_a_S - E_c_S]
  # Reallocation: for p ∈ [0,4), t ≥ 0
  # E^{P,S}_{p,t} = −g_{p,t−2p} · Σ_{x=1}^{x̄} E^{P,S}_{−x, t−2(x+p)}
  #
  # Algebraically: −g · Σ(E^P_origin) = g · Σ(−E^P_origin)
  # So we reuse the same origin_sum pattern as pure-L (with inner negation),
  # and multiply by g (same sign as pure-L). The sign difference is absorbed
  # in the assembly: E^S = E^a − E^P (not E^c + E^P).
  for (tt in 0:MAX_HORIZON) {
    for (pp in 0:3) {
      x_bar <- min(floor((tt + 1) / 2 - pp), 6)
      if (x_bar < 1) next

      g_val <- g5_data[points_norm == pp & dist_reform == (tt - 2 * pp), g_pta][1]
      if (is.na(g_val) || g_val == 0) next

      # Σ(−E^{P,S}_origin) = g · Σ(−E^P) = −g · Σ(E^P)  [same form as pure-L]
      origin_sum <- 0
      for (xx in 1:x_bar) {
        origin_t <- tt - 2 * (xx + pp)
        E_P_val <- g5_data[points_norm == -xx & dist_reform == origin_t, E_P_S][1]
        if (!is.na(E_P_val)) origin_sum <- origin_sum + (-E_P_val)
      }

      # Same sign as pure-L: E^P = g · Σ(−E^P_origin) = −g · Σ(E^P_origin)
      g5_data[points_norm == pp & dist_reform == tt, E_P_S := g_val * origin_sum]
    }
  }

  # p ≥ 4: no postponement inflow
  g5_data[points_norm >= 4, E_P_S := 0]
  g5_data[is.na(E_P_S), E_P_S := 0]
  # Assemble E^S (appendix 44/47 — DIFFERENT from E^L!):
  #   p < 0:       E^S = E^{c,S}           (counterfactual at origins)
  #   p ≥ 0:       E^S = E^{a,S} − E^{P,S}  (actual minus postponement)
  g5_data[points_norm < 0, E_S := E_c_S]
  g5_data[points_norm >= 0 & dist_reform == -1, E_S := E_a_S]
  g5_data[points_norm >= 0 & dist_reform >= 0, E_S := E_a_S - E_P_S]

  message("  E^{P,S} built. At p<0: ", sum(!is.na(g5_data[points_norm < 0, E_P_S])),
          " cells. At p∈[0,4): ", sum(!is.na(g5_data[points_norm %in% 0:3 & dist_reform >= 0, E_P_S])),
          " cells.")

  # --- §C diagnostic summary ---
  message("\n  §C Diagnostics:")
  message("    E_P_L at p<0 (should be ≤ 0): range [",
          round(min(g5_data[points_norm < 0, E_P_L], na.rm = TRUE) / 1e6, 4), "M, ",
          round(max(g5_data[points_norm < 0, E_P_L], na.rm = TRUE) / 1e6, 4), "M]")
  message("    E_P_L at p∈[0,4) (should be ≥ 0): range [",
          round(min(g5_data[points_norm %in% 0:3 & dist_reform >= 0, E_P_L], na.rm = TRUE) / 1e6, 4), "M, ",
          round(max(g5_data[points_norm %in% 0:3 & dist_reform >= 0, E_P_L], na.rm = TRUE) / 1e6, 4), "M]")
  message("    E_P_S at p<0: range [",
          round(min(g5_data[points_norm < 0, E_P_S], na.rm = TRUE) / 1e6, 4), "M, ",
          round(max(g5_data[points_norm < 0, E_P_S], na.rm = TRUE) / 1e6, 4), "M]")
  message("    E_P_S at p∈[0,4): range [",
          round(min(g5_data[points_norm %in% 0:3 & dist_reform >= 0, E_P_S], na.rm = TRUE) / 1e6, 4), "M, ",
          round(max(g5_data[points_norm %in% 0:3 & dist_reform >= 0, E_P_S], na.rm = TRUE) / 1e6, 4), "M]")

  # ======================================================================
  #   §D: BEHAV + COSTS + WELFARE + WMVPF  (per-quarter + cumulative)
  #       (spec Step 5, appendix 42-43/47 pure-L, 45/47 pure-S)
  #       Decision 6: discount (1.005^3)^(-t), not 0.995^(3t)
  #       Arthur 2026-05-20: output both per-quarter and cumulative WMVPF
  # ======================================================================
  message("\n--- §D: BEHAV + costs + welfare + WMVPF ---")

  # --- BEHAV^q_t = Σ_p E^q_{p,t}  (spec Step 4 cont., appendix 42/47, 45/47) ---
  # Aggregate over ALL p including p<0 (decision 3), for reform quarters t≥0
  behav_L <- g5_data[dist_reform >= 0,
    .(behav_L_t = sum(E_L, na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]

  behav_S <- g5_data[dist_reform >= 0,
    .(behav_S_t = sum(E_S, na.rm = TRUE)),
    by = dist_reform][order(dist_reform)]

  message("  BEHAV_L range: ", round(min(behav_L$behav_L_t) / 1e6, 2), "M to ",
          round(max(behav_L$behav_L_t) / 1e6, 2), "M")
  message("  BEHAV_S range: ", round(min(behav_S$behav_S_t) / 1e6, 2), "M to ",
          round(max(behav_S$behav_S_t) / 1e6, 2), "M")

  # --- CNTRF_t from PART 1 (per-quarter, NOT cumsum) ---
  # aux3 already has counterfactual_benefits_t = Σ_p(delta_ben × claims_c) per quarter
  # and counterfactual_benefits = cumsum(counterfactual_benefits_t)
  # Decision 5: reuse PART 1's no-reform baseline as-is
  cntrf <- aux3[, .(dist_reform, cntrf_t = counterfactual_benefits_t)]

  # --- Merge all per-quarter objects ---
  dt_pure_L <- Reduce(function(a, b) merge(a, b, by = 'dist_reform'),
    list(mech_L, behav_L, cntrf))
  dt_pure_S <- Reduce(function(a, b) merge(a, b, by = 'dist_reform'),
    list(mech_S, behav_S, cntrf))

  # --- Per-quarter costs and welfare (appendix 43/47 pure-L, 45/47 pure-S) ---
  # Decision 6: disc_t = (1.005^3)^(-t), replaces the old 0.995^(3t)
  # NOTE: mismatch with the 6% within-life annuity is known (flagged, not fixed)
  disc_t <- (1.005^3)^(-dt_pure_L$dist_reform)

  # ETA already defined at L57: 1 - GAMMA_BASELINE * (CONS_INSS - CONS_POP) / CONS_POP

  # --- Pure-L: TC, ME, WE, WMVPF ---
  dt_pure_L[, `:=`(
    TC_L_t = behav_L_t - cntrf_t,
    ME_L_t = mech_L_t  - cntrf_t
  )]
  dt_pure_L[, FE_L_t := TC_L_t - ME_L_t]    # fiscal externality = TC - ME
  dt_pure_L[, WE_L_t := ME_L_t * ETA]       # welfare effect (per-quarter, undiscounted)
  dt_pure_L[, WMVPF_L_t := WE_L_t / TC_L_t] # per-quarter WMVPF

  # --- Pure-S: TC, ME, WE, WMVPF ---
  dt_pure_S[, `:=`(
    TC_S_t = behav_S_t - cntrf_t,
    ME_S_t = mech_S_t  - cntrf_t
  )]
  dt_pure_S[, FE_S_t := TC_S_t - ME_S_t]
  dt_pure_S[, WE_S_t := ME_S_t * ETA]
  dt_pure_S[, WMVPF_S_t := WE_S_t / TC_S_t]

  # --- Cumulative (discounted) ---
  # Cumulative = cumsum of discounted per-quarter objects
  dt_pure_L[, `:=`(
    TC_L_cum = cumsum(TC_L_t * disc_t),
    ME_L_cum = cumsum(ME_L_t * disc_t),
    WE_L_cum = cumsum(WE_L_t * disc_t)
  )]
  dt_pure_L[, WMVPF_L_cum := WE_L_cum / TC_L_cum]

  dt_pure_S[, `:=`(
    TC_S_cum = cumsum(TC_S_t * disc_t),
    ME_S_cum = cumsum(ME_S_t * disc_t),
    WE_S_cum = cumsum(WE_S_t * disc_t)
  )]
  dt_pure_S[, WMVPF_S_cum := WE_S_cum / TC_S_cum]

  # --- Report both per-quarter (at T) and cumulative ---
  wmvpf_bL_T   <- dt_pure_L[dist_reform == MAX_HORIZON, WMVPF_L_t]
  wmvpf_bL_cum <- dt_pure_L[dist_reform == MAX_HORIZON, WMVPF_L_cum]
  wmvpf_bS_T   <- dt_pure_S[dist_reform == MAX_HORIZON, WMVPF_S_t]
  wmvpf_bS_cum <- dt_pure_S[dist_reform == MAX_HORIZON, WMVPF_S_cum]

  # For PART 3 backward compat: wmvpf_bL/bS = cumulative (the "headline" number)
  wmvpf_bL <- wmvpf_bL_cum
  wmvpf_bS <- wmvpf_bS_cum

  message("\n  §D Results:")
  message("  >>> WMVPF_bL (Pure Level):")
  message("      Per-quarter at T=", MAX_HORIZON, ": ", round(wmvpf_bL_T, 4))
  message("      Cumulative:         ", round(wmvpf_bL_cum, 4))
  message("      sum(WE_L_cum) = ", round(dt_pure_L[dist_reform == MAX_HORIZON, WE_L_cum] / 1e6, 2), "M")
  message("      sum(TC_L_cum) = ", round(dt_pure_L[dist_reform == MAX_HORIZON, TC_L_cum] / 1e6, 2), "M")
  message("  >>> WMVPF_bS (Pure Slope):")
  message("      Per-quarter at T=", MAX_HORIZON, ": ", round(wmvpf_bS_T, 4))
  message("      Cumulative:         ", round(wmvpf_bS_cum, 4))
  message("      sum(WE_S_cum) = ", round(dt_pure_S[dist_reform == MAX_HORIZON, WE_S_cum] / 1e6, 2), "M")
  message("      sum(TC_S_cum) = ", round(dt_pure_S[dist_reform == MAX_HORIZON, TC_S_cum] / 1e6, 2), "M")

  # ======================================================================
  #   §E: OUTPUT TABLES + PLOTS
  #       Both per-quarter (_t) and cumulative (_cum) columns.
  #       Plots: cumulative version (headline) + per-quarter for Juan.
  # ======================================================================
  message("\n--- §E: Output tables + plots ---")

  # --- Pure-L output table (in millions) ---
  out_L <- dt_pure_L[, .(
    quarter     = REFORM_QUARTER + dist_reform / 4,
    dist_reform,
    MECH_L_t    = mech_L_t,
    BEHAV_L_t   = behav_L_t,
    CNTRF_t     = cntrf_t,
    TC_L_t, ME_L_t, FE_L_t, WE_L_t, WMVPF_L_t,
    TC_L_cum, ME_L_cum, WE_L_cum, WMVPF_L_cum
  )]
  # Scale to millions (except WMVPF ratios and dist_reform/quarter)
  scale_cols_L <- setdiff(names(out_L),
    c('quarter', 'dist_reform', 'WMVPF_L_t', 'WMVPF_L_cum'))
  out_L[, (scale_cols_L) := lapply(.SD, function(x) round(x / 1e6, 4)),
    .SDcols = scale_cols_L]
  out_L[, WMVPF_L_t   := round(WMVPF_L_t, 4)]
  out_L[, WMVPF_L_cum := round(WMVPF_L_cum, 4)]

  # --- Pure-S output table (in millions) ---
  out_S <- dt_pure_S[, .(
    quarter     = REFORM_QUARTER + dist_reform / 4,
    dist_reform,
    MECH_S_t    = mech_S_t,
    BEHAV_S_t   = behav_S_t,
    CNTRF_t     = cntrf_t,
    TC_S_t, ME_S_t, FE_S_t, WE_S_t, WMVPF_S_t,
    TC_S_cum, ME_S_cum, WE_S_cum, WMVPF_S_cum
  )]
  scale_cols_S <- setdiff(names(out_S),
    c('quarter', 'dist_reform', 'WMVPF_S_t', 'WMVPF_S_cum'))
  out_S[, (scale_cols_S) := lapply(.SD, function(x) round(x / 1e6, 4)),
    .SDcols = scale_cols_S]
  out_S[, WMVPF_S_t   := round(WMVPF_S_t, 4)]
  out_S[, WMVPF_S_cum := round(WMVPF_S_cum, 4)]

  message("  Output tables built: out_L (", nrow(out_L), " rows), out_S (",
          nrow(out_S), " rows)")

  # --- Plot theme (shared, same style as Part 1) ---
  theme_wmvpf <- theme_classic() +
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
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))

  wmvpf_color_scale <- scale_color_brewer(palette = 'Set1',
    labels = c('1' = 'Mechanical Effect',
               '2' = 'Total Cost',
               '3' = 'Welfare Effect'))

  # --- Pure-L cumulative plot (headline) ---
  p_pure_L <- ggplot(out_L, aes(x = quarter)) +
    geom_line(aes(y = ME_L_cum, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = TC_L_cum, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = WE_L_cum, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = ME_L_cum, color = factor(1)), shape = 17) +
    geom_point(aes(y = TC_L_cum, color = factor(2)), shape = 17) +
    geom_point(aes(y = WE_L_cum, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
    wmvpf_color_scale +
    guides(color = guide_legend(nrow = 3, order = 1)) +
    theme_wmvpf +
    xlab('Quarter') + ylab(NULL) +
    ggtitle(paste0('Pure Level (cum): WMVPF_bL = ', round(wmvpf_bL_cum, 3)))

  # --- Pure-S cumulative plot (headline) ---
  p_pure_S <- ggplot(out_S, aes(x = quarter)) +
    geom_line(aes(y = ME_S_cum, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = TC_S_cum, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = WE_S_cum, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = ME_S_cum, color = factor(1)), shape = 17) +
    geom_point(aes(y = TC_S_cum, color = factor(2)), shape = 17) +
    geom_point(aes(y = WE_S_cum, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
    wmvpf_color_scale +
    guides(color = guide_legend(nrow = 3, order = 1)) +
    theme_wmvpf +
    xlab('Quarter') + ylab(NULL) +
    ggtitle(paste0('Pure Slope (cum): WMVPF_bS = ', round(wmvpf_bS_cum, 3)))

  # --- Per-quarter plots (for Juan) ---
  p_pure_L_t <- ggplot(out_L, aes(x = quarter)) +
    geom_line(aes(y = ME_L_t, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = TC_L_t, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = WE_L_t, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = ME_L_t, color = factor(1)), shape = 17) +
    geom_point(aes(y = TC_L_t, color = factor(2)), shape = 17) +
    geom_point(aes(y = WE_L_t, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
    wmvpf_color_scale +
    guides(color = guide_legend(nrow = 3, order = 1)) +
    theme_wmvpf +
    xlab('Quarter') + ylab(NULL) +
    ggtitle(paste0('Pure Level (per-qtr): WMVPF_bL_T = ', round(wmvpf_bL_T, 3)))

  p_pure_S_t <- ggplot(out_S, aes(x = quarter)) +
    geom_line(aes(y = ME_S_t, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = TC_S_t, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = WE_S_t, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = ME_S_t, color = factor(1)), shape = 17) +
    geom_point(aes(y = TC_S_t, color = factor(2)), shape = 17) +
    geom_point(aes(y = WE_S_t, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
    wmvpf_color_scale +
    guides(color = guide_legend(nrow = 3, order = 1)) +
    theme_wmvpf +
    xlab('Quarter') + ylab(NULL) +
    ggtitle(paste0('Pure Slope (per-qtr): WMVPF_bS_T = ', round(wmvpf_bS_T, 3)))

} else {
  wmvpf_bL <- NA_real_
  wmvpf_bS <- NA_real_
  message("Pure reform section skipped -- missing upstream data.")
}

#Cumulative plots
p_pure_L
p_pure_S

#Quarter-by-quarter plots
p_pure_L_t
p_pure_S_t
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
    "WMVPF_bL cumulative (Pure Level)",
    "WMVPF_bS cumulative (Pure Slope)",
    "WMVPF_bL per-quarter at T (Pure Level)",
    "WMVPF_bS per-quarter at T (Pure Slope)",
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
    ifelse(exists("wmvpf_bL_T"), round(wmvpf_bL_T, 4), NA_real_),
    ifelse(exists("wmvpf_bS_T"), round(wmvpf_bS_T, 4), NA_real_),
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
       height = 3.8, width = 5)
message("Saved: output/I/I6_plot_actual_reform", SUFFIX, ".pdf")

if (PURE_REFORM_AVAILABLE && exists("p_pure_L")) {
  ggsave(p_pure_L,
         filename = paste0('output/I/I6_plot_pure_L_reform', SUFFIX, '.pdf'),
         height = 3.8, width = 5)
  message("Saved: output/I/I6_plot_pure_L_reform", SUFFIX, ".pdf")
}

if (PURE_REFORM_AVAILABLE && exists("p_pure_S")) {
  ggsave(p_pure_S,
         filename = paste0('output/I/I6_plot_pure_S_reform', SUFFIX, '.pdf'),
         height = 3.8, width = 5)
  message("Saved: output/I/I6_plot_pure_S_reform", SUFFIX, ".pdf")
}

# Per-quarter plots (for Juan)
if (PURE_REFORM_AVAILABLE && exists("p_pure_L_t")) {
  ggsave(p_pure_L_t,
         filename = paste0('output/I/I6_plot_pure_L_reform_per_qtr', SUFFIX, '.pdf'),
         height = 3.8, width = 5)
  message("Saved: output/I/I6_plot_pure_L_reform_per_qtr", SUFFIX, ".pdf")
}

if (PURE_REFORM_AVAILABLE && exists("p_pure_S_t")) {
  ggsave(p_pure_S_t,
         filename = paste0('output/I/I6_plot_pure_S_reform_per_qtr', SUFFIX, '.pdf'),
         height = 3.8, width = 5)
  message("Saved: output/I/I6_plot_pure_S_reform_per_qtr", SUFFIX, ".pdf")
}

# --- ×20 scaled cumulative plots (provisional, to adjust for 5% sample) ------

MULT <- 20

# Actual reform cumsum ×20
out_actual_x20 <- copy(out_actual)
out_actual_x20[, `:=`(ME_cumsum = ME * MULT,
                       TC_cumsum = TC * MULT,
                       WE_cumsum = welfare * MULT)]
p_actual_cumsum_x20 <- ggplot(out_actual_x20, aes(x = dist_reform)) +
  geom_line(aes(y = ME_cumsum, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
  geom_line(aes(y = TC_cumsum, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
  geom_line(aes(y = WE_cumsum, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
  geom_point(aes(y = ME_cumsum, color = factor(1)), shape = 17) +
  geom_point(aes(y = TC_cumsum, color = factor(2)), shape = 17) +
  geom_point(aes(y = WE_cumsum, color = factor(3)), shape = 17) +
  scale_x_continuous(breaks = seq(2015, 2019, 1),
                     minor_breaks = seq(2015, 2019.25, 0.25),
                     guide = guide_axis(minor.ticks = TRUE)) +
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' B')) +
  scale_color_brewer(palette = 'Set1',
                     labels = c('1' = 'Mechanical Effect',
                                '2' = 'Total Cost',
                                '3' = 'Welfare Effect')) +
  theme_classic() +
  guides(color = guide_legend(nrow = 1, order = 1)) +
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
        legend.position      = 'bottom',
        legend.direction     = 'horizontal',
        legend.title      = element_blank(),
        legend.text       = element_text(family = 'serif', size = 10)) +
  xlab('Quarter') + ylab(NULL) +
  ggtitle(paste0('Actual Reform: WMVPF = ', round(wmvpf_actual, 3)))
ggsave(p_actual_cumsum_x20,
       filename = paste0('output/I/I6_plot_cumsum_actual_reform_multby20', SUFFIX, '.pdf'),
       height = 3.8, width = 5)
message("Saved: output/I/I6_plot_cumsum_actual_reform_multby20", SUFFIX, ".pdf")

# Pure reform cumulative ×20
if (PURE_REFORM_AVAILABLE && exists("out_L")) {
  out_L_x20 <- copy(out_L)
  # ×20 shown in R$ BILLIONS: out_L is in millions, so * MULT / 1e3 -> billions
  out_L_x20[, `:=`(ME_L_cum = ME_L_cum * MULT / 1e3,
                    TC_L_cum = TC_L_cum * MULT / 1e3,
                    WE_L_cum = WE_L_cum * MULT / 1e3)]
  p_pure_L_x20 <- ggplot(out_L_x20, aes(x = quarter)) +
    geom_line(aes(y = ME_L_cum, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = TC_L_cum, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = WE_L_cum, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = ME_L_cum, color = factor(1)), shape = 17) +
    geom_point(aes(y = TC_L_cum, color = factor(2)), shape = 17) +
    geom_point(aes(y = WE_L_cum, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' B')) +
    wmvpf_color_scale +
    guides(color = guide_legend(nrow = 1, order = 1)) +
    theme_wmvpf +
    theme(legend.position = 'bottom',
          legend.direction = 'horizontal',
          legend.justification = 'center',
          legend.background = element_blank()) +
    xlab('Quarter') + ylab(NULL) +
    ggtitle(paste0('Pure Level: WMVPF_bL = ', round(wmvpf_bL_cum, 3)))

  ggsave(p_pure_L_x20,
         filename = paste0('output/I/I6_plot_pure_L_reform_multby20', SUFFIX, '.pdf'),
         height = 3.8, width = 5)
  message("Saved: output/I/I6_plot_pure_L_reform_multby20", SUFFIX, ".pdf")
}

if (PURE_REFORM_AVAILABLE && exists("out_S")) {
  out_S_x20 <- copy(out_S)
  # ×20 shown in R$ BILLIONS: out_S is in millions, so * MULT / 1e3 -> billions
  out_S_x20[, `:=`(ME_S_cum = ME_S_cum * MULT / 1e3,
                    TC_S_cum = TC_S_cum * MULT / 1e3,
                    WE_S_cum = WE_S_cum * MULT / 1e3)]
  p_pure_S_x20 <- ggplot(out_S_x20, aes(x = quarter)) +
    geom_line(aes(y = ME_S_cum, color = factor(1)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = TC_S_cum, color = factor(2)), linetype = 'solid', linewidth = 0.4) +
    geom_line(aes(y = WE_S_cum, color = factor(3)), linetype = 'longdash', linewidth = 0.4) +
    geom_point(aes(y = ME_S_cum, color = factor(1)), shape = 17) +
    geom_point(aes(y = TC_S_cum, color = factor(2)), shape = 17) +
    geom_point(aes(y = WE_S_cum, color = factor(3)), shape = 17) +
    scale_x_continuous(breaks = seq(2015, 2019, 1),
                       minor_breaks = seq(2015, 2019.25, 0.25),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' B')) +
    wmvpf_color_scale +
    guides(color = guide_legend(nrow = 1, order = 1)) +
    theme_wmvpf +
    theme(legend.position = 'bottom',
          legend.direction = 'horizontal',
          legend.justification = 'center',
          legend.background = element_blank()) +
    xlab('Quarter') + ylab(NULL) +
    ggtitle(paste0('Pure Slope: WMVPF_bS = ', round(wmvpf_bS_cum, 3)))

  ggsave(p_pure_S_x20,
         filename = paste0('output/I/I6_plot_pure_S_reform_multby20', SUFFIX, '.pdf'),
         height = 3.8, width = 5)
  message("Saved: output/I/I6_plot_pure_S_reform_multby20", SUFFIX, ".pdf")
}

# --- Final summary -----------------------------------------------------------

message("\n=== I6 complete ===")
message("WMVPF actual = ", round(wmvpf_actual, 4))
if (!is.na(wmvpf_bL)) {
  message("WMVPF_bL (cumulative) = ", round(wmvpf_bL, 4))
  if (exists("wmvpf_bL_T")) message("WMVPF_bL (per-qtr T)  = ", round(wmvpf_bL_T, 4))
}
if (!is.na(wmvpf_bS)) {
  message("WMVPF_bS (cumulative) = ", round(wmvpf_bS, 4))
  if (exists("wmvpf_bS_T")) message("WMVPF_bS (per-qtr T)  = ", round(wmvpf_bS_T, 4))
}
if (!is.na(wmvpf_bL) && !is.na(wmvpf_bS)) {
  message("bS > bL (cum)?  = ", wmvpf_bS > wmvpf_bL)
}
