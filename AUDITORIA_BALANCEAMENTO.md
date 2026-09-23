# AUDITORIA DE BALANCEAMENTO DE DANO — Avatar Eclipse (TFS 1.4.2)

> Documento de auditoria.
>
> **STATUS: o modelo v2 foi APLICADO** (ver §14 — arquivos alterados, comandos de
> verificação e o que ficou pendente). O que este documento descreve como "hoje"
> é o servidor **antes** da aplicação; as "recomendações" que já foram executadas
> estão marcadas no §14.

---

## 0. Método e fontes

| O que | Onde foi lido |
|---|---|
| Curvas de HP / mana / XP / bend | `sources/player.cpp`, `sources/player.h`, `sources/iologindata.cpp`, `sources/vocation.cpp`, `sources/creature.cpp`, `data/XML/vocations.xml`, `config.lua` |
| Pipeline de dano | `data/lib/avatar lib.lua`, `data/lib/201-spellsExausted.lua`, `data/spells/lib/spellStages.lua` |
| Fórmula de cada magia | `data/spells/scripts/{fire,water,air,earth}/*.lua` (147 scripts) |
| Level / mana / CD / área | `data/spells/spells.xml` + tabelas `*Exausted` |
| Medição de dano | `tools/spell_balance_report.pl` (ferramenta do próprio projeto) + correções minhas |
| Talentos / passivas / proficiência | `data/lib/talentTree.lua`, `talentPassives.lua`, `creaturescripts/scripts/proficiencyCombat.lua`, `criticalOnAttack.lua` |
| Criaturas e faixas de caça | `data/monster/**/*.xml` (95 arquivos), `data/huntwaypoint/*.lua` |
| Bend / atributos | `data/talkactions/scripts/atributos/add.lua`, `onAdvance.lua`, `pedraElemental.lua` |

Duas correções importantes foram aplicadas nas medições da ferramenta do projeto
(ver Problema **P13**): o cooldown real (tabelas `*Exausted`, não o primeiro
`*Exausted.X` que aparece no script) e o eco do estágio ELITE (nível 100+), que
multiplica por 2 o dano de várias magias e **não** é contado pelo relatório.

---

## 1. De onde vem o dano final (pipeline completo)

```
formula da magia (level)                     onGetPlayerMinMaxValues(cid, level, magLevelUnused)
        x  atk/100 + 1                       data/lib/201-spellsExausted.lua -> spellsInfo["<magia>"].atk
        -> remakeValue(elemId, dano, cid)    (ou remakeAirEarth para ar/terra)
             |- debuff de jump               getPlayerStorageValue("debuffValue")  (-10% a -30%)
             |- talentBendDmgBonus           (talent tree, +%)
             |- orbita/cometa (storage 57302) fogo +20% | agua +20% | eclipse -20%
             |- storage 90526i1              +5%
             |- red skull                    divide por 4
             `- applySpellBalance(cid, value, elemento):
                   x SPELL_BALANCE[elemento]  fire 0.9827 | water 1.0847 | air 1.1915 | earth 1.0453
                   x getElementLevelScaling   (TABELA VAZIA -> 1.0)
                   x getSpellLevelCurve(level) 1.00 ate' 10; 0.66@25; 0.53@50; 0.50@100; 0.54@200
                   x getBendDamageBonus       1 + 0.04 * bend      (x3.00 em bend 50, x5.00 em bend 100)
        -> engine                            defesa/armadura do alvo, condicoes, onStatsChange
             |- proficiencyCombat            damageReduction + talentArmor (teto 99%), life/mana leech, burn
             |- talentPassives                dodge 5-10% (ar), heal crit (agua)
             `- spellStages                   ELITE (level 100+): magia de alvo unico ECOA = 2x dano
        -> crit                              config: 1% / x1.30  |  auto-attack: 2.5+atk*0.2 % (criticalOnAttack.lua)
```

Pontos que precisam ficar claros:

1. **O fator de elemento e o bend só valem para `isPlayer`.** Monstros, summons e
   dano de arma não passam por `applySpellBalance` (`if not (cid and isPlayer(cid)) then return value`).
2. **Magia nenhuma usa Magic Level na fórmula.** O script `tools/apply_level_scaling.pl`
   trocou `magLevel` por `level * 0.5`. Isso foi feito para o bend não entrar duas
   vezes (uma na fórmula, outra no multiplicador final). Só 2 scripts fora do padrão
   foram encontrados, e são monstros/antigos (`monster/inferno.lua`, `fire/thunderstorm old.lua`).
3. **O nível entra em todo lugar pela fórmula linear `level + ((level*0.5)/k)*c`**,
   ou seja ~3x a 5x o level. Depois a `SPELL_BALANCE_LEVEL_CURVE` **divide esse valor
   por ~2** a partir do level 25.
4. **O estágio ELITE dobra o dano** de toda magia registrada com `registerSpellStageEcho`
   (ver P5) — é a variável mais mal distribuída do sistema hoje.

---

## 2. Medições reais — dano por magia a nível 100 / bend 50

Mediana por elemento (uma aplicação, sem eco/`*` = com eco 2x):

| Vocação | magias | mediana | top-3 burst | DPS de rotação | melhor DPS | pior DPS |
|---|---|---|---|---|---|---|
| fire  | 15 | 641 | 2.440 | 1.736 | 363 (blast) | 12 (meteor) |
| water | 15 | 629 | 2.434 | 1.422 | 328 (explosion) | 11 (control) |
| air   | 14 | 649 | 2.290 | 1.603 | 344 (gale) | 14 (barrier) |
| earth | 13 | 642 | 2.306 | **3.256** | 567 (growth) | 17 (lavaball) |

O dano por cast é **igual em todas as vocações por construção** (a `SPELLBAR` foi
calibrada assim). O que quebra o balanceamento é o resto: cooldown, eco e número de hits.

Dentro da **mesma** vocação (fire, L100/bend50):

| Magia | nível | CD | dano/cast | DPS |
|---|---|---|---|---|
| fire blast | 16 | 2s | 726 | **363** |
| fire kick | 8 | 3s | 659 | 220 |
| fire thunderbolt | 70 | 12s | 766 | 64 |
| fire explosion | 110 | 25s | 936 | 37 |
| fire striker | 90 | 45s | 845 | 19 |
| fire discharge | 200 | 60s | 690 | 11,5 |
| fire conflagration | 250 | 90s | 741 | **8,2** |

**A curva está invertida**: a magia de level 16 entrega 44x o DPS da ultimate de level 250.

---

## 3. Curvas de personagem (medidas no C++)

| Grandeza | Fórmula | L1 | L25 | L50 | L75 | L100 | L150 | L200 |
|---|---|---|---|---|---|---|---|---|
| HP | `150 + 30*(L-1)` | 150 | 870 | 1.620 | 2.370 | **3.120** | 4.620 | 6.120 |
| Mana máx | `5*(L-1)` | 0 | 120 | 245 | 370 | **495** | 745 | 995 |
| Bend esperado* | ver §5 | 0 | 29 | 35 | 42 | **48** | 56 | 62 |
| XP acumulado do nível | `(50(L-1)³-150(L-1)²+400(L-1))/3` (`Player::getExpForLevel`) | 0 | 204.800 | 1.847.300 | 6.489.800 | **15,7M** | 54,0M | 129,4M |
| XP para o nível seguinte | diferença da linha acima | 100 | 27.700 | 117.700 | 270.200 | **485.200** | 1,10M | 1,97M |
| XP de monstro (exemplo) | tabela de criaturas | 980 | 1.325 | 5.500 | 2.200 | 18.000 | 8.000 | 13.000 |
| XP/hora efetivo (melhor spot) | `x rateExperience = 1` | — | — | — | — | **7,1 níveis/h** (~964 xp/s) | — | — |

\* ponto único: 1 ponto de atributo por level + 1 por pedra elemental, gasto todo em bend.
**Todos os números de XP deste documento assumem `rateExperience = 1`** (o `200`
que está no `config.lua` é valor de teste — ver P10). É esse valor que faz o bend
seguir o level (≈1 ponto por level ⇒ bend 48 @ L100), que é a base das §4 e §5.

Observações de engine:

- **Criação de personagem: um char novo (level 8, `newPlayerLevel = 8`) nasce com
  `manaMax = 0`.** `iologindata.cpp` soma `rookVoc->getGain(GAIN_MANA)` (= 0 em
  `vocations.xml`) para os 7 primeiros levels e só usa a vocação real em `level > 8`.
  Resultado: **personagem novo não consegue conjurar nada** (não há mana máxima para
  ser replenada) até subir 1 level. Ver P1.
- Mana regen: 5 a cada 2s (`manaRegen.lua`) + comida (HP 5/s).
- Poção de mana grande (`7590`): 3 ticks de 140 = **420 de mana por ~1s**.
  Ou seja, **mana não é limitador** — o limitador real é o cooldown + a exaustão global de 800ms.

---

## 4. Simulações de progressão (sistema ATUAL)

Mediana de dano por aplicação (com eco já aplicado no level 100+), por level x bend:

| Bend ↓ / Level → | 1 | 10 | 25 | 50 | 75 | 100 | 150 | 200 |
|---|---|---|---|---|---|---|---|---|
| **0**  | 14 | 50 | 73 | 104 | 164 | 215 | 338 | 458 |
| **10** | — | 66 | 102 | 146 | 229 | 300 | 474 | 640 |
| **25** | — | 89 | 146 | 210 | 323 | 427 | 676 | 913 |
| **50** | 36 | 128 | 220 | 303 | 481 | 640 | 1.015 | 1.344 |
| **75** | — | 168 | 294 | 404 | 642 | 854 | 1.353 | 1.826 |
| **100**| 55 | 208 | 366 | 505 | 803 | 1.068 | 1.692 | 2.282 |

Leitura:

- **De bend 0 para bend 50 o dano triplica** em qualquer level. Bend domina o level.
- De level 25 para level 100 (bend fixo 0) o dano cresce 2,9x — 75 levels valem menos
  que 25 pontos de bend.
- De level 1 a 25 (bend 0) cresce 5x. O começo é bom, o meio é plano (a
  `LEVEL_CURVE` corta), e o fim acelera de novo (bend + level).

DPS de rotação (soma de dano/CD de todas as magias liberadas, bend de referência):

| Level | fire | water | air | earth | HP do player | HP/DPS (pior caso) |
|---|---|---|---|---|---|---|
| 25 | 142 | 118 | 69 | 176 | 870 | 6s |
| 50 | 225 | 225 | 188 | 292 | 1.620 | 6s |
| 75 | 364 | 370 | 304 | 509 | 2.370 | 5s |
| 100 | 1.736 | 1.422 | 1.603 | 3.256 | 3.120 | **0,96s (terra)** |
| 150 | 3.078 | 2.262 | 2.627 | 5.176 | 4.620 | 0,9s (terra) |
| 200 | 4.146 | 3.062 | 4.344 | 7.039 | 6.120 | **0,87s (terra)** |

(a coluna HP/DPS usa o pior caso, que é terra; fogo em L100 dá 1,8s — mesmo assim,
nenhuma vocação sobrevive a uma rotação)

**Nenhum combate PvP de level 100+ sobrevive a uma rotação completa.** É o problema
central que você descreveu ("não deveria morrer porque o adversário acertou uma
única magia") — na prática ele morre com 2 a 4 magias, e contra terra (que ecoa 11
magias) morre com **2**.

---

## 5. BEND — análise dedicada

### 5.1 Como o bend é obtido

Não é mana gasta: é **ponto de atributo**. `/add bend, N` (`atributos/add.lua`),
1 ponto por level (`onAdvance.lua`), +1 por pedra elemental (máx. 50) e pelo totem.
O custo por ponto cresce:

| Bend | custo/ponto | custo acumulado |
|---|---|---|
| 1–19 | 1 | 19 |
| 20–29 | 2 | 40 (bend 30) |
| 30–49 | 4 | 120 (bend 50) |
| 50–59 | 7 | 190 (bend 60) |
| 60–69 | 10 | 290 (bend 70) |
| 70+ | 15 | — |

Bend esperado por level (1 ponto/level + 20 pedras, tudo em bend):

| Level | 1 | 10 | 25 | 50 | 75 | 100 | 150 | 200 | 300 |
|---|---|---|---|---|---|---|---|---|---|
| Bend | 14 | 21 | 29 | 35 | 42 | **48** | 56 | 62 | 71 |

