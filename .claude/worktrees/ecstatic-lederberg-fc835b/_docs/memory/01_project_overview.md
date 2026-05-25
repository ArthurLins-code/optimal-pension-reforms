# 01 — Project Overview

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
