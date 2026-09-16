# Estágios das magias — mini / padrão / elite

Documentação do sistema de estágios das magias de player: **o que a magia era antes** e
**o que ela faz em cada estágio agora**. Gerado a partir do código em disco (nada aqui foi
escrito de memória — os números de tiles saem de `tools/report_spell_stages.py`, que simula
`CombatArea::scaled()` do motor).

## Leitura rápida

| Estágio | Nível | O que acontece |
|---|---|---|
| **MINI** | 1 – 49 | Área mínima (perde o anel externo), sem efeito secundário |
| **PADRÃO** | 50 – 99 | Exatamente o que a magia sempre foi — **idêntico ao original** |
| **ELITE** | 100+ | Área máxima (ganha um anel) **ou** golpe dobrado, **+** sabor do elemento |

**Regras invioláveis**

- **O dano nunca muda.** Todos os estágios usam o mesmo callback (`onGetPlayerMinMaxValues`),
  a mesma fórmula e o mesmo `spellsInfo[spellName].atk`. Nada de escalonamento foi retocado.
- **Monstros, summons e NPCs castam sempre a área original** (`Combat::getStageArea` retorna a
  área base quando o conjurador não é player). Magias de monstro não herdam nada.
- **O estágio 2 é o comportamento antigo, bit a bit.** As áreas de mini/elite são derivadas;
  o original nunca é editado.

## Estado atual

| | |
|---|---|
| Magias declaradas em `spells.xml` | 117 |
| **Com estágio** | **70** (fire 16, water 15, air 19, earth 20) |
| Sem estágio | 47 (ver §8) |
| Áreas escaladas pelo motor | 51 chamadas `setCombatStageScaling` em 37 arquivos |
| Magias de alvo único com eco | 30 registros `registerSpellStageEcho` em 24 arquivos |
| Conversões escritas à mão | 9 arquivos |

## 1. Onde vive cada peça

| Camada | Arquivo | Papel |
|---|---|---|
| Motor (C++) | `sources/combat.cpp` | `scaleMatrixArea()`, `CombatArea::scaled()`, `Combat::getStageArea()` — deriva a área por estágio, com cache |
| Motor (C++) | `sources/combat.h` | flag `stageScaling`, cache `stageAreas[2]` |
| Binding | `sources/luascript.cpp` | `setCombatStageScaling(combat)` |
| Lib Lua | `data/spells/lib/spellStages.lua` | níveis, áreas de estágio, sabor por elemento, eco, helpers de escala, wrapper de `doCombat` (carregada automaticamente por `BaseEvents::loadFromXml`) |
| Magias | `data/spells/scripts/<elem>/*.lua` | 1 linha: `setCombatStageScaling(combat)` ou `registerSpellStageEcho(combat)` |
| Ferramentas | `tools/*.py` | `apply_spell_stages.py` (conversão em massa), `report_spell_stages.py` (relatório), `check_lua_syntax.py` / `check_lua_blocks.py` (validação) |

> **Recompilar é necessário** por causa do C++ (`combat.cpp`, `combat.h`, `luascript.cpp`).

## 2. Como o motor cresce a área

Convenção de área do TFS (`CombatArea::createArea`): **1** = tile atingido, **2** = centro
(não é dano), **3** = centro **e** dano. Sem 2/3, o centro fica em (0,0).

- **mini** → descarta todo tile cujo raio (Chebyshev) seja igual ao raio máximo da área = sai o anel externo
- **padrão** → a área original, sem tocar
- **elite** → cada tile do anel externo ganha **um vizinho "para fora"** (o formato é preservado: beam continua beam, cone continua cone, cruz continua cruz)
- **exceção**: se a área era um anel/bloco de raio 1 e o mini não deixa nada, o motor cai numa **cruz de 5 tiles em volta do conjurador** (isso é do motor, não escolha de design)

Áreas do datapack, com o resultado (tiles: mini / base / elite):

| Área | mini | base | elite | | Área | mini | base | elite |
|---|---|---|---|---|---|---|---|---|
| `AREA_BEAM4` | 4 | 5 | 6 | | `AREA_CIRCLE2X2` | 9 | 21 | 33 |
| `AREA_BEAM6` | 6 | 7 | 8 | | `AREA_CIRCLE3X3` | 25 | 37 | 49 |
| `AREA_WAVE4` | 7 | 12 | 17 | | `AREA_CROSS1X1` | 1 | 5 | 9 |
| `AREA_WAVE5` | 10 | 13 | 16 | | `AREA_CROSS5X5` | 69 | 73 | 77 |
| `AREA_SQUAREWAVE5` | 8 | 11 | 14 | | `AREA_CROSS6X6` | 81 | 85 | 89 |
| `AREA_WALLFIELD` | 3 | 5 | 7 | | `AREA_SQUARE1X1` | 1 | 9 | 17 |

