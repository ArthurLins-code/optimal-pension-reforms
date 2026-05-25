# Prompt — Refactor I6 PART 2 (Pure-Reforms WMVPF) to match the spec tit-for-tat

**Paste this into Claude Code, working on the `claude/magical-borg-18ac72` worktree.**
All paths and line numbers below refer to the **worktree** versions, verified 2026-05-21.

---

## Your role and goal

The file `trans_retirement/code/I6_wmvpf_with_pure_reforms_freq.R` (≈740 lines)
already exists and has three parts:

- **PART 1 — Actual Reform WMVPF** (L158–356): an exact I4 replication, marked
  "do NOT modify independently."
- **PART 2 — Pure Level/Slope WMVPF** (L357–633): the pure-reform decomposition.
- **PART 3 — Summary & outputs** (L634–741).

**Your job is to rebuild PART 2 only**, so that its pure-reform math maps
**one-to-one** to `_docs/pure_reforms_spec.md`. **Do not touch PART 1** beyond
what is needed to read its shared baseline (the no-reform `counterfactual_benefits`
from `aux3`, L211–215) — keep the actual-reform and pure-reform computations
**completely separated**, as they are now. PART 3 only needs updating where PART 2's
object names change.

Be a critical partner. This rebuilds a result for an empirical public-economics
paper ("Optimal Pension Reforms", Gonzaga/Lemos/Rios).

### The certainty rule (read this twice)

**Only implement something autonomously when it is BOTH (a) explicitly stated in
`_docs/pure_reforms_spec.md` AND (b) corroborated by the appendix slides
(33–47/47).** If a step is in the spec but not the slides, or in the slides but the
spec is silent/ambiguous, or the two disagree, or you must *infer/interpolate/guess*
any formula, index range, sign, weighting, or parameter — **STOP and ask Arthur.**
Do not pick a "reasonable default." When you stop, state precisely: what you need,
what the spec says, what the slides say, and the options you see.

## Authoritative sources

**The canonical source of the pure-reform math is the appendix images** in
`_docs/reference/appendix_pure_reform/` (frames 18–47/47). **Read them** — they are
the ground truth for every formula, sign, index range, and definition. The spec is a
faithful *restatement* of these frames; if the spec and the images ever disagree, the
**images win** — stop and flag it. Use both, in this order:

1. **Pure-reform appendix images: `_docs/reference/appendix_pure_reform/`** — the
   canonical math (see below). Start by reading `INDEX.md`, then the frames.
2. **`_docs/pure_reforms_spec.md`** — the operational restatement of those frames;
   verified 2026-05-21 to match them tit-for-tat. Use it as the working contract, but
   it is subordinate to the images.

**About the images:**
   the appendix frames **18–47/47** (canonical deck, PDF pp.121–150) rendered to
   PNG, with `INDEX.md` mapping frame → file → title. **Read these images, not the
   PDF.** The source `latex/presentation/_main.pdf` is gitignored (not in this
   worktree) and, more importantly, the PDF reader falsely rejects it as
   "password-protected" even though it is unencrypted — so a path to the PDF will
   not work. The images cover the two-step agent model (18/47), the ∆bL/∆bS
   theoretical densities (19–22/47), the frequency construction incl. the `g_{p,t}`
   derivation (24–32/47, with `g` at **30/47**), and the computation algorithm
   (33–47/47). **Ignore I6's current header citations** (they point to a
   non-canonical "…/56" deck); re-anchor all citations to these frames and the spec.
   > **Known discrepancy — already decided (see decision 8):** 30/47 (A3/A4,
   > Proportional Mixing) restricts bunching to `p=0,1`, while the code (`g_pta`) and
   > the reallocation use `p∈[0,4)`. Arthur is aware and chose **`p∈[0,4)` for now**
   > (2026-05-22). Use that range; do not stop to ask. (Still flagged for Juan.)

Citation convention: `k/52` = main presentation, `k/47` = appendix.

## Mandatory workflow (project rules)

- **Plan first.** Enter plan mode, read the spec end-to-end, save a plan to
  `quality_reports/plans/YYYY-MM-DD_I6-part2-rebuild.md`, and wait for Arthur's approval.
- **Build section by section, pausing for Arthur's sign-off after each** (protocol below).
- **Every change is its own commit** with a *what* + *why* message. The repo is on
  OneDrive and a stale `.git/index.lock` (and a truncated `.git/config`) have
  appeared — if git fails, tell Arthur to clear it; do not force it.
