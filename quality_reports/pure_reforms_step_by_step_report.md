# Pure Reforms: Step-by-Step Report

**Date:** 2026-05-16  
**Branch:** claude/magical-borg-18ac72  
**Files audited:** G5_effect_average_benefit_freq_bL_and_bS.R, I6_wmvpf_with_pure_reforms_freq.R  
**Reference:** Retirement_Presentations (10).pdf, slide 134/144

---

## Overview

The pure reform decomposition splits the 2015 reform into two orthogonal components:
- **Pure Level (bL):** only the level shift (replacement rate jumps to 1 at p̄)
- **Pure Slope (bS):** only the slope change (slope goes to 0 at p̄)

Each produces its own WMVPF, enabling comparison: if WMVPF_bS > WMVPF_bL, the optimal local reform increases slope and decreases level.

The computation runs across two files:
- **G5** computes per-cell benefits, DDs, selection corrections, and behavioral/mechanical benefits
- **I6** assembles the WMVPF using G5's cell-level outputs

---

## STEP 1: Construct Pure Reform Benefit Schedules (G5, lines 334–356)

### Math

For each individual *i* at point *p*, compute benefits under each pure reform schedule using replacement rates:

**Pre-reform replacement rates** (linear approximation):
- Women: `RR_pre(p) = 0.69 + 0.021 × (p − p̄)`
- Men: `RR_pre(p) = 0.82 + 0.025 × (p − p̄)`

**Pure Level:** `RR_PL(p) = 1` for `p ≥ p̄` (full replacement), same slope as pre-reform below p̄.

```
b_L(x'_i) = b_new(x'_i) × (1 + (1 − RR_p̄) / RR_pre(p))    for p ≥ p̄
           = b_new(x'_i)                                       for p < p̄
```

**Pure Slope:** `RR_PS(p) = RR_p̄` for `p ≥ p̄` (flat at threshold intercept), so slope = 0.

```
b_S(x'_i) = b_new(x'_i) × (RR_p̄ / RR_pre(p))    for p ≥ p̄
           = b_new(x'_i)                             for p < p̄
```

### Code (G5, lines 334–356)

```r
# Replacement rates (pre-reform, linear approx)
dt[male==0, replacement_rate := 0.69 + (0.021*(points_norm))]
dt[male==1, replacement_rate := 0.82 + (0.025*(points_norm))]

# Pure Level benefits: b_L(x'_i)
dt[male==1, benefits_bL := fifelse(points_norm<0, pv_benefits_new,
    pv_benefits_new*(1+(1-0.82)/replacement_rate))]
dt[male==0, benefits_bL := fifelse(points_norm<0, pv_benefits_new,
    pv_benefits_new*(1+(1-0.69)/replacement_rate))]

# Pure Slope benefits: b_S(x'_i)
dt[male==1, benefits_bS := fifelse(points_norm<0, pv_benefits_new,
    pv_benefits_new*(0.82/replacement_rate))]
dt[male==0, benefits_bS := fifelse(points_norm<0, pv_benefits_new,
    pv_benefits_new*(0.69/replacement_rate))]
```

### Note

The formula uses a **ratio-based approach**: `b_L = b_new × (RR_PL / RR_pre)`. The `1/RR_pre` factor varies only by `points_norm`, so `points_norm` FEs in the DD absorb this variation.

---

## STEP 2: Aggregate and Run DDs on Average Benefits (G5, lines 380–434)

### Math (Slide 134/144 — Alternative Approach)

**Chosen method:** Run the DD with average benefit `b̄_L(x^a_{p,t})` as the dependent variable (not expenditure `E_{a,L}` directly):

```
b̄_L(x^a_{p,t}) ~ i(dist_reform, treat_g, ref=-2) | dist_reform + points_norm
```

This yields **β̂^L_{p,t}** = the selection effect on average benefits under Pure L, by group and quarter.

