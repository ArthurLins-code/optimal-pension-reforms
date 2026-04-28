# Sugestões de reorganização e limpeza (não aplicadas)

Este documento lista melhorias **ainda não executadas**, ordenadas por risco/benefício. Cada item tem: (1) o que fazer; (2) por quê; (3) risco e dependências; (4) como verificar antes de aplicar.

Tudo isso **afeta o PC remoto**, não apenas esta cópia local. Recomenda-se discutir com Juan/Gabriel antes.

---

## Já aplicado (conservador) em 20/abr/2026

| # | Mudança | Onde |
|---|---------|------|
| A1 | Criada pasta `_docs/` com `CLAUDE.md` + `memory/` (8 arquivos) | `_docs/` |
| A2 | Movidos PDFs de `versões do artigo/` raiz para subpastas vazias `Paper versions/` e `Presentations/` | `versões do artigo/` |

---

## Sugestões não aplicadas — código

### R1. Corrigir typo em `F7_counterfactual_pure_reforms_in_frequncies.R`

- **O quê:** renomear para `F7_counterfactual_pure_reforms_in_frequencies.R`.
- **Por quê:** clareza e consistência.
- **Risco:** algum script antigo pode carregar via `source("...frequncies.R")` hardcoded.
- **Como verificar:**
  ```bash
  grep -r "frequncies" trans_retirement/code/
  grep -r "frequncies" trans_retirement/docs/
  ```
- **Se o grep retornar nada externo, renomear.**

### R2. Padronizar paths `U:/` vs `F:/Users/tucalins/`

- **O quê:** introduzir um `paths.R` que exporta `BASE_DATA`, `BASE_OUTPUT`, etc., e cada script abre com:
  ```r
  source("paths.R")
  file.path(BASE_DATA, "suibe.rds")
  ```
- **Por quê:** migrar de PC (ex. de remoto atual para novo) vira mudança de 1 arquivo.
- **Risco:** alto se feito em batch. Fazer gradualmente, começando pelos scripts novos (`new_counterfactual_*`).

### R3. Extrair `constants.R`

- **O quê:** arquivo único com:
  ```r
  P_BAR_WOMEN  <- 85
  P_BAR_MEN    <- 95
  RR_ALPHA_W   <- 0.69;  RR_SLOPE_W <- 0.021
  RR_ALPHA_M   <- 0.82;  RR_SLOPE_M <- 0.025
  REFORM_DATE  <- as.Date("2015-06-01")
  BUNCHING_W   <- 4
  GAMMA        <- 4
  DISC_RATE    <- 0.03
  ```
- **Por quê:** evitar que F7, G5, I5 divirjam em valores hardcoded.
- **Risco:** baixo. Fazer em paralelo com refatoração mínima.

### R4. Deduplicar `fn_open_rais_*` em B4

- **O quê:** B4 tem 4 funções `fn_open_rais_*` idênticas exceto pelo cohort. Converter para:
  ```r
  fn_open_rais <- function(cohort_year, vars_to_keep, ...) { ... }
  ```
- **Por quê:** 4 funções = 4 lugares para propagar bugs.
- **Risco:** baixo se cuidadoso; uso local.

### R5. Migrar `/tmp/` do `new_counterfactual_claiming3_gabriel.R`

- **O quê:** substituir `saveRDS(..., "/tmp/intermediate.rds")` por path persistente.
- **Por quê:** `/tmp/` é volátil. Se gabriel.R roda hoje e pure.R roda amanhã (reboot entre), pure.R quebra.
- **Risco:** zero. Mudança pequena.
- **Ação:** combinar com Gabriel onde persistir. Sugestão: `output/rdata/new_counterfactual/`.

### R6. Corrigir syntax error em `D4_create_panel.R` linha 249

- **O quê:** `)` solto imediatamente após `gc()`. Remover.
- **Por quê:** script não parseia puro; deve estar rodando com workaround.
- **Risco:** zero se o parêntese é órfão. Verificar contexto:
  ```bash
  sed -n '240,255p' trans_retirement/code/D4_create_panel.R
  ```

### R7. Arquivar versões antigas de scripts

