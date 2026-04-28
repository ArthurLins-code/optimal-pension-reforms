# 02 — Pipeline de código

O código roda no PC remoto. Paths são `U:/Documents/...` (scripts antigos) ou `F:/Users/tucalins/Documents/...` (scripts mais novos). Esta memória lista o pipeline canônico por letra, com versão mais recente em **negrito**.

## Visão geral

```
A  → balance check (SUIBE identificado vs não-identificado)
B  → construção de features cross-sectional (RAIS → SUIBE) por claim_year
C  → imputação de tempo de contribuição contínuo (feols)
D  → construção do painel (cell-level p, t; treat pre/post)
E  → plots de claiming (hazard, density) para diagnóstico
F  → contrafactual Pure L e Pure S (version canônica: F7)
G  → efeito sobre benefício médio (G5) e despesas totais (G6)
H  → policy elasticity (IPW-DD)
I  → WMVPF para reforma atual (I4) e + pure reforms (I5)
new_counterfactual_claiming3_*  → versão unificada / mais recente do F,
    com gabriel.R gerando inputs que pure.R consome
```

## Arquivos canônicos (versões a usar)

| Letra | Arquivo canônico | Papel | Observação |
|-------|------------------|-------|------------|
| A | `A4_balance_check.R` | Balance SUIBE id vs unid | 281 linhas, limpo |
| B | `B4_create_clean_candidates_cross.R` | Features RAIS por claim_year | 649 linhas; **4 funções `fn_open_rais_*` redundantes** — ver 06_reorg_notes |
| C | `C6_estimate_continuous_contrib.R` | Imputa tempo contínuo via feols | 434 linhas |
| D | `D4_create_panel.R` | Constrói painel p,t | 414 linhas; **SYNTAX ERROR linha 249** (`)` solto após `gc()`) |
| E | `E4_plots_claiming_distributions.R` | Plots hazard + density | 491 linhas |
| F | **`F7_counterfactual_pure_reforms_in_frequncies.R`** | Pure L/S em **frequências (contagens)** | Canônico. Filename typo: "frequncies". |
|   | `F6_counterfactual_pure_reforms_bl_and_bs.R` | Versão em **densidades** | **Deprecated.** Fórmula de hazard diferente (com normalização); usa no lugar F7. |
| G | **`G5_effect_average_benefit_freq_bL_and_bS.R`** | DD sobre **avg benefit** para bL e bS separados | 400+ linhas |
|   | **`G6_effect_expenditures_freq_bL_and_bS.R`** | DD sobre **despesa total** (benefit × count) | 68KB |
| H | `H3_policy_elasticity.R` | Policy elasticity via IPW-DD | 459 linhas; output `noyearr.pdf` (typo "noyear") |
| I | `I4_wmvpf_no_pure_reforms_freq.R` | WMVPF reforma atual | 304 linhas |
|   | **`I5_wmvpf_w_pure_reforms_freq.R`** | WMVPF reforma atual + Pure L + Pure S | **Canônico.** 400+ linhas |
| new_counterfactual | `new_counterfactual_claiming3_gabriel.R` | Upstream (Gabriel) — gera contrafactual unificado | 300+ linhas; **salva intermediários em `/tmp/`** ⚠️ |
|   | `new_counterfactual_claiming3_pure.R` | Downstream (Arthur) — consome saída do gabriel.R e decompõe Pure L/S | 300+ linhas |

## Passo a passo (pipeline canônico)

### A4 — Balance check
- **Input:** SUIBE identificado + não-identificado.
- **Objetivo:** verificar se a base identificada (com CPF, linkável a RAIS) é representativa do universo de claims.
- **Output:** tabela de balance (médias por subgrupo, p-values).

### B4 — Features cross-sectional
- **Input:** RAIS anual 1995–2020 + SUIBE identificado.
- **Objetivo:** para cada claimant, construir features no ano do claim (wage, contract type, município, tenure, etc.).
- **Alerta:** existem 4 funções `fn_open_rais_*` com estrutura idêntica (por cohort de ano); deveriam ser uma função única parametrizada. **Não tocar sem coordenar** — ver 06_reorg_notes.

