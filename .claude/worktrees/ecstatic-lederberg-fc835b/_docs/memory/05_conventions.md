# 05 — Convenções de código e dados

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