## 3. Magias de alvo único → eco no elite

`registerSpellStageEcho(combat)` liga o eco: no nível 100+, o **mesmo golpe é repetido
~300 ms depois**, com o mesmo dano (na prática, dobra o golpe). O wrapper só age quando o
`var` é um alvo (`type(var) == "number"`), então **magia de área nunca duplica dano em vários
alvos** — e se o alvo morrer ou entrar em PZ, o eco não sai.

| | mini | padrão | elite |
|---|---|---|---|
| Efeito | nada muda | nada muda | 2º golpe ~300 ms depois |

**Magias com eco (24 arquivos / 30 combats):**
`fire/skyfall` (1) · `fire/cannon` (2) · `fire/bomb` (2) · `fire/clock` (2) · `fire/explosion` (1) ·
`water/iceSpikes` (1) · `water/cannon` (1) · `water/punch` (1) · `water/bubbles` (2) · `water/icebolt` (1) ·
`air/gale` (1) · `air/suffocation` (1) · `air/windblast` (1) · `earth/punch` (1) · `earth/rock` (3) ·
`earth/pull` (1) · `earth/growth` (1) · `earth/collapse` (1) · `earth/petrify` (1) · `earth/fury` (1) ·
`earth/control` (1) · `earth/smash` (1) · `earth/lavaball` (1) · `earth/metalwall` (1)

> **Lacuna conhecida:** o eco puro não aplica o slow do elemento — só o segundo golpe. Para ter o
> sabor também, é uma linha de `spellStageElite(...)` na magia (como foi feito em `fire/kick`, `fire/blast`,
> `water/explosion` e `air/ball`).

## 4. Sabor do elemento no elite

Aplicado só nas magias que chamam `spellStageElite` / `spellStageFlavor` (tabela `SPELL_ELITE_FLAVOR`):

| Elemento | Nome | Efeito | Extra |
|---|---|---|---|
| fire | **Combustão** | efeito 5 na vítima | só o efeito (o dano vem do eco) |
| water | **Correnteza** | efeito 53 | slow 35% por 1,5 s |
| air | **Vendaval** | efeito 76 | slow 25% por 1,2 s |
| earth | **Fissura** | efeito 287 | slow 40% por 1,2 s |

Onde está ligado hoje: `fire/kick` (Combustão), `fire/blast` (Combustão), `water/explosion` (Correnteza),
`air/ball` (Vendaval). `earth/crush` tem a própria Fissura (callback `onTargetCreatureFissure`) e
`fire/wave` tem um flourish de chamas no conjurador antes do cone abrir.

## 5. Kit de escala (magias sem área de dano)

Para magias cujo "crescer" não é área — cura, duração, ondas, velocidade. **Sempre** multiplica o
valor base da própria magia, então o estágio 2 sai idêntico ao de hoje.

| Função | mini (<50) | padrão | elite (100+) | Usada em |
|---|---|---|---|---|
| `spellStageHeal` | 60% | 100% | 160% | `earth/ingrain` (via `spellStageScale` 0,7×/1,6×) |
| `spellStageDuration` / `spellStageSeconds` | 60% | 100% | 160% | `earth/ingrain`, `air/trap` |
| `spellStageCount` | n−1 | n | n+1 | `earth/quake` |
| `spellStageSpeed` | 75% | 100% | 150% | — |
| `spellStageScale(base, miniF, eliteF)` | livre | base | livre | `earth/quake` (1,25×/0,7×) |

## 6. Magia por magia

Legenda: **tiles** = quantos tiles a área atinge (o conjunto pode ter mais de um combat — separados por `+`).
`[manual]` = estágio escrito à mão no script · `[área]` = derivado pelo motor · `[eco]` = segundo golpe no elite.

### 6.1 Fire (16 magias)

