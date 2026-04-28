# Optimal Pension Reforms: An Application to Brazilian Administrative Data

Research project measuring the welfare effects of Brazil's 2015 pension reform (Lei 13.183/2015) using the **Welfare-weighted MVPF** framework. The reform introduced a points-based eligibility rule (age + contribution years ≥ 85/95 for women/men) that altered both the level and slope of the benefit schedule for early retirees.

## Authors

- **Gustavo Gonzaga** — PUC-Rio
- **Juan Rios** — PUC-Rio
- **Gabriel Lemos** — MIT Sloan

Research assistance: Arthur (PUC-Rio)

## Repository Structure

```
trans_retirement/
  code/               # R and Stata scripts for the full pipeline
    A1..A4            # Data cleaning (SUIBE)
    B1..B4            # RAIS cross-sections and candidate panels
    C1..C6            # Merge SUIBE–RAIS, sample restrictions
    D1..D4            # Cross-section and panel construction
    E1..E4            # Claiming distribution plots, frictions
    F1..F7            # Counterfactual claiming hazards and bunching
    G1..G6            # Benefit calculations, welfare costs
    H1..H3            # Heterogeneity analysis
    I1..I5            # MVPF and WMVPF estimation
    new_counterfactual_claiming*.R   # Pure-reform counterfactuals
    aux_codes_RAIS/   # RAIS helper scripts and CBO mappings

Surrogate Indices/    # Surrogate index approach (Athey et al.) — in progress

_docs/                # Project documentation and memory files
  CLAUDE.md           # Working-memory entry point
  memory/             # Detailed context files (pipeline, math, conventions, etc.)
```

## Data

The analysis uses Brazilian administrative records (SUIBE 2012–2019 and RAIS 1995–2020). These datasets are confidential and not included in this repository. Code runs on a restricted-access remote server.

## Pipeline

The pipeline runs sequentially from A (data cleaning) through I (welfare estimation). See `_docs/memory/02_pipeline.md` for detailed documentation of each step, its inputs, and outputs.

## Key Results

- Reform MVPF ≈ 0.31, WMVPF ≈ 0.26
- Optimal local reform: increase slope (bS), decrease level (bL) of benefit schedule
- Budget-neutral optimum: ΔbS* = +0.081 (+350%), ΔbL* = −R$791 (−26%)
