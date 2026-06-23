# =============================================================================
# constants.R — Pension Reform Parameters (Single Source of Truth)
# =============================================================================
#
# Purpose: Centralize all magic numbers used across the pipeline.
# Source:  Canonical deck "Retirement_Presentations (old strat reverted).pdf"
#
# Usage:   source("constants.R")  # at the top of each pipeline script
#
# NOTE (Phase 2, 2026-05-11): This file is created as a reference. Integration
# into individual scripts (replacing hardcoded values with these constants) will
# happen incrementally in Phase 4 when scripts can be tested on the remote PC.
# Until then, each canonical script still has its own hardcoded values.
#
# When integrating:
#   1. Add source("constants.R") after library() calls
#   2. Replace hardcoded values with constant names
#   3. Run script on sample data to verify no change in outputs
#   4. Do NOT replace values in axis labels or plot annotations
# =============================================================================

# --- Eligibility Thresholds (Slide 12/56) ---
# Points-based eligibility: age + years of contribution
P_BAR_WOMEN <- 85L
P_BAR_MEN   <- 95L

# --- Replacement Rate Formulas (Slide 10/56) ---
# RR = intercept + slope * points_norm (for points >= p_bar)
RR_INTERCEPT_WOMEN <- 0.69
RR_SLOPE_WOMEN     <- 0.021
RR_INTERCEPT_MEN   <- 0.82
RR_SLOPE_MEN       <- 0.025

# --- Reform Parameters (Slide 12/56) ---
# Lei 13.183/2015: enacted 2015-11-04, effective retroactively
REFORM_YEAR_FRAC <- 2015 + 5/12   # ~2015.417 (used in dist_reform calculations)

# --- WMVPF Parameters (Slides 38/56, 18/56) ---
GAMMA_BASELINE <- 4     # CRRA coefficient for welfare weights
BUNCHING_W     <- 4L    # Bunching window width in points
DID_REF        <- -2L   # DiD reference point (2 points below threshold)

# --- Discount Factor (used in I4 line 235) ---
# Per-quarter discount factor: 0.995 per quarter ~ 2% annual
# NOTE: Verify against canonical deck — some formulas may use different rates
DISCOUNT_FACTOR_QUARTERLY <- 0.995

# --- Derived Constants ---
# Reform change in slope (delta_bS) computed from sex-weighted average
# delta_bS = share_women * RR_SLOPE_WOMEN + share_men * RR_SLOPE_MEN
# (shares computed from data, not hardcoded here)

# --- Where These Constants Appear (canonical files) ---
#
# D4_create_panel.R:
#   Line 374: points_norm := ifelse(male==0, points_d - 85, points_d - 95)
#
# G5_effect_average_benefit_freq_bL_and_bS.R:
#   Line 76:  points_norm := ifelse(male==0, points_d - 85, points_d - 95)
#   Line 312: replacement_rate := 0.69 + (0.021 * points_norm)  [women]
#   Line 313: replacement_rate := 0.82 + (0.025 * points_norm)  [men]
#   Line 319: benefits_bL formula uses (1 - 0.82) / replacement_rate  [men]
#   Line 320: benefits_bL formula uses (1 - 0.69) / replacement_rate  [women]
#   Line 327: RR_pbar := fifelse(male==1, 0.82, 0.69)
#   Line 335: delta_bS := shares * 0.021 + shares * 0.025
#   Lines 702, 707: gamma = 4
#
# I4_wmvpf_no_pure_reforms_freq.R:
#   Lines 32, 132: points_norm := ifelse(male==0, points_d - 85, points_d - 95)
#   Line 211: gamma = 4
#   Line 235: 0.995^(3*dist_reform) — quarterly discount factor
#
# new_counterfactual_claiming3_pure.R:
#   (Uses 85/95 thresholds — verify exact lines in Phase 4)