| Magia | lvl | Padrão 50–99 (era / é sempre) | Mini <50 | Elite 100+ | |
|---|---|---|---|---|---|
| **Fire Wave** | 1 | cone curto 7 tiles abaixo do 50; cone grande 12 tiles do 50 pra cima | cone curto (7 tiles) | leque de 5 fileiras (13 tiles) + chamas no conjurador | manual |
| **Fire Kick** | 8 | 4 rastros de chama convergindo no alvo + ricochete em até 4 alvos (4 SQM, -10% por pulo) | 2 rastros (só leste/oeste) | 4 rastros + ricochete + eco 300 ms + Combustão | manual |
| **Fire Skyfall** | 12 | golpe único | igual | 2º golpe 300 ms | eco |
| **Fire Blast** | 16 | cruz 3x3 (5 tiles) | só o tile do alvo (1) | 7x7 em volta (37 tiles) + Combustão | manual |
| **Fire Bolt** | 25 | cruz 3x3 (5) | 1 | cruz esticada (9) | área ×2 |
| **Fire Cannon** | 42 | golpe único | igual | eco (2 combats registrados) | eco |
| **Fire Lightning** | 55 | beam de 5 tiles + linha de 2 | beam de 4 + 5 | beam de 6 + 4 | área ×2 |
| **Fire Bomb** | 60 | golpe único | igual | eco (2 combats) | eco |
| **Fire Clock** | 65 | golpe único | igual | eco (2 combats) | eco |
| **Fire Thunderbolt** | 70 | 4 tiles em T | cruz de 5 (fallback do motor) | 8 tiles | área |
| **Fire Meteor** | 80 | 79 tiles | 67 | 91 | área |
| **Fire Striker** | 90 | 49 tiles (7x7) | 25 (5x5) | 73 | área ×2 |
| **Fire Overload** | 100 | 9 tiles (3x3) | 1 | 17 | área |
| **Fire Explosion** | 110 | golpe único | igual | eco | eco |
| **Fire Discharge** | 200 | 9 tiles (3x3) | 1 | 17 | área ×2 |
| **Fire Conflagration** | 250 | 37 tiles | 25 | 49 | área |

### 6.2 Water (15 magias)

| Magia | lvl | Padrão 50–99 | Mini <50 | Elite 100+ | |
|---|---|---|---|---|---|
| **Water Whip** | 1 | 8 áreas (linhas/golpes de 1 a 3 tiles) | perde o anel externo de cada uma | ganha um anel em cada uma | área |
| **Water Explosion** | 8 | cruz 3x3 (5 tiles) | só o tile do alvo (1) | 7x7 (37 tiles) + Correnteza (slow 35%/1,5 s) | manual |
| **Water IceSpikes** | 20 | golpe único | igual | eco | eco |
| **Water Shards** | 30 | 9 tiles (3x3) | 1 | 17 | área |
| **Water Cannon** | 42 | golpe único | igual | eco | eco |
| **Water Punch** | 55 | golpe único | igual | eco | eco |
| **Water Dragon** | 60 | 37 tiles (círculo 7x7) | 25 | 49 | área |
| **Water Rain** | 65 | 85 tiles | 81 | 89 | área |
| **Water Bubbles** | 70 | golpe único | igual | eco (2 combats) | eco |
| **Water IceBolt** | 90 | golpe único | igual | eco | eco |
| **Water Flow** | 100 | 9 + 80 tiles (3x3 + zona 9x9) | 1 + 48 | 17 + 112 | área ×2 |
| **Water Tsunami** | 130 | 7 ondas crescentes (3 → 15 tiles) | cada onda perde o anel externo | cada onda ganha um anel | área |
| **Water Clock** | 150 | 12 áreas próprias (4 tiles cada) | perdem o anel externo | ganham um anel | área |
| **Water Blizzard** | 200 | 21 tiles | 9 | 33 | área |
| **Water BloodBending** | 250 | 20 tiles | 8 | 32 | área |

### 6.3 Air (19 magias)