A curva de pontos **já é boa**: ela satura sozinha (bend 60+ fica caro), o que faz o
bend acompanhar o level sem estourar. Esse desenho deve ser mantido.

### 5.2 Quanto o bend multiplica hoje

| Bend | 0 | 10 | 25 | 50 | 75 | 100 | 150 |
|---|---|---|---|---|---|---|---|
| Atual (`1 + 0.04b`) | x1,00 | x1,40 | x2,00 | **x3,00** | x4,00 | **x5,00** | x7,00 |
| Proposto (`1 + 1.2·b/(b+80)`) | x1,00 | x1,13 | x1,29 | **x1,46** | x1,58 | **x1,67** | x1,78 |

Com o bend atual, **25 pontos de bend valem mais que 75 levels**. Com o bend
proposto, o level passa a mandar (level 50→200 = 3,4x) e o bend continua relevante
(+46% em bend 50, +67% em bend 100), sem nunca virar o eixo principal.

### 5.3 Resposta à pergunta "1 bend = X dano?"

Não use valor fixo por ponto. **Use multiplicador com retorno decrescente**:
`bendFactor = 1 + 1.2 · bend / (bend + 80)`. Ele:
- não zera a utilidade do bend em level baixo (bend 20 = +24%);
- não permite que bend 100 (que é caríssimo em pontos, 740) valha 5x o dano;
- é contínuo, então não precisa de teto artificial (o bend efetivo é limitado pela
  própria tabela de pontos, que chega no máximo a ~70-80).

---

## 6. Modelo de dano RECOMENDADO (v2)

```
danoPorCast(level, classe, shape) = (20 + 1.55 * (level - 1))
                                    * CLASSE[classe]
                                    * SHAPE[shape]
                                    * bendFactor(bend)
                                    * eco                       -- ver abaixo

classe (pelo cooldown da magia)      shape (pelo spells.xml)
  filler  CD <= 3s   x0.40            needtarget  x1.00
  core    CD 4-15s   x1.00            direction   x0.95
  heavy   CD 16-45s  x1.75            area        x0.85
  ult     CD >= 60s  x2.75            selftarget  x0.75

eco (estagio ELITE, level 100+): o orçamento da classe e' dividido entre as duas
  aplicacoes -> cada uma vale 50%. O visual/efeito continua, o total nao muda.

multi-hit: o total do cast e' o orcamento da classe; cada hit = orcamento / hits.
```

Valores de referência (shape target, com eco já dividido, bend esperado do level):

| Level | Bend | HP rec. | base | filler | core | heavy | ult | DPS rotação |
|---|---|---|---|---|---|---|---|---|
| 20 | 26 | 1.005 | 49 | 26 | 64 | 112 | 176 | 26 |
| 40 | 33 | 1.905 | 81 | 43 | 108 | 190 | 298 | 66 |
| 60 | 38 | 2.805 | 112 | 62 | 155 | 271 | 425 | 139 |
| 80 | 43 | 3.705 | 138 | 79 | 196 | 344 | 540 | 220 |
| 100 | 48 | 4.605 | 173 | 101 | **253** | 443 | 696 | 355 |
| 150 | 56 | 6.855 | 251 | 150 | 376 | 658 | 1.034 | 546 |
| 200 | 62 | 9.105 | 328 | 201 | 502 | 879 | 1.381 | 878 |

Mudanças de sistema necessárias:

1. `SPELL_BALANCE_LEVEL_CURVE` → **todos os valores em 1.00** (o corte de 2x
   deixa de existir; a inclinação correta vai para dentro da fórmula base).
2. `getBendDamageBonus` → fórmula com retorno decrescente (§5.3).
3. `vocations.xml` → `gainhp` de 30 para **45** (HP do level 100: 3.120 → 4.605).
   Compensar do outro lado com **`rateMonsterAttack = 1.4`** no `config.lua`
   (uma linha, escala o dano de todos os monstros), para o PvE não ficar mole.
4. Estágio ELITE: cada aplicação do eco passa a valer metade (ou o eco é removido —
   recomendação: manter o visual, dividir o dano).
5. `atk` de cada magia = `CLASSE x SHAPE x 100` (tabela única, gerada pelo próprio
   `tools/spell_balance_report.pl --bar --emit` depois de ajustar o alvo do
   emissor: hoje ele mira `300 + 3*level`, que é exatamente a origem dos ~650 atuais).

### Resultado do modelo

| Level | Burst de 3 (ult+heavy+core) | % do HP | TTK execução perfeita | execução boa | execução ruim |
|---|---|---|---|---|---|
| 20 | 323 | 32% | ~25s | ~38s (4 kills) | > 60s / perde |
| 50 | ~600 | 31% | ~18s | ~30s | perde |
| 100 | 1.383 | **30%** | **~13s** | ~22s | perde |
| 150 | 2.082 | 30% | ~12s | ~21s | perde |
| 200 | 2.794 | 31% | ~10s | ~18s | perde |

O burst de 3 magias passa a valer ~30% do HP em **todos** os estágios (hoje vale
100-125% em terra e ~90% em fogo no level 100). Matar exige **2 a 3 rotações** de
combo: 10 a 14 aplicações. Isso é exatamente o "execução perfeita mata rápido,
execução boa demora mais, execução ruim perde".

---

## 7. PvE — criaturas e faixas

Faixas dadas pelo próprio servidor (`data/huntwaypoint/*.lua`) cruzadas com HP/XP:

| Criatura | HP | XP | Faixa rec. | XP/HP | Situação |
|---|---|---|---|---|---|
| Terra Beetle | 150 | 980 | 0–30 | 6,5 | ok |
| Verme de cemitério | 250 | 1.200 | 15–30 | 4,8 | ok |
| Urso feroz | 600 | 1.600 | 20–30 | 2,7 | ok |
| Aranha cospe pedra | 1.500 | 3.000 | 20–30 | 2,0 | ok |
| Joaninha da terra | 400 | 1.025 | 25–35 | 2,6 | ok |
| Abelha de barro | 650 | 1.325 | 30–40 | 2,0 | ok |
| Homem de barro | 850 | 1.900 | 45–50 | 2,2 | ok |
| Besouro luminoso | 800 | 2.200 | 50–60 | 2,8 | ok |
| Tarântula de pedra | 750 | 2.075 | 50–60 | 2,8 | ok |
| **Caranguejo capa quente** | 400 | 3.500 | 60–80 | **8,8** | **quebrado (farm trap)** |
| Leão de Ba Sing Se | 2.000 | 2.500 | 65–80 | 1,3 | ok |
| **Caracol gigante** | 700 | 5.500 | 80–100 | **7,9** | **quebrado (farm trap)** |
| Centopeia carapaça de aço | 2.300 | 2.800 | 80–85 | 1,2 | ok |
| Pica-pau da terra | 2.780 | 3.500 | 85–105 | 1,3 | ok |
| Elefante | 2.600 | 3.200 | 85–105 | 1,2 | ok |
| Grilo gigante | 1.600 | 5.500 | 90–120 | 3,4 | alto |
| Abelha urubu | 3.000 | 3.800 | 105–115 | 1,3 | ok |
| Mordecasca da terra | 3.480 | 4.500 | 115–125 | 1,3 | ok |
| Traidor | 4.200 | 5.400 | 130–155 | 1,3 | ok |
| Iguana-marinha | 4.500 | 18.000 | 150–200 | 4,0 | alto |
| Onça | 6.500 | 8.000 | 155–190 | 1,2 | ok |
| Conhecimento descontrolado | 8.000 | 11.000 | 190–200 | 1,4 | **fora de faixa** (deveria ser 150–170) |
| Vacaceronte | 7.500 | 12.000 | 200–210 | 1,6 | ok |
| Pantera negra | 9.500 | 13.000 | 200–250 | 1,4 | **fora de faixa** (dano 2.900/ciclo) |
| Barata come rocha | 15.000 | 20.000 | 250–300 | 1,3 | ok |
| Crocodilo do deserto | 12.800 | 36.500 | 250–300 | 2,9 | alto |
| Livro de dobras proibidas | 18.000 | 24.000 | 250–300 | 1,3 | ok |

Problemas:

- **XP/HP varia 7x** (1,2 a 8,8). Ideal: manter entre ~2,0 e ~3,0 em toda a escada,
  crescendo levemente com o level. O Caranguejo (400 HP) e o Caracol (700 HP) são
  os dois melhores pontos de XP do jogo inteiro e estão no level 60–100.
- **Conhecimento descontrolado (8.000 HP, 11k XP) e Pantera negra (9.500 HP, 13k XP)**
  aparecem como 190–250, mas a Pantera bate 2.900 por ciclo de ataques — o dobro da
  Iguana-marinha do mesmo bloco.
- Bosses (`data/monster/bosses/*.xml`) vão de 2.400 HP (Alpha Warm Cape Crab) a
  1.200.000 HP (Alpha Blue Hydra Head / Mountain Defender). Sem faixa declarada.

Tempo de kill (TK) hoje e recomendado para a criatura da faixa:

| Level | Criatura da faixa | HP | TK hoje | TK recomendado |
|---|---|---|---|---|
| 25 | Aranha cospe pedra | 1.500 | 6s | 12s |
| 50 | Homem de barro | 850 | 3s | 6s |
| 75 | Leão de Ba Sing Se | 2.000 | 4s | 9s |
| 100 | Centopeia carapaça | 2.300 | **1,5s** | 6,5s |
| 150 | Iguana-marinha | 4.500 | 1,5s | 8s |
| 200 | Pantera negra | 9.500 | 2,4s | 11s |

Conclusão de PvE: hoje o jogador **destrói** a criatura da faixa (1–3s). O modelo
recomendado leva o TK para 6–12s — que é o que faz o jogador precisar de rotação,
posicionamento e mana. Depois da mudança, criaturas com XP/HP acima de 3,0 devem
ter o XP cortado ~40% e as duas "farm traps" corrigidas.

---

## 8. PvP — tempo para matar (TTK)

Premissas: alvo do mesmo level, sem suporte externo, atacante com kit completo.

### Hoje

| Level | HP do alvo | Dano do burst (3 melhores) | TTK |
|---|---|---|---|
| 50 | 1.620 | ~900 | 4s |
| 100 | 3.120 | 2.440–2.930 | **2–3s** |
| 100 (terra) | 3.120 | 3.256 (DPS) | **1s** |
| 200 | 6.120 | ~4.000 | 3–4s |

Não existe "execução": com 15 magias disponíveis e CD de 2–8s em várias delas, o
atacante sempre tem uma magia pronta. **Errar uma magia não custa nada.**

### Recomendado

| Execução | Nº de aplicações | TTK (L100) | Como chega lá |
|---|---|---|---|
| perfeita | 10–12 | **13–15s** | ult + heavy + core, sem errar, usando o slow/freeze para segurar |
| boa | 14–18 | **22–30s** | perde 2–3 golpes por esquiva/posicionamento, precisa de 2ª rotação |
| ruim | 20+ | perde | mana/cd acabam antes, o alvo cura/poteia e escapa ou vira |

Com isso "acertar a magia importante" passa a importar: a ultimate (696 no L100)
vale 15% do HP; perder ela custa ~2 golpes de tempo.

---

## 9. Comparação entre vocations

Medições a L100/bend50 (sem contar os talentos):

| | fire | water | air | earth |
|---|---|---|---|---|
| Mediana por cast | 641 | 629 | 649 | 642 |
| DPS de rotação | 1.736 | 1.422 | 1.603 | **3.256** |
| Burst (top-3) | 2.440 | 2.434 | 2.290 | 2.306 |
| Magias com eco (2x) | 5 | 5 | 3 | **11** |
| Scripts com evolução de área | 8 | 8 | **14** | 6 |
| Slow por elemento (ELITE) | 0% | **35% / 1,5s** | 25% / 1,2s | **40% / 1,2s** |
| CC próprio | stun, push | freeze 4s, slow 50%, trap | trap, jail, suffocation | petrify 4s, control, stun |
| Cura própria | recover | **heal + sregen + mregen + revive passivo (25–50% do HP)** | recover | recover |
| Defesa de vocação | 1,0 | 1,0 | 1,0 | **armor/defense 1,4** |
| Mobilidade | jump (com debuff de dano) | surf | **run/jump/wings + dodge 5–10%** | jump/scape |

Leitura:

- **terra está acima em tudo**: 2x o DPS de rotação (por causa do eco), a única
  com `armor/defense 1.4` na `vocations.xml`, e as duas melhores magias de controle.
  Precisa descer.
- **fogo** tem o melhor burst pontual (`fire explosion` multiplica por 1,8 dentro do
  script, e ainda ganha 1,5x–2,0x com `isFocusExplosion`/OverPower) e o único DoT
  (burn 0,5–1% do HP máximo/s). É a vocação de "matar rápido" e está coerente.
- **água** tem o menor DPS de rotação mas o melhor sustain (heal + revive passivo que
  devolve 25% do HP, 50% upgradeado, e ainda dá imune/OverPower/stun conforme o
  elemento). Está compensada.
- **ar** tem a melhor área (14 scripts com evolução de área), dodge e mobilidade;
  o dano é o mais baixo do grupo e o eco é o menor (3). Está ligeiramente abaixo.
- **Equipamento não dá bend direto, mas dá dano e defesa por caminhos obscuros**
  (§10 P11 e P17). Não há item com `maglv`/`magiclevelpoints` (nenhum item aumenta
  o bend somado), mas há 112 itens com `increasemagicpercent` e 68 com
  `absorbPercentAll`. O poder mágico vem de level + bend + talentos + dobras, com
  o equipamento entrando como multiplicador condicional e como redução de dano.

---

## 10. Problemas encontrados (lista completa)

**P1 — Personagem novo nasce sem mana.** `iologindata.cpp` usa a vocação 0
(`gainmana = 0`) para os levels ≤ 8 e só aplica a vocação real em `level > 8`.
Com `newPlayerLevel = 8`, o char nasce com `manaMax = 0` e **não consegue conjurar**.
Correção: usar `manaMax = 5 * (level - 1)` também no `else` (`level >= 8`).

**P2 — Bend multiplica por 3 (bend 50) e 5 (bend 100).** Domina o level (§5).

**P3 — `SPELL_BALANCE_LEVEL_CURVE` corta o dano pela metade a partir do level 25.**
Faz o trecho 25→100 ser 2,9x enquanto 1→25 é 5x.

**P4 — Dano por cast igualado, cooldown não.** O DPS dentro da mesma vocação varia
de 8 a 368 (44x). A escada de dobras é inútil: a magia mais nova não é a melhor.

**P5 — Eco do estágio ELITE distribuído de forma desigual.** `registerSpellStageEcho`:
earth 11 scripts, fire 5, water 5, air 3. Isso dá a terra ~2x de dano efetivo a partir
do level 100 (DPS 3.256 vs ~1.500 dos demais). Nenhuma magia usa
`registerSpellStageCombats` (0 scripts), então a evolução de área por estágio também
está incompleta.

**P6 — Magias multi-hit furam o orçamento do cast.** `air vortex` 32 hits x 691 =
**22.112 por cast**; `air gale` 12 x 430 = 5.166; `earth growth` 9 x 567 = 5.106;
`fire thunderstorm` 6 x 906 = 5.436; `earth crush` (level 1!) 3 x 444 = 1.332.
O medidor conta 1 aplicação e o `--emit` limita o ajuste a +25%, então isso nunca
foi corrigido.

**P7 — `air ball` (level 1) tem 1s de cooldown** (`airExausted.ball` via
`allSpellChecks`, não via `doPlayerAddExaust`) e entrega 443 de dano → **443 DPS no
level 100**, mais que qualquer ultimate.

**P8 — `earth leech`: `atk = 880`, CD 3s, e ainda cura.** É 5–9x o `atk` das magias
da mesma faixa. Outliers parecidos: `water punch` (atk 556, CD 6, 50% slow),
`fire thunderbolt` (atk 340, CD 12), `earth curse` (atk 726, CD 30),
`fire voltage` (atk 500 — formula não interpretável pela ferramenta).

**P9 — Mana não limita nada.** Poção de mana grande dá 420 por ~1s; mana regen
2,5/s. O `mana` das magias é igual ao level da magia, sem relação com o dano
(`earth curse` = 28 de dano por mana; `fire clock` = 9,7). Não há custo por classe.

**P10 — `rateExperience = 1` é a premissa dos números desta auditoria (o `200` do
`config.lua` é valor de teste).** Com 1x, cada kill de Caracol gigante vale 5.500 de
XP e o nível 100→101 pede 485.200 (≈ 88 kills); o ritmo fica em ~7,1 níveis/hora no
L100, caindo para 3,3 no L200 — exatamente o desenho que a §4 pressupõe ao usar
**bend 48 @ L100** (≈1 ponto de atributo por level). Com 200x o mesmo trecho vale
1.430 níveis/hora, o bend chega ao **teto de 100 em menos de uma hora** e todas as
matrizes de dano desta auditoria teriam de ser relidas na coluna "bend 100".
Correção: garantir `rateExperience = 1` em produção (o `200` só pode existir em
ambiente de teste) — não é um ajuste de balanceamento, é o valor que **valida** os
números; a tabela de criaturas (`hunts/equipament tier list.txt`) também é descrita
para ~1x–1,5x, então 1 está dentro do que ela espera.

**P11 — A resistência elementar existe, mas está torta em relação às vocações.**
Nenhum **monstro** tem `<immunity>`, mas **itens** têm `absorbPercent*`
(68 itens com `absorbPercentAll`, 24 Fire, 24 Energy, 19 Ice, 17 Earth, 7 Physical,
5 Holy, 4 Elements, 2 Magic). O problema é o tipo de combate de cada vocação
(`data/spells/scripts/*`):

| vocação | tipo de combate | absorvido por |
|---|---|---|
| fire | `COMBAT_FIREDAMAGE` | All, Fire, Elements, Magic |
| earth | `COMBAT_EARTHDAMAGE` / `COMBAT_POISONDAMAGE` | All, Earth, Elements, Magic |
| air | `COMBAT_AIRDAMAGE` | All, Elements, Magic |
| water | `COMBAT_DROWNDAMAGE` (+ `COMBAT_ICEDAMAGE` em algumas) | **só All** (drown não está em nenhuma lista específica) |

Ou seja: fogo e terra têm resistência dedicada no equipamento, ar tem duas
listas, e **água (drown) só é resistida por `absorbPercentAll`**. O parser suporta
`absorbPercentAir` (`items.cpp:1350`) mas nenhum item usa. Como o dano mágico é
quase todo da vocação do próprio jogador, o efeito prático é que o gear de
resistência que existe no jogo é desigual para as quatro vocações.

**P12 — Empilhamento de redução de cooldown.** `doPlayerAddExaust` aplica:
talentos (−30%), storage 13403 (−8%), `timeInEffectCdReduction` (−30%) → até ~−55%
de CD em cima de tudo. Duplica o DPS de rotação no endgame e não está contabilizado
em nenhum lugar.

**P13 — Três falhas na ferramenta de medição (`tools/spell_balance_report.pl`):**
(a) o `cd` é lido do primeiro `*Exausted.X` que aparece no script, que muitas vezes
é um helper interno — `fire clock` aparece com 0,8s em vez de 20s;
(b) o detector de `remake` marca `water icebeam` e `water whip` como se não
levassem bend (elas levam — conferido no script, `remakeValue(2, ...)`);
(c) `water whip` aparece duas vezes no relatório porque o `spellsInfo` tem
"water wave" **e** "water whip" apontando para o mesmo script.

**P14 — Auto-attack (`criticalOnAttack.lua`) não escala com bend nem elemento.**
No level 100 dá ~150 de dano a cada 2s = 75 DPS, contra 1.700 DPS de magia. É
decorativo, mas ainda existe e não entra em nenhuma curva.

**P15 — Revive passivo da água** (`imuneable.lua`): 25% do HP máximo de volta (50%
com `revivelevel2`), CD de 3h (2h), e ainda aplica o bônus elemental do revival
(OverPower de fogo, imune de água, stun de terra, haste de ar). Em PvP isso é uma
segunda barra de vida não contabilizada.

