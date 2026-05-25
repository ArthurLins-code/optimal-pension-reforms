# 08 — Surrogate Indexes (próxima fase)

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