| Magia | lvl | Padrão 50–99 | Mini <50 | Elite 100+ | |
|---|---|---|---|---|---|
| **Air Ball** | 1 | golpe único + impacto de vento (efeito 76) no alvo | golpe seco, **sem** o efeito | eco 450 ms + Vendaval (slow 25%/1,2 s) | manual |
| **Air Burst** | 8 | áreas de 8 e 12 tiles | 5 e 5 | 16 e 24 | área |
| **Air Force** | 20 | cruz 3x3 (5) | 1 | 9 | área |
| **Air Gust** | 25 | 6 áreas (3 a 7 tiles) | perdem o anel externo | ganham um anel | área |
| **Air Gale** | 30 | golpe único | igual | eco | eco |
| **Air Fan** | 42 | 9 leques (3 a 5 tiles) | perdem o anel externo | ganham um anel | área |
| **Air Wings** | 46 | 11 áreas (5 a 14 tiles) | perdem o anel externo | ganham um anel | área |
| **Air Suffocation** | 50 | golpe único | igual | eco | eco |
| **Air Hurricane** | 55 | 7 áreas (3 a 7 tiles) | perdem o anel externo | ganham um anel | área |
| **Air Tempest** | 60 | 9 tiles (3x3) | 1 | 17 | área |
| **Air Windblast** | 65 | golpe único | igual | eco | eco |
| **Air Tornado** | 70 | 9 tiles (3x3) | 1 | 17 | área |
| **Air Barrier** | 80 | 9 tiles (3x3) | 1 | 17 | área |
| **Air Trap** | 90 | 1 armadilha no tile da frente, duração base | igual | armadilha na **cruz inteira** (5 tiles, cada um checando `getPlayerCanWalk`) + duração 160% | manual |
| **Air Bomb** | 110 | 8 tiles | 5 | 16 | área |
| **Air Windstorm** | 130 | 80 tiles | 48 | 112 | área |
| **Air Stormcall** | 150 | 6 nuvens concêntricas (9, 16, 26, 21, 21 tiles) | 1, 5, 16, 16, 16 | 17, 32, 36, 26, 26 | área ×6 |
| **Air Vortex** | 200 | áreas de 9 e 12 tiles | 1 e 5 | 17 e 24 | área |
| **Air Deflection** | 250 | 48 tiles | 24 | 72 | área |

### 6.4 Earth (20 magias)

| Magia | lvl | Padrão 50–99 | Mini <50 | Elite 100+ | |
|---|---|---|---|---|---|
| **Earth Crush** | 1 | 3x3 em volta (9 tiles), 3 ondas de 500 ms | cruz de 4 tiles em volta, 3 ondas | 5x5 (25 tiles), **4 ondas** + Fissura (slow 40%/1,2 s) | manual |
| **Earth Punch** | 8 | golpe único | igual | eco | eco |
| **Earth Rock** | 12 | golpe único | igual | eco (3 combats) | eco |
| **Earth Pull** | 20 | golpe único | igual | eco | eco |
| **Earth Growth** | 25 | golpe único | igual | eco | eco |
| **Earth Collapse** | 30 | golpe único | igual | eco | eco |
| **Earth Petrify** | 42 | golpe único | igual | eco | eco |
| **Earth Fury** | 46 | golpe único | igual | eco | eco |
| **Earth Control** | 50 | golpe único (sem área) | igual | eco | eco |
| **Earth Leech** | 55 | 8 tiles | 5 | 16 | área |
| **Earth Smash** | 60 | golpe único | igual | eco | eco |
| **Earth Ingrain** | 65 | cura 4,7% do HP máx por tick × `cf.heal`; raiz dura `cf.segundos` | cura 70%, raiz 60% | cura **160%**, raiz **160%** | manual |
| **Earth Fists** | 70 | 9 tiles | 6 | 12 | área ×2 |
| **Earth Arena** | 80 | 40 tiles | 28 | 52 | área |
| **Earth Curse** | 90 | 9 tiles (3x3) | 1 | 17 | área |
| **Earth Quake** | 100 | 4 rodadas de tremor (1 s entre elas) × 4 ondas internas (200 ms) | 3 rodadas (1,25 s) × 3 ondas (250 ms) | **5 rodadas (700 ms) × 5 ondas (150 ms)** | manual |
| **Earth Cataclysm** | 110 | 8 tiles | 5 | 16 | área |
| **Earth Aura** | 130 | 4 áreas (9, 12, 4 tiles) | 1, 5, 5 | 17, 24, 8 | área ×4 |
| **Earth Lavaball** | 200 | golpe único | igual | eco | eco |
| **Earth Metalwall** | 250 | golpe único | igual | eco | eco |

## 7. Magias com estágio escrito à mão (as 9)

Foram as primeiras, feitas uma a uma antes do motor existir — servem de referência de estilo.