Same for Pure S:
```
b̄_S(x^a_{p,t}) ~ i(dist_reform, treat_g, ref=-2) | dist_reform + points_norm
```

yielding **β̂^S_{p,t}**.

### Code (G5, lines 380–434)

```r
# Aggregate to (points_norm, dist_reform) cells
dt_agg <- dt[, .(avg_benefits_bL = mean(benefits_bL, na.rm=TRUE),
                  avg_benefits_bS = mean(benefits_bS, na.rm=TRUE)),
             by = .(points_norm, dist_reform)]

# DD for Pure Level
models_bL <- list()
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  formula <- as.formula(paste0(
    'avg_benefits_bL ~ i(dist_reform, `treat_', g, '`, ref = -2)',
    ' | dist_reform + points_norm'))
  models_bL[[paste0('treat_bL_',g)]] <- feols(
    data = dt_agg[!is.na(get(paste0('treat_',g))) & dist_reform<=15],
    fml = formula, cluster = 'points_norm')
}

# DD for Pure Slope (same structure)
models_bS <- list()
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  formula <- as.formula(paste0(
    'avg_benefits_bS ~ i(dist_reform, `treat_', g, '`, ref = -2)',
    ' | dist_reform + points_norm'))
  models_bS[[paste0('treat_bS_',g)]] <- feols(
    data = dt_agg[!is.na(get(paste0('treat_',g))) & dist_reform<=15],
    fml = formula, cluster = 'points_norm')
}
```

---

## STEP 2b: Construct Counterfactual Benefits b̄(x^c) (G5, lines 583–588)

### Math

Per the slide 134/144 alternative:

```
b̄_L(x^c_{p,t}) = b̄_L(x^a_{p,t}) − β̂^L_{p,t}
```

This removes the selection effect from observed average benefits, yielding the counterfactual (no behavioral response) average benefit.

### Code (G5, lines 583–601)

```r
# Merge DD point estimates back to cell-level data
data_counterfactual_reforms_step_2 <- merge(
  rbind(dt_agg[dist_reform >= 0, .(points_norm, dist_reform, group,
               reform = 'bL', avg_benefits = avg_benefits_bL)],
        dt_agg[dist_reform >= 0, .(points_norm, dist_reform, group,
               reform = 'bS', avg_benefits = avg_benefits_bS)]),
  results_counterfactual[, .(group, dist_reform = claim_quarter,
                             reform, point_estimate)],
  by = c('group','dist_reform','reform'))

# b̄_L(x^c) = b̄_L(x^a) − β̂^L
data_counterfactual_reforms_step_2[,
  avg_reform_benefits_pre_reform_choices := avg_benefits - point_estimate]
```

---

## STEP 3: Mechanical Expenditure E^{c,L} (G5, lines 612–616)

### Math (Slide 134/144 Alternative — the core formula)

```
E^{c,L}_{t} = Σ_p  N^c_{p,t} × [b̄_L(x^a_{p,t}) − β̂^L_{p,t}]
```

Where `N^c` = counterfactual claims (no behavioral response) = `claims_c`.

**BUG FOUND AND FIXED:** G5 previously used `claims_L`/`claims_S` here instead of `claims_c`. Fixed to match the slide formula.

### Code (G5, lines 612–616 — AFTER FIX)

```r
MECH_by_qtr <- dt_merged[,
  .(MECH_L = sum(claims_c * avg_reform_benefits_pre_reform_choices_bL, na.rm=TRUE),
    MECH_S = sum(claims_c * avg_reform_benefits_pre_reform_choices_bS, na.rm=TRUE)),
  by = dist_reform]
```

### Code (I6, lines 424–427 and 471–474 — already correct)

```r
# Pure L mechanical
mech_L <- g5_data[,
  .(mech_L_t = sum(avg_reform_benefits_pre_reform_choices_bL * claims_c, na.rm=TRUE)),
  by = dist_reform]

# Pure S mechanical
mech_S <- g5_data[,
  .(mech_S_t = sum(avg_reform_benefits_pre_reform_choices_bS * claims_c, na.rm=TRUE)),
  by = dist_reform]
```

