# Pure Reforms — Computational Spec (DRAFT for review)

**Status:** DRAFT. This is the plain-language + equation restatement of the
pure-reforms computation, to be reviewed by Arthur before it becomes the
committed spec on `claude/magical-borg-18ac72`. Once approved it is the
authority that I6/G5 are verified against.

**Canonical sources, in priority order:**
1. **Appendix, frames 33–47/47** (PDF pp.136–150) — the *operational* algorithm.
   This is the primary source for code.
2. **Main presentation, frames 14, 25–33, 40–46/52** (PDF pp.19, 46–95) — the
   *welfare-accounting* layer the appendix feeds into, plus the 5-step overview.

Citation convention: `k/52` = main presentation, `k/47` = appendix.

---

## 0. Notation and objects (33/47, p.136; 14/52, p.19)

- `p` — normalized points relative to the 85/95 retirement threshold; `t` —
  quarter; a **cell** is a `(p, t)` pair.
- Choice vectors for individual `i` in quarter `t`:
  - `x^a_it` — **actual** choices observed after the reform.
  - `x^c_it` — **counterfactual** choices, absent the reform.
  - `x^L_it` — choices that would be made under the **pure-Level** reform
    (analogously `x^S_it` for pure-Slope).
- Benefit schedules: `b(·)` baseline; `b^a(·)` actual reformed; `b^c(·)`
  counterfactual; `b_L(·)` pure-level reform; `b_S(·)` pure-slope reform.