### C6 — Tempo de contribuição contínuo
- **Input:** RAIS por CPF + SUIBE.
- **Objetivo:** imputar tempo de contribuição em escala contínua (vs. discreto anual) via regressão `feols`.
- **Output:** variável `contrib_time_cont` no SUIBE.

### D4 — Construção do painel
- **Input:** SUIBE + features (B4) + contrib_time_cont (C6).
- **Objetivo:** painel na célula `(p, t)` = (points, claim_year). Marca `treat = 1{t ≥ 2015.5}` e define o ponto normalizado `points_norm = p - p̄`.
- **⚠️ Bug conhecido:** linha 249 tem `)` solto logo após chamada `gc()`. Corrigir no PC remoto.

### E4 — Plots diagnósticos
- Plots de claiming hazard e densidade por célula (p, t), pré vs pós-reforma. Útil para ver bunching visualmente.

### F7 — Pure L/S em frequências (canônico)
- **Método:** trabalha em **contagens** (N claims em cada célula) em vez de densidades. Fórmula de hazard é `hazard_{p,t} = N_claims_{p,t} / N_at_risk_{p,t}`.
- **Output:** contrafactual de claims no cenário Pure L (só ΔbL, sem resposta de slope) e Pure S (só ΔbS, sem resposta de level), via DiD duplo.
- **Por que F7 e não F6:** F6 usa densidades, o que requer normalização e introduz um extra degree of freedom (escolha de bandwidth/window). F7 fica com contagens brutas, mais transparente.

### G5/G6 — Efeito sobre benefícios
- **G5:** DD sobre **benefício médio** separado em componentes bL e bS.
- **G6:** DD sobre **despesa total** = (benefit × count). Por construção, G6 = G5 × (count effect estimated in F7).
- Ambos usam `fixest::feols` com interação `i(points_norm, treat, ref=-2)` (evento = 2 anos antes do threshold como ref).

### H3 — Policy elasticity
- Estima elasticidade do claiming com respeito a mudança no benefício via IPW-DD (inverse probability weighting + DD). 459 linhas.
- **Typo no output:** `noyearr.pdf` (duplicado "r"). Não bloqueante.

### I4 / I5 — WMVPF
- **I4:** WMVPF da reforma observada (combina F7, G5/G6, H3 com pesos de consumo ELSI/POF).
- **I5:** WMVPF separado para reforma observada, Pure L e Pure S. **É o arquivo principal hoje.**
- **γ baseline = 4.** Sensibilidade testada em [2, 6].

### new_counterfactual_claiming3_{gabriel, pure}.R

- **gabriel.R (upstream):** constrói o contrafactual canônico no novo framework. **⚠️ Salva outputs intermediários em `/tmp/`**, que é não-persistente. Se pure.R rodar em outra sessão, `/tmp/` já foi limpo e pure.R quebra. **Prioridade 1:** migrar `/tmp/` para um path persistente combinado (ex.: `F:/Users/tucalins/Documents/tmp_counterfactual/`).
- **pure.R (downstream):** lê saída do gabriel.R e aplica a decomposição Pure L/S. Esta é a versão em que Arthur está trabalhando ativamente agora.

## Outputs

Os códigos salvam em subpastas de `output/`:

- `output/tables/` — tabelas .csv e .tex
- `output/figures/` — pdfs
- `output/rdata/` — .RData intermediários (usados entre scripts)

Na cópia local, a pasta `trans_retirement/output/` reflete uma fotografia desses outputs (provavelmente desatualizada em relação ao PC remoto).

## Dependências entre scripts (ordem de execução)

```
A4 (independente — diagnóstico)
B4 → (depende: RAIS + SUIBE identificado)
C6 → (depende: B4)
D4 → (depende: C6)
E4 → (depende: D4; só plots, não alimenta nada)
F7 → (depende: D4)
G5, G6 → (dependem: D4, F7)
H3 → (depende: D4, F7)
I4 → (depende: F7, G5/G6, H3)
I5 → (depende: I4 + Pure L/S via F7)

new_counterfactual_claiming3_gabriel.R → (depende: D4)
new_counterfactual_claiming3_pure.R → (depende: saída do gabriel.R em /tmp/)
```