---

## STEP 4: Decompose Selection into Postponement and Anticipation (G5, lines 618–714)

### Math

The DD coefficient β̂^L captures the total selection effect. This decomposes into:

**Postponement component β̂^{L,P}_{p,t}:**

For each (p,t) cell with `p ≥ 0`, identify origin cells `(-x, t-2(x+p))` where postponers came from (for `x = 1, ..., x̄_{p,t}`):

```
x̄_{p,t} = min(6, (t+1)/2 − p)

P_{-x,t-2(x+p)} = N^c_{-x,t-2(x+p)} − N^a_{-x,t-2(x+p)}

β̂^{L,P}_{p,t} = − Σ_x [ P_{origin} × β̂^L_{origin} ] / Σ_x P_{origin}
```

**Anticipation component β̂^{L,A}_{p,t}:**

```
β̂^{L,A}_{p,t} = β̂^L_{p,t} − β̂^{L,P}_{p,t}
```

Same decomposition applies to Pure S: β̂^{S,P} and β̂^{S,A}.

### Code (G5, lines 628–696)

```r
# Step 4.1: compute x_bar per cell
dt_merged[, x_bar_tp := pmin(6, ((dist_reform+1)/2) - points_norm)]

# Step 4.2: expand to enumerate all postponement origins
dt_origin_of_pstpnmnt <- dt_merged[x_bar_tp >= 1,
  .(x = sequence(x_bar_tp)),
  by = .(points_norm, dist_reform)]
dt_origin_of_pstpnmnt[, origin_p := -x]
dt_origin_of_pstpnmnt[, origin_t := dist_reform - 2*(x + points_norm)]

# Step 4.3: lookup N^c, N^a, β̂^L, β̂^S at origin cells
dt_origin_lookup <- dt_merged[, .(
  origin_p = points_norm, origin_t = dist_reform,
  N_c = claims_c, N_a = claims,
  beta_L = point_estimate_bL, beta_S = point_estimate_bS)]
dt_origin_lookup[, P_tp := N_c - N_a]

# Step 4.4: compute β̂^{L,P} and β̂^{S,P}
dt_beta <- dt_beta %>% group_by(points_norm, dist_reform) %>%
  mutate(denom = sum(P_tp, na.rm=TRUE))
dt_beta <- dt_beta %>% group_by(points_norm, dist_reform) %>%
  mutate(Beta_LP = -sum(P_tp * beta_L, na.rm=TRUE) / denom)
dt_beta <- dt_beta %>% group_by(points_norm, dist_reform) %>%
  mutate(Beta_SP = -sum(P_tp * beta_S, na.rm=TRUE) / denom)

# Step 4.7: compute anticipation components
dt_merged_with_betas[, Beta_LA := point_estimate_bL - Beta_LP]
dt_merged_with_betas[, Beta_SA := point_estimate_bS - Beta_SP]
```

---

## STEP 4b: Average Post-Pure-Reform Benefits b̄_L(x^L) and b̄_S(x^S) (G5, lines 698–714)

### Math

These are the average benefits under each pure reform **accounting for behavioral responses** (selection-corrected by component):

**Pure Level:**
```
b̄_L(x^L_{p,t}) = b̄_L(x^a)                          for p < 0
                 = b̄_L(x^a) − β̂^{L,A}_{p,t}          for 0 ≤ p < 4  (anticipation correction)
                 = b̄_L(x^a) − β̂^L_{p,t}               for p ≥ 4      (full correction)
```

**Pure Slope:**
```
b̄_S(x^S_{p,t}) = b̄_S(x^a) − β̂^S_{p,t}              for p < 0
                 = b̄_S(x^a) − β̂^{S,P}_{p,t}          for p ≥ 0      (postponement correction only)
```