**P16 — `imuneable.lua` guarda um `atk = 175` congelado** ("era o atk de air barrier
antes do balance da spellbar") e `combatMiniExp` usa `atk = 214` congelado. Se a
tabela `spellsInfo` mudar, essas passivas ficam fora da curva.

**P17 — `increasemagicpercent` é um multiplicador binário de dano mágico.**
`Player::increaseCombatValues` (`player.cpp:5827`, chamado em `combat.cpp:1331`
para TODA magia) soma `(valor - 100)` de cada item equipado em `totalMagicPercent`
e, **se a soma passar de 100, multiplica o min/max da magia por `soma/100`**
(`if (totalMagicPercent > 100)`). Há 112 itens com esse atributo, com valores de
101 a 120. Uma única peça não faz nada (soma 6, 10, 20...), mas ~8 peças boas
(120+118+117+115+114+113+112+111) somam `120` → **todo o dano mágico do jogador
passa a x2,2 de uma vez**, sem aviso e sem escala gradual. Hoje o limite está
encostado no teto (poucos itens 110+), então o sistema está a um item de mudar a
curva inteira. Recomendação: trocar o `if (>100)` por escala linear
`1 + soma/100` com teto explícito (ex.: +30%), ou remover o atributo.

**P18 — O tier dos itens multiplica a absorção.** `player.cpp:2507`:
`absorbVal = round(absorbVal * (1.0 + tier * 0.10))`. Com tier 10, a absorção de um
item dobra. Como o dano final é `dano - absorção`, um set tier 10 com
`absorbPercentAll` pode cortar mais da metade do dano recebido — e isso não é
contabilizado em nenhuma simulação de TTK de PvP.

---

## 11. Plano de aplicação por magia

Comparação ao nível 100, bend 50 (atual) contra bend 48 (recomendado).
`cast` = dano total do cast (já com eco). Colunas `classe` = classe de cooldown e
`var%` = variação do dano por cast.

| elem | magia | lvl | shape | classe | cd | hits | cast atual | cast rec. | var% |
|---|---|---|---|---|---|---|---|---|---|
| fire | fire whip | 1 | target | filler | 2 | 1 | 445 | 99 | −78 |
| fire | fire kick | 8 | target | filler | 3 | 1 | 659 | 99 | −85 |
| fire | fire skyfall | 12 | self | filler | 3 | 1 | 900 | 148 | −84 |
| fire | fire blast | 16 | target | filler | 2 | 1 | 726 | 99 | −86 |
| fire | fire bolt | 25 | target | core | 10 | 1 | 564 | 247 | −56 |
| fire | fire cinder | 30 | target | core | 8 | 1 | 432 | 247 | −43 |
| fire | fire star | 36 | target | heavy | 25 | 8 | 583 | 433 | −26 (por hit −26) |
| fire | fire cannon | 42 | beam | core | 8 | 1 | 1.282 | 470 | −63 |
| fire | fire lightning | 55 | beam | core | 8 | 1 | 680 | 235 | −65 |
| fire | fire bomb | 60 | target | heavy | 20 | 1 | 1.316 | 865 | −34 |
| fire | fire clock | 65 | area | heavy | 20 | 1 | 1.261 | 735 | −42 |
| fire | fire thunderbolt | 70 | target | core | 12 | 1 | 766 | 247 | −68 |
| fire | fire meteor | 80 | self | heavy | 45 | 1 | 557 | 324 | −42 |
| fire | fire striker | 90 | area | heavy | 45 | 1 | 845 | 368 | −56 |
| fire | fire overload | 100 | target | heavy | 30 | 1 | 829 | 433 | −48 |
| fire | fire explosion | 110 | self | heavy | 25 | 1 | 1.872 | 649 | −65 |
| fire | fire thunderstorm | 150 | self | heavy | 30 | 6 | 5.433 | 1.946 | −64 |
| fire | fire discharge | 200 | self | ult | 60 | 1 | 690 | 510 | −26 |
| fire | fire conflagration | 250 | self | ult | 90 | 1 | 741 | 510 | −31 |
| water | water whip | 1 | beam | filler | 2 | 1 | 453 | 104 | −77 |
| water | water explosion | 8 | target | filler | 2 | 1 | 656 | 109 | −83 |
| water | water icespikes | 20 | beam | core | 4 | 1 | 589 | 259 | −56 |
| water | water freeze | 25 | target | heavy | 30 | 1 | 1.130 | 955 | −16 |
| water | water shards | 30 | area | core | 12 | 1 | 433 | 232 | −46 |
| water | water icebeam | 30 | target | core | 10 | 1 | 391 | 273 | −30 |
| water | water cannon | 42 | beam | core | 8 | 1 | 1.282 | 518 | −60 |
| water | water bloodcontrol | 50 | target | heavy | 45 | 1 | 507 | 477 | −6 |
| water | water punch | 55 | target | core | 6 | 1 | 1.356 | 546 | −60 |
| water | water dragon | 60 | area | heavy | 25 | 1 | 655 | 406 | −38 |
| water | water rain | 65 | area | heavy | 45 | 1 | 629 | 406 | −36 |
| water | water bubbles | 70 | target | core | 12 | 1 | 1.529 | 546 | −64 |
| water | water icebolt | 90 | target | heavy | 20 | 1 | 1.686 | 955 | −43 |
| water | water flow | 100 | self | heavy | 30 | 1 | 826 | 358 | −57 |
| water | water tsunami | 130 | beam | heavy | 45 | 1 | 727 | 454 | −38 |
| water | water clock | 150 | self | heavy | 45 | 1 | 914 | 358 | −61 |
| water | water blizzard | 200 | self | ult | 60 | 1 | 692 | 563 | −19 |
| water | water bloodbending | 250 | target | ult | 90 | 1 | 741 | 750 | +1 |
| air | air burst | 8 | area | filler | 2 | 1 | 656 | 102 | −84 |
| air | air force | 20 | target | core | 4 | 1 | 587 | 300 | −49 |
| air | air gust | 25 | beam | core | 6 | 1 | 565 | 285 | −50 |
| air | air gale | 30 | beam | core | 15 | 12 | 10.333 | 683 (total) | −93 |
| air | air icywind | 30 | beam | heavy | 20 | 1 | 652 | 498 | −24 |
| air | air fan | 42 | beam | heavy | 30 | 1 | 646 | 498 | −23 |
| air | air wings | 46 | beam | core | 14 | 1 | 698 | 285 | −59 |
| air | air suffocation | 50 | target | heavy | 35 | 1 | 1.008 | 1.049 | +4 |
| air | air hurricane | 55 | beam | core | 13 | 1 | 679 | 285 | −58 |
| air | air tempest | 60 | area | heavy | 25 | 1 | 653 | 446 | −32 |
| air | air windblast | 65 | area | heavy | 20 | 1 | 1.260 | 892 | −29 |
| air | air tornado | 70 | target | heavy | 20 | 1 | 766 | 524 | −32 |
| air | air barrier | 80 | self | heavy | 40 | 1 | 555 | 393 | −29 |
| air | air doom | 100 | area | heavy | 45 | 1 | 826 | 446 | −46 |
| air | air bomb | 110 | target | heavy | 30 | 1 | 938 | 524 | −44 |
| air | air windstorm | 130 | self | heavy | 45 | 1 | 728 | 393 | −46 |
| air | air stormcall | 150 | self | heavy | 45 | 1 | 906 | 393 | −57 |
| air | air vortex | 200 | self | ult | 60 | 32 | 22.112 | 1.978 (total) | −91 |
| air | air deflection | 250 | self | ult | 90 | 1 | 742 | 618 | −17 |
| earth | earth crush | 1 | self | filler | 3 | 3 | 1.332 | 237 | −82 |
| earth | earth punch | 8 | target | core | 4 | 1 | 1.309 | 526 | −60 |
| earth | earth rock | 12 | target | filler | 3 | 1 | 902 | 210 | −77 |
| earth | earth pull | 20 | target | core | 4 | 1 | 1.178 | 526 | −55 |
| earth | earth growth | 25 | beam | core | 9 | 9 | 10.211 | 1.000 (total) | −90 |
| earth | earth collapse | 30 | self | core | 10 | 1 | 866 | 394 | −54 |
| earth | earth petrify | 42 | target | heavy | 30 | 1 | 1.284 | 920 | −28 |
| earth | earth fury | 46 | beam | core | 14 | 1 | 1.396 | 500 | −64 |
| earth | earth control | 50 | beam | heavy | 30 | 1 | 1.016 | 874 | −14 |
| earth | earth leech | 55 | self | filler | 3 | 1 | 678 | 79 | −88 |
| earth | earth smash | 60 | target | core | 7 | 1 | 1.307 | 526 | −60 |
| earth | earth fists | 70 | beam | core | 15 | 1 | 764 | 250 | −67 |
| earth | earth curse | 90 | target | heavy | 30 | 1 | 844 | 460 | −45 |
| earth | earth cataclysm | 110 | target | heavy | 45 | 1 | 937 | 460 | −51 |
| earth | earth aura | 130 | self | heavy | 45 | 1 | 727 | 345 | −53 |
| earth | earth lavaball | 200 | target | ult | 60 | 1 | 1.386 | 1.446 | +4 |
| earth | earth metalwall | 250 | beam | ult | 90 | 1 | 1.482 | 1.374 | −7 |

### Itens 11/12 do pedido — magias que sobem / descem

- **Precisam AUMENTAR dano (na prática: ficar quase igual):**
  `water bloodbending` (+1%), `air suffocation` (+4%), `earth lavaball` (+4%)
  — todas são as últimas da escada e já estavam na faixa certa. Nenhuma outra
  magia precisa de aumento.
- **Aumento por *hit* (não por cast):** `air vortex` (19 por hit), `air gale`
  (47), `earth growth` (56), `fire thunderstorm` (324) — hoje cada hit vale quase
  nada porque o cast inteiro é absurdo; normalizando o total, o hit sobe.
- **Precisam DESCER (por cast), em ordem de urgência:**
  `earth leech` (−88), `fire blast` (−86), `fire kick` (−85), `air burst` (−84),
  `fire skyfall` (−84), `water explosion` (−83), `earth crush` (−82),
  `earth rock` (−77), `water whip` (−77), `air vortex` (−91, total),
  `earth growth` (−90, total), `air gale` (−93, total),
  `fire thunderstorm` (−64, total), `fire thunderbolt` (−68),
  `air windblast` (−29, mas atk 140 num CD de 20 com eco),
  `water punch` (−60), `water bubbles` (−64), `earth fury` (−64).

### Itens 13/14 — cooldowns e mana

**Cooldowns que precisam mudar (fora da banda da classe):**

| Magia | CD atual | CD recomendado | Motivo |
|---|---|---|---|
| air ball | 1s | **3s** | level 1 com 443 DPS |
| earth leech | 3s | **15s** | atk 880 + cura + CD de filler |
| water punch | 6s | **10s** | atk 556 + slow 50% |
| fire thunderbolt | 12s | **15s** | atk 340 num CD de core |
| water bloodcontrol | 45s | **45s (manter)** | já ok, mas o relatório mostra 0,8s (P13) |
| fire clock | 20s | **20s (manter)** | idem P13 |
| water icebeam | 10s | 10s (manter) | conferir se o alvo correto é CD 10 ou 4 |
| fire star | 25s | 25s (manter) | 8 hits = 583 no cast: ok para heavy |

**Mana:** hoje `mana = level da magia`. Recomendo **amarrar o mana ao dano**
(`mana = danoPorCast / 25`, arredondado): filler 4–10, core 25–35, heavy 45–60,
ult 70–90 no level 100+. Isso torna "spammar filler" tão caro quanto usar ultimate,
que é o que impede o DPS de rotação de estourar; hoje o filler é praticamente de graça.

### Itens a NÃO mexer

- Fórmulas de cura, buffs, efeitos visuais, condições, `spellStages` (a não ser o
  ajuste do eco), `spells.xml` (exceto mana), sistema de dobras, talent tree,
  resistências. Nada de refatorar.

---

## 12. Respostas objetivas ao pedido

1. **Fórmula recomendada:**
   `dano = (20 + 1.55*(level-1)) * CLASSE[cd] * SHAPE[area] * bendFactor(bend) * eco(0.5 se elite)`,
   com `CLASSE` = 0,40 / 1,00 / 1,75 / 2,75 e `bendFactor = 1 + 1.2*b/(b+80)`.
2. **Progressão de level recomendada:** manter as magias a cada 8–15 levels como
   estão; a curva de dano passa a ser `20 + 1,55*(level-1)`, sem correção por level.
3. **Progressão de bend recomendada:** manter a tabela de pontos atual (1 ponto por
   level, custo 1/2/4/7/10/15) — ela naturalmente dá bend 29 @ L25, 35 @ L50,
   48 @ L100, 62 @ L200. O que muda é o multiplicador (§5.3).
4. **Dano médio esperado:** 64 (L20) → 108 (L40) → 155 (L60) → 196 (L80) →
   **253 (L100)** → 376 (L150) → 502 (L200).
5. **Dano máximo razoável (ultimate):** 176 / 298 / 425 / 540 / **696** / 1.034 / 1.381.
6. **DPS aproximado (rotação completa):** 26 / 66 / 139 / 220 / **355** / 546 / 878.
7. **Burst (ult+heavy+core):** 323 / 575 / 834 / 1.104 / **1.383** / 2.082 / 2.794 —
   sempre ~30% do HP do próprio nível.
8. **Tempo para matar jogador equivalente:** perfeito 13–15s, bom 22–30s, ruim perde
   (no level 100).
9. **Tempo para matar criatura da faixa:** 6–12s (hoje 1,5–4s).
10. **Problemas do sistema atual:** P1 a P18 (§10).
11. **Magias que precisam aumentar:** só 3, e por margem pequena —
    `water bloodbending`, `air suffocation`, `earth lavaball`; mais os *hits* de
    `air vortex`, `air gale`, `earth growth`, `fire thunderstorm`.
12. **Magias que precisam reduzir:** todas as demais (74 no total); a §11 lista
    as 20 mais urgentes.
13. **Cooldowns a alterar:** 4 (air ball, earth leech, water punch, fire thunderbolt)
    + revisão de `water icebeam`; P12 (empilhamento de −55%) precisa de teto global.
14. **Custos de mana:** amarrar ao dano da classe (§11).
15. **Vocações acima/abaixo da curva:** **terra acima** (eco 11 magias + defense 1.4);
    **ar abaixo** no dano (eco 3, mediana 649 mas sem burst); fogo e água coerentes
    com o kit.
16. **Criaturas fora da curva:** `Caranguejo capa quente` e `Caracol gigante`
    (XP/HP 8,8 e 7,9 = farm trap); `Conhecimento descontrolado` e `Pantera negra`
    declaradas 190–250 mas com HP/dano de 250+.

### Sobre a referência de "250–300 no level 100 com 50 de bend"

**Ela está correta como dano da magia PADRÃO (classe core) — e o servidor entrega
2,6x isso hoje.** O que está errado não é o número, é o que ele representa:
"magia forte" deve bater ~1,75x a padrão (440) e a ultimate ~2,75x (696). Se o
número fosse aplicado como "magia forte = 250", a ultimate ficaria em ~390 e o
level 100 (HP 3.120) precisaria de 13 acertos de ultimate para morrer, o que não
fecha com o seu requisito de PvP. Mantenha 250 para a magia padrão e a hierarquia
de classe acima dela.

---

## 13. Ordem de execução sugerida (depois da sua aprovação)

1. `getBendDamageBonus` (retorno decrescente) e `SPELL_BALANCE_LEVEL_CURVE` = 1.0.
2. `vocations.xml` (`gainhp 30 → 45`) + `rateMonsterAttack 1.4` no `config.lua`.
3. Eco ELITE dividido por 2 (`spellStages.lua`, uma linha) — ou registro uniforme
   de todas as magias de alvo único.
4. Normalização das 5 magias multi-hit (`vortex`, `gale`, `growth`, `thunderstorm`,
   `crush`) para o orçamento da classe.
5. Ajuste de CD dos 4 outliers.
6. Recálculo em massa dos `atk` com `tools/spell_balance_report.pl --bar --emit --apply`,
   depois de atualizar o alvo do emissor para `20 + 1,55*(level-1)` com as
   multiplicações de classe/shape.
7. Correções P1 (mana do char novo), P13 (ferramenta), confirmar P10
   (`rateExperience = 1` em produção — o doc inteiro assume 1 e não 200),
   P6/P16 (atks congelados de passivas), P17 (`increasemagicpercent`) e
   revisão do P11 (drown sem absorção dedicada) e P12 (teto de CDR).

---

## 14. Implementação (v2 aplicada)

O que saiu do papel (e como conferir):

| # | arquivo | mudança |
|---|---|---|
| 1 | `data/lib/avatar lib.lua` | `getBendDamageBonus` virou `1 + 1.2·bend/(bend+80)` (retorno decrescente); `SPELL_BALANCE_LEVEL_CURVE` toda em **1.00**; novo multiplicador de eco do estágio ELITE (`SPELL_ECHO_FACTOR = 0.5`, ligado por `spellStages.lua`) |
| 2 | `data/spells/lib/spellStages.lua` | liga `SPELL_ECHO_ACTIVE` **só** em volta do golpe que repete a magia (as duas vias de eco), com `pcall`: a reaplicação vale metade e o desconto não vaza |
| 3 | `data/lib/201-spellsExausted.lua` | **73 magias** de dano com `atk` recalibrado para `(20 + 1,55·(L−1)) × CLASSE[cd] × ÁREA[formato]`; CD de 4 outliers (`air ball` 1→3, `earth leech` 3→15, `water punch` 6→10, `fire thunderbolt` 12→15) |
| 4 | `tools/spell_balance_report.pl` | modo `--model` que emite a tabela do modelo v2 (classe por cooldown real da tabela `*Exausted`, área pelo `spells.xml`, eco, aplicações por cast e bend decrescente lidos do próprio lib). A calibração é em **dano bruto** (antes do fator de elemento), para o `SPELL_BALANCE` do lib não ser cancelado |
| 5 | `data/lib/avatar lib.lua` (`SPELL_BALANCE`) | **hierarquia de papel entre as vocações**: fogo **1,10** (DPS) · ar **1,00** (controle) · terra **0,95** (tank) · água **0,90** (healer) |

Verificação (rodado depois do `--apply`):

```
perl tools/spell_balance_report.pl --level 100 --mag 48      # ladder por classe
perl tools/spell_balance_report.pl --level 100 --mag 48 --bar # paridade nas 4 vocações
python tools/check_lua_syntax.py "data/lib/avatar lib.lua" data/spells/lib/spellStages.lua data/lib/201-spellsExausted.lua
```

Resultado medido em L100/bend 48 (uma aplicação, no formato alvo, magia `sem eco`):

| | fogo | ar | terra | água |
|---|---|---|---|---|
| `core` (raw 173,45) | **278** | 252 | 239 | 226 |
| `heavy` | 482 | 440 | 419 | 396 |
| `ultimate` | 760 | 691 | 658 | 623 |

Ou seja: a escada `0,40 / 1,00 / 1,75 / 2,75` do modelo **multiplicada pelo papel**
de cada vocação (fogo +10% / ar 0% / terra −5% / água −10%). O total do cast nas
magias **com eco** continua igual ao das sem eco (`earth punch` = 160 + eco 80 =
240 = o orçamento da terra): o eco segue neutro. Drift fora do ponto de referência:
**±6%** para `core` em L25/L50/L200 (medido com o bend do próprio level), e até
−24% em magia `self` de level baixo (`fire conflagration`).

**Nota de design (decisão do dono do servidor):** a validação partia de "dano igual
nas quatro vocações, identidade só no kit" (§2.1 e §10.1 de
`VALIDACAO_BALANCEAMENTO.md`, DPS 277–293 ±3%). O pedido mudou: **fogo é DPS, ar é
controle, terra é tank e água é healer**, e isso tem de aparecer no dano. Com a
tabela `SPELL_BALANCE` agora em 1,10 / 1,00 / 0,95 / 0,90, onde a validação lia
"paridade" leia-se "hierarquia": os números de PvP do §5 dela (TTK, matriz de
confronto) ficam **desatualizados em ±10%** entre vocações e precisam ser refeitos
antes do próximo teste de PvP. O eco, o bend, as classes e as áreas continuam
exatamente como a validação aprovou.