- Claiming frequencies per cell: `N^a_{p,t}` (actual), `N^c_{p,t}`
  (counterfactual). Expenditures and frequencies are linked by
  `E = N · b̄` (a cell's total PDV expenditure = frequency × average benefit).
- For each pure reform `q ∈ {L, S}` we need **three** benefit objects (33/47):
  - `b_q(x^a)` — pure-`q` schedule applied to **observed** post-reform choices;
  - `b_q(x^c)` — **mechanical** benefits (no behavioral response);
  - `b_q(x^q)` — benefits under the pure-`q` schedule with **only** pure-`q`
    behavioral responses.

### Replacement-rate schedules (35/47, p.138)

`RR(x^a) = RR_0(x^a) + κ · p(x^a)`, gender-specific:

```
RR(x^a) = 0.69 + 0.021·p   if i is a woman
RR(x^a) = 0.82 + 0.025·p   if i is a man
```

so `RR_0 = 0.69 / 0.82` (intercept) and `κ = 0.021 / 0.025` (slope).

```
b_L(x^a) = b(x^a)                                    if p < 0
         = b(x^a) · { 1 + [1 − RR_0(x^a)] / RR(x^a) } if p ≥ 0

b_S(x^a) = b(x^a)                                    if p < 0
         = b(x^a) · RR_0(x^a) / RR(x^a)              if p ≥ 0
```

---

## The 5-step recipe (main 42/52, p.64) ↔ appendix steps

| Main 5-step (42/52) | Appendix operationalization |
|---|---|
| 1. Frequencies under pure-L, redistributing postponement missing mass to future bunching | Steps 1, 4 — `E^{a,L}`, postponement inflows `E^{P,L}` (34, 39–41/47) |
| 2. Frequencies under pure-S, removing the postponement found in (1) | Pure-S steps (44–45/47) |
| 3. Mechanical expenditures under both reforms, no responses, correcting all selection | Steps 2–3 — DD selection + `MECH^q` (36–38/47) |
| 4. Expenditures under each reform, correcting only for anticipation (postponement) selection | Step 4 — `E^L`, `E^S` (39, 44/47) |
| 5. Welfare effects, total costs, WMVPFs | Final outputs (43, 45/47) + welfare layer (25–33/52) |

> **Framing seam (verify in code):** the main slides phrase steps 1–2 in terms
> of *frequencies* (redistributing missing mass); the appendix operationalizes
> in terms of *expenditures* `E = N·b̄` (reallocating expenditure losses). These
> are equivalent only if the reallocation is applied to the right object. A
> wrong implementation could reallocate *frequencies* where the appendix
> reallocates *expenditures*. **Check that I6 reallocates expenditures per
> 40–41/47, not raw frequencies.**

---

## Pure-Level reform — step by step

### Step 1 — Actual expenditures under the pure-L schedule (34/47, p.137)
Apply `b_L` to **observed** post-reform choices:
```
E^{a,L}_{p,t} = Σ_{i∈{p|t}} Σ_t b_L(x^a_it)/(1+r)^t = N^a_{p,t} · b̄_L(x^a_{p,t})
```
PDV of total expenditure for those claiming at `(p,t)` under pure-L + observed
choices. (`b_L(x^a)` is approximated via the replacement rates in §0.)

### Step 2 — Selection via cell-level DiD (36/47, p.139)
For `q ∈ {L, S}` recover selection with the same cell DD:
```
y^{a,q}_{p,t} = δ^q_p + γ^q_t + Σ_{k≠−2} β^{y,q}_{p̃,k} · 1(p∈p̃) · 1(t=k) + ε^{y,q}_{p,t}
```
where `y` is either expenditure `E^{a,q}_{p,t}` or average benefits
`b̄^{q,a}_{p,t} ≡ E^{a,q}_{p,t}/N^a_{p,t}`. The slide presents two equivalent
recoveries of mechanical (counterfactual-choice) expenditure:
```
Ê^{c,q}_{p,t} = E^{a,q}_{p,t} − β̂^{E,q}_{p,t}            (expenditure DD)
Ê^{c,q}_{p,t} = N̂^c_{p,t} · [ b̄^{q,a}_{p,t} − β̂^{b̄,q}_{p,t} ]   (avg-benefit DD × counterfactual freq)
```

> **IMPLEMENTATION (required):** the code must use the **avg-benefit route** —
> run the DD with the dependent variable `y = b̄^{q,a}_{p,t}` (average benefit),
> then **multiply the selection-corrected average benefit by the counterfactual
> frequencies** `N̂^c_{p,t}` to obtain the mechanical expenditures by cell:
> `Ê^{c,q}_{p,t} = N̂^c_{p,t} · [ b̄^{q,a}_{p,t} − β̂^{b̄,q}_{p,t} ]`. Do **not**
> recover mechanical expenditures from the direct expenditure DD.

### Step 2.1 — No-reform counterfactual expenditure (37/47, p.140)
```
E^c_{p,t} = Σ_{i∈{p|t}} Σ_t b^c(x^c_it)/(1+r)^t
Ê^c_{p,t} = E^{a,c}_{p,t} − β̂^{E,c}_{p,t}   or   N̂^c_{p,t}[ b̄^{c,a}_{p,t} − β̂^{b̄,c}_{p,t} ]
```

> **IMPLEMENTATION (required):** same rule as Step 2 — use the **avg-benefit
> route**. Run the DD on `y = b̄^{c,a}_{p,t}`, then multiply the
> selection-corrected average benefit by the counterfactual frequencies:
> `Ê^c_{p,t} = N̂^c_{p,t}·[ b̄^{c,a}_{p,t} − β̂^{b̄,c}_{p,t} ]`. Not the direct
> expenditure DD.

### Step 3 — Mechanical expenditures under pure-L (38/47, p.141)
Higher benefits, **no** behavioral response, aggregated over points:
```
MECH^L_t = Σ_p Ê^{c,L}_{p,t}
```

### Step 4 — Pure-L expenditures `E^L` (39/47, p.142)
Pure-L generates **postponement but no anticipation**, so only postponement
selection is removed:
```
E^L_{p,t} = E^{a,L}_{p,t}                 for p < 0,  t ≥ −1
E^L_{p,t} = E^{a,L}_{p,t}                 for p ≥ 0,  t = −1   (postponement in both actual and pure-L)
E^L_{p,t} = E^{c,L}_{p,t} + E^{P,L}_{p,t}  for p ≥ 0,  t ≥ 0
```

### Step 4 (cont.) — Postponement inflows (40/47 examples p.143; 41/47 general p.144)
Origin-cell logic: to move from `−x` to `p` takes `2x` periods to reach zero
then `2p` more, so postponers observed at `(p,t)` left at `t − 2(x+p)`.
```
Postponers to (p,t) come from (−x, t−2(x+p)),  x = 1,…,x̄_{t,p}
x̄_{t,p} = (t+1)/2 − p   if (t+1)/2 − p ≤ 6,   else 6
```
They arrive at the threshold in `t−2p` and claim with `p` with probability
`g_{p, t−2p}`.

> **`g` source (resolved 2026-05-21):** `g_{p,t−2p}` is **not** a free parameter.
> It is **derived in the slides at 30/47** (p.133, "Estimating `g_{p,t}` from Arrival
> Cohorts") under **Assumption A4 (Proportional Mixing)**:
> `ĝ_{p,t} = #{arrived in t, claimed with p} / #{arrived in t, claimed with p∈[0,1]}`,
> with A3 restricting bunching to `p=0,1`. It is **estimated in**
> `new_counterfactual_claiming3_pure.R` as `g_pta = claims / Σ_{p∈[0,Xt)} claims`
> within each arrival cohort `t_arrival`, `Xt = min((t+1)/2, 4)`, plus a
> `t>7 → g(t=7)` carry-forward for the end-of-sample window.
> **Discrepancy — decided for now:** the slide (A3/A4) restricts bunching to `p∈[0,1]`,
> but the code and the reallocation below use `p∈[0,Xt)`/`p∈[0,4)`. **Arthur chose to
> use `p∈[0,4)` for now (2026-05-22)**; still to confirm with Juan, but proceed with
> `p∈[0,4)`. It is **shipped as a column** (`g_pta`, alongside
> `PA_ta`, `PB_pt`, `claims_c`, `claims_L`, `claims_S`) in
> `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv`.
> So I6 can read `g_pta` directly — no recompute needed — which makes the
> expenditure-space reallocation below (rather than reusing the already-frequency-
> reallocated `claims_L`/`claims_S`) feasible. **Note the framing seam (checklist
> item 1):** the shipped `claims_L`/`claims_S` apply `g` in *frequency* space
> (`PB_pt = g·PA_ta`); the appendix applies `g` in *expenditure* space. These
> differ because postponers carry the *origin* (`p<0`) benefit in the expenditure
> form but the *arrival* (`p≥0`) benefit in the frequency form — confirm with Juan
> which the WMVPF should use.

Origin-cell expenditure loss (for `p∈(−6,0)`, `t≥−1`):
```
E^{P,L}_{p,t} = E^{a,L}_{p,t} − E^{c,L}_{p,t}
```
Reallocated inflow expenditure (for `p ∈ [0,4)`):
```
E^{P,L}_{p,t} = g_{p,t−2p} · Σ_{x=1}^{x̄_{t,p}} ( − E^{P,L}_{−x, t−2(x+p)} )
```
(Implicitly `p ≥ 4` → no inflow.)

### Step 4 (cont.) — Behavioral and counterfactual aggregates (42/47, p.145)
```
BEHAV^L_t = Σ_p E^L_{p,t}
CNTRF_t   = Σ_p E^c_{p,t} ≡ Σ_p N^c_{p,t} · b̄(x_{p,t})
```

> **RESOLVED (was an open item — verified against 42/47, 43/47, 45/47 on 2026-05-21):**
> `CNTRF` is the **no-reform** baseline `Σ N^c · b̄(x^c)` — the *same* object for
> **both** pure-L and pure-S (it has no `q` superscript). The mechanical effects
> are `ME^L = MECH^L − CNTRF` and `ME^S = MECH^S − CNTRF` against this common
> no-reform baseline. This is economically consistent with the pure-S sign
> restriction (`ME^S ≤ 0`): because `b_S = b·RR_0/RR ≤ b` for `p ≥ 0`,
> `MECH^S` (built from `b_S` × counterfactual frequencies) is **below** `CNTRF`,
> so `ME^S < 0` automatically. The earlier sign anomaly was an **implementation
> bug**, not a spec/slide issue. **Code pitfall:** keep `CNTRF` anchored to the
> no-reform `b^c` and build `MECH^q` from `b_q` — do **not** re-anchor `CNTRF` to
> the actual reformed schedule `b^a`, and do not build `MECH^S` from `b^a`.

### Step 5 — Costs, welfare, WMVPF (43/47, p.146; welfare layer 25–33/52)
```
TC^L_t   = BEHAV^L_t − CNTRF_t                              (total cost)
ME^L_t   = MECH^L_t − CNTRF_t                               (mechanical effect)
WE^L_t   = ME^L_t · ( 1 − γ·(c_b − c_pop)/c_pop )           (welfare effect)
WMVPF^L_t = WE^L_t / TC^L_t
```
Average level change at `t = T` (Q3 2018):
```
∆b_L = (1/N_T) Σ_i b(x^a_iT) · [1 − RR_0(x^a_iT)] / RR(x^a_iT)
```
Mechanical effect = WTP via envelope theorem (25/52, p.46); average
counterfactual benefits identified by the DiD parallel-trends assumption
(`b̄^{c,a}_{p,t}` parallel for `p≥−6` vs `p<−6`) (26/52, p.47); cost expression
net-of-tax, ignoring fiscal externalities on tax collection for now (33/52, p.54).

---

## Pure-Slope reform — mirror steps (44–45/47, pp.147–148)

```
1. b_S(x^a),  E^{a,S}_{p,t} = Σ_{i∈{p|t}} b_S(x^a_it)
2. selection DD as in Step 2 with q = S
3. mechanical expenditure from expenditure DD or avg benefits + N̂^c
4. correct (1) only for postponement selection:
   E^{P,S}_{p,t} = E^{a,S}_{p,t} − E^{c,S}_{p,t}                      for p < 0
                 = − g_{p,t−2p} · Σ_{x=1}^{x̄_{t,p}} E^{P,S}_{−x, t−2(x+p)}  for p ∈ [0,4)
                 = 0                                                  for p ≥ 4
   E^S_{p,t}     = E^{c,S}_{p,t}                                      for p < 0
                 = E^{a,S}_{p,t} − E^{P,S}_{p,t}                      for p ≥ 0
5. BEHAV^S_t = Σ_p E^S_{p,t}
6. TC^S_t = BEHAV^S_t − CNTRF_t,  ME^S_t = MECH^S_t − CNTRF_t,
   WE^S_t = ME^S_t·(1 − γ(c_b−c_pop)/c_pop),  WMVPF^S_t = WE^S_t / TC^S_t
7. ∆b_S = − ( s_w·0.021 + s_m·0.025 )   (s_w, s_m = shares of women / men)
8. outputs: WMVPF inputs graph, ∆b_S, TC^S_T, WMVPF^S_T
```

> **Sign-convention seam (verify in code):** the pure-L and pure-S postponement
> objects use **different signs**. Pure-L: `E^{P,L}_{p≥0} = +g·Σ(−E^{P,L}_{−x,·})`
> and `E^L = E^{c,L} + E^{P,L}`. Pure-S: `E^{P,S}_{p≥0} = −g·Σ E^{P,S}_{−x,·}`
> and `E^S = E^{a,S} − E^{P,S}`. This is a classic place for a coding sign bug —
> **confirm I6 reproduces both conventions exactly.**

---

## Downstream of the pure reforms (for reference, not part of the core redo)

- **Optimal budget-balanced reform** (46/47, p.149): increase `b_S` and decrease
  `b_L` to balance a fixed budget `C(b^c,b^a)`; uses `dC/db_S`, `dC/db_L`
  estimated from `C(b,b_S)/∆b_S`, `C(b,b_L)/∆b_L`.
- **WNSBD** (47/47, p.150): `WNSBD_p` for `p=L,S`, using `WMVPF_T ≈` Lobel (2025)
  calibration (`MVPF_T ≈ 1.64`, incidence 23% firms / 12% workers / 65% consumers).

---

## Final outputs the redo must reproduce (43/47, 45/47)

(i) densities; (ii) WE/FE/ME graph; (iii) `∆b_S` and `∆b_L`; (iv) `TC_T` and
`TC^L_T` / `TC^S_T`; (v) WMVPFs for the last quarter (Q3 2018).

---

## Verification checklist (use these to find I6's divergence)

0. **Avg-benefit route for mechanical expenditures** (Steps 2 & 2.1, 36–37/47) —
   run the DD on average benefits `b̄^{q,a}` and multiply by counterfactual
   frequencies `N̂^c`; do not use the direct expenditure DD.
1. **Reallocate expenditures, not frequencies** — the framing seam above (40–41/47).
2. **Sign conventions** differ between pure-L and pure-S (39 vs 44/47) — the seam above.
3. **`p`-range boundaries:** `p<0`, `p≥0`, the `t=−1` special case for pure-L
   (39/47), and `p≥4` → no postponement inflow (40, 44/47). Confirm all branches.
4. **Origin-cell mapping** `(−x, t−2(x+p))` with `x̄_{t,p}` cap (41/47) — confirm
   exact indices, not an approximation.
5. **`N^L` vs `N^S` label** on the pure-Slope frequency plots (81–93/52) is
   likely a slide typo; the appendix (`E^{a,S}`, `b_S`) is the authority. Do not
   propagate the `L` label into pure-S code.
6. **Welfare-weight parameters** `γ`, `c_b`, `c_pop` in `WE` — confirm the values
   used in code match the intended calibration.

## Resolved

- **Canonical deck (resolved 2026-05-21):** `latex/presentation/_main.pdf` is the
  canonical version. Its compiled PDF is byte-identical (md5 `372c993655d05…`) to
  the deck Arthur uploaded as the authority; `latex/apresentacao/_main.pdf` is a
  different, older 149-page file. Use `latex/presentation/` for all slide refs.
- **CNTRF baseline (resolved 2026-05-21):** see the RESOLVED note under Step 4
  aggregates above — `CNTRF` is the no-reform `Σ N^c·b̄(x^c)`, common to both
  reforms; the pure-S `ME ≤ 0` restriction holds because `MECH^S` uses `b_S ≤ b`.
- **`g_{p,t}` source (resolved 2026-05-21):** estimated upstream in
  `new_counterfactual_claiming3_pure.R` (Assumption 2, proportional mixing) and
  shipped as the `g_pta` column in
  `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv`.
  See the `g` source note under Step 4 (incl. the open expenditure-vs-frequency
  reallocation choice for Juan).

## Open questions for Arthur

- Confirm parameter values for `γ`, `c_b`, `c_pop`, and the discount rate `r`.
- Expenditure-vs-frequency postponement reallocation (Step 4 `g` note): does
  `BEHAV` value the postponed mass at origin or arrival benefits? — for Juan.