### Code (G5, lines 698–714)

```r
# Pure Level behavioral benefits
dt_merged_with_betas[, avg_post_pure_reform_benefits_bL :=
  fifelse(points_norm < 0,
    avg_benefits_bL,
    fifelse(points_norm >= 4,
      avg_benefits_bL - point_estimate_bL,
      avg_benefits_bL - Beta_LA))]

# Pure Slope behavioral benefits
dt_merged_with_betas[, avg_post_pure_reform_benefits_bS :=
  fifelse(points_norm < 0,
    avg_benefits_bS - point_estimate_bS,
    avg_benefits_bS - Beta_SP)]
```

---

## STEP 5: Behavioral Expenditure E^{a,L} and E^{a,S} (G5, lines 717–722)

### Math

Behavioral expenditure uses **reformed claims** (including behavioral responses):

```
E^{a,L}_t = Σ_p  N^L_{p,t} × b̄_L(x^L_{p,t})
E^{a,S}_t = Σ_p  N^S_{p,t} × b̄_S(x^S_{p,t})
```

Where `N^L`, `N^S` are the claiming distributions under each pure reform (from F-stage).

### Code (G5, lines 720–722)

```r
BEHAV_by_qtr <- dt_merged_with_betas[,
  .(BEHAV_L = sum(claims_L * avg_post_pure_reform_benefits_bL, na.rm=TRUE),
    BEHAV_S = sum(claims_S * avg_post_pure_reform_benefits_bS, na.rm=TRUE)),
  by = dist_reform]
```

---

## STEP 6: WMVPF Computation (I6, lines 415–510)

### Math

I6 assembles the WMVPF using the standard framework. For Pure Level:

```
b(x)_t       = Σ_p N^c_{p,t} × [b̄_old(x^a_{p,t}) − β̂^old_{p,t}]     (counterfactual, no reform)
b'_L(x)_t    = Σ_p N^c_{p,t} × [b̄_L(x^a_{p,t}) − β̂^L_{p,t}]         (mechanical, Pure L)
b'_L(x')_t   = Σ_p N^L_{p,t} × b̄_L(x^L_{p,t})                         (behavioral, Pure L)

ME_L_t = b'_L(x)_t − b(x)_t              (mechanical effect)
TC_L_t = b'_L(x')_t − b(x)_t             (total cost)
FE_L_t = b'_L(x')_t − b'_L(x)_t          (fiscal externality)

WE_L_t = η × ME_L_t                       where η = 1 − γ(c_INSS − c_pop)/c_pop

WMVPF_bL = Σ_t [δ^t × WE_L_t] / Σ_t [ρ^t × TC_L_t]
```

where δ = 0.995^3 (welfare discount) and ρ = 1/(1.005^3) (cost discount).

Same structure for Pure S, replacing L→S throughout.

### Code (I6, lines 424–510)

```r
# --- Pure Level ---

# Mechanical: b'_L(x) using claims_c
mech_L <- g5_data[,
  .(mech_L_t = sum(avg_reform_benefits_pre_reform_choices_bL * claims_c, na.rm=TRUE)),
  by = dist_reform][order(dist_reform)]
mech_L[, mech_L_cumsum := cumsum(mech_L_t)]

# Behavioral: b'_L(x') using claims_L
behav_L <- g5_data[,
  .(behav_L_t = sum(avg_post_pure_reform_benefits_bL * claims_L, na.rm=TRUE)),
  by = dist_reform][order(dist_reform)]
behav_L[, behav_L_cumsum := cumsum(behav_L_t)]

# Merge with b(x) baseline
dt_wmvpf_L <- merge(aux3[, .(dist_reform, counterfactual_benefits)],
                     mech_L[, .(dist_reform, mech_L_cumsum)], by = 'dist_reform') %>%
  merge(behav_L[, .(dist_reform, behav_L_cumsum)], by = 'dist_reform')

# WMVPF components
dt_wmvpf_L[, net_cost_L  := (behav_L_cumsum - counterfactual_benefits) / ((1.005^3)^dist_reform)]
dt_wmvpf_L[, mech_cost_L := (mech_L_cumsum - counterfactual_benefits) / ((1.005^3)^dist_reform)]
dt_wmvpf_L[, welfare_L   := (0.995^(3*dist_reform)) *
  (1 - GAMMA_BASELINE*(CONS_INSS - CONS_POP)/CONS_POP) *
  (mech_L_cumsum - counterfactual_benefits)]

wmvpf_bL <- sum(dt_wmvpf_L$welfare_L) / sum(dt_wmvpf_L$net_cost_L)
```