### O que a aplicação NÃO incluiu (fica para a próxima rodada)

1. `vocations.xml` — `gainhp` 30 → **45** (o modelo de PvP pressupõe HP 4.605 no L100).
2. `config.lua` — `rateExperience = 1` em produção (hoje 200, valor de teste).
3. **Cura da água** — `atk`/CD/mana do `water heal` (hoje 145 HPS → alvo ~36 HPS).
4. **Kit de level 1** — ar não tem magia nenhuma no level 1.
5. P1 (mana do char novo), P11 (drown/air sem resistência em criatura), P12 (teto de CDR), P16 (atks congelados de passivas), P17 (`increasemagicpercent` sem teto).
6. `water whip` — chave de `atk` **compartilhada** por dois scripts (`water/whip.lua`, a dobra da spellbar, e `water/whip man.lua`); ficou em 118 e está marcada em `%MODEL_SKIP` no emissor até o atalho ser desmembrado.
7. Spells com `atk` que não passa pela tabela (`water/whip.lua` não multiplica por `cf.atk` no callback) ficam fora do alcance do emissor — precisam de ajuste no próprio script.
8. **Contagem de aplicações das magias de vários golpes** (v3, correção da §15): as que ainda não foram contadas linha a linha podem entregar mais de um orçamento por cast. Lista em `%APPLICATIONS` (`tools/spell_balance_report.pl`).

---

## 15. Correção v3 — magias de vários golpes (aplicações por cast)

**Sintoma (relato em jogo):** `air fan`, `air wings` e outras magias de golpe
múltiplo **matam rápido demais**, com números por golpe baixos (30/35/29 no log).

**Causa:** o modelo v2 calibra o `atk` para o **total do cast** — o alvo da classe
e' dividido pelo numero de aplicacoes que caem no mesmo alvo (`emit_model`:
`$measured = $r->{dmg} * $apps`, `$apps = $r->{hits} // 1`, e `hits` vem de
`%APPLICATIONS`). Só que a tabela `%APPLICATIONS` só tinha as magias contadas na
validação (§3 dela). **`air fan` e `air wings` não estavam lá: rodaram com
`apps = 1`.** Resultado medido pelo próprio emissor:

| magia | cd | aplicações reais | aplicações usadas | total do cast (alvo bruto) |
|---|---|---|---|---|
| `air fan` | 30 s | **15** | 1 | **4.326** contra alvo **288** (15×) |
| `air wings` | 14 s | **10** | 1 | **1.647** contra alvo **165** (10×) |
| `air deflection` | 90 s | **15** | 1 | **5.372** contra alvo **358** |
| `air tempest` | 25 s | **11** | 1 | **2.839** contra alvo **258** |
| `air windstorm` | 45 s | **9** | 1 | **2.048** contra alvo **228** |
| `water flow` | 30 s | **9** | 1 | **2.054** contra alvo **228** |
| `water punch` | 10 s | **6** | 1 | **695** contra alvo **116** |

E' por isso que os números do log são baixos e mesmo assim a barra de vida
some: **o dano não está no tamanho do golpe, está na quantidade deles.** Com 15
aplicações de 440 (L100, bend 48) o `air fan` entrega ~6.600 num único cast —
que é exatamente o "quase 6k de vida" do relato (o alvo ainda reduz cada golpe
individualmente, o que explica os 30–64 por linha).

**Contagem (linha do script, pior caso de um alvo parado na área):**

| magia | aplicações | evidência |
|---|---|---|
| `air vortex` | 32 | `for y = 0, 15` × 2 `sendCombat` (`vortex.lua:161`) |
| `air fan` | 15 | `sequencia` tem 15 pulsos de área (`fan.lua:97`) |
| `air deflection` | 15 | `for i = 0, 14` (`deflection.lua:101`) |
| `air tempest` | 11 | `for x = 0, 10` (`tempest.lua:110`) |
| `air wings` | 10 | `combats = {1..10}`, `for x = 0, #combats-1` (`wings.lua:179`) |
| `air windstorm` | 9 | `for i = 0, 8` (`windstorm.lua:87`) |
| `water flow` | 9 | `for i = 0, 8` (`flow.lua:135`) |
| `air hurricane` | 6 | `for x = 0, 5` (`hurricane.lua:132`) |
| `water punch` | 6 | `doCombat` imediato + `for i = 1, 5` (`punch.lua:52`) |
| `earth aura` | 6 | 26 pulsos com `times % 4 == 0` → 6 ticks (`aura.lua:169`) |
| `air gust` | 4 | `for x = 0, 3` (`gust.lua:116`) |
| `air tornado` | 4 | `tornadoWork(…,3)` → `times` 3,2,1,0 (`tornado.lua:60`) |
| `air ball` | 2 | `doCombat` imediato + `addEvent` 250 ms (`ball.lua:57`) |
| `air burst` | 2 | `for x = 0, 1` (`burst.lua:98`) |

**O que foi feito:** os números entraram em `%APPLICATIONS`
(`tools/spell_balance_report.pl`) e o `atk` das 13 magias afetadas foi reemitido
(`--model --emit --level 100 --mag 48 --apply`). Exemplos: `air fan` 259 → **17**,
`air deflection` 358 → **24**, `air tempest` 242 → **22**, `air windstorm`
159 → **18**, `water flow` 135 → **15**, `air wings` 111 → **11**, `water punch`
154 → **26**, `earth aura` 13 → **15**. Depois da correção, **o total do cast**
(L100 / bend 48) caiu na classe certa:

| classe | antes | depois | alvo do modelo |
|---|---|---|---|
| `core` — `air wings` | 1.647 | **~251** | 250 |
| `core` — `air hurricane` | 988 | **~253** | 250 |
| `heavy` — `air fan` | 4.326 | **~434** | 440 (ar) |
| `heavy` — `air tempest` | 2.839 | **~389** | 440 |
| `ult` — `air deflection` | 5.372 | **~545** | 519 (`self`) |

(valores da coluna "depois" são o `dano/cast` do relatório com `--level 100 --mag 48`;
a fórmula sorteia o midpoint a cada execução, então varia ±1%.)

Validação: `perl tools/_validate_spells_exausted.pl` → "nenhuma vírgula faltando,
balanceamento íntegro"; `python tools/check_lua_syntax.py` → 0 problemas. O drift
fora do ponto de referência continua sendo o da §14 (a correção é linear no `atk`).

**Ainda sem contagem (mesmo risco, total do cast acima do orçamento):**
`air stormcall`, `air bomb`, `air doom`, `air suffocation`, `air trap`,
`earth quake`, `earth cataclysm`, `earth fists`, `earth lavaball`, `earth leech`,
`fire conflagration`, `fire thunderbolt`, `fire meteor`, `fire striker`,
`fire cannon`, `fire explosion`, `water clock`, `water bloodbending`,
`water shards`, `water dragon`, `water tsunami`. Elas dependem de mecanica
variavel (bomba com fuse, onda por distancia, worker que recursiona enquanto a
tabela do cast existe), entao a contagem tem de vir do worker, nao do `for` do
cast. Enquanto nao entram em `%APPLICATIONS`, cada uma leva o valor 1 e pode
entregar N vezes o orcamento — e' o proximo item da fila.

---

## 16. Correção v4 — contagem das magias "com risco"

**Feito:** as 21 magias do §15 foram contadas linha a linha no worker (pior caso
de um alvo parado dentro do cast) e entraram em `%APPLICATIONS`
(`tools/spell_balance_report.pl`); o `atk` das afetadas foi reemitido
(`--model --emit --level 100 --mag 48 --apply`). A regra é a mesma do v3: o alvo
da classe é o **total do cast**, então cada aplicação vale `orçamento/N`.

**Onde estava o estouro:** não no `for` do cast, mas no **worker que se
reagenda** — `addEvent` recursivo, ondas (2 passadas), ticks e cadeias de
`onTargetTile`.

