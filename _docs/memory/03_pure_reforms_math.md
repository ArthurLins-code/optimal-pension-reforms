# 03 — Matemática das reformas Pure L e Pure S

Este arquivo detalha as assunções (A1–A4), as fórmulas de contrafactual em frequências (F7 / new_counterfactual_claiming3_pure.R), e a derivação de WMVPF_bL / WMVPF_bS. Notação segue a apresentação 15/mai/2026 (`Retirement_Presentations (10).pdf`) e o paper.

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

## Números da apresentação (15/mai/2026)

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
