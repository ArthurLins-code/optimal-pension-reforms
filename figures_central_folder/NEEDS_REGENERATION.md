# Figures that need regeneration (frozen / sample-only)

> **What this is.** A register of presentation figures that are **not currently coming
> from a good code run**. They are either *frozen* to their old full-data image (so the
> slides look right) or still showing a noisy **5% sample** render. All of them should be
> regenerated from a **full-data run on the server**, then re-wired to their code source.
>
> Last updated: 2026-06-08.

## How to restore any of these (after a full-data server run)

1. On the server, run the listed stage on full data (it writes to `trans_retirement/output/<stage>/`).
2. In `manifest.csv`, flip the figure's row back to its code source:
   - set `code_script`, `code_output_path`, `code_output_name` to the values in the table below,
   - set `status` to `OK-RENAME` (or `OK` if the name matches),
   - set `mode` to `any`.
3. Run `python figures_central_folder/update_deck.py <stage>` (or `--collect-only`) and recompile.
4. If a figure was frozen, you may delete its copy from `static/`.

See also: `_docs/memory/07_open_issues.md` (the G5 bugs O5a–O5c affect the benefit plots),
`_docs/plans/server_rerun_checklist.md` (full-data rerun steps).

---

## A. FROZEN to the old (full-data) image — slides look correct, but are not live

These rows in `manifest.csv` are `status = NONE` pointing at `static/`. The image shown is the
original; it will **not** update from code until restored.

| Deck figures | Slides | Code source to restore | Why frozen |
|---|---|---|---|
| `frequenciesLQ0…12.pdf` (13) | Frequencies under Pure **Level** Reform | `new_counterfactual_claiming3_pure.R` → `output/new_counter_claiming/..._level_..._<YYYY_Qn>.pdf` | sample plots noisy |
| `frequenciesSQ0…12.pdf` (13) | Frequencies under Pure **Slope** Reform | `new_counterfactual_claiming3_pure.R` → `..._slope_..._<YYYY_Qn>.pdf` | sample plots noisy |
| `old-12, old-3, old0, old4, old13.pdf` (5) | Effect on Avg **Counterfactual / Pre-Reform** Benefits | `G5_effect_average_benefit_freq_bL_and_bS.R` → `output/G/G4_eventstudy_benegits_old_{1..5}.pdf` | sample plots degenerate; **+ G5 bugs O5a–c** |
| `new-12, new-3, new0, new4, new13.pdf` (5) | Effect on Avg **Actual / Post-Reform** Benefits | `G5_…bL_and_bS.R` → `output/G/G4_eventstudy_benegits_new_{1..5}.pdf` | sample plots degenerate; **+ G5 bugs O5a–c** |

Panel → suffix map for the benefit figures: `1 → -12, 2 → -3, 3 → 0, 4 → 4, 5 → 13`.

## B. Still SAMPLE-sourced — live, but only 5% sample (not yet frozen)

These update from code, but locally that means the 5% sample. They will become publication-quality
on a full-data run. Freeze them too (move to section A) if you want the deck fully on old images first.

| Deck figure | Slide | Code source | Note |
|---|---|---|---|
| `I6_plot_cumsum_actual_reform_multby20_sample.pdf` | Welfare Weighted MVPF | `I6_wmvpf_with_pure_reforms_freq.R` | sample WMVPF (×20-scaled); numbers match slide text |
| `E4_pension_schedule_women.pdf` | Empirical Distribution | `E4_plots_claiming_distributions.R` | sample render of the pension schedule |
| `E4_pension_schedule_men.pdf` | Men's Replacement Rate | `E4_plots_claiming_distributions.R` | sample render of the pension schedule |

## C. Watch-list (not a figure problem, but related)

- **G5 bugs O5a–O5c** (`_docs/memory/07_open_issues.md`): the benefit event-study values may be wrong
  even on full data until these are fixed. The frozen `old*`/`new*` figures depend on G5.
- **`E3_claiming_*` slides** use the **E4** code output (`E4_plots_claiming_distributions.R`), confirmed
  2026-06-08 (an earlier E3 hold was reversed). They are code-routed, so on the 5% sample they show the
  E4 sample render and will sharpen on a full-data run — same as the section-B items.