- **Do not change the discount rates.** Cross-cohort discount is `1.005^3` per
  quarter, `disc_t = (1.005^3)^(-dist_reform)`. The mismatch with the 6% within-life
  annuity is known — **flag it, do not fix it.**

## Locked decisions (confirmed by Arthur, 2026-05-21)

1. **DD granularity: follow the appendix.** Keep G5's point-*group* indicators
   (`[-15,-7]` control vs `[-6,-3]`,`[-2,-1]`,`[0,1]`,`[2,6]`,`[7,15]`), matching the
   `1(p ∈ p̃)` group treatment on 36/47. Do **not** switch to per-point DD.
2. **PDV basis: PV-at-claim.** The pure-reform per-cell benefits come from G5's
   cross-section (`pv_benefits_*` = full remaining-life annuity at the claim
   quarter). The cross-cohort `1.005^3` discount is applied **later**, at the
   aggregate level. Keep within-life (6% annuity) and cross-cohort (`1.005^3`)
   discounts as two separate operations.
3. **Aggregate over all `p`, not just `p ≥ 0`** (38/47, 42/47 use unrestricted
   `Σ_p`; `p<0` cells are postponement origins). Add a header note to this effect.
4. **Mechanical route: avg-benefit DD × counterfactual frequencies.** `MECH^q_t =
   Σ_p claims_c·(b̄^{q,a} − β̂^{b̄,q})`. G5 already supplies the per-cell
   `avg_reform_benefits_pre_reform_choices_bL/bS` (= `b̄ − β̂`) and I6 already
   weights MECH by `claims_c` — keep this; it is correct.
5. **CNTRF includes the selection correction** and is the no-reform PDV baseline,
   common to both reforms. I6 PART 1's `counterfactual_benefits` (from G4 `period=='old'`,
   `(avg_benefits_pv − point_estimate)·claims_c`, L205–215) already satisfies this —
   reuse it; do not rebuild it.
6. **Discount symmetrically with `(1.005^3)^(-t)`** on both the WE numerator and the
   TC denominator. **Replace** I6's current `0.995^(3t)` welfare factor (L454, L501)
   with `(1.005^3)^(-t)`, and build WE from the **raw** (undiscounted) `(MECH−CNTRF)`,
   discounting once.
