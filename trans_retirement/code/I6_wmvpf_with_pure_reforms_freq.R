# ******************************************************************************
# I6_wmvpf_with_pure_reforms_freq.R
#
# WMVPF Estimation: Actual Reform + Pure Reform Decomposition (bL/bS)
# Uses frequencies (not densities) — canonical approach post-strategy reversion.
#
# Combines:
#   - I4's actual reform WMVPF computation
#   - Pure reform WMVPF_bL / WMVPF_bS (adapted from I5, using G5 outputs)
#
# Inputs:
#   - working/D3_cross_section.csv.gz   (cross-section from D3)
#   - working/D2_panel.csv.gz           (panel from D2)
#   - output/F/new_counterfactual_claim_counts.csv              (actual reform)
#   - output/G/G5_table_results_contrafactual_reforms_and_benefits_freq.csv
#                                   (pure reform benefits + frequencies from G5)
#   - output/G/G5_table_results_selection.csv   (selection correction from G5)
#   - output/H/H3_table_results.csv             (tax elasticity from H3)
#   - extra/Expectativa_Vida_IBGE.xlsx          (life expectancy tables)
#
# Outputs:
#   - output/I/I6_wmvpf_actual.csv
#   - output/I/I6_wmvpf_pure_L.csv
#   - output/I/I6_wmvpf_pure_S.csv
#   - output/I/I6_summary.csv
#   - output/I/I6_plot_actual_reform.pdf
#   - output/I/I6_plot_pure_L_reform.pdf
#   - output/I/I6_plot_pure_S_reform.pdf
#
# References:
#   - Canonical deck: Retirement_Presentations (old strat reverted).pdf
#   - Slides 37-41/56 (WMVPF framework)
#   - Slides 46-52/56 (Pure reforms decomposition)
#   - Appendix slides 22-25/57 (Pure L/S counterfactual frequencies)
#
# ******************************************************************************

# --- Setup -------------------------------------------------------------------

pkgs <- c('scales', 'zoo', 'readxl', 'fixest', 'tidyr', 'stringr',
          'data.table', 'dplyr', 'lubridate', 'haven', 'ggplot2',
          'grid', 'RColorBrewer', 'ggpubr')

# NOTE: On restricted-access server, uncomment: .libPaths('F:/docs/R-library')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- Constants (slide references in comments) --------------------------------
# See also: trans_retirement/code/constants.R

P_BAR_WOMEN        <- 85L                  # Slide 12/56
P_BAR_MEN          <- 95L                  # Slide 12/56
GAMMA_BASELINE     <- 4L                   # Slide 38/56: CRRA coefficient
CONS_INSS          <- 1536.4               # Avg consumption of INSS beneficiaries
CONS_POP           <- 1473.1               # Avg consumption of general population
R_ANNUAL           <- 0.06                 # Annual discount rate for PDV
DISCOUNT_Q         <- 0.995                # Per-period discount factor (Slide 41/56)
REFORM_QUARTER     <- 2015.25              # Q2 2015 = reform effective quarter
MAX_HORIZON        <- 12L                  # Quarters post-reform to analyze (0:12)

# Derived
R_Q <- (1 + R_ANNUAL)^(1/4) - 1           # Quarterly discount rate for annuity
ETA <- 1 - GAMMA_BASELINE * (CONS_INSS - CONS_POP) / CONS_POP  # Welfare weight (~0.828)

# --- Directory ---------------------------------------------------------------
# NOTE: On restricted-access server, set to the server path.
# On local machine with sample data, set to sample data location.

# Detect environment: server (F:/) vs local sample
# NOTE: On the server, the root has working/, output/, extra/ as subdirectories.
# On local sample, transfer_may_retirement/ mirrors this with data/, output/.
if (dir.exists("F:/Users/tucalins/Documents/transf_11_11/directory_2025")) {
  dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"
  DATA_MODE <- "full"
} else if (dir.exists("C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")) {
  dir <- "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement"
  DATA_MODE <- "sample"
} else {
  stop("No data directory found. Set 'dir' manually.")
}

message("I6: Data mode = ", DATA_MODE, " | dir = ", dir)
setwd(dir)

set.seed(20260511L)

# Create output directories
dir.create('output/I', recursive = TRUE, showWarnings = FALSE)

