# PROJECT_CONTEXT — Optimal Pension Reforms (single-file bundle)

**Fonte:** Arthur (RA do Juan). Data do snapshot: 2026-04-20.

Este é um documento único consolidando todo o contexto do projeto — pensado para ser colado na primeira mensagem de uma IA (Codex, ChatGPT, Claude) que não lê filesystem. Se a IA lê filesystem, prefira `README_FOR_JUAN.md` + `memory/` pasta (mesmo conteúdo fracionado, mais navegável).

> Perspectiva: escrito do ponto de vista do Arthur. "Eu", "minha tarefa", etc. referem-se a Arthur.

---

## 1. Project overview

## Título do paper

**"Optimal Pension Reforms: An Application to the Brazilian Administrative Data"**

Autores: Gustavo Gonzaga (PUC-Rio), Juan Rios (PUC-Rio), Gabriel Lemos (MIT Sloan). Arthur é RA do Juan.

## Pergunta de pesquisa

Qual é o efeito de bem-estar da reforma previdenciária brasileira de 2015 sobre o regime de aposentadoria por tempo de contribuição? Mais ambiciosamente: qual seria a **reforma local ótima** na vizinhança do sistema atual?

A resposta é construída em três etapas:

1. **Estimar o MVPF/WMVPF** da reforma de 2015 (Hendren & Sprung-Keyser 2020; Bergstrom et al. 2026 para a versão weighted).
2. **Decompor** a reforma em componentes *Pure L* (só ΔbL, nível pós-threshold) e *Pure S* (só ΔbS, inclinação pós-threshold) e estimar WMVPF_bL e WMVPF_bS separadamente.
3. **Caracterizar a reforma local ótima** via comparação: `WMVPF_bL < WMVPF_bS ⇒ reforma ótima aumenta bS e reduz bL` (budget-neutral) ou, em formulação expenditure-based, `WNSBD_bS > WNSBD_bL ⇒ expandir bS financiado via payroll tax`.

## Setting institucional (Brasil)

- **Regime:** Aposentadoria por tempo de contribuição no setor formal privado (RGPS), vigente até a reforma constitucional de 2019.
- **Elegibilidade (pré-reforma 04/2015):** mínimo 30 anos de contribuição (mulheres) / 35 (homens). Fator previdenciário aplicado ao benefício reduzia RR abaixo de 1 para claimants "jovens".
- **Reforma 06/2015 (Lei 13.183/2015, anunciada em abril, convertida em novembro):** introduz a **fórmula 85/95 progressiva** — se `points = idade + anos_contribuição ≥ p̄` (p̄ = 85 mulheres, 95 homens), o fator previdenciário é dispensado e `RR ≈ 100%`.
- **Efeito mecânico:** pré-reforma, `RR = 0.69 + 0.021·p` (M) e `0.82 + 0.025·p` (H). Pós-reforma, `RR` sobe para ≈1 em `p ≥ p̄`, e a inclinação bS colapsa a 0 acima do threshold.
- **Resposta comportamental esperada:** bunching no threshold (postponement) + possível anticipation (se a inclinação abaixo de p̄ ficou mais atrativa relativamente a esperar).

## Modelo de bem-estar (MVPF/WMVPF)

- **MVPF = WTP / Net cost** (willingness to pay / custo fiscal líquido).
- **WTP** é aproximada via envelope: ΔWTP_i ≈ `b_i · η_i` para quem claima em ambos os regimes; para responders (claiming deferred), `ΔWTP ≈ 0` no envelope (first-order).
- **Net cost:** ΔG = mudança na despesa previdenciária (benefícios) − mudança em receita de impostos (externalidade fiscal).
- **WMVPF:** substitui WTP por `Σ ωᵢ · WTP_i`, onde `ωᵢ` são welfare weights baseados em η(c) = marginal utility of consumption. No paper, `u(c) = c^{1-γ}/(1-γ)` com γ = 4 como baseline.
- **Consumption weights** são construídos usando ELSI (idosos) + POF (famílias brasileiras) para mapear benefício → consumo → η_i.

Números-âncora atuais (apresentação 20/abr/2026):
- **MVPF ≈ 0.31**, **WMVPF ≈ 0.26** (ambos sem externalidade fiscal de impostos futuros; virá via Surrogate Indexes)
- **WMVPF_bL ≈ 0.68**, **WMVPF_bS ≈ 0.71**
- **ΔbS\*** = 0.081 (+350%), **ΔbL\*** = −R$ 791 (−26%) (reforma ótima budget-neutral local)
- **WNSBD_bS ≈ −0.96 > WNSBD_bL ≈ −1.04** (reforma ótima expenditure-based: expandir bS, financiar via payroll)

## Pure L vs Pure S (intuição)

