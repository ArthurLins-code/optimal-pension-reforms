# 04 — Pessoas, papéis e arquivos

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
- **`Retirement_Presentations (8).pdf`** — **mais recente (20/abr/2026)**. É a referência canônica para números-âncora atuais.
- Versões anteriores: `Retirement_Presentations (1).pdf` até `(7).pdf` — presas para comparação histórica.
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