# ******************************************************************************
#
#                        PART 1: ACTUAL REFORM WMVPF
#
# ******************************************************************************
# Follows I4/I5 approach: cell-level flows using panel + counterfactual counts.
# Key formula (Slide 37/56):
#   WMVPF = sum_t [ beta^t * eta * (b'(x) - b(x)) ] / sum_t [ r^t * (b'(x') - b(x)) ]
# ******************************************************************************

message("=== PART 1: Actual Reform WMVPF ===")

# --- Load Data ---------------------------------------------------------------

if (DATA_MODE == "sample") {
  # Sample data has pre-computed panel with all needed variables
  # Sample CSVs live in data/ subdirectory of the sample root
  dt_cs <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv'))
  panel  <- fread(file.path(dir, 'data', 'panel_sampled_anon.csv'))
  message("Loaded sample data: ", nrow(dt_cs), " cross-section obs, ",
          nrow(panel), " panel obs")
} else {
  # Full data: load and compute PDV variables (same as I4 lines 29-136)
  dt_cs <- fread('working/D3_cross_section.csv.gz')
  panel  <- fread('working/D2_panel.csv.gz')

  # --- Life expectancy merge (for PDV) ---
  expectativa <- read_excel(file.path(dir, 'extra/Expectativa_Vida_IBGE.xlsx')) %>%
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

  # --- Panel benefit construction ---
  panel[, 'benefits' := NULL]
  # NOTE: Full data uses 'indiv' as identifier; sample uses 'cpf_anon'
  id_var <- if ("indiv" %in% names(dt_cs)) "indiv" else "cpf_anon"
  panel <- left_join(panel,
                     dt_cs[, .SD, .SDcols = c(id_var, 'benef_size','expec_ibge','fp_est','points_norm')],
                     by = id_var)

  # Benefits under new schedule
  panel[d_claim_post_reform == 1, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm < 0, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est < 1, benefits_new_claim := benef_size / fp_est]

  # Benefits under old schedule
  panel[d_claim_post_reform == 0, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm < 0, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est < 1, benefits_old_claim := benef_size * fp_est]

  # Quarterly annuity factor
  panel[, quarters_remaining_at_claim := pmax(round(4 * expec_ibge), 0L)]
  panel[, quarters_elapsed := pmax(dist_claim, 0L)]
  panel[, quarters_remaining_of_life := pmax(quarters_remaining_at_claim - quarters_elapsed, 0L)]
  panel[, ann_factor_q := fifelse(
    quarters_remaining_of_life >= 0L,
    (1 - (1 + R_Q)^(-quarters_remaining_of_life)) / R_Q,
    0
  )]

  # PV of benefits (monthly -> quarterly: *3)
  panel[, benefits := fifelse(dist_claim >= 0L, 3 * benef_size * ann_factor_q, 0)]
  panel[, benefits_old_pv := fifelse(dist_claim >= 0L, 3 * benefits_old_claim * ann_factor_q, 0)]
  panel[, benefits_new_pv := fifelse(dist_claim >= 0L, 3 * benefits_new_claim * ann_factor_q, 0)]

  # Normalized points and reform distance for panel
  panel[, points_d := floor(points_quarter)]
  panel[, points_norm := ifelse(male == 0L, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  panel[, dist_reform := 4 * (year_quarter - REFORM_QUARTER)]
}

# Ensure cross-section has normalized points and dist_reform
if (!"points_norm" %in% names(dt_cs)) {
  dt_cs[, points_d := floor(points_claim)]
  dt_cs[, points_norm := ifelse(male == 0L, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
}
if (!"dist_reform" %in% names(dt_cs)) {
  dt_cs[, dist_reform := 4 * (claim_quarter - REFORM_QUARTER)]
}

gc()

message("Panel dimensions: ", nrow(panel), " x ", ncol(panel))
message("Cross-section dimensions: ", nrow(dt_cs), " x ", ncol(dt_cs))

# --- Cell-level flows for actual reform (I5 approach, lines 164-197) ---------

# Aggregate panel to (dist_reform, points_norm) cells
dt_actual_cells <- panel[
  dist_reform %in% 0:MAX_HORIZON,
  .(
    N_a            = .N,
    avg_benefits_old_pv = mean(benefits_old_pv, na.rm = TRUE),
    avg_benefits_new_pv = mean(benefits_new_pv, na.rm = TRUE)
  ),
  by = .(dist_reform, points_norm)
]

message("After cell aggregation: ", nrow(dt_actual_cells), " cells")

# Load counterfactual claiming counts (actual reform)
cf_counts <- fread('output/F/new_counterfactual_claim_counts.csv')
setnames(cf_counts, c("t", "p"), c("dist_reform", "points_norm"), skip_absent = TRUE)

# Merge counterfactual counts into cell data
dt_actual_cells <- merge(
  dt_actual_cells,
  cf_counts[dist_reform %in% 0:MAX_HORIZON, .(dist_reform, points_norm, claims_c, claims)],
  by = c("dist_reform", "points_norm"),
  all = TRUE
)

# Cell-level expenditure flows (Slide 37/56)
# CNTRF = N^c * b_old(x)     — counterfactual outlays (no reform)
# MECH  = N^c * b_new(x)     — mechanical (new schedule, old choices)
# BEHAV = N^a * b_new(x')    — behavioral (new schedule, new choices)
dt_actual_cells[, E_CNTRF := claims_c * avg_benefits_old_pv]
dt_actual_cells[, E_MECH  := claims_c * avg_benefits_new_pv]
dt_actual_cells[, E_BEHAV := N_a * avg_benefits_new_pv]

# Aggregate to quarterly flows (only for p >= 0, above threshold)
CNTRF_by_qtr <- dt_actual_cells[
  dist_reform %in% 0:MAX_HORIZON & points_norm >= 0,
  .(CNTRF_t = sum(E_CNTRF, na.rm = TRUE)),
  by = dist_reform
][order(dist_reform)]

MECH_by_qtr <- dt_actual_cells[
  dist_reform %in% 0:MAX_HORIZON & points_norm >= 0,
  .(MECH_t = sum(E_MECH, na.rm = TRUE)),
  by = dist_reform
][order(dist_reform)]

BEHAV_by_qtr <- dt_actual_cells[
  dist_reform %in% 0:MAX_HORIZON & points_norm >= 0,
  .(BEHAV_t = sum(E_BEHAV, na.rm = TRUE)),
  by = dist_reform
][order(dist_reform)]

# Merge all flows
dt_flows_actual <- merge(CNTRF_by_qtr, MECH_by_qtr, by = "dist_reform", all = TRUE) %>%
  merge(BEHAV_by_qtr, by = "dist_reform", all = TRUE)

# --- WMVPF computation (Slide 37-41/56) --------------------------------------

# Discount factors
# Cost: (1/beta)^(3*t) — matches I4 convention (costs grow at interest rate)
# Welfare: beta^(3*t) — social discount factor
# NOTE: I4 uses literal 1.005^3 for cost; here we use 1/DISCOUNT_Q = 1/0.995
# for internal consistency. Difference is ~0.06% (see [LEARN:i4-discount]).
dt_flows_actual[, discount_cost    := (1 / DISCOUNT_Q)^(3 * dist_reform)]
dt_flows_actual[, discount_welfare := DISCOUNT_Q^(3 * dist_reform)]

# Net cost = b'(x') - b(x) = BEHAV - CNTRF, discounted
dt_flows_actual[, net_cost := (BEHAV_t - CNTRF_t) * discount_cost]

# Mechanical effect = b'(x) - b(x) = MECH - CNTRF, discounted
dt_flows_actual[, mech_cost := (MECH_t - CNTRF_t) * discount_cost]

# Fiscal externality = b'(x') - b'(x) = BEHAV - MECH, discounted
dt_flows_actual[, fiscal_ext := (BEHAV_t - MECH_t) * discount_cost]

# Welfare = beta^t * eta * ME_t (Slide 41/56)
dt_flows_actual[, welfare := discount_welfare * ETA * (MECH_t - CNTRF_t)]

# WMVPF = sum(welfare) / sum(net_cost)
wmvpf_actual <- sum(dt_flows_actual$welfare, na.rm = TRUE) /
                sum(dt_flows_actual$net_cost, na.rm = TRUE)

message("WMVPF (actual reform) = ", round(wmvpf_actual, 4))

# --- Output table for actual reform ------------------------------------------

out_actual <- dt_flows_actual[, .(
  dist_reform = REFORM_QUARTER + dist_reform / 4,
  CNTRF_t, MECH_t, BEHAV_t,
  ME_t = MECH_t - CNTRF_t,
  net_cost_t = BEHAV_t - CNTRF_t,
  FE_t = BEHAV_t - MECH_t,
  net_cost, mech_cost, fiscal_ext, welfare
)]

out_actual[, (names(out_actual)[names(out_actual) != 'dist_reform']) :=
  lapply(.SD, function(x) round(x / 1e6, 2)),
  .SDcols = names(out_actual)[names(out_actual) != 'dist_reform']
]

# --- Plot: Actual reform components ------------------------------------------

p_actual <- ggplot(out_actual, aes(x = dist_reform)) +
  geom_line(aes(y = mech_cost, color = 'Mechanical Effect'), linewidth = 0.4) +
  geom_line(aes(y = net_cost, color = 'Total Cost'), linewidth = 0.4) +
  geom_line(aes(y = welfare, color = 'Welfare Effect'), linetype = 'longdash', linewidth = 0.4) +
  geom_point(aes(y = mech_cost, color = 'Mechanical Effect'), shape = 17) +
  geom_point(aes(y = net_cost, color = 'Total Cost'), shape = 17) +
  geom_point(aes(y = welfare, color = 'Welfare Effect'), shape = 17) +
  scale_x_continuous(breaks = seq(2015, 2019, 1),
                     minor_breaks = seq(2015, 2019.25, 0.25)) +
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
  scale_color_brewer(palette = 'Set1') +
  theme_classic() +
  theme(legend.position = 'bottom', text = element_text(family = 'serif')) +
  labs(x = 'Quarter', y = NULL, color = NULL,
       title = paste0('WMVPF = ', round(wmvpf_actual, 3)))

# ******************************************************************************
#
#                        PART 2: PURE REFORM WMVPF
#
# ******************************************************************************
# Decomposes the actual reform into Pure Level (bL) and Pure Slope (bS).
#
# Requires G5 output: cell-level pure reform expenditure flows.
# The counterfactual frequencies under pure reforms come from F-stage:
#   output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv
#   (columns: claims_L = N^L, claims_S = N^S, claims_c = N^c)
#
# Key formulas (Slides 46-52/56):
#   WMVPF_bL = sum_t [ beta^t * eta * ME_L_t ] / sum_t [ r^t * TC_L_t ]
#   WMVPF_bS = sum_t [ beta^t * eta * ME_S_t ] / sum_t [ r^t * TC_S_t ]
#
# where:
#   ME_L_t  = MECH_L_t - CNTRF_t   (mechanical effect of Pure Level)
#   TC_L_t  = BEHAV_L_t - CNTRF_t  (total cost of Pure Level)
#   analogously for S
# ******************************************************************************

message("\n=== PART 2: Pure Reform WMVPF (bL/bS decomposition) ===")

# --- Load G5 output (single source for frequencies + benefits) ---------------
# G5 output already includes F-stage frequency columns (claims_L, claims_S,
# claims_c) merged with G5's benefit estimates. Loading it as a single source
# avoids duplicate-column issues from merging two files with overlapping keys.
#
# File: output/G/G5_table_results_contrafactual_reforms_and_benefits_freq.csv

g5_pure_path <- 'output/G/G5_table_results_contrafactual_reforms_and_benefits_freq.csv'

if (!file.exists(g5_pure_path)) {
  message("WARNING: G5 pure reform output not found at: ", g5_pure_path)
  message("This file is produced by G5's Steps 1-3. Run G5 successfully first.")
  PURE_REFORM_AVAILABLE <- FALSE
} else {
  PURE_REFORM_AVAILABLE <- TRUE
}

if (PURE_REFORM_AVAILABLE) {
  dt_pure_cells <- fread(g5_pure_path)
  message("Loaded G5 pure reform data: ", nrow(dt_pure_cells), " rows")

  # --- Compute cell-level pure reform flows ----------------------------------
  # G5 output contains per-cell:
  #   claims_L, claims_S, claims_c       (from F-stage, merged by G5)
  #   avg_reform_benefits_pre_reform_choices_bL/bS  (mechanical benefits)
  #   avg_post_pure_reform_benefits_bL/bS           (behavioral benefits)

  g5_cols <- names(dt_pure_cells)
  message("G5 columns: ", paste(head(g5_cols, 20), collapse = ", "))

  # Filter to analysis horizon
  dt_pure_cells <- dt_pure_cells[dist_reform %in% 0:MAX_HORIZON]

  # Merge the counterfactual (pre-reform) average benefits from actual cells
  dt_pure_cells <- merge(
    dt_pure_cells,
    dt_actual_cells[, .(dist_reform, points_norm, avg_benefits_old_pv)],
    by = c("dist_reform", "points_norm"),
    all.x = TRUE
  )

  # --- Cell-level expenditure flows for Pure Level ---
  # CNTRF_L  = N^c * avg_b_old       (same counterfactual as actual reform)
  # MECH_L   = N^L * avg_b_bL_pre    (Pure L schedule, counterfactual choices)
  # BEHAV_L  = N^L * avg_b_bL_post   (Pure L schedule, actual choices)

  has_mech_bL <- "avg_reform_benefits_pre_reform_choices_bL" %in% g5_cols
  has_behav_bL <- "avg_post_pure_reform_benefits_bL" %in% g5_cols

  if (has_mech_bL) {
    dt_pure_cells[, E_MECH_L := claims_L * avg_reform_benefits_pre_reform_choices_bL]
  }
  if (has_behav_bL) {
    dt_pure_cells[, E_BEHAV_L := claims_L * avg_post_pure_reform_benefits_bL]
  } else if (has_mech_bL) {
    # If behavioral not available (G5 Step 4+ failed), use mechanical as proxy
    message("NOTE: G5 behavioral benefits (bL) not available. Using mechanical as proxy.")
    dt_pure_cells[, E_BEHAV_L := claims_L * avg_reform_benefits_pre_reform_choices_bL]
  }

  # Counterfactual outlays (same for both L and S)
  dt_pure_cells[, E_CNTRF := claims_c * avg_benefits_old_pv]

  # --- Cell-level flows for Pure Slope ---
  has_mech_bS <- "avg_reform_benefits_pre_reform_choices_bS" %in% g5_cols
  has_behav_bS <- "avg_post_pure_reform_benefits_bS" %in% g5_cols

  if (has_mech_bS) {
    dt_pure_cells[, E_MECH_S := claims_S * avg_reform_benefits_pre_reform_choices_bS]
  }
  if (has_behav_bS) {
    dt_pure_cells[, E_BEHAV_S := claims_S * avg_post_pure_reform_benefits_bS]
  } else if (has_mech_bS) {
    message("NOTE: G5 behavioral benefits (bS) not available. Using mechanical as proxy.")
    dt_pure_cells[, E_BEHAV_S := claims_S * avg_reform_benefits_pre_reform_choices_bS]
  }

  # --- Aggregate to quarterly flows ------------------------------------------

  # Pure Level quarterly flows
  if ("E_MECH_L" %in% names(dt_pure_cells)) {
    flows_L <- dt_pure_cells[
      dist_reform %in% 0:MAX_HORIZON & points_norm >= 0,
      .(CNTRF_t = sum(E_CNTRF, na.rm = TRUE),
        MECH_L_t = sum(E_MECH_L, na.rm = TRUE),
        BEHAV_L_t = sum(E_BEHAV_L, na.rm = TRUE)),
      by = dist_reform
    ][order(dist_reform)]

    # Discount and compute WMVPF components
    flows_L[, discount_cost    := (1 / DISCOUNT_Q)^(3 * dist_reform)]
    flows_L[, discount_welfare := DISCOUNT_Q^(3 * dist_reform)]

    flows_L[, net_cost_L  := (BEHAV_L_t - CNTRF_t) * discount_cost]
    flows_L[, mech_cost_L := (MECH_L_t - CNTRF_t) * discount_cost]
    flows_L[, fiscal_ext_L := (BEHAV_L_t - MECH_L_t) * discount_cost]
    flows_L[, welfare_L   := discount_welfare * ETA * (MECH_L_t - CNTRF_t)]

    wmvpf_bL <- sum(flows_L$welfare_L, na.rm = TRUE) /
                sum(flows_L$net_cost_L, na.rm = TRUE)
    message("WMVPF_bL (Pure Level) = ", round(wmvpf_bL, 4))
  } else {
    message("WARNING: Could not compute WMVPF_bL — missing G5 bL benefit data.")
    wmvpf_bL <- NA_real_
  }

  # Pure Slope quarterly flows
  if ("E_MECH_S" %in% names(dt_pure_cells)) {
    flows_S <- dt_pure_cells[
      dist_reform %in% 0:MAX_HORIZON & points_norm >= 0,
      .(CNTRF_t = sum(E_CNTRF, na.rm = TRUE),
        MECH_S_t = sum(E_MECH_S, na.rm = TRUE),
        BEHAV_S_t = sum(E_BEHAV_S, na.rm = TRUE)),
      by = dist_reform
    ][order(dist_reform)]

    flows_S[, discount_cost    := (1 / DISCOUNT_Q)^(3 * dist_reform)]
    flows_S[, discount_welfare := DISCOUNT_Q^(3 * dist_reform)]

    flows_S[, net_cost_S  := (BEHAV_S_t - CNTRF_t) * discount_cost]
    flows_S[, mech_cost_S := (MECH_S_t - CNTRF_t) * discount_cost]
    flows_S[, fiscal_ext_S := (BEHAV_S_t - MECH_S_t) * discount_cost]
    flows_S[, welfare_S   := discount_welfare * ETA * (MECH_S_t - CNTRF_t)]

    wmvpf_bS <- sum(flows_S$welfare_S, na.rm = TRUE) /
                sum(flows_S$net_cost_S, na.rm = TRUE)
    message("WMVPF_bS (Pure Slope) = ", round(wmvpf_bS, 4))
  } else {
    message("WARNING: Could not compute WMVPF_bS — missing G5 bS benefit data.")
    wmvpf_bS <- NA_real_
  }

  # --- Output tables for pure reforms ----------------------------------------

  if (exists("flows_L")) {
    out_L <- flows_L[, .(
      dist_reform = REFORM_QUARTER + dist_reform / 4,
      CNTRF_t, MECH_L_t, BEHAV_L_t,
      net_cost_L, mech_cost_L, fiscal_ext_L, welfare_L
    )]
    out_L[, (names(out_L)[names(out_L) != 'dist_reform']) :=
      lapply(.SD, function(x) round(x / 1e6, 2)),
      .SDcols = names(out_L)[names(out_L) != 'dist_reform']
    ]
  }

  if (exists("flows_S")) {
    out_S <- flows_S[, .(
      dist_reform = REFORM_QUARTER + dist_reform / 4,
      CNTRF_t, MECH_S_t, BEHAV_S_t,
      net_cost_S, mech_cost_S, fiscal_ext_S, welfare_S
    )]
    out_S[, (names(out_S)[names(out_S) != 'dist_reform']) :=
      lapply(.SD, function(x) round(x / 1e6, 2)),
      .SDcols = names(out_S)[names(out_S) != 'dist_reform']
    ]
  }

  # --- Plots for pure reforms ------------------------------------------------

  if (exists("out_L")) {
    p_pure_L <- ggplot(out_L, aes(x = dist_reform)) +
      geom_line(aes(y = mech_cost_L, color = 'Mechanical Effect'), linewidth = 0.4) +
      geom_line(aes(y = net_cost_L, color = 'Total Cost'), linewidth = 0.4) +
      geom_line(aes(y = welfare_L, color = 'Welfare Effect'), linetype = 'longdash', linewidth = 0.4) +
      geom_point(aes(y = mech_cost_L, color = 'Mechanical Effect'), shape = 17) +
      geom_point(aes(y = net_cost_L, color = 'Total Cost'), shape = 17) +
      geom_point(aes(y = welfare_L, color = 'Welfare Effect'), shape = 17) +
      scale_x_continuous(breaks = seq(2015, 2019, 1)) +
      scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
      scale_color_brewer(palette = 'Set1') +
      theme_classic() +
      theme(legend.position = 'bottom', text = element_text(family = 'serif')) +
      labs(x = 'Quarter', y = NULL, color = NULL,
           title = paste0('Pure Level Reform: WMVPF_bL = ', round(wmvpf_bL, 3)))
  }

  if (exists("out_S")) {
    p_pure_S <- ggplot(out_S, aes(x = dist_reform)) +
      geom_line(aes(y = mech_cost_S, color = 'Mechanical Effect'), linewidth = 0.4) +
      geom_line(aes(y = net_cost_S, color = 'Total Cost'), linewidth = 0.4) +
      geom_line(aes(y = welfare_S, color = 'Welfare Effect'), linetype = 'longdash', linewidth = 0.4) +
      geom_point(aes(y = mech_cost_S, color = 'Mechanical Effect'), shape = 17) +
      geom_point(aes(y = net_cost_S, color = 'Total Cost'), shape = 17) +
      geom_point(aes(y = welfare_S, color = 'Welfare Effect'), shape = 17) +
      scale_x_continuous(breaks = seq(2015, 2019, 1)) +
      scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M')) +
      scale_color_brewer(palette = 'Set1') +
      theme_classic() +
      theme(legend.position = 'bottom', text = element_text(family = 'serif')) +
      labs(x = 'Quarter', y = NULL, color = NULL,
           title = paste0('Pure Slope Reform: WMVPF_bS = ', round(wmvpf_bS, 3)))
  }

} else {
  wmvpf_bL <- NA_real_
  wmvpf_bS <- NA_real_
  message("Pure reform section skipped — missing upstream data.")
}

# ******************************************************************************
#
#                     PART 3: SUMMARY & BUDGET-NEUTRAL OPTIMUM
#
# ******************************************************************************
# The budget-neutral optimal reform direction follows from comparing
# WMVPF_bL vs WMVPF_bS (Slides 51-52/56):
#   If WMVPF_bS > WMVPF_bL => optimal reform increases slope, decreases level
# ******************************************************************************

message("\n=== PART 3: Summary ===")

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
    message("\n>>> WMVPF_bS > WMVPF_bL => Optimal direction: INCREASE slope (bS), DECREASE level (bL)")
    message(">>> The 2015 reform went in the OPPOSITE direction (increased bL, decreased bS)")
  } else {
    message("\n>>> WMVPF_bL >= WMVPF_bS => Optimal direction: INCREASE level (bL)")
  }
}

# ******************************************************************************
#
#                            SAVING OUTPUTS
#
# ******************************************************************************

message("\n=== Saving outputs ===")

fwrite(out_actual, file = 'output/I/I6_wmvpf_actual.csv')
message("Saved: output/I/I6_wmvpf_actual.csv")

if (PURE_REFORM_AVAILABLE && exists("out_L")) {
  fwrite(out_L, file = 'output/I/I6_wmvpf_pure_L.csv')
  message("Saved: output/I/I6_wmvpf_pure_L.csv")
}

if (PURE_REFORM_AVAILABLE && exists("out_S")) {
  fwrite(out_S, file = 'output/I/I6_wmvpf_pure_S.csv')
  message("Saved: output/I/I6_wmvpf_pure_S.csv")
}

fwrite(summary_dt, file = 'output/I/I6_summary.csv')
message("Saved: output/I/I6_summary.csv")

ggsave(p_actual, filename = 'output/I/I6_plot_actual_reform.pdf',
       height = 3, width = 5)
message("Saved: output/I/I6_plot_actual_reform.pdf")

if (PURE_REFORM_AVAILABLE && exists("p_pure_L")) {
  ggsave(p_pure_L, filename = 'output/I/I6_plot_pure_L_reform.pdf',
         height = 3, width = 5)
  message("Saved: output/I/I6_plot_pure_L_reform.pdf")
}

if (PURE_REFORM_AVAILABLE && exists("p_pure_S")) {
  ggsave(p_pure_S, filename = 'output/I/I6_plot_pure_S_reform.pdf',
         height = 3, width = 5)
  message("Saved: output/I/I6_plot_pure_S_reform.pdf")
}

message("\n=== I6 complete ===")
message("WMVPF actual = ", round(wmvpf_actual, 4))
if (!is.na(wmvpf_bL)) message("WMVPF_bL    = ", round(wmvpf_bL, 4))
if (!is.na(wmvpf_bS)) message("WMVPF_bS    = ", round(wmvpf_bS, 4))
