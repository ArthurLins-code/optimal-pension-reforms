# Plan: Rebuild I6 PART 2 — Pure-Reforms WMVPF (per spec + appendix)

**Status:** READY FOR APPROVAL
**Branch:** `claude/magical-borg-18ac72` (worktree at `.claude/worktrees/magical-borg-18ac72`)
**Spec:** `_docs/pure_reforms_spec.md`
**Appendix:** `_docs/reference/appendix_pure_reform/` (frames 33–47/47)

## Context

I6 PART 2 (L357–633) currently computes pure-reform WMVPF using G5's frequency-space behavioral benefits (`avg_post_pure_reform_benefits_bL/bS × claims_L/claims_S`). The spec and appendix (decision 7) require rebuilding BEHAV via **expenditure reallocation** using `g_pta`, eliminating the Beta_LP/LA/SP/SA layer and NA fallback entirely.

## §A — Scope confirmation (inputs verified)

### A.1 PART 1 reuse — CONFIRMED
`aux3$counterfactual_benefits` (L211-215) = cumsum of `Σ_p (delta_ben × claims_c)` by quarter. This is CNTRF — the no-reform baseline. **Reuse as-is.**

### A.2 CSV columns — CONFIRMED
**G5 output** (`G5_table_results_contrafactual_reforms_and_benefits_freq*.csv`) contains:
- `dist_reform`, `points_norm` ✓
- `claims_c`, `claims`, `claims_L`, `claims_S` ✓
- `avg_benefits_bL/bS`, `point_estimate_bL/bS` ✓
- `avg_reform_benefits_pre_reform_choices_bL/bS` (= `b̄ − β̂`, for MECH) ✓
- `avg_post_pure_reform_benefits_bL/bS` (exists but will NOT be used) ✓
- `Beta_LP/LA/SP/SA` (exists but will NOT be used) ✓
- `delta_ben` (from G2, exists but may not be needed) ✓
- `g_pta` ✓ (carried through from F-stage merge at G5 L609)

**F-stage output** (`new_counterfactual_claim_counts_with_pure_schedules_3*.csv`) contains:
- `g_pta`, `PA_ta`, `PB_pt` ✓
- `claims`, `claims_c`, `claims_L`, `claims_S` ✓

**Key finding:** `g_pta` is already in the G5 CSV (carried through from the F-stage merge). We may not need to load the F-stage CSV separately — verify at build time.

### A.3 Cumulative vs per-quarter — **RESOLVED (Arthur, 2026-05-20)**
- **Answer:** Build **per-quarter** objects first (following the slides), then **cumsum** for the cumulative version. Output both formulations so Juan can plot both.
- Per-quarter: `WMVPF_q_T = WE_q_T / TC_q_T` (last quarter)
- Cumulative: `WMVPF_q = Σ_t WE_q_t·disc_t / Σ_t TC_q_t·disc_t` (discounted sum)
- Natural approach: per-quarter is the building block, cumulative is derived via `cumsum`.

## §B — Load inputs and build per-cell expenditures

**Files modified:** `I6_wmvpf_with_pure_reforms_freq.R` (PART 2 only, ~L357-633)

1. Keep G5 CSV load (L387-393) — already correct
2. Remove NA fallback block (L395-413) — no longer needed
3. Build per-cell expenditures for each reform q ∈ {L, S}:
   ```r
   # Actual expenditure: E^{a,q}_{p,t} = N^a * b̄^{q,a}
   g5_data[, E_a_L := claims * avg_benefits_bL]
   g5_data[, E_a_S := claims * avg_benefits_bS]
   
   # Mechanical expenditure: E^{c,q}_{p,t} = N^c * (b̄^{q,a} − β̂^{b̄,q})
   g5_data[, E_c_L := claims_c * avg_reform_benefits_pre_reform_choices_bL]
   g5_data[, E_c_S := claims_c * avg_reform_benefits_pre_reform_choices_bS]
   ```

## §C — Build postponement reallocation (E^P)