```r
# --- Pure Slope --- (same structure, replacing L → S)

mech_S <- g5_data[,
  .(mech_S_t = sum(avg_reform_benefits_pre_reform_choices_bS * claims_c, na.rm=TRUE)),
  by = dist_reform][order(dist_reform)]
mech_S[, mech_S_cumsum := cumsum(mech_S_t)]

behav_S <- g5_data[,
  .(behav_S_t = sum(avg_post_pure_reform_benefits_bS * claims_S, na.rm=TRUE)),
  by = dist_reform][order(dist_reform)]
behav_S[, behav_S_cumsum := cumsum(behav_S_t)]

dt_wmvpf_S[, net_cost_S  := (behav_S_cumsum - counterfactual_benefits) / ((1.005^3)^dist_reform)]
dt_wmvpf_S[, mech_cost_S := (mech_S_cumsum - counterfactual_benefits) / ((1.005^3)^dist_reform)]
dt_wmvpf_S[, welfare_S   := (0.995^(3*dist_reform)) *
  (1 - GAMMA_BASELINE*(CONS_INSS - CONS_POP)/CONS_POP) *
  (mech_S_cumsum - counterfactual_benefits)]

wmvpf_bS <- sum(dt_wmvpf_S$welfare_S) / sum(dt_wmvpf_S$net_cost_S)
```

---

## Summary of Findings

| Step | What | G5 Status | I6 Status |
|------|------|-----------|-----------|
| 1. Benefit schedules | RR-based b_L, b_S | ✓ Correct | N/A (reads G5 output) |
| 2. DD on avg benefits | `b̄_L` as dep var | ✓ Correct (slide alternative) | N/A |
| 2b. Counterfactual benefits | `b̄_L - β̂^L` | ✓ Correct | N/A |
| 3. Mechanical expenditure | `N^c × [b̄_L - β̂^L]` | **FIXED** (`claims_L` → `claims_c`) | ✓ Already correct |
| 4. Postponement/anticipation | β̂^{L,P}, β̂^{L,A} decomposition | ✓ Correct | N/A |
| 4b. Behavioral benefits | Selection-corrected by component | ✓ Correct | N/A |
| 5. Behavioral expenditure | `N^L × b̄_L(x^L)` | ✓ Correct (uses `claims_L`) | ✓ Correct |
| 6. WMVPF | η × ME / TC | ⚠️ O5b parenthesization bug (not fixed) | ✓ Correct |

### Remaining known G5 bugs (documented in O5a–O5c, not addressed here)

- **O5b (line 765):** WMVPF parenthesization — `(MECH_L - CNTRF*γ*...)` should be `(MECH_L - CNTRF)*γ*...`. Does not affect I6 (which computes WMVPF independently).
- **O5c (lines 732–734):** CNTRF reads `delta_ben` from G2 (density-based, ×3 factor). Does not affect I6 (which uses G4 for its baseline).

### Key architectural note

G5's internal WMVPF computation (Step 6 in G5) is **not used downstream** — I6 reads G5's cell-level CSV and computes WMVPF independently with correct formulas. The O5b/O5c bugs only matter if someone reads G5's standalone WMVPF output.