| magia | cd | classe | aplic. | evidência | atk antes → depois |
|---|---|---|---|---|---|
| `air suffocation` | 35s | heavy | **18** | `for x = 1, 18` de `sendDistanceEffect` → `doCombat` (+eco → 36 no ELITE) | 120 → **7** |
| `water clock` | 45s | heavy | **10** | cada ray de combate roda 2× (`125*x` e `+1500`) e encadeia `doDrown(...,5)` | 154 → **15** |
| `water bloodbending` | 90s | ult | **16** | `rollClock(times=8)` × (`combat` área + `combat2` alvo) | 323 → **20** |
| `fire conflagration` | 90s | ult | **11** | `doConflagration` recursiona `times=10` + o cast inicial | 336 → **31** |
| `water shards` | 12s | core | **10** | estados 1/3 alternados por 3s → ~10 `combat2` no alvo | 67 → **7** |
| `fire striker` | 45s | heavy | **9** | `for x = 0, 8` → `sendDamage` → `doCombat` | 83 → **9** |
| `fire thunderbolt` | 15s | core | **8** | `doCombat(combat)` + `doCombat(combat3)` + `doElectrify(...,6)` | 113 → **14** |
| `water tsunami` | 45s | heavy | **7** | 7 áreas cumulativas, cada uma com `onTargetTile` → `doCombat` | 130 → **19** |
| `water dragon` | 25s | heavy | **5** | `dragonWork` id 0..3 + `doCombat(combat)` inicial | 127 → **25** |
| `earth quake` | 45s | heavy | **5** | `spellStageCount(4)` → 5 rodadas no ELITE | 104 → **52** |
| `earth lavaball` | 60s | ult | **5** | `doCombat(combat)` + `doMelt(...,4)` (+eco em `combat2`) | 173 → **35** |
| `fire meteor` | 45s | heavy | **5** | 5 `startWaves` (área central) | 53 → **11** |
| `air stormcall` | 45s | heavy | **8** | 4 `stormcallWork` × 2 combates no mesmo tornado | 72 → **9** |
| `air doom` | 45s | heavy | **4** | 4 `posQuakeWork`, 1 acerto por rodada | 114 → **29** |
| `air bomb` | 30s | heavy | **2** | `doCombat(combat)` + `doCombat(combat2)` [metade] | 204 → **102** |
| `earth cataclysm` | 45s | heavy | **2** | `combat` + `combat2` [metade] | 204 → **102** |
| `earth fists` | 15s | core | **2** | `combat` imediato + `combat2` (250ms) | 76 → **38** |
| `fire cannon` | 8s | core | **2** | 2 linhas (`h=1,2`) na direção, +eco | 29 → **15** |
| `fire explosion` | 25s | heavy | **2** | `combatSelf` + 1 direção, +eco | 37 → **18** |

**Não precisaram de nada:** `earth leech` (aplicação única; os "3" do scanner
eram o helper `getDamage`) e `air trap` (utilidade, sem dano). O scanner de
`tools/spell_applications_report.pl` marcava as duas como CANDIDATA — é o falso
positivo esperado (ele conta ramos de código, não golpes sequenciais).

**Impacto:** o total do cast dessas magias caiu para o orçamento da classe. As
demais 54 magias ficaram estáveis (o reemit é linear; o ±1 é o midpoint
aleatório da fórmula). Validação: `tools/_validate_spells_exausted.pl` →
"nenhuma vírgula faltando, balanceamento íntegro"; `check_lua_syntax.py` → 0
problemas.

**Ressalva:** as contagens de `water clock`, `air stormcall`, `fire meteor` e
`water tsunami` são estimativas de pior caso (geometria/worker); as demais são
contagens diretas de `for`/recursão. Se em jogo alguma ainda apagar alvo, o
número em `%APPLICATIONS` é o único lugar a ajustar (e reemitir).

## 17. Ajuste v5 — +100% de dano global (calibração preservada)

O feedback de jogo foi que o dano por golpe ficou baixo demais no level alto
(level 500 batendo ~80 nas magias de vários golpes, depois do corte da §16).
A resposta **não** foi mexer em `atk` de novo — isso seria desfeito no próximo
`--model --emit`. O corte virou um **ajuste de servidor**:

- `data/lib/avatar lib.lua`: novo `SPELL_BALANCE_GLOBAL_MULT = 2.00`,
  aplicado no **fim** de `applySpellBalance` (depois do fator de elemento, do
  bend e do eco). 1.00 = modelo v2 puro; 2.00 = +100%.

Por que ali: o `--model --emit` calibra o `atk` em dano **bruto** (antes deste
multiplicador), então a calibração continua válida e um novo reemit **não
desfaz** o buff. A hierarquia entre vocações (fogo 1.10 > ar 1.00 > terra 0.95
> água 0.90) e a escada por classe/área também ficam intactas — tudo sobe 2x.

Escopo: só magia de **dano** de player (`remakeValue`/`remakeAirEarth`). Não
pega cura (`water heal`/`earth ingrain` calculam por fora), monstro, summon nem
dano de arma.

Verificação (`level 500, bend 80`): mediana de dano/cast subiu de ~1.4k para
~2.8k no fogo e de ~1.8k para ~3.5k no ar; `check_lua_syntax.py` → 0
problemas; `_validate_spells_exausted.pl` → balanceamento íntegro. O relatório
passou a exibir `dano global x2.00` no cabeçalho e no medidor (`dmg_final`).

**Ponto de atenção (pré-existente, não tocado aqui):** `air stormcall` mede
~25k por cast no level 500 — ordens acima do orçamento da classe. É a
aproximação do `%APPLICATIONS` (8) contra a fórmula real da magia em level alto,
que o `--model` só calibra no level 100. Fica registrado para uma próxima
passada de contagem.

---

## 18. REVERSÃO — paridade com o servidor de referência (`raava ot wind`)

> **As seções 6 a 17 deste documento estão OBSOLETAS.** Elas descrevem o modelo
de balanceamento v2/v5, que foi **removido** do servidor. Servem agora apenas
como histórico do que existiu. O modelo em vigor é o da seção abaixo.

O alvo passou a ser **paridade literal** com o servidor de referência em
`C:\Users\imfis\Desktop\raava ot wind`: mesmo dano por magia, mesma lista e
mesmos nomes na spellbar. O sistema de estágios (mini/base/elite) foi removido.

### 18.1 O que mudou

| Camada | Antes (v2/v5) | Agora (= referência) |
|---|---|---|
| Fórmula de dano das magias | usava `(level * 0.5)` no lugar do bend | usa **`magLevel`** (o bend), como o original |
| Multiplicador de dano | `applySpellBalance`: fator de elemento (fogo 1.10 · ar 1.00 · terra 0.95 · água 0.90), curva de level, bend decrescente (×1.45 em bend 48) e `SPELL_BALANCE_GLOBAL_MULT = 2.00` | **nenhum**. `remakeValue`/`remakeAirEarth` só aplicam reset 750+ (+15%), debuff de jump, órbita/cometa (±20%), item 90526i1 (+5%) e skull vermelha (÷4) |
| `atk` de cada dobra (`spellsInfo`) | recalibrado pelo emissor (ex: `air suffocation` 7, `water bloodbending` 20) | **valores do raava** (100 = dano original da fórmula; ex: `air suffocation` 35, `water bloodbending` 100) |
| Cooldowns (`*Exausted`) | `ball` 1→3s, `leech` 3→15s, `thunderbolt` 12→15s, `punch` 6→10s, `iceSpikes` 15→4s, `skyfall` 10→3s | voltaram aos do raava (1s, 3s, 12s, 6s, 15s, 10s) |
| Estágios (mini/elite) | `spellStages.lua` + `registerSpellStageEcho`/`setCombatStageScaling` + eco de 0.5× no level 100+ | **sistema removido** (ver 18.3) |
| Scripts de magia | 142 arquivos, 28 deles com código só do servidor atual | **os 142 são os do raava** (mais `air/furydown`, `air/furyup`, `water/res`; saíram `water/freeze` e o hook de estágio) |
| Spellbar | `Fire Wave` (lvl1), `Fire Cinder`, `Water Wave` (lvl1), `Water Freeze` | `Fire Whip` (lvl1), `Fire Res`, `Water Whip` (lvl1), `Water Res`; `Fire Wave` (lvl 8) e `Water Wave` (lvl 16) voltam a ser as dobras cruzadas de voc 6 |
| Ferramentas | `spell_balance_report.pl`, `apply_level_scaling.pl`, `spell_applications_report.pl`, `apply_spell_stages.py`, `fix_spell_stage_insert.py`, `report_spell_stages.py` | **removidas** (todas mediam/emitiam o modelo extinto) |

### 18.2 Magias renomeadas na spellbar

| Antes | Agora | Onde |
|---|---|---|
| `Fire Wave` (lvl 1, `fire/wave.lua`) | `Fire Whip` (lvl 1, `fire/whip.lua`) | `spells.xml`, `199-ServerToDll.lua` |
| — | `Fire Wave` (lvl 8, voc 6, `fire/wave.lua`) | `spells.xml` |
| `Fire Cinder` (`fire/res.lua`) | `Fire Res` (`fire/res.lua`, `direction=1` em vez de `needtarget`) | `spells.xml`, `199-ServerToDll.lua`, `201-spellsExausted.lua` |
| `Water Wave` (lvl 1, `water/whip.lua`) | `Water Whip` (lvl 1, `water/whip.lua`) | `spells.xml`, `199-ServerToDll.lua` |
| — | `Water Wave` (lvl 16, voc 6, `water/wave.lua`) | `spells.xml` |
| `Water Freeze` (`water/freeze.lua`) | `Water Res` (`water/res.lua`, `direction=1`) | `spells.xml`, `199-ServerToDll.lua`, `201-spellsExausted.lua` |

Outros alvos padrão voltaram ao original: `Fire Star` (sem `needtarget`/`range`),
`Fire Voltage` e `Earth Crush` (`direction=1` em vez de `selftarget=1`).

Os textos que citavam os nomes antigos foram atualizados: `data/lib/upgrade lib.lua`
(upgrades 7 do fogo e 6 da água), `data/talkactions/scripts/stats.lua`,
`data/npc/scripts/fireisland.lua`, `data/npc/scripts/waterisland.lua` e os tutoriais
`data/talkactions/scripts/tutorial/fire whip.lua` / `water whip.lua`.

### 18.3 O sistema de estágios foi removido

- `data/spells/lib/spellStages.lua` **deletado** (era ele que sombrava o
  `doCombat` global e ligava o eco).
- Todas as chamadas `setCombatStageScaling(combat)`, `registerSpellStageEcho(combat)`,
  `registerSpellStageCombats`, `spellStageElite/Echo/Flavor/Scale/Count/...`
  saíram junto com os scripts (os do raava não as têm). Nada mais referencia esses
  símbolos em `data/` — confirmado por varredura.
- No motor (`sources/luascript.cpp`, `sources/combat.cpp|h`) a função
  `setCombatStageScaling` e `Combat::getStageArea()` **continuam compiladas**, mas
  agora são código morto: nenhum script as chama. Removê-las exigiria recompilar o
  `theforgottenserver.exe`; não foi feito.

### 18.4 Chaves de storage preservadas (progresso dos jogadores)

Os nomes internos de progressão **não** foram renomeados, só o texto exibido:
`levelWaterfreeze`/`expWaterfreeze`, `WaterfreezeLvL4` e `levelWaterfreeze`
continuam iguais — mudou apenas o `storageName` mostrado ao jogador
("Water Freeze" → "Water Res"). Assim ninguém perde nível de dobra.

Já o `atk` de `spellsInfo` passou a responder pelas palavras novas (`fire res`,
`water res`), que é o que os scripts do raava procuram.

### 18.5 Diferença proposital em relação ao raava

Uma só: **`remakeValue`/`remakeAirEarth` continuam aplicando o talento
`talentBendDmgBonus`** (árvore de talentos do servidor atual). Sem talento o
valor é 0 e o dano é idêntico ao raava; com talento, o jogador bate acima.
Para paridade absoluta, apagar os dois blocos `talentBendDmgBonus` em
`data/lib/avatar lib.lua`.

### 18.6 O que se perdeu junto (features só do servidor atual)

Os 28 scripts que divergiam do raava foram substituídos pelos do raava, então
saíram junto com eles:

- `earth/quake` e o dano de monstro lido do XML da criatura (via `monsterSpell`);
- `fire/star` em 8 golpes com efeitos alternados e `fire/kick`/`fire/voltage`/
  `water/iceSpikes`/`water/heal`/`water/whip` reescritos;
- os hooks de talento dentro das fórmulas (`talentBendDmgBonus`).

Tudo isso está no histórico do git (commit `dbe08cf`, o HEAD anterior) — dá para
recuperar qualquer arquivo com `git show dbe08cf:"caminho"`.

### 18.7 Verificação executada

```
python tools/check_lua_syntax.py data/spells/scripts data/spells/lib data/lib data/creaturescripts/scripts
  -> 319 arquivo(s) verificado(s), 0 com problema
perl tools/_validate_spells_exausted.pl data/lib/201-spellsExausted.lua
  -> OK: nenhuma virgula faltando, balanceamento integro
```