| Magia | O que mudou além da área |
|---|---|
| `fire/wave` | 3 estágios reais: cone curto (era o Fire Whip) → `AREA_WAVE4` → leque de 5 fileiras; o elite sobe chamas no conjurador (efeito 5) antes de abrir o cone |
| `fire/kick` | mini corta 2 dos 4 rastros de chama; elite ecoa e o alvo pega fogo |
| `fire/blast` | mini vira alvo único; elite vira 7x7 + `Condition` de combustão; a fórmula foi replicada em fábrica com `minMult/maxMult` (1/1 e 1,5/2,0 — iguais às originais) |
| `water/explosion` | mini alvo único; elite 7x7 + Correnteza; preserva o sistema de dobras (`dif`) do original |
| `air/ball` | mini sem o impacto de vento; elite ecoa com 450 ms de atraso (para não colidir com o eco de dobras de 250 ms) |
| `earth/crush` | mini cruz de 4 tiles; elite 5x5 em 4 ondas + fissura (callback `onTargetCreatureFissure`) |
| `earth/ingrain` | cura e duração por `spellStageScale` / `spellStageSeconds`; o tick de cura acompanha o novo tempo |
| `air/trap` | elite arma a cruz inteira em volta do alvo, checando `getPlayerCanWalk` em cada tile |
| `earth/quake` | rodadas e intervalos por `spellStageCount` / `spellStageScale`; o dano de cada hit é o mesmo `getMin`/`getMax` |

## 8. As 47 magias sem estágio

### 8.1 Fora de propósito (15) — cura/regen

`fire/recover` · `fire/urecover` · `water/recover` · `water/urecover` · `water/heal` · `water/sheal` ·
`water/regen` · `water/sregen` · `water/mregen` · `air/recover` · `air/urecover` · `earth/recover` ·
`earth/urecover` · `monster/regen` · `monster/massHeal`

### 8.2 Não são de player (6)

5 de monstro (`monster/checkFrost`, `monster/checkSand`, `monster/inferno`, `monster/massBlood`,
`monster/monsterSpell`) + 1 runa (`runes/elemental wall`).

### 8.3 Faltando (26) — dano/utilidade com estrutura própria

| Grupo | Magias | O que faria sentido |
|---|---|---|
| Movimento / dash (9) | `fire/jump` `fire/impulse` `water/jump` `water/surf` `air/jump` `air/run` `air/boost` `earth/jump` `earth/track` | tempo do efeito e velocidade do deslocamento (`spellStageSpeed` / `spellStageDuration`) |
| Buff / summon / controle (5) | `water/protect` `water/iceGolem` `water/res` `earth/armor` `air/jail` | duração do buff e tempo de invocação 60%/160% |
| Dano fora do padrão (12) | `fire/res` (Cinder) `fire/star` `fire/wrath` `fire/focus` `fire/voltage` `fire/thunderstorm` `air/doom` `air/icywind` `water/bloodControl` `water/wave` `water/iceBeam man` `water/whip man` | `spellStageCount` (nº de golpes/ondas) e, onde o `setCombatArea` está em loop, uma linha de `setCombatStageScaling` resolve a área pelo motor |

## 9. Observações importantes

- **44 das 70 magias têm nível mínimo ≥ 50, então nunca mostram o mini em jogo** — o estágio 1
  delas existe no código mas é inalcançável (fire 10, water 10, air 12, earth 12). Se quiser
  que o mini apareça, o caminho é baixar o `lvl` delas no `spells.xml` ou criar um segundo
  limiar para o mini.
- O eco é de ~300 ms, fixo, ajustável por magia no último parâmetro de `spellStageElite`/`spellStageEcho`.
- Os limiares vivem em `data/spells/lib/spellStages.lua` (`SPELL_MINI_LEVEL = 50`,
  `SPELL_ELITE_LEVEL = 100`) e no C++ (`STAGE_MINI_LEVEL` / `STAGE_ELITE_LEVEL` em `combat.cpp`).
  **Se mudar um, mude o outro.**
- Resíduo que **não** é deste trabalho: `data/spells/scripts/air/fury.lua` (arquivo de 2016, 3 linhas,
  com um `end` sobrando e sem referência no `spells.xml` — o server nem carrega).

## 10. Como conferir / testar

```bash
# relatório de área por estágio (simula o motor, não precisa de Lua nem compilar)
python tools/report_spell_stages.py

# sanidade de sintaxe Lua (parênteses/chaves, ignora strings e comentários)
python tools/check_lua_syntax.py data
```

No jogo: reinicie o server (a validação `[Error - Test Interface]` recheca os 147 scripts no boot)
e caste a mesma magia em **níveis 49, 50 e 100**. A luz do mundo também ajuda a testar à noite:
`/worldlight <40..250>` (ou o módulo `game_lightcontrol` no client, CTRL+X).
