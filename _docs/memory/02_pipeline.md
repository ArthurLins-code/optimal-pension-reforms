# 02 — Pipeline de codigo

O codigo roda no PC remoto. Paths sao `U:/Documents/...` (scripts antigos) ou `F:/Users/tucalins/Documents/...` (scripts mais novos). Esta memoria lista o pipeline canonico por letra, com versao mais recente em **negrito**.

> **STRATEGY REVERSION (2025):** The project REVERTED to the AVERAGE BENEFITS
> path for pure-reform computations. The "Expenditures path" is ABANDONED.
> Consequently: **I5 and G6 are LEGACY** — never rerun, never review as current.
> The canonical F-stage is `new_counterfactual_claiming3_pure.R`, NOT F7.

## Visao geral

```
A  -> balance check (SUIBE identificado vs nao-identificado)
B  -> construcao de features cross-sectional (RAIS -> SUIBE) por claim_year
C  -> imputacao de tempo de contribuicao continuo (feols)
D  -> construcao do painel (cell-level p, t; treat pre/post)
E  -> plots de claiming (hazard, density) para diagnostico
F  -> contrafactual Pure L e Pure S (CANONICAL: new_counterfactual_claiming3_pure.R)
G  -> efeito sobre beneficio medio (G5 CANONICAL; G6 LEGACY — expenditures path abandoned)
H  -> policy elasticity (IPW-DD)
I  -> WMVPF para reforma atual (I4 CANONICAL; I5 LEGACY — included pure reforms under abandoned strategy)
new_counterfactual_claiming3_*  -> versao unificada / mais recente do F,
    com gabriel.R gerando inputs que pure.R consome
```

## Arquivos canonicos (versoes a usar)

| Letra | Arquivo canonico | Papel | Observacao |
|-------|------------------|-------|------------|
| A | `A4_balance_check.R` | Balance SUIBE id vs unid | 281 linhas, limpo |
| B | `B4_create_clean_candidates_cross.R` | Features RAIS por claim_year | 649 linhas; **4 funcoes `fn_open_rais_*` redundantes** — ver 06_reorg_notes |
| C | `C6_estimate_continuous_contrib.R` | Imputa tempo continuo via feols | 434 linhas |
| D | `D4_create_panel.R` | Constroi painel p,t | 414 linhas; **SYNTAX ERROR linha 249** (`)` solto apos `gc()`) |
| E | `E4_plots_claiming_distributions.R` | Plots hazard + density | 491 linhas |
| F | **`new_counterfactual_claiming3_pure.R`** | Pure L/S em **frequencias (contagens)** | **CANONICAL.** New methodology replacing F1-F7. |
|   | `F7_counterfactual_pure_reforms_in_frequncies.R` | Pure L/S (old method, frequencies) | **LEGACY.** Superseded by new_counterfactual. Filename typo: "frequncies". |
|   | `F6_counterfactual_pure_reforms_bl_and_bs.R` | Versao em **densidades** | **LEGACY.** Deprecated — used densities instead of frequencies. |
| G | **`G5_effect_average_benefit_freq_bL_and_bS.R`** | DD sobre **avg benefit** para bL e bS separados | **CANONICAL.** 400+ linhas |
|   | `G6_effect_expenditures_freq_bL_and_bS.R` | DD sobre **despesa total** (benefit x count) | **LEGACY.** Expenditures path abandoned. |
| H | `H3_policy_elasticity.R` | Policy elasticity via IPW-DD | 459 linhas; output `noyearr.pdf` (typo "noyear") |
| I | **`I4_wmvpf_no_pure_reforms_freq.R`** | WMVPF reforma atual (sem pure reforms) | **CANONICAL.** 304 linhas |
|   | `I5_wmvpf_w_pure_reforms_freq.R` | WMVPF reforma atual + Pure L + Pure S | **LEGACY.** Used pure reforms under abandoned expenditure strategy. |
| new_counterfactual | `new_counterfactual_claiming3_gabriel.R` | Upstream (Gabriel) — gera contrafactual unificado | 300+ linhas; **salva intermediarios em `/tmp/`** :warning: |
|   | `new_counterfactual_claiming3_pure.R` | Downstream (Arthur) — consome saida do gabriel.R e decompoe Pure L/S | 300+ linhas; **THIS IS THE CANONICAL F-STAGE** |

## Passo a passo (pipeline canonico)

### A4 — Balance check
- **Input:** SUIBE identificado + nao-identificado.
- **Objetivo:** verificar se a base identificada (com CPF, linkavel a RAIS) e representativa do universo de claims.
- **Output:** tabela de balance (medias por subgrupo, p-values).