- **Pure L:** desloca o benefício em `p ≥ p̄` por um offset ΔbL (level shift). Afeta WTP mecânica proporcionalmente ao benefício médio pós-threshold; gera **postponement** (responders que esperam atingir p̄ para capturar o nível maior) mas **não** induz anticipation.
- **Pure S:** muda a inclinação bS acima ou abaixo de p̄ por Δbs. No baseline do paper, Pure S é construída como "pivot" mantendo o benefício em um ponto fixo e girando a schedule. Gera **anticipation** (mudança na atratividade relativa de pontos logo abaixo de p̄) e pode também gerar postponement dependendo de onde o pivot ocorre.
- As duas decomposições somam (localmente) a reforma observada via Shephard-lemma-like first-order: `dW = WMVPF_bL · dbL + WMVPF_bS · dbS`.

## Dados

- **SUIBE:** base administrativa da Previdência, identificada (CPF) e não-identificada. Universo de claims de aposentadoria por tempo de contribuição entre 2012 e 2019. N ≈ 2.7M.
- **RAIS:** Relação Anual de Informações Sociais, universo de empregados formais 1995–2020 (link via CPF). Usada para construir histórico de contribuição, variáveis pre-reform (controls no DiD), e surrogate variables.
- **ELSI:** Estudo Longitudinal da Saúde dos Idosos Brasileiros. Consumo de idosos.
- **POF:** Pesquisa de Orçamentos Familiares. Consumo de famílias (benchmarking η(c)).

## Literatura relacionada

- **MVPF framework:** Hendren & Sprung-Keyser (QJE 2020), "A Unified Welfare Analysis of Government Policies"; Bergstrom et al. (2026), WMVPF com welfare weights η(c).
- **Bunching / pension claiming:** Saez (2010) bunching; Gelber-Jones-Sacks (AEJ Applied 2013) Social Security earnings test; Manoli-Weber (AEJ Applied 2016) Austrian pension bunching — inspiração direta para o design aqui.
- **Anticipation/deferral in pension:** Brown (2013); Cribb-Emmerson (2019); Lalive-Magesan-Staubli (2023).
- **Surrogate Indexes:** Athey, Chetty, Imbens, Kang (2025) — usado como ferramenta para imputar τᵢᴾᴰⱽ de longo prazo sem esperar décadas de RAIS.
- **Reforma brasileira 2015 (85/95 progressiva):** background institucional detalhado em Early_Retirement_Benefits_atualizado_11_11_2025.pdf, seções 2–3.

## Output final esperado

1. **Paper completo** (Early Retirement Benefits) com seções 1–7 preenchidas. Seção 7.4 ("Disentangling bL and bS") está **vazia hoje** — é o que Arthur está construindo.
2. **NBER Application** com seção específica sobre MVPF brasileiro (versão atual 16/11/2025, com footnotes do Arthur).
3. **Grant proposal** (fim de outubro/2025) com deliverables Q1–Q3 2026 sobre bL/bS + Surrogate.

---

## 2. Pipeline de código

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

---

## 3. Matemática das reformas Pure L / Pure S

Este arquivo detalha as assunções (A1–A4), as fórmulas de contrafactual em frequências (F7 / new_counterfactual_claiming3_pure.R), e a derivação de WMVPF_bL / WMVPF_bS. Notação segue a apresentação 20/abr/2026 e o paper.

## Notação

| Símbolo | Significado |
|---------|-------------|
| `p` | points = idade + anos de contribuição |
| `t` | ano-mês (ou ano de claim) |
| `p̄` | threshold (85 mulheres, 95 homens) |
| `b_{p,t}` | benefício em (p,t) sob regime vigente |
| `bL`, `bS` | nível e inclinação de b em `p ≥ p̄`: `b_{p,t} = bL + bS·(p - p̄)` |
| `g_{p,t}` | claiming hazard em (p,t): P(claim em t | at-risk em t) |
| `EM_{p,t}` | eligible mass (claimants elegíveis mas que ainda não claimaram) em (p,t) |
| `N_{p,t}` | claims observados |
| `PA_t` | postponement arrivals = cohort que cruza p̄ no ano t |
| `PB_{p,t}` | postponement bunching = bunched mass em (p,t) vindo de PA_{t - 2p} |
| `A_{p,t}` | anticipation mass em (p,t) |
| `η_i` | marginal utility of consumption (weight) de indivíduo i |
| `γ` | CRRA parameter (baseline 4) |

## Assunções

### A1 — Point accumulation determinístico

Dado que o indivíduo está empregado formalmente, `points` cresce 2 unidades por ano (1 idade + 1 contribuição). Logo:

> Se o claimant *i* está em `p` no ano `t`, então em `t'` ele estará em `p + 2(t' - t)` (conditional on continued formal employment).

Isso permite traçar cohort trajectories e converter bunching em postponement arrivals.

### A2 — Attention mapping

Assumimos que o indivíduo reage à schedule de benefícios *no momento do claim*. Não há antecipação imperfeita ou myopic misperception, exceto pelo que está capturado em A4.

### A3 — Bunching window

O bunching acontece em uma **janela finita** `[p̄, p̄ + W]` (W ≈ 4 pontos ≈ 2 anos calendário). Fora dessa janela, o bunching é tratado como zero. W é escolhido empiricamente via inspeção visual (E4).

### A4 — Proportional mixing

Responders (indivíduos que esperam atingir p̄ para claimar) se misturam proporcionalmente com a população at-risk no momento do claim. Isso permite escrever:

> `PB_{p,t} = g_{p,t-2p} · PA_{t-2p}`

(bunching mass em (p,t) = hazard no momento em que a cohort cruza p̄, ponderado pela arrival mass naquele momento).

## Fórmulas Pure L

Em Pure L, mudamos só bL. A resposta comportamental é **postponement** (responders que esperam até p̄ para capturar o nível maior).

**Contrafactual de claims em Pure L (p ≥ p̄, t ≥ 2015.5):**

```
N^PL_{p,t} = N^obs_{p,t} − PB_{p,t} + PA_{t-2p} · δ_{p,p̄}
```

Intuição: o contrafactual tira o bunching pós-reforma (`PB_{p,t}`) e o realoca para o momento em que ele "teria claimado" sem a mudança de bL — aproximado como o momento de arrival em p̄ (via A1-A4).

**Benefício agregado:**

```
B^PL_t = Σ_p N^PL_{p,t} · b^PL_{p,t}
```

onde `b^PL_{p,t} = b^pre_{p,t} + ΔbL · 1{p ≥ p̄}`.

**WMVPF_bL:**

```
WMVPF_bL = Σ_{p,t} η_{p,t} · ΔWTP^PL_{p,t} / ΔG^PL
```

com `ΔWTP^PL = b^pre · (count effect do PL)` para não-responders (envelope) e `0` para responders.

## Fórmulas Pure S

Em Pure S, mudamos só bS. A resposta principal é **anticipation** (mudança relativa na atratividade de pontos logo abaixo de p̄ dispara claims "cedo"). Podem ocorrer efeitos de postponement secundários dependendo do pivot point.

**Anticipation mass:**

```
A_{p,t} = 0.5 · EM_{p,t+1} + 0.5 · EM_{p+1,t+1}
```

Intuição: assume-se que metade dos responders vem da célula imediatamente "à frente" em tempo (p, t+1) e metade da próxima célula de points (p+1, t+1) — modelo simétrico.

**Contrafactual Pure S:**

```
N^PS_{p,t} = N^obs_{p,t} − A_{p,t}          para p < p̄ (célula de anticipation)
N^PS_{p,t} = N^obs_{p,t} + A_{p',t'}         no destino natural (p', t') sem reforma
```

**WMVPF_bS:** análogo, com `ΔWTP ≈ b · η · (slope effect)`.

## Decomposição total

Por first-order Taylor, a reforma observada decompõe localmente como:

```
dW_obs ≈ WMVPF_bL · dbL_obs + WMVPF_bS · dbS_obs
```

Se `WMVPF_bL < WMVPF_bS`, a reforma **local ótima** é `↑ bS, ↓ bL` (budget-neutral): aumentar a inclinação, reduzir o nível.

## Números da apresentação (20/abr/2026)

| Objeto | Valor |
|--------|-------|
| WMVPF (reforma observada) | 0.26 |
| WMVPF_bL | 0.68 |
| WMVPF_bS | 0.71 |
| ΔbL\* (budget-neutral) | −R$ 791 (−26%) |
| ΔbS\* (budget-neutral) | +0.081 (+350%) |
| WNSBD_bL (expenditure-based) | −1.04 |
| WNSBD_bS (expenditure-based) | −0.96 |

Como WMVPF_bS > WMVPF_bL, a reforma local ótima é **expandir bS e reduzir bL**. Em formulação expenditure-based (WNSBD), o mesmo sinal aparece: expandir bS financiado via payroll tax é melhor que expandir bL.

## Reforma observada (decomposição real)

A reforma 85/95 de 2015 fez, na prática:
- `ΔbL > 0` (nível pós-threshold sobe de `0.69 + 0.021·p̄` para ≈1)
- `ΔbS < 0` (inclinação colapsa para 0 em `p ≥ p̄`)

Ou seja, a reforma foi `↑ bL, ↓ bS`. Dado que WMVPF_bS > WMVPF_bL, **a reforma foi na direção oposta à ótima** em termos marginais. Esse é o ponto central do paper.

## Sensibilidade

- **γ:** testar em [2, 6]. γ = 4 é o baseline. Resultado qualitativo (bS melhor que bL) é robusto a γ ∈ [2, 6].
- **Bunching window W:** testar W ∈ {2, 3, 4, 5}. Baseline W=4 pontos.
- **Proportional mixing (A4):** alternativas = 100% cohort arrival vs 100% at-risk population; baseline é 50/50.

---

## 4. Equipe e arquivos

## Equipe

| Pessoa | Papel | Afiliação | O que produz |
|--------|-------|-----------|--------------|
| **Juan Rios** | Orientador principal do Arthur | PUC-Rio (Economia) | Estrutura teórica MVPF/WMVPF, decisão editorial sobre paper, direção do projeto |
| **Gustavo Gonzaga** | Coautor sênior | PUC-Rio (Economia) | Setting institucional brasileiro, supervisão de dados (SUIBE, RAIS) |
| **Gabriel Lemos** | Coautor / PhD student | MIT Sloan | Código "upstream" (`new_counterfactual_claiming3_gabriel.R`), versão unificada de F; owner do contrafactual canônico |
| **Arthur (você)** | RA do Juan | PUC-Rio | Decomposição Pure L / Pure S, WMVPF separado por componente (I5), scripts de conferência, Surrogate Indexes (próxima fase) |