Além disso: `spells.xml` continua XML válido (158 `<instant>`, sem nomes
duplicados); toda palavra da spellbar (`199-ServerToDll.lua`, 100 entradas) tem
uma magia correspondente no `spells.xml`, exceto as 4 entradas `*searcher`, que
já não existiam no raava; toda chave lida pelos scripts (`spellsInfo["..."]`)
existe na tabela, exceto `earth kick` (idem no raava); e nenhum arquivo do
datapack cita mais `Fire Cinder`, `Water Freeze`, `firecinder` ou `waterfreeze`.

**Não testado em servidor rodando** — a validação foi estática (sintaxe, XML,
tabelas, referências cruzadas). O teste de jogo é o próximo passo.

### 18.8 Como voltar atrás

```
git checkout dbe08cf -- data/lib data/spells data/creaturescripts data/npc data/talkactions tools
```

---

## 19. Correção — recursão no `statschange` ("Call stack overflow")

### 19.1 Sintoma

Em partidas com muita coisa acontecendo ao mesmo tempo (PvP com redução e
reflexão ativas, AoE em vários alvos, avatar mode), o console imprime:

```
[Error - CreatureEvent::executeStatsChange] Call stack overflow.
```

Não é crash: **o evento é pulado em silêncio** — enquanto a cadeia está no teto,
a magia/AoE deixa de aplicar o dano.

### 19.2 O que o motor faz

`sources/luascript.h:250-267` — `reserveEnv()`/`releaseEnv()` são um contador
**estático (global)** de execuções Lua **simultâneas**:

```cpp
static bool reserveEnv() {
    if(++m_scriptEnvIndex > 20) { --m_scriptEnvIndex; return false; }
    return true;
}
```

- 21 slots (`m_scriptEnv[21]`, índice começa em -1), compartilhados por magia,
  action, movement, creature event, `addEvent`, talkaction, NPC, weapon e
  callback de dano.
- O teto existe porque cada nível de aninhamento também é recursão C++ real
  (Lua -> C++ -> Lua); subir o número sem tratar a cadeia apenas troca "evento
  ignorado" por "servidor cai".

### 19.3 A causa neste datapack

`data/creaturescripts/creaturescripts.xml` registra **7** eventos em
`statschange`. Cinco deles causam dano de DENTRO do próprio `onStatsChange`, e
essas chamadas (`doTargetCombatHealth`, `doCombat`, `doCreatureAddHealth`
negativo) são **síncronas**: disparam um `statschange` completo dentro do handler
que ainda está rodando.

| script | o que gera dano dentro do handler |
|---|---|
| `imuneable.lua:482,498` | dano reduzido (PvP e buffs de redução) |
| `imuneable.lua:515,517` | reflexão (`BendReflection`) |
| `imuneable.lua:532` | reflexão (`belzeAtivo`) |
| `imuneable.lua:568,571` | procs do armor chest/set |
| `proficiencyCombat.lua:127` | dano reduzido (proficiency + talento de armadura) |
| `statueBonus.lua:76` | +5% da nação (PvE) |
| `pvpDamageBonus.lua:118` | +200% do PvP |
| `reflect.lua:51` | dano refletido |

Cada script protegia apenas a **própria** reentrada (flag em storage própria:
`antiloop`, `antiloopDois`, `REDUCTION_LOOP_KEY`, `LOOP_KEY`), e essas flags são
**limpas dentro da passagem aninhada**:

```lua
elseif isPlayer(cid) and getPlayerStorageValue(cid, "antiloop") == 1 then
    setPlayerStorageValue(cid, "antiloop", -1)   -- libera a trava no nivel de baixo
end
```

Resultado: dois scripts diferentes se alimentavam mutuamente (reduz -> o dano
reduzido recebe +X% -> o dano com bônus é reduzido de novo -> ...), **+1 nível por
rodada** até estourar os 21.

### 19.4 A correção

Nova lib **`data/lib/combatRecursionGuard.lua`** (auto-carregada pelo
`loadDirectory` de `lib/`; todos os creature events compartilham a mesma
interface/Lua state, então a tabela global enxerga os 5 scripts):

```lua
CombatRecursionGuard.isInside()      -- estamos dentro de dano gerado por script?
CombatRecursionGuard.run(fn, ...)    -- marca o dano que ESTE script gera
```

Quem **bloqueia** (usa `isInside()`): `imuneable.lua` (5 pontos),
`proficiencyCombat.lua`, `reflect.lua` — exatamente os handlers que
**reduzem/cancelam** ou **refletem**. Aplicar isso em cima de dano já gerado por
script era o que alimentava o ciclo.

Quem apenas **marca** (`run()` no envio): `statueBonus.lua` e
`pvpDamageBonus.lua`. São amplificadores, e o percentual deles (`+5%`, `+200%` —
este último existe para compensar o `/2` que o motor aplica em player x player)
continua valendo integralmente no hit original. Decisão consciente: bloquear os
amplificadores também derrubaria o dano de PvP contra quem tem redução em
~metade, sem o dono do servidor ter pedido.

Teto de aninhamento depois da correção: `cast/movement` (1) -> `statschange` (2)
-> reenvio marcado (3) -> amplificador, limitado pela trava própria (4) -> fim.

### 19.5 Arquivos

```
data/lib/combatRecursionGuard.lua                    (novo)
data/creaturescripts/scripts/imuneable.lua           5 travas + 7 envios marcados
data/creaturescripts/scripts/proficiencyCombat.lua   1 trava + 1 envio marcado
data/creaturescripts/scripts/statueBonus.lua         envio marcado
data/creaturescripts/scripts/pvpDamageBonus.lua      envio marcado
data/creaturescripts/scripts/reflect.lua             1 trava + 1 envio marcado
```

### 19.6 Verificação executada

```
python tools/check_lua_syntax.py data/lib/combatRecursionGuard.lua \
  data/creaturescripts/scripts/imuneable.lua data/creaturescripts/scripts/proficiencyCombat.lua \
  data/creaturescripts/scripts/statueBonus.lua data/creaturescripts/scripts/pvpDamageBonus.lua \
  data/creaturescripts/scripts/reflect.lua
  -> 6 arquivo(s) verificado(s), 0 com problema

luaparser (parser Lua real) nos 6 arquivos            -> sintaxe OK
git diff --stat                                       -> 5 arquivos, +58/-17
```

Nenhum arquivo foi reescrito por EOL: `pvpDamageBonus.lua` continua CRLF
(119 linhas / 119 CRs) e os demais continuam LF. O `cat -A` de cada ponto
alterado foi conferido (sem linha colada).

**Não testado em servidor rodando** — a validação foi estática.

### 19.7 Bugs de motor encontrados (NÃO corrigidos aqui)

`sources/combat.cpp` tem três caminhos que reservam um slot de env e retornam
**sem devolvê-lo**:

```
combat.cpp:1255-1256  ValueCallback::getMinMaxValues  if(!env->setCallbackId(...)) return;
combat.cpp:1351-1352  TileCallback::onTileCombat      if(!env->setCallbackId(...)) return;
combat.cpp:1376-1377  TargetCallback::onTargetCombat  if(!env->setCallbackId(...)) return;
```

`setCallbackId` falha quando o slot já tem callback e imprime `Nested callbacks!`.
Cada falha **nunca devolve o slot**: o contador sobe e não desce, e depois de 21
vazamentos *todo* evento scriptado do servidor passa a responder "Call stack
overflow" até reiniciar. Neste datapack só o de `ValueCallback` é alcançável
(`imuneable.lua` registra `setCombatCallback(... CALLBACK_PARAM_LEVELMAGICVALUE ...)`) —
se aparecer `Nested callbacks!` no console, é este vazamento. A correção exige
recompilar o servidor.

### 19.8 Como voltar atrás

```
git checkout -- data/creaturescripts/scripts
rm data/lib/combatRecursionGuard.lua
```

---

## 20. Auditoria de paridade — camada de magias (`raava ot wind` -> atual)

Medição feita arquivo por arquivo + comparação **estrutural** (tabela por tabela,
spell por spell) entre `C:\Users\imfis\Desktop\raava ot wind` e
`C:\Users\imfis\Desktop\Avatar-Compraado-server`, neutralizando acentos (o raava
é Latin-1) e quebras de linha.

### 20.1 Veredito por camada

| camada | resultado |
|---|---|
| `data/spells/scripts/**` (146 arquivos) | **idênticos** ao raava, 0 diferenças. O atual tem 1 arquivo extra (`monster/monsterSpell.lua`, feature própria) |
| `data/spells/lib/**` | **idêntico** (0 diferenças) |
| `data/spells/spells.xml` | as **117** magias do raava estão todas presentes, com atributos (`words`, `lvl`, `mana`, `exhaustion`, `aggressive`, `event`, `value`) e `<vocation>` **idênticos**. O atual tem 159 entradas = 117 + 42 extras (48 com `enabled="0"` são magias de monstro da feature própria) |
| `spellsInfo` (`201-spellsExausted.lua`) | **101 magias**, 0 faltando, 0 campos diferentes |
| tabelas de cooldown `airExausted` / `earthExausted` / `fireExausted` / `waterExausted` | **idênticas** (81 / 87 / 81 / 87 campos) |
| `199-ServerToDll.lua` (lista da spellbar) | **idêntico** |
| `248-Spells Info.lua`, `100-shortcut.lua` | **idênticos** |
| `data/weapons/**` | **idêntico** |
| `avatar lib.lua` (dano) | raava **+** `talentBendDmgBonus` (2 pontos, §18). As 6 funções de escolha de Avatar do raava não existem no atual (aqui o Avatar vem de item/battle royale) |
| `spellLevelSystem.lua` (crescimento) | idêntico em **todos** os `needLevel` / `porcentageDamage` / `needStorage`. Única diferença: chaves de storage do `res` (`levelWaterfreeze`/`WaterfreezeLvL4` no atual vs `levelWaterres`/`WaterresLvL4` no raava) - mantidas de propósito para ninguém perder progresso |
| `upgrade lib.lua` (pedras de aprimoramento) | idêntico (após 20.2) |
| `203-serverToOTC.lua` | atual **mais defensivo** (nil-checks em `refreshSpellsFunc`); nada perdido |
| `203-buyFolds.lua` | atual tem 4 helpers extras (`getFoldDisplayName`, `getFoldSlot`, `foldSlotTables`, `displayName` em `getListLearnFold`) e **não exige resets** para aprender dobra (o raava exige 100, 150 na última) - ver 20.3 |
| `247-Extra Funcs.lua` | nada de magia/dano faltando (as diferenças são `paragonRewards`/`applyFloat`) |
| scripts referenciados pelo `spells.xml` | 118 referências, **todas existem no disco** (0 faltando) |

Verificação cruzada de identificadores: `spellsInfo["..."]` usados pelos scripts
existem na tabela; campos `*Exausted.<campo>` usados pelos scripts (122) existem
no raava e no atual com o mesmo conjunto.

### 20.2 O que faltava e foi corrigido

**(a) `canPlayerStartFly` - função de magia quebrada.** O raava define em
`data/lib/202-playerCanDoIt.lua`; o atual não tinha, mas
`data/spells/scripts/air/furyup.lua:13` chama a função. Restaurada (com os mesmos
avisos, usando `doPlayerSendCancelEf` + `getLangString`, que existem nos dois).
Observação: `air/furyup.lua` não é referenciada por nenhum XML/script em nenhum
dos dois servidores, então o defeito era **latente** (só apareceria quando alguém
registrasse a magia), mas a paridade agora é total.

**(b) Texto de aprimoramento errado.** `upgrade lib.lua:84` dizia
`Water IceSpikes ... de 4s para 1s`. O valor real é o da tabela
(`waterExausted.iceSpikes = 15`) e o script aplica `waterExausted.iceSpikes-3`,
ou seja **15s -> 12s** (exatamente o texto do raava). Corrigido.

Auditoria automática de funções Lua: o raava define **398** funções em
`data/lib**`, o atual **448**; 58 do raava não existem no atual e, dessas, apenas
**uma** ainda era chamada (a `canPlayerStartFly`, agora resolvida).

### 20.3 Divergências intencionais (não são falhas de port)

