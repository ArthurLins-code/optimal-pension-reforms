# 07 — Open issues e lacunas

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

### O5a. G5 bug: MECH usa `claims_L`/`claims_S` em vez de `claims_c` (linha 614)
- **Arquivo:** `G5_effect_average_benefit_freq_bL_and_bS.R`, linha 614.
- **Sintoma:** a computação do efeito mecânico (MECH) usa `claims_L` e `claims_S` (claims separados por pure reform) em vez de `claims_c` (claims do contrafactual combinado).
- **Impacto:** não afeta I6 (que computa WMVPF independentemente), mas pode afetar valores internos do G5 usados nos slides.
- **Descoberto em:** Phase 6, rewrite de I6 (mai/2026).

### O5b. G5 bug: parenthesização errada na fórmula WMVPF (linha 765)
- **Arquivo:** `G5_effect_average_benefit_freq_bL_and_bS.R`, linha 765.
- **Sintoma:** agrupamento incorreto na fórmula de WMVPF.
- **Impacto:** mesmo que O5a — não afeta I6, mas pode afetar valores nos slides.
- **Descoberto em:** Phase 6, rewrite de I6 (mai/2026).

### O5c. G5 bug: lê `delta_ben` de G2 (density-based) com fator ×3 (linhas 732–734)
- **Arquivo:** `G5_effect_average_benefit_freq_bL_and_bS.R`, linhas 732–734.
- **Sintoma:** G5 lê `delta_ben` do output de G2, que usa estimação density-based com fator de escala ×3. Isso é inconsistente com a abordagem frequency-based do restante do pipeline.
- **Impacto:** pode afetar valores de WMVPF_bL/bS nos slides.
- **Descoberto em:** Phase 6, rewrite de I6 (mai/2026).

### ⚠️ Questão aberta sobre origem dos valores canônicos
- Os valores WMVPF_bL=0.68 e WMVPF_bS=0.71 nos slides canônicos vieram da computação interna do G5 ou de um I-stage (I3/I5)?
- Se vieram do G5, os bugs O5a–O5c podem afetar esses números.
- **Ação:** investigar provenance dos valores nos slides antes de corrigir G5.

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

### O12. Stale worktree metadata dirs in `.git/worktrees/`
- **Sintoma:** 3 diretórios órfãos em `.git/worktrees/` (`ecstatic-lederberg-fc835b`, `interesting-engelbart-520505`, `stupefied-nightingale-3dbe65`) não puderam ser deletados por lock do OneDrive.
- Git já não os rastreia (`git worktree prune` marcou como inválidos, mas falhou ao deletar).
- **Ação:** deletar manualmente pelo File Explorer (ou pausar OneDrive sync antes). Depois rodar `git worktree prune` para confirmar.
- **Também:** deletar worktree `naughty-bardeen-3342ff` e branch `claude/naughty-bardeen-3342ff` quando a sessão Claude Code que o criou terminar.

## Decisões já tomadas (arquivo)

- F7 (frequências) é canônico, F6 (densidades) deprecated.
- γ = 4 baseline.
- Ref period = `p̄ − 2` no DiD (`i(points_norm, treat, ref=-2)`).
- Cluster em `cpf_mask` (individual).
- Reforma cutoff: Jun/2015 (`treat = t ≥ 2015.5`).