## Quem produz o quê

### Gabriel (upstream)
- `new_counterfactual_claiming3_gabriel.R` — versão unificada do contrafactual, substitui em grande parte F6/F7 no novo framework.
- Design decisions sobre assunções A1–A4.
- Paper editing (principal writer da seção de identificação).

### Arthur (downstream)
- `new_counterfactual_claiming3_pure.R` — lê saída do gabriel.R e decompõe em Pure L/S.
- Diagnósticos (E4 rodadas adicionais, sensibilidades).
- **Surrogate Indexes** (próxima fase): construção do τᵢᴾᴰⱽ usando RAIS.
- Footnotes da NBER Application (versão `_arthur_footnotes.pdf`).

### Juan
- WMVPF framework e aplicação.
- Decisão sobre quais counterfactuals reportar.
- Grant proposal (fim de outubro/2025, deliverables 2026).

### Gustavo
- Setting institucional (Seção 2 do paper).
- Supervisão sobre SUIBE (acesso, validação).

## Papers e versões

Todos em `versões do artigo/`.

### Paper principal — "Early Retirement Benefits"
- **`Early_Retirement_Benefits_atualizado_11_11_2025.pdf`** — versão mais recente.
- Status de seções:
  - 1–6: completas ou quase.
  - 7 "Disentangling bL and bS": parcial.
  - **7.4 "Disentangling bL and bS" (subseção): VAZIA.** Este é o espaço para os resultados do Arthur (I5 + Pure L/S math).

### NBER Application
- `NBER_Application_16_11_25.pdf` — versão "clean".
- `NBER_Application_arthur_footnotes.pdf` — versão com footnotes adicionados pelo Arthur.
- Números-âncora na NBER: MVPF ≈ 0.21, budget $7,000 (difere dos números atuais da apresentação; é uma estimativa anterior).

### Grant Proposal
- `grant_proposal_late_october.pdf` — fim de outubro/2025.
- Contém deliverables Q1–Q3 2026 sobre Pure L/S + Surrogate Indexes.

### Presentations
- **`Retirement_Presentations (10).pdf`** — **mais recente (15/mai/2026)**. É a referência canônica para números-âncora atuais.
- Versões anteriores: `Retirement_Presentations (1).pdf` até `(8).pdf` — presas para comparação histórica.
- `paper_presentation_late_october.pdf` — versão de outubro/2025.

### Notas de reunião
- `Cálculos Juan Reunião 05032026.pdf` — OCR quality baixa (handwritten scan). **Pedir versão digital ao Juan** (ver 07_open_issues).

## Outros arquivos relevantes

### Surrogate Indexes/
- `Potential Variables- Surrogate Indexes.docx` — lista de variáveis candidatas RAIS:
  - **Aprovadas:** município, tipo de contrato, gênero, escolaridade, idade, wage options, tenure, contr_hours, occupation.
  - **Vetadas:** worker_munic 2015+ (quebra série), raça (cobertura ruim pré-2005), contractual wage (inconsistente).

### _docs/ (esta pasta)
- `CLAUDE.md` — entry point.
- `memory/` — este conjunto de arquivos.

## Convenções de autoria no código

- Arquivos que Gabriel "owna": `new_counterfactual_claiming3_gabriel.R`, todo o pipeline F6→F7 (histórico).
- Arquivos que Arthur "owna": `new_counterfactual_claiming3_pure.R`, I5, conferências ad-hoc.
- **Regra:** ao editar arquivos "do Gabriel", combinar antes. Ao editar os "do Arthur", ok seguir, mas mencionar no próximo push.

---

## 5. Convenções de código e dados

## Paths (PC remoto)

Dois padrões coexistem — ao editar, respeitar o que já está no arquivo:

| Padrão | Uso | Exemplo |
|--------|-----|---------|
| `U:/Documents/...` | Scripts antigos (A, B, C, D, E, F, G, H, I) | `U:/Documents/trans_retirement/data/suibe.rds` |
| `F:/Users/tucalins/Documents/...` | Scripts novos (`new_counterfactual_*`) | `F:/Users/tucalins/Documents/trans_retirement/output/...` |

- **Não misturar.** Scripts antigos referenciam outputs antigos salvos em U:; novos referenciam em F:.
- Outputs intermediários do `new_counterfactual_claiming3_gabriel.R` são salvos em `/tmp/` — isso é **frágil** (ver 07_open_issues).

## Estrutura de projeto no PC remoto

```
trans_retirement/
├── code/                        # scripts R/Stata
│   ├── A4_balance_check.R
│   ├── B4_create_clean_candidates_cross.R
│   ├── ...
│   ├── new_counterfactual_claiming3_gabriel.R
│   └── new_counterfactual_claiming3_pure.R
├── data/                        # dados intermediários
│   ├── suibe.rds
│   ├── rais_panel.rds
│   └── ...
├── output/
│   ├── tables/                  # .csv, .tex
│   ├── figures/                 # .pdf
│   └── rdata/                   # .RData para comunicação entre scripts
└── docs/                        # LaTeX do paper
```