1. `talentBendDmgBonus` no dano (§18) - única diferença proposital de balanceamento.
2. Chaves de storage do `res` no `spellLevelSystem` - preserva o nível das dobras de quem já jogava.
3. `203-buyFolds.lua` sem a exigência de resets (o raava pede 100/150 resets + pedras) - **isto é diferença de progressão**: no atual dá para aprender dobra só com pedras. Decisão do dono do servidor; para voltar ao raava é reinserir o bloco `counter`.
4. Magias de monstro (`enabled="0"` + `monster/monsterSpell.lua` + `tools/gen_monster_spells.py` + `lib/monsterSpellBook.lua`) - feature só do atual.
5. Escolha de Avatar por sorteio (raava: `searchAvatar`/`makeNewAvatar`/`randomizeNewAvatar` + broadcast no login) não existe no atual; aqui o `isAvatar` é setado por item de pergaminho e por battle royale. Leitura de `isAvatar` continua funcionando (revive do `imuneable`, `avatarAttack`, `onSee`).

### 20.4 Pendência fora de magia (não corrigida)

`data/npc/scripts/itemMissions.lua:140` chama `getTasksCompleted`, que só existe
no raava (`data/lib/isoled/152-npcTaskSystem.lua`; o atual tem só
`150-npcSystem.lua`). O NPC `Palomino.xml` usa esse script, então o ramo de
tarefas desse NPC erra em runtime. É o sistema de tarefas de NPC inteiro
(1000+ linhas) - não é magia e **não foi portado**; precisa de decisão.

### 20.5 Como repetir a auditoria

- scripts/xml: `diff -rq --strip-trailing-cr` entre as duas árvores.
- `spells.xml`: parse por `name`, comparando `attrib` + filhos `<vocation>`.
- `spellsInfo` e `*Exausted`: parser de tabela Lua (casamento de chaves e
  normalização de espaços), não diff de texto.
- funções: extrair `function NOME(` de `data/lib**` nos dois lados e procurar
  quem chama as que faltam no atual.

---

## 21. REVERSÃO da paridade — o dano volta ao modelo v2/v5

> A **§18 (e as tabelas de nome dela) está obsoleta**: a paridade foi desfeita.
> O modelo em vigor volta a ser o das §6 a §17.

### 21.1 Por quê

Depois da §18 o dono do servidor relatou dano incoerente entre magias: "todas ou
muito altas ou muito bosta". A causa foi medida no próprio diff da paridade: ela
trocou, em **86 scripts**, `magLevelUnused` + `(level * 0.5)` por `magLevel`.

Como aqui o **bend é o magic level do motor** e a tabela de pontos satura em ~70-85
(custo 15 por ponto acima de 70), o `magLevel` da fórmula é pequeno e travado — então
o **level passou a mandar sozinho** (`level + ~44` no level 500) e o `atk` cru do
raava (18 a 650) apareceu sem nenhum dos amortecedores que davam coerência ao
conjunto: fator de elemento, curva de level, bend com retorno decrescente e
`SPELL_BALANCE_GLOBAL_MULT`. Trocar o magic level pelo bend, sozinho, foi isso.

### 21.2 O que voltou (estado do commit `dbe08cf`, o anterior à §18)

| camada | agora |
|---|---|
| fórmulas (86 scripts) | `magLevelUnused` + `(level * 0.5)`, como no v5 |
| `data/lib/avatar lib.lua` | `applySpellBalance` = fator de elemento + `getSpellLevelCurve` + `getBendDamageBonus` + `SPELL_BALANCE_GLOBAL_MULT = 2.00` |
| `atk` (`spellsInfo`) | recalibrado pelo emissor (v5) |
| cooldowns (`*Exausted`) | v5 (`ball` 3s, `leech` 15s, `iceSpikes` 4s, `skyfall` 3s...) |
| estágios | `data/spells/lib/spellStages.lua` de volta, com `registerSpellStageEcho`/`setCombatStageScaling` (51 chamadas em 37 arquivos) |
| spellbar e nomes | `Fire Wave` / `Fire Cinder` / `Water Wave` / `Water Freeze`; `199-ServerToDll.lua` do v5 |
| crescimento | `spellLevelSystem.lua` do v5 |
| scripts de magia | os 117 do v5, com os extras do servidor (`fire/star` em 8 golpes, `earth/quake` lendo o XML do monstro, `water/heal` reescrito) |
| ferramentas | `spell_balance_report.pl`, `spell_applications_report.pl`, `apply_level_scaling.pl`, `apply_spell_stages.py`, `fix_spell_stage_insert.py`, `report_spell_stages.py` restauradas |

### 21.3 O que NÃO foi desfeito (de propósito)

- **O guard de recursão (§19)**: `data/lib/combatRecursionGuard.lua` e as marcas nos
  cinco scripts de `statschange` continuam. No `imuneable.lua` foram desfeitos
  **só** os 3 hunks da §18 (`magLevelUnused` e o `atk` congelado de 175/214) — os 7
  envios marcados seguem lá.
- **`canPlayerStartFly`** (§20.2) continua restaurada em `202-playerCanDoIt.lua`.

### 21.4 Cliente

O `Client pra jogar com tonto` voltou para `Fire Wave` / `Fire Cinder` /
`Water Wave` / `Water Freeze` (`modules/game_folds/configs.lua`, restaurado do
backup `configs.lua.bak_firewhip`) e o `data/sounds/README.txt` foi acertado nos
4 nomes. Conferido por script: **96 de 96** nomes (e `var`s) da lista do cliente
têm magia correspondente no `spells.xml`. Os outros dois clientes
(`Avatar-comprado-client` e `... - Copia`) já estavam com os nomes antigos e
nunca foram tocados — ficaram coerentes outra vez.

### 21.5 Verificação executada

```
python tools/check_lua_syntax.py data/spells/scripts data/spells/lib data/lib data/creaturescripts/scripts data/npc
  -> 429 arquivo(s) verificado(s), 0 com problema
perl tools/_validate_spells_exausted.pl data/lib/201-spellsExausted.lua
  -> OK: nenhuma virgula faltando, balanceamento integro
```

- `spellsInfo`: **101** chaves definidas e **0 uso órfão** em todo o `data/`
  (varredura com parser, não diff de texto).
- 11 campos `*Exausted.X` lidos por scripts não existem nas tabelas do v5 — mas
  **também não existiam na versão da paridade**, e nenhum desses scripts está
  registrado no `spells.xml` (`air/scape`, `water/purify`, `water/bubble`,
  `fire/light`, `earth/kick`...). São scripts mortos: não é regressão da reversão.
- `spellStages.lua` é lido pelo motor (o diretório `data/spells/lib/` é varrido
  antes do `spells.xml`), então as 51 chamadas de estágio têm definição.
- **Não testado em servidor rodando** — a validação foi estática.

### 21.6 Como refazer a paridade (se quiser voltar)

```
git checkout f38480d -- data/spells data/lib/199-ServerToDll.lua data/lib/201-spellsExausted.lua \
  data/lib/203-buyFolds.lua "data/lib/avatar lib.lua" data/lib/spellLevelSystem.lua \
  "data/lib/upgrade lib.lua" data/creaturescripts/scripts/avatarAttack.lua data/npc \
  data/talkactions/scripts/stats.lua
```

No cliente, é só reaplicar os 4 nomes de `modules/game_folds/configs.lua`.

### 21.7 Correção de registro

A §20.3 item 5 dizia que `searchAvatar`/`makeNewAvatar`/`randomizeNewAvatar` são
"feature só do atual". Está errado: elas foram **apagadas** em `410802e` (05/set),
junto com `aisNonPvp`/`aisInPz`/`aisGM` e a talkaction `testAvatar`, substituídas
por `avatarTracker.lua`. Não existem em nenhum arquivo hoje, mas o git devolve:
`git show 410802e~1:"data/lib/avatar lib.lua"`.

---

## 22. Nivelamento do dano entre os quatro elementos

### 22.1 Objetivo e ponto de partida

Depois da reversão (§21), o modelo v5 estava de volta: **cada magia já era**
batia o alvo do modelo (§6) em dano BRUTO — o `--model --emit` só propunha
diferenças de 1 a 3 atk em 73 magias. O problema não estava na magia isolada,
e sim **entre as vocações**: a mediana de dano/cast ia de 359 (terra) a 665 (ar)
no level 100, ou seja **1,85x** de diferença, e isso se mantinha no 300 e no 500.

| level / bend | fire | water | air | earth | spread |
|---|---|---|---|---|---|
| 100 / 48 | 556 | 530 | 665 | 359 | **1,85x** |
| 300 / 71 | 1.664 | 1.650 | 2.058 | 1.153 | **1,78x** |
| 500 / 85 | 2.835 | 2.826 | 3.521 | 1.985 | **1,77x** |

### 22.2 O que foi feito

Duas tabelas do `data/lib/avatar lib.lua` — as duas que o próprio lib deixou
preparadas para isso:

1. `SPELL_BALANCE` (fator constante por elemento) iguala as medianas **no ponto
de calibração** (level 100).
2. `SPELL_BALANCE_LEVEL_GROWTH` (correção `1 + b·x + c·x²`, com `x = level - 100`)
segura a igualdade nos outros levels, porque a mediana de cada elemento cresce
com um coeficiente próprio.

Os números não foram chutados: medi os três pontos com
`perl tools/spell_balance_report.pl --level N --mag B --json` (100/48, 300/71,
500/85), tirei a mediana de dano/cast por elemento e resolvi
`mediana(elemento) · correção(L) = média das quatro` — `b` e `c` saem de duas
equações (dois levels), solução exata.

| | fire | water | air | earth |
|---|---|---|---|---|
| `SPELL_BALANCE` (era) | 1.10 | 0.90 | 1.00 | 0.95 |
| `SPELL_BALANCE` (agora) | **1.0441** | **0.8953** | **0.7933** | **1.3956** |
| `b` | 2,328632e-04 | -4,477009e-05 | -5,627562e-06 | -2,632917e-04 |
| `c` | -3,470510e-07 | 6,794450e-08 | 1,093442e-08 | 3,907051e-07 |

### 22.3 Resultado medido

| level | fire | water | air | earth | média (preservada) | spread |
|---|---|---|---|---|---|---|
| 25 | 163 | 170 | 148 | 140 | 155 | 1,21x |
| 50 | 276 | 285 | 273 | 254 | 272 | 1,12x |
| 100 | 527 | 527 | 529 | 527 | **527** | **1,00x** |
| 300 | 1.632 | 1.631 | 1.631 | 1.631 | **1.631** | **1,00x** |
| 500 | 2.792 | 2.792 | 2.792 | 2.792 | **2.792** | **1,00x** |

A média das quatro vocações **em cada level é exatamente a de antes** (527,
1.631 e 2.792): ninguém ganhou ou perdeu poder no conjunto — o que aconteceu foi
redistribuição. Abaixo do level 100 a correção extrapola de leve (1,2x no 25),
que é o preço de calibrar em três pontos.

### 22.4 O que isso **não** resolve (e precisa da sua decisão)

O DPS **não** ficou igual, e não tem como ficar por multiplicador: quem decide o
DPS é o cooldown, que é diferente por elemento. Mediana de DPS depois do ajuste:

| level | fire | water | air | earth | spread |
|---|---|---|---|---|---|
| 100 | 35,1 | 26,4 | 23,5 | 35,1 | 1,50x |
| 500 | 185 | 129 | 125 | 186 | 1,49x |

Ou seja: o dano por cast agora é justo nas quatro, mas **terra e fogo rendem
~50% mais DPS que ar e água** (antes o fogo era o topo sozinho, com 37 contra
23,9 do terra). Igualar DPS é outro cálculo — o alvo deixa de ser a mediana de
dano/cast e passa a ser a de DPS, e os quatro fatores mudam de novo. Ver
§22.5 para refazer.

### 22.5 Como refazer / afinar

```
perl tools/spell_balance_report.pl --level 100 --mag 48 --json > /tmp/a.json   # idem 300/71 e 500/85
tools/spell_level_drift.pl /tmp/a.json /tmp/c.json                            # conferir deriva
```

Com a mediana de dano/cast (ou de DPS, se o alvo mudar) por elemento nos três
levels: `k = média / mediana` no level 100 para o `SPELL_BALANCE`, e o `b`/`c`
de `SPELL_BALANCE_LEVEL_GROWTH` para os outros dois pontos. Os três pontos saem
exatos; a extrapolação fora deles fica em ~1,2x.

**Não testado em servidor rodando** — a verificação é o relatório (que lê a
fórmula de cada script, o `atk` da tabela e o XML) e a checagem de sintaxe (319
arquivos, 0 problemas).