7. **Postponement reallocation: expenditure path (spec 39–41/47) — this is the core
   change.** Replace I6's current BEHAV construction (`Σ claims_L ·
   avg_post_pure_reform_benefits_bL`, L431–434, which uses the frequency path *and*
   G5's non-spec Beta_LA/Beta_LP layer + the NA fallback at L399–413). Instead:
   reallocate **expenditures** using the shipped `g_pta`, building origin losses
   `E^{P}_{origin} = E^{a} − E^{c}` and `E^{P,L}_{p,t} = g_{p,t−2p}·Σ_x(−E^{P,L}_{origin})`,
   then `E^L = E^{c,L} + E^{P,L}` (pure-S with its own sign). Do **not** reuse
   `avg_post_pure_reform_benefits_*` or `claims_L`/`claims_S` for BEHAV.
   > **Caveat to surface, not resolve:** frequency reallocation values postporners at
   > *arrival* (`p≥0`) benefits; the expenditure path values them at *origin* (`p<0`)
   > benefits. Follow the spec (expenditure), but report the gap for Juan.
8. **Postponement-bunching range: `p∈[0,4)`** (Arthur's choice, 2026-05-22). The
   slides' A3/A4 (30/47) restrict bunching to `p=0,1`, but the postponement inflow
   `E^{P}` and the reallocation are applied over **`p∈[0,4)`** — matching the code's
   `g_pta`/`x̄` construction and the spec. This is a deliberate override of the slide's
   narrower range; **use `p∈[0,4)` and do not stop to ask** about it. It remains an
   open item to confirm with Juan, so note it in the final summary, but proceed.

## Inputs (worktree, sample-aware via `SUFFIX`)

- Per-cell pure-reform benefits — **G5 output CSV**
  `output/G/G5_table_results_contrafactual_reforms_and_benefits_freq<SUFFIX>.csv`
  (I6 already loads this at L374). Columns it provides include `dist_reform`,
  `points_norm`, `claims_c`, `claims` (N^a), `claims_L`, `claims_S`,
  `avg_benefits_bL/bS` (uncorrected `b̄^{q,a}`), `point_estimate_bL/bS` (`β̂^{b̄,q}`),
  `avg_reform_benefits_pre_reform_choices_bL/bS` (= `b̄−β̂`, **use for MECH and for
  `E^{c}`**). **Verify these columns exist before relying on them.** The
  `avg_post_pure_reform_benefits_*` and `Beta_*` columns exist but are the layer you
  are removing — do not use them.
- Claiming probability + postponement objects — **F-stage CSV**
  `output/F/new_counterfactual_claim_counts_with_pure_schedules_3<SUFFIX>.csv`:
  `g_pta` (= `g_{p,t−2p}`), `PA_ta`, `PB_pt`, `claims`, `claims_c`, `claims_L`,
  `claims_S`. **Read `g_pta` directly for decision 7; do not recompute.** (`g_pta`
  is built upstream in `new_counterfactual_claiming3_pure.R` from Assumption 2,
  proportional mixing: `g_pta = claims / Σ_{p∈[0,Xt)} claims`, `Xt=min((t+1)/2,4)`,
  with a `t>7→g(t=7)` carry-forward.)
- Shared no-reform baseline — PART 1's `aux3$counterfactual_benefits` (do not recompute).
- Reform window `dist_reform ∈ 0:12`; last quarter T = 13 (Q3 2018) for ∆b.
- Parameters (already constants in I6): `GAMMA_BASELINE=4`, `CONS_INSS (c_b)=1536.4`,
  `CONS_POP=1473.1`, `R_ANNUAL=0.06`. **Confirm these with Arthur before relying on them.**

## Source-file provenance map (worktree line numbers — verify, then lift/reject)

**First inspect G5 and the current I6 PART 2 yourself** and confirm this map; report
any discrepancy before building.

> **Reference implementations live in `trans_retirement/code/legacy/`.** I5 is at
> `trans_retirement/code/legacy/I5_wmvpf_w_pure_reforms_freq.R` (462 lines) — read it
> as the closest precedent for the pure-reform welfare/discount block (its pure
> section is L298–456; the per-cell `claims_c`/`N_a` flow pattern is L163–193). The same
> folder holds `G6_effect_expenditures_freq_bL_and_bS.R` and `F6/F7` pure-reform
> counterfactual scripts, which may help you understand the expenditure-space
> construction. Treat these as **reference only** — they are superseded, and where
> they conflict with the locked decisions, the decisions win (notably: use G5's
> PV-at-claim per decision 2, **not** I5's shrinking-horizon panel PV; and use the
> symmetric `(1.005^3)^(-t)` per decision 6, **not** I5's `0.995^(3t)` welfare factor).
> I3 (`trans_retirement/code/I3_wmvpf_pure_reforms.R`) is identical to main but
> superseded by I6's own scaffolding.

| Spec step | Lift from (worktree) | Reject / rewrite |
|---|---|---|
| Per-cell PDV + RR + b_L/b_S (§0, 34–35/47) | **G5 L98–126** (`ann_factor_q`, `pv_benefits_*`), **L334–356** (RR, `benefits_bL/bS`) | — (b_S coefficient already fixed to `0.82/0.69`). |
| Selection DD, avg-benefit route (Step 2/2.1) | **G5 L409–438** (group DD), **L588** (`avg_benefits − point_estimate`) | Keep group DD (decision 1). |
| MECH = Σ_p claims_c·(b̄−β̂) (Step 3, 38/47) | **I6 L424–428 / L471–475** (already `claims_c`) | — already correct. |
| CNTRF (no-reform, selection-corrected) | **I6 L205–215, aux3** | Do not use G5's L739 `claims_c*delta_ben` (still the old density route). |
| Postponement E^P, x̄, origin map (Step 4, 39–41/47) | **G5 L626–628** scaffolding only (`x_bar_tp`, origin index) + **`g_pta` from F CSV** | **Reject G5's Beta_LP/LA layer (L636–713) and I6's BEHAV at L431–434 + NA fallback L399–413.** Rebuild as expenditure reallocation (decision 7). |
| BEHAV = Σ_p E^q (Step 4, 42/47) | new (spec branches 39/47) | Replace I6 L431–434 / L478–482. |
| TC / ME / FE + cost discount (Step 5) | **I6 L445–452 / L492–499** (single `1.005^3` on costs — keep) | — |
| WE / WMVPF (Step 5, 43/47, 45/47) | I6 L458–459 / L505–506 (ratio form OK) | **Fix the welfare discount**: I6 L454/L501 use `0.995^(3t)` → change to `(1.005^3)^(-t)` (decision 6). |
| Pure-S signs (44–45/47) | spec | Enforce `E^S = E^{a,S} − E^{P,S}` vs pure-L `E^L = E^{c,L} + E^{P,L}`. |
| ∆b_L, ∆b_S (43/47, 45/47) | **G5 L362–369** | — |
| Output table + WE/FE/ME plot | **I6 L514–624** (existing scaffolding) | Keep; just repoint to the rebuilt objects and the canonical deck. |

## Bugs that must NOT remain after the rebuild (acceptance checklist)

- [ ] BEHAV via **expenditure reallocation** with `g_pta` — not `claims_L/claims_S × avg_post_pure_reform_benefits`, no Beta_LA/Beta_LP, no NA fallback.
- [ ] MECH weighted by `claims_c` (already true — keep).
- [ ] CNTRF = PART 1's selection-corrected no-reform baseline (already true — reuse).
- [ ] WE uses `(1 − γ(c_b−c_pop)/c_pop)`, built from raw `(MECH−CNTRF)`, discounted **once** by `(1.005^3)^(-t)` (no `0.995^(3t)`).
- [ ] WMVPF = `Σ WE·disc / Σ TC·disc` with correct parentheses (do not reproduce G5 L765/L769).
- [ ] Pure-L vs pure-S signs both exact.
- [ ] `p<0` cells included in all `Σ_p` aggregates.
- [ ] Pure-S objects use `b_S`/`claims_S` (no `N^L` slide-label typo).
- [ ] PART 1 untouched; citations re-anchored to `_main.pdf` 33–47/47.
- [ ] **Open structural check (ask Arthur):** I6 currently *cumsums* MECH/BEHAV/CNTRF across `t` (cumulative stock), while the spec writes per-quarter `Σ_p E_{p,t}`. Confirm whether the pure-reform WMVPF should be cumulative or per-quarter before finalizing — this is a certainty-rule stop.

## Build protocol — one section per checkpoint

After each: show Arthur the code, the spec lines it implements, and a numeric sanity
check; **wait for his OK; then commit.**

- **§A Confirm scope & inputs** — re-read PART 1 (do not change it), confirm the G5
  and F CSV columns exist, confirm the cumulative-vs-per-quarter question (checklist
  last item) with Arthur. **Stop here for sign-off before any rewrite.**
- **§B Per-cell E^{a,q} and E^{c,q}** (Step 1–3) — from G5 per-cell data build
  `E^{c,q}_{p,t} = claims_c·(b̄^{q,a}−β̂)` and `E^{a,q}_{p,t} = claims·b̄^{q,a}`
  (confirm the `E^{a}` benefit object against the spec/34/47 before coding). Sanity:
  `MECH^L>CNTRF>MECH^S` signs.
- **§C Postponement reallocation** (Step 4; 39–41/47, 44/47) — read `g_pta`; origin
  map `(−x, t−2(x+p))`, `x̄_{t,p}=min(6,(t+1)/2−p)`, origin loss `E^{P}_{origin}=E^{a}−E^{c}`
  on `p∈(−6,0)`, inflow `E^{P,L}_{p,t}=g_{p,t−2p}·Σ_{x=1}^{x̄}(−E^{P,L}_{origin})` on
  `p∈[0,4)`, then the p-branches and signs for `E^L`/`E^S`. Sanity: reallocated
  expenditure conserved vs origin losses; compare to the old frequency-path BEHAV and
  report the gap (for Juan).
- **§D BEHAV + WMVPF** (Step 4–5; 42/47, 43/47, 45/47) — `BEHAV^q=Σ_p E^q`; apply
  `disc_t=(1.005^3)^(-t)`; `TC`, `ME`, `FE`, `WE=ME·(1−γ(c_b−c_pop)/c_pop)`,
  `WMVPF=ΣWE·disc/ΣTC·disc`; `∆b_L`, `∆b_S`.
- **§E Outputs** — repoint the existing tables/plots (I6 L514–624) and PART 3 to the
  rebuilt objects; re-anchor citations. Report WMVPF^L_T, WMVPF^S_T.
- **§F Verification** — run the checklist; cross-check a couple of cells by hand
  against the spec; confirm the four required outputs (densities, WE/FE/ME graph,
  ∆b's, TC_T and WMVPFs for Q3 2018); diff the new WMVPFs against the pre-rebuild I6.

## When you finish

Summarize: what changed in PART 2, the expenditure-vs-frequency BEHAV gap (decision 7
caveat), the cumulative-vs-per-quarter resolution, where the new WMVPFs land vs the
old I6, and every point where the certainty rule made you stop. Open items for
Arthur/Juan: the `γ, c_b, c_pop, r` values, the origin-vs-arrival benefit question,
and the cumulative-vs-per-quarter convention. Do not mark done until §F passes.