## Pacotes R

Os scripts usam preferencialmente:

- `data.table` — manipulação (preferido sobre `dplyr` em scripts pesados)
- `fixest` — regressões (`feols`, `feglm`) com FE, cluster, IV
- `dplyr` — quando clareza > performance
- `ggplot2` — plots
- `haven` — leitura de Stata `.dta` (RAIS legacy)
- `stringr` — regex
- `lubridate` — datas
- `readr` — CSVs grandes

Scripts novos (`new_counterfactual_*`) usam predominantemente `data.table` + `fixest`.

## Nomes de variáveis

| Nome | Significado |
|------|-------------|
| `cpf_mask` | ID do indivíduo (mascarado) |
| `claim_year`, `claim_ym` | ano / ano-mês do claim |
| `points`, `p` | pontos = idade + anos de contribuição |
| `points_norm` | points − p̄ (threshold-normalized) |
| `age_yrs` | idade em anos |
| `tenure_yrs` | anos de contribuição |
| `treat` | dummy `1{t ≥ 2015.5}` |
| `post`, `pre` | dummies temporais (redundantes com treat — verificar) |
| `benefit` | benefício em reais (nominal, não ajustado) |
| `benefit_rr` | replacement rate (benefício / SB médio dos últimos 36) |
| `g_pt` | claiming hazard em (p,t) |
| `EM_pt` | eligible mass em (p,t) |
| `PB_pt`, `PA_t` | postponement bunching / arrivals |

## DiD syntax (fixest)

Padrão canônico usado:

```r
feols(
  y ~ i(points_norm, treat, ref = -2) + controls | fe1 + fe2,
  data = panel,
  cluster = ~ cpf_mask
)
```

- `ref = -2`: referência é **2 pontos abaixo do threshold** (não 0). Razão: em `p̄ - 1` pode já existir antecipation; `p̄ - 2` é "limpo".
- Cluster em `cpf_mask` (individual).
- FE típicos: `points_norm + claim_year` (ou `points_norm + claim_ym` em specs mais ricas).

## Convenções de output

- **Tabelas:** `.csv` para uso em R/python, `.tex` para incluir no paper. Nomes iguais com extensão diferente.
- **Figuras:** `.pdf` (preferido) e/ou `.png`. Nome descritivo (`bunching_men_post_reform.pdf`).
- **RData intermediários:** `.RData` em `output/rdata/`. **Anti-pattern:** salvar em `/tmp/` (não persistente) — ver caso do `new_counterfactual_claiming3_gabriel.R`.

## Typos conhecidos nos nomes de arquivos/outputs

| Arquivo/output | Typo | Correção sugerida |
|----------------|------|-------------------|
| `F7_counterfactual_pure_reforms_in_frequncies.R` | "frequncies" | → "frequencies" |
| `H3_policy_elasticity.R` gera `noyearr.pdf` | "noyearr" | → "noyear" |

**Não renomear sem antes verificar** se outros scripts referenciam esses nomes (busca por string literal em `.R` / `.do`).

## Hardcoded magic numbers (por tabela)

Os seguintes valores estão hardcoded no código — centralizar em um `constants.R` seria melhoria futura:

- **Replacement rates pré-reforma:**
  - Mulheres: `RR = 0.69 + 0.021·p`
  - Homens: `RR = 0.82 + 0.025·p`
- **Thresholds 85/95:** `p̄_women = 85`, `p̄_men = 95`.
- **Janela de bunching W = 4 pontos.**
- **γ (CRRA) = 4** baseline.
- **Data da reforma:** Jun/2015 (`treat = t ≥ 2015.5`).
- **Tax brackets 2015:** IRPF alíquotas e faixas — hardcoded em I4/I5.
- **Consumption quantiles ELSI/POF:** valores absolutos hardcoded.

## Encoding e locale

- Arquivos `.R` devem ser UTF-8.
- Alguns `.do` (legacy Stata) são em Latin-1 — cuidar ao abrir/editar.
- RAIS tem caracteres especiais em variáveis de município/nome; sempre ler com `encoding = "Latin1"` via `haven` ou `fread(..., encoding = "Latin-1")`.

## Git / versionamento

- Esta cópia local **não é** um working tree Git; é uma fotografia.
- O repositório canônico está no PC remoto. Ao propor mudanças, escrever diff em `.md` e discutir antes.

---

## 6. Estado do diretório e reorg notes

## Estado atual (20/abr/2026, pós-reorganização conservadora)