- **O quê:** mover `E1..E3`, `F1..F5`, `G1..G4`, `H1..H2`, `I1..I3`, `C1..C5`, `D1..D3`, `A1..A3`, `B1..B3` para `code/archive/`.
- **Por quê:** listar mais curto em IDE; reduzir confusão sobre qual versão é atual.
- **Risco:** médio-alto. Alguma versão antiga pode ser referenciada por um script que ainda uso.
- **Como verificar:**
  ```bash
  # Para cada arquivo a arquivar, conferir que não é chamado:
  for f in E1 E2 E3 F1 F2 F3 F4 F5 G1 G2 G3 G4 H1 H2 I1 I2 I3 C1 C2 C3 C4 C5 D1 D2 D3 A1 A2 A3 B1 B2 B3; do
    grep -r "$f" trans_retirement/code/ --exclude-dir=old | grep -v "^trans_retirement/code/${f}_"
  done
  ```

### R8. Output `noyearr.pdf` de H3

- **O quê:** corrigir typo no nome de saída (deve ser `noyear.pdf`).
- **Por quê:** estético / clareza.
- **Risco:** zero se nenhum LaTeX puxa esse pdf por nome.
- **Como verificar:**
  ```bash
  grep -r "noyearr" trans_retirement/ docs/
  ```

### R9. Consolidar `aux_codes_RAIS/`

- **O quê:** `trans_retirement/code/aux_codes_RAIS/` tem `Sample_RAIS_arthur.do`, `Puxa RAIS.do` (com espaço no nome!), `Build_*_panel.do`, `join_rais_few_vars.R`, subpasta `Mappings_CBO/`. Mistura R e .do, português e inglês, nomes com espaço.
- **Por quê:** espaços em filename quebram shell scripts; mistura de linguagens dificulta navegação.
- **Ação sugerida:** renomear `Puxa RAIS.do` → `pull_rais.do`; padronizar inglês; manter `Mappings_CBO/` como está (tem estrutura própria `code/input/output/`).

### R10. Mover `Cálculos Juan Reunião 05032026.pdf`

- **Está no root** da pasta. Não tem um lar óbvio.
- **Opções:** (a) deixar no root; (b) mover para `_docs/references/`; (c) criar `versões do artigo/meeting_notes/`.
- **Não aplicado** aguardando input.

---

## Sugestões não aplicadas — paper / deliverables

### R11. Preencher Seção 7.4 do paper

- `Early_Retirement_Benefits_atualizado_11_11_2025.pdf` tem Seção 7.4 vazia.
- Conteúdo base está em `_docs/memory/03_pure_reforms_math.md`: assunções A1–A4, fórmulas para `PB_{p,t}` e `A_{p,t}`, resultados de I5.
- Tradução para LaTeX + tables de WMVPF_bL/bS.

### R12. Pedir versão digital dos "Cálculos Juan" a Juan

- PDF atual é OCR de manuscrito, qualidade baixa.
- Pedir: planilha, foto de resolução maior, ou transcrição.

### R13. Verificar estado do `output/E/`

- Em `trans_retirement/output/` esta cópia não tem pasta `E/`. Se E4 é o script canônico de plots, deveria existir.
- Checar no PC remoto.

---

## Sugestões não aplicadas — estrutura de diretório

### R14. Consolidar `Surrogate Indices/` em `trans_retirement/surrogate/`

- Hoje `Surrogate Indices/` está no root do projeto. Quando começar a escrever código, faria sentido ficar dentro de `trans_retirement/` (onde o pipeline vive).
- Aguardar início do trabalho de código para mover.

### R15. `videos/` tem arquivos grandes (> 100 MB cada)

- 5 arquivos totalizando ~800 MB. Ocupa OneDrive.
- Considerar: (a) mover para armazenamento separado; (b) transcrever vídeos de reunião e manter só as transcrições + vídeos em outro storage.
- Baixa prioridade, só se ficar apertado em espaço.

---

## Ordem sugerida para aplicar

Do mais seguro para o mais arriscado:

1. **R6** (fix D4 syntax) — zero risco, alto valor.
2. **R5** (migrar /tmp/) — zero risco com Gabriel concordando.
3. **R12** (pedir Cálculos Juan digital) — não-técnico.
4. **R3** (constants.R) — risco baixo, refatoração incremental.
5. **R1, R8** (typos) — após grep confirmar não-referenciado.
6. **R11** (seção 7.4) — trabalho de conteúdo, não structural.
7. **R4** (deduplicar fn_open_rais) — refactor local.
8. **R2** (paths.R) — fazer gradual.
9. **R7** (arquivar versões antigas) — alto risco, fazer por último.
10. **R9, R10, R14, R15** — cosméticas / estrutural; fazer quando conveniente.
