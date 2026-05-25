# Índice de arquivos externos (no drive do Juan)

Este bundle **não inclui** os PDFs do paper nem os scripts. O Juan já tem tudo no próprio drive / PC remoto. Este arquivo é só um mapa para a IA saber o que procurar e onde.

## Papers e apresentações

Localização provável: pasta compartilhada `versões do artigo/` (ou equivalente no drive do Juan).

| Arquivo | Papel | Notas |
|---------|-------|-------|
| `Paper versions/Early_Retirement_Benefits_atualizado_11_11_2025.pdf` | **Versão mais recente do paper.** | Seção 7.4 ("Disentangling bL and bS") **VAZIA** — é o que Arthur está escrevendo. Seções 1–6 completas. |
| `Paper versions/NBER_Application_16_11_25.pdf` | NBER application (versão clean) | Números-âncora ali são mais antigos (MVPF ≈ 0.21); usar apresentação 8 para números atuais. |
| `Paper versions/NBER_Application_arthur_footnotes.pdf` | NBER application com footnotes que Arthur adicionou | |
| `Paper versions/grant_proposal_late_october.pdf` | Grant proposal (fim out/2025) | Contém deliverables Q1–Q3 2026 sobre Pure L/S + Surrogate. |
| `Presentations/Retirement_Presentations (8).pdf` | **Apresentação mais recente, 20/abr/2026** | **Fonte canônica dos números-âncora atuais**: MVPF 0.31, WMVPF 0.26, WMVPF_bL 0.68, WMVPF_bS 0.71. |
| `Presentations/paper_presentation_late_october.pdf` | Apresentação de out/2025 | Histórica. |

## Notas de reunião

| Arquivo | Notas |
|---------|-------|
| `Cálculos Juan Reunião 05032026.pdf` | No root do drive. OCR ruim (manuscrito escaneado). Arthur sugere pedir versão digital. |

## Surrogate Indexes (próxima fase)

| Arquivo | Notas |
|---------|-------|
| `Surrogate Indices/Potential Variables- Surrogate Indexes.docx` | Lista de variáveis RAIS candidatas. Aprovadas e vetadas listadas em `memory/08_surrogate_indexes.md`. |

## Código (PC remoto do Juan/Gabriel)

Paths no PC remoto:
- `U:/Documents/trans_retirement/...` (scripts antigos)
- `F:/Users/tucalins/Documents/trans_retirement/...` (scripts novos do Arthur)
- Juan provavelmente tem seu próprio path — substituir conforme necessário.

Estrutura canônica (ver `memory/02_pipeline.md` para detalhes):

```
trans_retirement/
├── code/
│   ├── A4_balance_check.R
│   ├── B4_create_clean_candidates_cross.R
│   ├── C6_estimate_continuous_contrib.R
│   ├── D4_create_panel.R                             ← syntax error linha 249 (ver memory/07)
│   ├── E4_plots_claiming_distributions.R
│   ├── F7_counterfactual_pure_reforms_in_frequncies.R   ← canônico (F)
│   ├── G5_effect_average_benefit_freq_bL_and_bS.R   ← canônico G (benefit)
│   ├── G6_effect_expenditures_freq_bL_and_bS.R      ← canônico G (expenditures)
│   ├── H3_policy_elasticity.R
│   ├── I5_wmvpf_w_pure_reforms_freq.R                ← canônico (I)
│   ├── new_counterfactual_claiming3_gabriel.R       ← upstream (Gabriel)
│   ├── new_counterfactual_claiming3_pure.R          ← downstream (Arthur) — depende de gabriel.R
│   └── aux_codes_RAIS/                               ← helpers RAIS, Mappings_CBO/
├── data/                                             ← intermediários .rds
└── output/
    ├── tables/
    ├── figures/
    └── rdata/
```

## Como referenciar na IA

Quando a IA do Juan precisar dos números atuais:
> "Leia `Presentations/Retirement_Presentations (8).pdf` para os números-âncora."

Quando precisar entender a matemática da decomposição:
> "Leia `memory/03_pure_reforms_math.md` (está no for_juan/) e confira contra Seção 7 de `Paper versions/Early_Retirement_Benefits_atualizado_11_11_2025.pdf`."

Quando precisar auditar código:
> "Leia `memory/02_pipeline.md` e depois abra o script canônico `trans_retirement/code/I5_wmvpf_w_pure_reforms_freq.R` no seu PC."