```
RA- Prev- JR-GG-GL/
├── Cálculos Juan Reunião 05032026.pdf      ← notas manuscritas escaneadas (OCR ruim)
├── _docs/                                   ← NOVO: memória do projeto para Claude/futuro
│   ├── CLAUDE.md
│   ├── REORG_SUGGESTIONS.md
│   └── memory/
│       ├── 01_project_overview.md
│       ├── 02_pipeline.md
│       ├── 03_pure_reforms_math.md
│       ├── 04_people_and_files.md
│       ├── 05_conventions.md
│       ├── 06_reorg_notes.md  (este arquivo)
│       ├── 07_open_issues.md
│       └── 08_surrogate_indexes.md
├── Surrogate Indices/
│   └── Potential Variables- Surrogate Indexes.docx
├── trans_retirement/
│   ├── code/                                ← 60+ scripts .R/.do (cópia local do PC remoto)
│   │   ├── A1..A4, B1..B4, C1..C6, D1..D4, E1..E4, F1..F7, G1..G6, H1..H3, I1..I5
│   │   ├── new_counterfactual_claiming*.R
│   │   ├── aux_codes_RAIS/                  ← helpers RAIS (incluindo Mappings_CBO)
│   │   └── old/
│   └── output/
│       ├── A/, C/, F/, G/, H/, I/          ← tabelas/figuras por letra
│       ├── E/                               ← (vazia nesta cópia)
│       └── new_counter_claiming/
│           └── actual_reform_gabriel/
├── versões do artigo/
│   ├── Paper versions/                      ← movido: PDFs de paper/NBER/grant
│   │   ├── Early_Retirement_Benefits_atualizado_11_11_2025.pdf
│   │   ├── NBER_Application_16_11_25.pdf
│   │   ├── NBER_Application_arthur_footnotes.pdf
│   │   └── grant_proposal_late_october.pdf
│   └── Presentations/                       ← movido: PDFs de apresentação
│       ├── Retirement_Presentations (10).pdf
│       └── paper_presentation_late_october.pdf
└── videos/
    ├── audio1795069851.m4a
    ├── Juan-lecture*.mp4 (x2)
    ├── video1795069851.mp4
    ├── video_reuniao_RA...
    └── recording.conf
```

## O que foi aplicado (conservador)

1. **Criada pasta `_docs/`** com `CLAUDE.md` (entry point) e subpasta `memory/` com 8 arquivos de contexto.
2. **Movidos PDFs** em `versões do artigo/` para as subpastas vazias já existentes (`Paper versions/`, `Presentations/`):
   - `Paper versions/`: Early_Retirement_Benefits_*, NBER_Application_*, grant_proposal_*.
   - `Presentations/`: Retirement_Presentations (10), paper_presentation_*.

Essas duas subpastas **já existiam** vazias; só foram populadas.

## O que NÃO foi aplicado (sugestões para discussão)

Documentadas em `_docs/REORG_SUGGESTIONS.md`. Resumo aqui:

### R1. Corrigir typo no nome de F7
`F7_counterfactual_pure_reforms_in_frequncies.R` → `..._in_frequencies.R`.
**Risco:** outro script pode chamar via `source("F7_...frequncies.R")`. Grep antes de renomear.

### R2. Padronizar paths U:/ vs F:/Users/tucalins/
Em código antigo convive `U:/Documents/...`; em novo, `F:/Users/tucalins/Documents/...`. Usar uma variável `BASE <- if (new) "F:/.../" else "U:/..."` no topo de cada arquivo, ou um `paths.R` compartilhado.

### R3. Extrair constants.R
Centralizar magic numbers: replacement rates, thresholds 85/95, γ, tax brackets 2015, janela de bunching. Reduz risco de divergência entre F7, G5, I5.

### R4. Deduplicar `fn_open_rais_*` em B4
B4 tem 4 funções `fn_open_rais_*` com estrutura idêntica, diferindo só por cohort de ano. Refatorar como uma função parametrizada.

### R5. Migrar `/tmp/` do new_counterfactual_claiming3_gabriel.R
Script salva RDatas em `/tmp/` (Linux) — não persistente entre sessões. `pure.R` depende desses arquivos. Substituir por path em `output/rdata/new_counterfactual/`.

### R6. Corrigir syntax error em D4
`D4_create_panel.R` linha 249: `)` solto logo após `gc()`. Se o script está rodando no PC remoto, é porque alguém comentou/ignorou; confirmar e limpar.

### R7. Consolidar versões históricas (E1..E4, F1..F7, etc.)
Versões antigas (E1, E2, F1..F5, G1..G4, H1..H2, I1..I3) ainda no diretório `code/`. Consider mover para `code/archive/` se não são mais usadas. **Só após auditar se algum output atual depende delas.**

### R8. Atualizar output/E/
A pasta `output/E/` não aparece na cópia local (não listada na árvore). Se E4 é canônico e gera plots, deveria haver `output/E/` populada. Verificar no PC remoto.

### R9. Corrigir typo `noyearr.pdf` em H3
Output gerado pelo H3 tem nome com typo.

### R10. Considerar mover `Cálculos Juan Reunião 05032026.pdf`
Está no root. Pode ir para `_docs/references/` ou `versões do artigo/meeting_notes/`. **Não movido por enquanto** — aguardando decisão.

## Checklist antes de aplicar sugestões R1–R10

Para cada sugestão:
1. Grep em `.R` e `.do` por string literal do arquivo sendo renomeado/movido.
2. Checar se algum LaTeX (`docs/`) importa output por path absoluto.
3. Rodar pipeline end-to-end no PC remoto antes de mergear.
4. Comunicar com Gabriel se o arquivo é dele.

