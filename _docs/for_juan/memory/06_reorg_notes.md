# 06 — Estado do diretório e notas de reorganização

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