### B4 — Features cross-sectional
- **Input:** RAIS anual 1995-2020 + SUIBE identificado.
- **Objetivo:** para cada claimant, construir features no ano do claim (wage, contract type, municipio, tenure, etc.).
- **Alerta:** existem 4 funcoes `fn_open_rais_*` com estrutura identica (por cohort de ano); deveriam ser uma funcao unica parametrizada. **Nao tocar sem coordenar** — ver 06_reorg_notes.

### C6 — Tempo de contribuicao continuo
- **Input:** RAIS por CPF + SUIBE.
- **Objetivo:** imputar tempo de contribuicao em escala continua (vs. discreto anual) via regressao `feols`.
- **Output:** variavel `contrib_time_cont` no SUIBE.

### D4 — Construcao do painel
- **Input:** SUIBE + features (B4) + contrib_time_cont (C6).
- **Objetivo:** painel na celula `(p, t)` = (points, claim_year). Marca `treat = 1{t >= 2015.5}` e define o ponto normalizado `points_norm = p - p_bar`.
- **Bug conhecido:** linha 249 tem `)` solto logo apos chamada `gc()`. Corrigir no PC remoto.

### E4 — Plots diagnosticos
- Plots de claiming hazard e densidade por celula (p, t), pre vs pos-reforma. Util para ver bunching visualmente.

### F-stage — Counterfactual claiming (CANONICAL: new_counterfactual_claiming3_pure.R)
- **Metodo:** trabalha em **contagens** (N claims em cada celula) em vez de densidades. Formula de hazard e `hazard_{p,t} = N_claims_{p,t} / N_at_risk_{p,t}`.
- **Output:** contrafactual de claims no cenario Pure L (so delta_bL, sem resposta de slope) e Pure S (so delta_bS, sem resposta de level).
- **Why new_counterfactual and not F7:** F7 was the old method; the new_counterfactual framework is a complete rewrite with improved methodology. F1-F7 are ALL LEGACY.
- **gabriel.R (upstream):** constroi o contrafactual canonico no novo framework. **Salva outputs intermediarios em `/tmp/`**, que e nao-persistente. Se pure.R rodar em outra sessao, `/tmp/` ja foi limpo e pure.R quebra. **Prioridade 1:** migrar `/tmp/` para um path persistente.
- **pure.R (downstream):** le saida do gabriel.R e aplica a decomposicao Pure L/S. Esta e a versao em que Arthur esta trabalhando ativamente agora.

### G5 — Efeito sobre beneficio medio (CANONICAL)
- **G5:** DD sobre **beneficio medio** separado em componentes bL e bS.
- Usa `fixest::feols` com interacao `i(points_norm, treat, ref=-2)` (evento = 2 anos antes do threshold como ref).
- **G6 is LEGACY** — used total expenditures (benefit x count) under the now-abandoned strategy.

### H3 — Policy elasticity
- Estima elasticidade do claiming com respeito a mudanca no beneficio via IPW-DD (inverse probability weighting + DD). 459 linhas.
- **Typo no output:** `noyearr.pdf` (duplicado "r"). Nao bloqueante.

### I4 — WMVPF (CANONICAL)
- **I4:** WMVPF da reforma observada. Combina F-new, G5, H3 com pesos de consumo ELSI/POF.
- **gamma baseline = 4.** Sensibilidade testada em [2, 6].
- **I5 is LEGACY** — included pure-reform decomposition under the abandoned expenditure strategy. Do not rerun.

## Outputs

Os codigos salvam em subpastas de `output/`:

- `output/tables/` — tabelas .csv e .tex
- `output/figures/` — pdfs
- `output/rdata/` — .RData intermediarios (usados entre scripts)

Na copia local, a pasta `trans_retirement/output/` reflete uma fotografia desses outputs (provavelmente desatualizada em relacao ao PC remoto).

## Dependencias entre scripts (ordem de execucao)

```
A4 (independente — diagnostico)
B4 -> (depende: RAIS + SUIBE identificado)
C6 -> (depende: B4)
D4 -> (depende: C6)
E4 -> (depende: D4; so plots, nao alimenta nada)
new_counterfactual_claiming3_gabriel.R -> (depende: D4)
new_counterfactual_claiming3_pure.R   -> (depende: saida do gabriel.R)
G5 -> (depende: D4, new_counterfactual_claiming3_pure.R)
H3 -> (depende: D4, new_counterfactual_claiming3_pure.R)
I4 -> (depende: new_counterfactual_claiming3_pure.R, G5, H3)

LEGACY (do not rerun):
F7 -> superseded by new_counterfactual_claiming3_pure.R
G6 -> expenditures path abandoned
I5 -> pure reforms under abandoned strategy
```