## Regra geral

**Não renomear / não mover** sem grep prévio em `.R`/`.do`/`.tex` por referências ao nome. Prefire criar copy + deprecate old do que rename in-place.

---

## 7. Open issues e lacunas

Itens que precisam de decisão, input externo, ou investigação. Ordenados por criticidade.

## Críticos (bloqueiam trabalho atual)

### O1. `new_counterfactual_claiming3_gabriel.R` salva em `/tmp/`
- **Sintoma:** o script salva intermediários em `/tmp/` (Linux não persistente). `new_counterfactual_claiming3_pure.R` lê esses arquivos.
- **Risco:** se o PC remoto reinicia, ou se rodamos `pure.R` em sessão diferente, falha silenciosa.
- **Ação sugerida:** combinar com Gabriel um path persistente dentro de `output/rdata/new_counterfactual/`. Mudança pequena, alto impacto.

### O2. Seção 7.4 do paper vazia
- **Sintoma:** `Early_Retirement_Benefits_atualizado_11_11_2025.pdf` tem seção 7.4 "Disentangling bL and bS" como placeholder vazio.
- **Responsável:** Arthur (este é o deliverable atual).
- **Conteúdo a escrever:** derivação A1–A4 + fórmulas `PB_{p,t}`, `A_{p,t}` (ver `memory/03_pure_reforms_math.md`) + resultados de I5.

### O3. Syntax error em D4
- `D4_create_panel.R`, linha 249: `)` solto após `gc()`. 
- **Status:** se o script está rodando no PC remoto, é porque alguém comentou; mas no arquivo desta cópia a linha está presente.
- **Ação:** verificar estado real do arquivo no PC remoto. Se bug persiste, corrigir.

## Importantes (não bloqueiam mas impactam qualidade)

### O4. Cálculos Juan Reunião 05032026 — OCR ruim
- `Cálculos Juan Reunião 05032026.pdf` é scan de anotações manuscritas. OCR via pdftotext produz gibberish.
- **Ação:** pedir versão digital ao Juan (LaTeX, foto de lousa em resolução maior, ou transcrição).

### O5. Tax externality (τᵢᴾᴰⱽ) ainda não incorporada
- WMVPF atual (0.26) **não inclui** externalidade fiscal de impostos futuros.
- **Plano:** usar Surrogate Indexes (Athey et al. 2025) para estimar PDV de impostos futuros — ver `08_surrogate_indexes.md`.
- **Impacto esperado:** pode aumentar MVPF/WMVPF (ou reduzir, dependendo do sinal da resposta de labor supply).

### O6. Versões de código redundantes (E1..E4, F1..F5, etc.)
- Muitas versões antigas ainda em `code/`. Não sabemos se alguma é chamada por script atual.
- **Ação:** auditoria + movimentação para `code/archive/` se ok. (Sugestão R7 em 06_reorg_notes.)

### O7. Output `noyearr.pdf` em H3
- Typo no nome de output. Não bloqueia.
- **Ação:** renomear quando revisitar H3.

## Menores / estilo

### O8. Typo em nome do F7
- `F7_counterfactual_pure_reforms_in_frequncies.R` → `..._in_frequencies.R`.

### O9. Hardcoded magic numbers
- Replacement rates, thresholds, γ etc. espalhados pelos scripts. Centralizar em `constants.R`.

### O10. 4 funções `fn_open_rais_*` duplicadas em B4
- Refatorar como uma função parametrizada por cohort.

### O11. Inconsistência de paths U:/ vs F:/Users/tucalins/
- Scripts antigos vs novos. Gerenciar via variável de base path.

## Itens de produto / pesquisa (precisam de discussão com JR/GG/GL)

### P1. Bunching window W
- Baseline W=4 pontos. Testado? Em que range?
- **Perguntar a Juan/Gabriel:** qual é o range testado, e qual o efeito sobre WMVPF_bS?

### P2. Proportional mixing (A4)
- Assumida 50/50 (metade da cohort arrival, metade at-risk). 
- **Perguntar:** isso é motivado por algum modelo explícito ou escolha ad-hoc?

### P3. γ = 4
- Escolha CRRA baseline. Sensibilidade testada em [2, 6].
- **Perguntar:** existe justificativa baseada em lit de consumption (Attanasio et al.)?

### P4. Variáveis de Surrogate Index (RAIS)
- Lista aprovada em `Surrogate Indices/Potential Variables- Surrogate Indexes.docx`. Vetadas: worker_munic 2015+, raça, contractual wage.
- **Ação:** começar pipeline de construção τᵢᴾᴰⱽ quando Pure L/S estiver fechado.

### P5. Anticipation em Pure S: onde pivotar bS?
- Pivot point escolhido em `p̄` ou em algum ponto fixo abaixo?
- **Perguntar:** robustez a diferentes pivots.

## Decisões já tomadas (arquivo)

- F7 (frequências) é canônico, F6 (densidades) deprecated.
- γ = 4 baseline.
- Ref period = `p̄ − 2` no DiD (`i(points_norm, treat, ref=-2)`).
- Cluster em `cpf_mask` (individual).
- Reforma cutoff: Jun/2015 (`treat = t ≥ 2015.5`).

