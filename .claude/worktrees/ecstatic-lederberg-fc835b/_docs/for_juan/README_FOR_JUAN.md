# Contexto do projeto Optimal Pension Reforms — para o Juan

Olá Juan,

Este é um bundle de contexto que eu (Arthur) organizei sobre o projeto **"Optimal Pension Reforms: An Application to the Brazilian Administrative Data"**. A ideia é que você possa plugar isto no Codex do ChatGPT (ou qualquer AI que leia filesystem) e a IA já tenha contexto completo do paper, pipeline, decisões metodológicas, e estado atual, sem precisar de briefing longo.

**Importante:** todo o texto está escrito do meu ponto de vista (RA). Sinta-se livre para reescrever / adaptar. As conclusões, números e decisões metodológicas são documentadas conforme eu entendi — se alguma coisa estiver errada, me avise.

---

## Como usar com o Codex do ChatGPT

O Codex lê o diretório de trabalho. Há duas formas de plugar o bundle:

### Opção A — Drop-in no seu projeto (recomendado)

1. Coloque esta pasta `for_juan/` dentro do diretório onde o Codex abre o projeto (ao lado de `trans_retirement/`, por exemplo).
2. No primeiro turno, diga ao Codex:
   > "Leia `for_juan/README_FOR_JUAN.md` e os arquivos em `for_juan/memory/` antes de responder qualquer pergunta sobre este projeto."
3. O Codex vai indexar tudo e ter o contexto.

### Opção B — Workspace dedicado só de contexto

1. Abra um workspace separado só com a pasta `for_juan/`.
2. Use esse workspace para perguntas conceituais (teoria, decisões, status).
3. Para perguntas de código, abra o workspace com `trans_retirement/` e o Codex lê os scripts diretamente.

### Mensagem de abertura sugerida (copiar/colar no Codex)

```
Contexto: leia for_juan/README_FOR_JUAN.md e os 8 arquivos em for_juan/memory/ antes de responder. Esse é o projeto Optimal Pension Reforms (Gonzaga/Rios/Lemos) sobre a reforma previdenciária brasileira de 2015. O paper está na versão Early_Retirement_Benefits_atualizado_11_11_2025.pdf. O foco atual é decomposição das reformas Pure L (level) e Pure S (slope) do benefício, e a próxima fase é Surrogate Indexes para impostos futuros.

Sempre cite o arquivo de memória específico (ex.: "per memory/03_pure_reforms_math.md, assumption A4 é ...") ao fazer afirmações sobre o projeto, para eu conferir.
```

---

## O que tem no bundle

```
for_juan/
├── README_FOR_JUAN.md         ← este arquivo
├── FILE_INDEX.md              ← onde cada PDF/script importante mora (no SEU drive)
├── PROJECT_CONTEXT.md         ← versão consolidada single-file (paste-ready em chat)
└── memory/
    ├── 01_project_overview.md     ← setting, modelo MVPF/WMVPF, dados, literatura
    ├── 02_pipeline.md             ← pipeline A..I + new_counterfactual_*
    ├── 03_pure_reforms_math.md    ← matemática Pure L / Pure S (A1..A4, fórmulas)
    ├── 04_people_and_files.md     ← quem faz o quê no time
    ├── 05_conventions.md          ← convenções de código, paths, DiD syntax, typos
    ├── 06_reorg_notes.md          ← estado do diretório, sugestões não aplicadas
    ├── 07_open_issues.md          ← lacunas, bugs conhecidos, itens a discutir
    └── 08_surrogate_indexes.md    ← próxima fase (τᵢᴾᴰⱽ)
```

### Qual arquivo ler primeiro

- **Visão geral em 3 min:** só `README_FOR_JUAN.md` + primeira seção de `PROJECT_CONTEXT.md`.
- **Para entender o paper:** `memory/01` + `memory/03`.
- **Para mexer no código:** `memory/02` + `memory/05`.
- **Para saber o que está aberto / pendente:** `memory/06` + `memory/07`.
- **Para a próxima fase (Surrogate):** `memory/08`.

---

## Resumo executivo em 200 palavras

O paper mede o efeito de bem-estar da reforma previdenciária brasileira de Jun/2015 (fórmula 85/95 progressiva) via MVPF/WMVPF (Hendren-Sprung-Keyser 2020; Bergstrom et al. 2026 para a versão weighted). O estimativo atual (apresentação 20/abr/2026) é **MVPF ≈ 0.31, WMVPF ≈ 0.26** (ainda sem externalidade fiscal de impostos futuros — vem via Surrogate Indexes).

O ponto central é decompor a reforma em componentes **Pure L** (só ΔbL, nível pós-threshold) e **Pure S** (só ΔbS, inclinação pós-threshold) e calcular WMVPF separado por componente. Estimativas correntes: **WMVPF_bL ≈ 0.68 < WMVPF_bS ≈ 0.71**. Isso implica que a reforma local ótima é `↑ bS, ↓ bL` — **direção oposta** à reforma de 2015 (que fez `↑ bL, ↓ bS`). Numericamente: ΔbS\* = +0.081 (+350%), ΔbL\* = −R$791 (−26%), budget-neutral.

Arquivos canônicos no pipeline: `F7_counterfactual_pure_reforms_in_frequncies.R` (typo no nome), `G5`/`G6`, `I5_wmvpf_w_pure_reforms_freq.R`, e a versão mais nova `new_counterfactual_claiming3_{gabriel,pure}.R` onde gabriel.R gera upstream e pure.R (meu) decompõe.

Lacunas críticas: Seção 7.4 do paper vazia, `/tmp/` não-persistente em gabriel.R, syntax error em D4 linha 249.

---

## Como manter atualizado

Sempre que mudar algo importante (fórmula, número-âncora, arquivo canônico), posso regenerar este bundle. A fonte de verdade está no meu OneDrive em `_docs/` — este `for_juan/` é um snapshot.

Qualquer correção ou inconsistência que a IA apontar, me avisa — vou atualizar na origem.

— Arthur
