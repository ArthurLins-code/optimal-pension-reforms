# Notation Registry

Canonical source: `Retirement_Presentations (old strat reverted).pdf`

| Symbol | Definition | Introduced | Common confusions |
|--------|-----------|------------|-------------------|
| MVPF | Marginal Value of Public Funds = WTP / Cost | Slide 5/56 | Not welfare-weighted; see WMVPF |
| WMVPF | Welfare-weighted MVPF = eta * MVPF | Slide 5/56 | Incorporates CRRA welfare weights |
| bL | Benefit level component (intercept of benefit schedule) | Slide 4/56 | delta_bL > 0 in 2015 reform |
| bS | Benefit slope component (marginal benefit per point) | Slide 4/56 | delta_bS < 0 in 2015 reform |
| delta_bS* | Optimal budget-neutral change in slope | Slide 52/56 | Positive = increase slope (opposite to reform) |
| delta_bL* | Optimal budget-neutral change in level | Slide 52/56 | Negative = decrease level (opposite to reform) |
| fp_est | Estimated claiming frequency at point p | Slide 21/56 | Frequency (count), NOT density |
| dist_reform | Distribution of claims post-reform | Slide 22/56 | Na_{p,t} in formulas |
| points_norm | Normalized points: p - 85 (women) or p - 95 (men) | Slide 18/56 | Zero at threshold, negative below |
| points_claim | Raw points at claiming (age + years of contribution) | Slide 4/56 | Not normalized |
| dist_claim_cutoff | Claiming distribution at the threshold | Slide 21/56 | Key for bunching identification |
| pv_benefits_old | NPV of benefits under pre-reform schedule | Slide 26/56 | bNPV_{i,cnt} in formulas |
| pv_benefits_new | NPV of benefits under reformed schedule | Slide 26/56 | bNPV_i in formulas |
| benefits_new | Per-period benefit under reformed schedule | Slide 42/56 | b'(x_it) = b(x_it) + 1(p >= p_bar)[delta_bL + delta_bS * p] |
| benefits_old | Per-period benefit under pre-reform schedule | Slide 42/56 | b(x_it) = bL(x_it) + bS(x_it) * p(x_it) |
| eta | Average welfare weight on reform beneficiaries | Slide 5/56 | From CRRA with gamma = 4 |
| gamma | CRRA coefficient for welfare weights | Slide 38/56 | Baseline = 4 |
| CH_pt | Claiming hazard at (p, t) = C_pt / R_pt | Slide 18/56 | Claims / at-risk population |
| PA_t | Postponement arrivals at cutoff in quarter t | App slide 22/57 | Sum of postponers reaching p=0 |
| PB_pt | Postponement bunching at (p, t) | App slide 23/57 | = g_{p,t-2p} * PA_{t-2p} |
| NL_pt | Frequency under Pure Level reform | App slide 23/57 | Adjusts for postponement only |
| NS_pt | Frequency under Pure Slope reform | App slide 25/57 | = Na_{p,t} - PB_{p,t} for p >= 0 |
| g_pt | Claiming probability at (p, t) conditional on arrival | App slide 24/57 | Estimated from proportional mixing (A3) |
| WNSBD | Welfare Net Social Benefit per Dollar | Slide 54/56 | For optimal expenditure problem |
| SMU_it | Social Marginal Utility of consumption | Slide 15/56 | E(beta^t * du/dc | x) |
| RR | Replacement rate (benefit / contribution wage) | Slide 10/56 | Women: 0.69 + 0.021p; Men: 0.82 + 0.025p |

## Mapa símbolo ↔ variável de código ↔ linguagem (pipeline reformas puras)

Do diagnóstico I7 das indagações do Juan (WhatsApp, 23–25/05/2026). Ponte entre a notação
dos slides, os nomes das variáveis em R, e os termos informais usados no grupo "Retirement".

| Conceito | Slides | Código (R) | WhatsApp |
|----------|--------|-----------|----------|
| Frequência contrafactual | N^c_{p,t} | `claims_c` | "N^c" |
| Frequência observada | N^a_{p,t} | `claims` | — |
| PV benefício antigo / novo | PV(b^old/new) | `pv_benefits_old/new` = `3 * benefits_* * ann_factor_q` | — |
| Benefício pure-level / pure-slope | b^L_i / b^S_i | `benefits_bL` / `benefits_bS` | "b_bar_S" |
| Média celular bL / bS | b̄^L_{p,t} / b̄^S_{p,t} | `avg_benefits_bL` / `avg_benefits_bS` | — |
| Benefício contrafactual (pós-DD) | b̄^c(x_a) − β̂ | `avg_reform_benefits_pre_reform_choices_*` | "b_bar_c" |
| Beta DD contrafactual (G4) | β̂^{b̄,c} | G4 `point_estimate` (period='old') | "β^{b_bar_c}" |
| Beta DD bL / bS (G5) | β̂^{b̄,L/S} | G5 `point_estimate_bL/bS` | "β^{b_bar_S}" |
| Betas postponement / anticipação | β̂^{*,P/A} | `Beta_LP/SP`, `Beta_LA/SA` | — |
| Fator anuidade trimestral | a_q | `ann_factor_q` | "ann_factor_q" |
| Benefício trimestral (G2, densidade) | — | `delta_ben` = `(avg_benefits − point_estimate) * 3` | "R$ 6.700" |
| MECH / BEHAV / CNTRF por trimestre | MECH^q_t, BEHAV^q_t, CNTRF_t | `MECH_L/S`, `BEHAV_L/S`, `CNTRF` | — |

**Identidade para p < 0** (schedule S = contrafactual abaixo do cutoff): por indivíduo
`pv_benefits_old = pv_benefits_new = benefits_bL = benefits_bS`, logo β̂^{bL} = β̂^{bS}
dentro do G5. A diferença β̂^c(G4) vs β̂^bS(G5) vem de spec da regressão, não de conceito
(ver `10_corrections_log.md`, [LEARN:juan-diag-beta]).