---

## 8. Surrogate Indexes (próxima fase)

## Objetivo

Estimar o **valor presente descontado (PDV) dos impostos futuros** pagos por indivíduo induzido a deferir claim pela reforma — `τᵢᴾᴰⱽ`. Hoje o WMVPF não inclui essa externalidade fiscal; com ela, o cálculo de welfare fica completo.

## Por que Surrogate Indexes?

Não dá para esperar 30+ anos de RAIS para observar `τᵢᴾᴰⱽ` real de quem claimou em 2015. Surrogate Indexes (Athey, Chetty, Imbens, Kang 2025) permitem **imputar** outcomes de longo prazo via combinação de:

1. **Cohort completa** (amostra histórica com outcome observado longo prazo) — uso RAIS 1995–2020 para treinar mapeamento `surrogates → outcome`.
2. **Cohort de interesse** (treatment/control do estudo) — aplico o mapeamento para projetar outcomes futuros.

A ideia é: uma combinação rica de surrogates de curto prazo (primeiros 2–5 anos após reforma) pode ser suficiente para reconstruir outcomes de longo prazo, se o mapeamento for estável.

## Estado atual da pasta `Surrogate Indices/`

Só tem um arquivo: `Potential Variables- Surrogate Indexes.docx` — lista de variáveis candidatas da RAIS, com marcação de aprovação.

### Variáveis aprovadas (pode usar)

| Variável | Descrição | Notas |
|----------|-----------|-------|
| município | município do emprego | Boa cobertura; usar `cod_muni_*` |
| tipo de contrato | CLT, temporário, estatutário, etc. | Categórica |
| gênero | F/M | |
| escolaridade | nível de instrução RAIS | Categórica |
| idade | ano do nascimento → idade | |
| wage options | vários: média, mínimo, máximo | Usar `remun_media`, `remun_dez_sm` |
| tenure | tempo de emprego no establishment | |
| contr_hours | horas contratuais | |
| occupation | CBO code | Mapeamentos em `aux_codes_RAIS/Mappings_CBO/` |

### Variáveis vetadas (não usar)

| Variável | Motivo do veto |
|----------|---------------|
| worker_munic (2015+) | Quebra de série após 2015; não comparável |
| raça | Cobertura ruim pré-2005 |
| contractual wage | Inconsistente entre cohorts |

## Pipeline proposto (esboço)

```
Passo 1 — Construir painel RAIS de longo prazo
   Input: RAIS 1995-2020 (worker-level)
   Output: painel com surrogates (listados acima) em t_claim, t_claim+1, ..., t_claim+k
           e outcome de longo prazo = Σ_{s=t_claim+k}^{t_claim+T} tax_paid(s)

Passo 2 — Treinar mapeamento surrogates → outcome
   Usar cohort histórica (ex.: claims 2001-2005, que têm 15+ anos de RAIS pós-claim)
   Modelo: random forest / LASSO / ElasticNet — ver Athey et al. 2025 para pros/cons
   Target: τ_i^PDV (descontado a r=3% a.a. ou taxa real de juros brasileira)

Passo 3 — Aplicar mapeamento à cohort 2015-2019
   Input: surrogates de curto prazo (2015-2019 + 0..5 anos futuro observados)
   Output: τ_i^PDV imputado para cada claimant do período de interesse

Passo 4 — Incorporar no WMVPF
   Net cost = Δbenefits − Δtaxes_PDV (até agora estávamos usando só impostos correntes)
   Atualizar I5 com τ_i^PDV imputado.
```

## Discount rate

Para PDV de impostos futuros, precisa de discount rate. Candidatos:
- r = 3% real (Hendren-Sprung-Keyser 2020 usa isso)
- r = taxa Selic real (ex.: 5-7% no BR histórico)
- Sensibilidade em [2%, 6%]

**Discutir com Juan.** Provavelmente usar 3% baseline com sensibilidade a 5%.

## Questões pendentes

1. **Cohort de treino:** usar quais anos? Idealmente 2001–2005 (15+ anos pós-claim observados). Mas temos RAIS até 2020 — então cohort 2001 tem 19 anos; cohort 2005 tem 15; cohort 2010 tem 10.
2. **Horizonte T:** até quantos anos queremos projetar? Provavelmente até idade 80 do claimant (vida esperada).
3. **Modelo ML:** Athey et al. 2025 recomendam double/debiased ML. Mas precisamos da simples outcome prediction, não ATE. LASSO pode bastar.
4. **Inclusão de emprego informal:** RAIS só cobre formal. Como tratar quem sai para informal pós-claim? Tax contribution = 0 no informal.
5. **Heterogeneidade:** τ_i^PDV deve ser estimado por gênero × idade × setor separadamente (modelo interagido).

## Marcos

- **Q2 2026:** finalizar Pure L/S (I5 + seção 7.4 do paper).
- **Q3 2026:** começar Surrogate — construir painel RAIS de longo prazo.
- **Q4 2026:** τ_i^PDV imputado + WMVPF atualizado.

Ver `grant_proposal_late_october.pdf` para deliverables formais.