This is the **core change** (decision 7). For each reform:

### Pure-L (frames 39-41/47):
```
For p < 0, t ≥ -1:  E^{P,L} = E^{a,L} − E^{c,L}         (origin losses, negative)
For p ∈ [0,4):      E^{P,L} = g_{p,t-2p} · Σ_x(−E^{P,L}_{−x, t-2(x+p)})   (inflows, positive)
For p ≥ 4:          E^{P,L} = 0
Then: E^L = E^{c,L} + E^{P,L}   for p ≥ 0, t ≥ 0
      E^L = E^{a,L}             for p < 0 OR (p ≥ 0, t = -1)
```

### Pure-S (frames 44-45/47, **different signs**):
```
For p < 0:          E^{P,S} = E^{a,S} − E^{c,S}
For p ∈ [0,4):      E^{P,S} = −g_{p,t-2p} · Σ_x(−E^{P,S}_{−x, t-2(x+p)})  (note leading minus)
For p ≥ 4:          E^{P,S} = 0
Then: E^S = E^{a,S} − E^{P,S}   for p ≥ 0
      E^S = E^{c,S}             for p < 0
```

**x̄_{t,p}** = min((t+1)/2 − p, 6)

**Implementation:** Loop over `t` in ascending order (t = 0,1,...,12) and `p ∈ [0,3]`. For each (p,t), look up origin cells `(-x, t-2(x+p))` for x = 1,...,x̄, sum their `−E^P` values, multiply by `g_{p,t-2p}`.

## §D — Assemble BEHAV, MECH, costs, welfare, WMVPF

### MECH (unchanged — already correct):
```r
MECH_q_t = Σ_p E^{c,q}_{p,t}   # = Σ claims_c * (b̄ − β̂), per quarter
```

### BEHAV (rebuilt):
```r
BEHAV_q_t = Σ_p E^q_{p,t}   # from §C, per quarter
```

### CNTRF (reused from PART 1):
```r
CNTRF_t = aux3$counterfactual_benefits_t   # per-quarter (not cumsum)
```

### Costs and welfare (decision 6 — fix discount):
```r
disc_t = (1.005^3)^(-dist_reform)          # replaces 0.995^(3*dist_reform)

# --- Per-quarter objects (building blocks, per slides 43/47, 45/47) ---
TC_q_t  = BEHAV_q_t − CNTRF_t
ME_q_t  = MECH_q_t − CNTRF_t
WE_q_t  = ME_q_t * (1 − gamma * (c_b − c_pop) / c_pop)
WMVPF_q_t = WE_q_t / TC_q_t               # per-quarter WMVPF

# --- Cumulative objects (derived via cumsum, for cumulative plots) ---
TC_q_cum   = cumsum(TC_q_t * disc_t)
ME_q_cum   = cumsum(ME_q_t * disc_t)
WE_q_cum   = cumsum(WE_q_t * disc_t)
WMVPF_q_cum = WE_q_cum / TC_q_cum         # cumulative discounted WMVPF

# Report both: WMVPF_q_T (last quarter) and WMVPF_q_cum[T] (cumulative)
```

## §E — Update PART 3 outputs

Repoint output table columns to new objects. Keep output file structure.

## §F — Verification

Per acceptance checklist:
- [ ] BEHAV via expenditure reallocation with `g_pta`
- [ ] MECH weighted by `claims_c`
- [ ] CNTRF = PART 1's no-reform baseline
- [ ] WE uses `(1.005^3)^(-t)`, not `0.995^(3t)`
- [ ] WMVPF with correct parentheses
- [ ] Pure-L vs pure-S signs exact
- [ ] p < 0 cells included in all Σ_p
- [ ] PART 1 untouched
- [ ] Citations re-anchored to appendix frames

## Build protocol

One section per checkpoint, each followed by Arthur's sign-off:
1. §B commit → sign-off
2. §C commit → sign-off
3. §D commit → sign-off
4. §E commit → sign-off
5. §F verification → final sign-off
