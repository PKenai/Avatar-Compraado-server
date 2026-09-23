# VALIDAÇÃO MATEMÁTICA — MODELO DE DANO v2

> **OBSOLETO (ver `AUDITORIA_BALANCEAMENTO.md` §18).** O modelo v2 descrito aqui
> foi removido do servidor: dano e spellbar agora são os do servidor de referência
> (`raava ot wind`) e o sistema de estágios não existe mais. Este documento fica
> como registro da análise.

Segunda etapa. Este documento existe para provar (ou derrubar) a fórmula proposta na auditoria antes de escrever qualquer linha de código.

> **STATUS: o modelo v2 foi APLICADO** (com uma mudança de premissa) — ver
> `AUDITORIA_BALANCEAMENTO.md` §14.
>
> A escada de classes, o bend decrescente, o eco neutro, as áreas e o corte de
> `SPELL_BALANCE_LEVEL_CURVE` saíram como esta validação previu (drift de ±6% para
> `core` fora do ponto de referência). **Mas a premissa "as quatro vocações batem o
> mesmo dano" caiu**: a decisão do dono do servidor é fogo = DPS, ar = controle,
> terra = tank, água = healer, então o `SPELL_BALANCE` virou 1,10 / 1,00 / 0,95 /
> 0,90 e o dano por cast agora carrega essa hierarquia (em L100/bend 48, magia
> `core` de formato alvo: fogo 278 · ar 252 · terra 239 · água 226). Onde este
> documento fala em "paridade" (§2.1, §5 e §10.1), leia "hierarquia por papel"; a
> matriz de PvP do §5 precisa ser refeita.
>
> **v3:** a contagem de aplicações por cast (§3) estava incompleta — as magias de
> vários golpes fora da tabela do §3 over-deliveravam (ver §15 da auditoria).

Ferramentas usadas (fora do servidor, em `/tmp`): `spellmod.pl` (carrega as 74 magias de dano + cooldowns reais + `echo`), `valida2.pl` (simulador de rotação), `monatk.pl` (extrai ataque/resistências das 96 criaturas), `tabela_magias.md` (tabela completa).

---

## 0. RESUMO EXECUTIVO

**A fórmula funciona.** Ela resolve os problemas que a auditoria apontou — mas **não do jeito que estava escrita em quatro pontos**, e um deles era grave o bastante para criar um novo desbalanceamento pior que o atual (o eco).

| Item proposto | Veredito | O que muda |
|---|---|---|
| `dano = (20 + 1.55·(L-1)) × CLASSE × ÁREA × BEND` | **APROVADO** | L100/bend48 → core **254** (a referência de 250–300 estava certa) |
| Classes 0.40 / 1.00 / 1.75 / 2.75 | **APROVADO** | DPS de rotação das 4 vocações fica em 277–293 (±5%) |
| `1 + 1.2·bend/(bend+80)` | **APROVADO** | bend 50 = +46% (hoje +200%); L1→L25 ainda escala ×3,2 (evolução rápida no começo) |
| HP 30 → 45 por level | **APROVADO** | Sem isso, 2 rotações matam em PvP (HP 3.120 vs burst 1.395) |
| Reduzir o eco pela metade | **CORRIGIDO** | "metade" ainda dá **+47% para a terra**. O eco tem que ser **neutro**: base = 2/3 do orçamento, eco = 1/3 |
| Multi-hit divide o orçamento | **APROVADO + EXTENDIDO** | Vale também para **zonas** (aura 7 ticks, discharge 12, cinder 4, blizzard 10, rain 4) — a proposta só falava de "32 hits" |
| `rateMonsterAttack 1.0 → 1.4` | **REPROVADO** | Com o TTK ~5× maior, o jogador já toma ~5× mais dano por kill. Subir 1,4× faz a Stone-Spitting Spider causar **184% do HP** em um kill. Manter **1.0** (ou 0,9) |
| — | **RESOLVIDO** | Referência **`rateExperience = 1`** (o `200` do `config.lua` é valor de **teste**). A 1x a curva dá **21 / 7,1 / 3,3 níveis/hora** (L50/L100/L200) e o bend natural (≈1 ponto/level ⇒ 48 @ L100) — a premissa do §1. Com 200x o bend bate o teto de 100 em <1 h e as matrizes do §1 teriam de ser lidas em bend 100 |
| — | **NOVO** | Cura da água = **145 HPS** a L100 (5× a segunda melhor) → água ganha *todos* os confrontos |
| — | **NOVO** | Ar **não tem nenhuma magia no level 1** e água/ar causam `DROWNDAMAGE`/`AIRDAMAGE`, que **nenhuma** criatura resiste (fogo/terra são resistidos por 40+ criaturas) |
| — | **CORRIGIDO** | Os 112 itens de "% magic level" **não têm salto em 100%**: o multiplicador é linear (`(100+Σ(valor−100))/100`). Continua sendo um segundo multiplicador oculto, mas não "dobra do nada" |

---

## 1. VALIDAÇÃO DA FÓRMULA (matriz level × bend × classe)

```
dano = (20 + 1.55*(Level-1)) × CLASSE × ÁREA × (1 + 1.2·bend/(bend+80))
CLASSE: filler CD<=3s = 0.40 | core 4-15s = 1.00 | heavy 16-45s = 1.75 | ultimate >=60s = 2.75
```

**Bend esperado** (1 ponto de atributo por level, tabela de custo do `/add bend`) e piso (só pontos de level):

| Level | 1 | 25 | 50 | 75 | 100 | 150 | 200 |
|---|---|---|---|---|---|---|---|
| bend esperado | 14 | 29 | 35 | 42 | **48** | 56 | 62 |
| piso (só level) | 0 | 17 | 30 | 36 | 43 | 53 | 60 |

**Bend comparado** — proposta × atual (4%/ponto, linear):

| bend | 0 | 25 | 50 | 75 | 100 |
|---|---|---|---|---|---|
| **proposto** | ×1.000 | ×1.286 | ×1.462 | ×1.581 | ×1.667 |
| atual | ×1.000 | ×2.000 | ×3.000 | ×4.000 | ×5.000 |

### FILLER (×0.40)

| Level | bend 0 | 25 | 50 | 75 | 100 |
|---|---|---|---|---|---|
| L1 | 8 | 10 | 12 | 13 | 13 |
| L25 | 23 | 29 | 33 | 36 | 38 |
| L50 | 38 | 49 | 56 | 61 | 64 |
| L75 | 54 | 69 | 79 | 85 | 90 |
| L100 | 69 | 89 | **101** | 110 | 116 |
| L150 | 100 | 129 | 147 | 159 | 167 |
| L200 | 131 | 169 | 192 | 208 | 219 |

### CORE (×1.00)

| Level | bend 0 | 25 | 50 | 75 | 100 |
|---|---|---|---|---|---|
| L1 | 20 | 26 | 29 | 32 | 33 |
| L25 | 57 | 74 | 84 | 90 | 95 |
| L50 | 96 | 123 | 140 | 152 | 160 |
| L75 | 135 | 173 | 197 | 213 | 224 |
| L100 | 173 | 223 | **254** | 274 | 289 |
| L150 | 251 | 323 | 367 | 397 | 418 |
| L200 | 328 | 422 | 480 | 519 | 547 |

### HEAVY (×1.75)

| Level | bend 0 | 25 | 50 | 75 | 100 |
|---|---|---|---|---|---|
| L1 | 35 | 45 | 51 | 55 | 58 |
| L25 | 100 | 129 | 146 | 158 | 167 |
| L50 | 168 | 216 | 245 | 265 | 280 |
| L75 | 236 | 303 | 345 | 373 | 393 |
| L100 | 304 | 390 | **444** | 480 | 506 |
| L150 | 439 | 565 | 642 | 694 | 732 |
| L200 | 575 | 739 | 840 | 909 | 958 |

### ULTIMATE (×2.75)

| Level | bend 0 | 25 | 50 | 75 | 100 |
|---|---|---|---|---|---|
| L1 | 55 | 71 | 80 | 87 | 92 |
| L25 | 157 | 202 | 230 | 249 | 262 |
| L50 | 264 | 339 | 386 | 417 | 440 |
| L75 | 370 | 476 | 541 | 586 | 617 |
| L100 | 477 | 613 | **697** | 754 | 795 |
| L150 | 690 | 887 | 1009 | 1091 | 1150 |
| L200 | 903 | 1161 | 1320 | 1428 | 1505 |

**Escala entre estágios** (core, bend esperado do level):

| Estágio | core | vs. estágio anterior |
|---|---|---|
| L1 | 23,6 | — |
| L25 | 75,5 | **×3,20** |
| L50 | 131,0 | ×1,74 |
| L75 | 190,3 | ×1,45 |
| L100 | 251,5 | ×1,32 |
| L150 | 374,9 | ×1,49 |
| L200 | 500,5 | ×1,33 |

**Veredito §1:** a curva cumpre o pedido — acelera no começo (×3,2 até o L25) e depois desacelera para ×1,3–1,5 por estágio. O bend saiu de "manda mais que 75 levels" (×5) para "+67% no teto" (×1,67). Com a referência de L100/bend 48 a magia **core** dá 254 — exatamente dentro dos 250–300 que você tinha como alvo, só que aplicados à magia **padrão**, não à ultimate (como explicado na auditoria).

---

## 2. VALIDAÇÃO DAS MAGIAS EXISTENTES

Tabela completa (74 magias, avaliadas **no próprio level de unlock**, com o bend esperado daquele level): `tabela_magias.md`. Colunas: dano atual, dano proposto, variação, DPS atual, DPS proposto, aplicações por cast, total do cast, dano por aplicação, área, bend e eco.

### 2.1 Cobertura de kit por vocação (L100)

| voc | filler | core | heavy | ult | qtd total | Σ DPS-por-CD atual | Σ DPS-por-CD proposto |
|---|---|---|---|---|---|---|---|
| fire | 4 | 5 | 8 | 2 | 19 | 1479,9 | **212,4** |
| water | 2 | 6 | 8 | 2 | 18 | 940,8 | **208,4** |
| air | 1 | 5 | 11 | 2 | 19 | 779,2 | **198,7** |
| earth | 3 | 7 | 5 | 2 | 17 | 1157,4 | **193,0** |

O modelo equaliza o **dano por segundo de cooldown** (193–212, ±5%). O que **não** equaliza é a *distribuição* de classes:

- **ar** tem 11 heavies e **1 filler** (e esse filler é L8!) → dependente de cooldown, sem sustentação;
- **terra** tem 9 magias com eco e só 5 heavies;
- **água** tem 2 fillers;
- **fogo** é o mais equilibrado (4/5/8/2).

### 2.2 Magias desbloqueadas por estágio

| voc | L1 | L25 | L50 | L75 | L100 | L150 | L200 |
|---|---|---|---|---|---|---|---|
| fire | 1 | 5 | 8 | 12 | 15 | 17 | 18 |
| water | 1 | 4 | 8 | 12 | 14 | 16 | 17 |
| air | **0** | 3 | 8 | 12 | 14 | 17 | 18 |
| earth | 1 | 5 | 9 | 12 | 13 | 15 | 16 |

**Achado crítico:** no level 1 o jogador tem **1 magia** (ar tem **zero**). Como o grupo ATTACK compartilhado limita a 1 cast a cada 0,8 s, quem tem 1 magia de CD 2–3 s fica limitado pelo **próprio cooldown** — DPS real de 3 a 5, não de 12. Isso explica o TTK de 32–64 s contra uma Earth Beetle de 150 HP (§7).

### 2.3 Magias fora da curva

**Precisam de atk MENOR** (o modelo proposto já entrega mais do que o atual):

| magia | lvl | CD | atual | proposto | var |
|---|---|---|---|---|---|
| water bloodbending | 250 | 90s | 909 | 1727 | **+90%** |

**Precisam de atk MAIOR** — a lista abaixo é o "o servidor está 3–50× acima da curva" (esperado). Os casos que importam são os discrepantes **dentro** da própria lista (baixo nível com dano de alto nível):

| magia | lvl | CD | atual | proposto | var | leitura |
|---|---|---|---|---|---|---|
| earth crush | 1 | 3s | 692 | 7 | -99% | 3 hits no L1 valendo 692 |
| earth leech | 55 | 3s | 561 | 43 | -92% | **filler** que ainda cura |
| water rain | 65 | 45s | 2685 | 247 | -91% | 4 ondas × 671 |
| earth aura | 130 | 45s | 3778 | 427 | -89% | 7 ticks × 540 |
| fire thunderstorm | 150 | 30s | 5868 | 492 | -92% | 6 aplicações × 978 |
| fire cinder | 30 | 8s | 1584 | 86 | -95% | 4 ticks × 396 |
| water blizzard | 200 | 60s | 4015 | 1032 | -74% | 10 ticks × 401 |
| air vortex | 200 | 60s | 4008 | 1032 | -74% | 32 hits × 125 |
| fire discharge | 200 | 60s | 4004 | 1032 | -74% | 12 ticks × 333 |

Fora essas, **todas** as magias caem 44–85% — é a correção de escala prevista (o servidor entrega ~650 por cast onde o alvo é 254).

---

## 3. MULTI-HIT E ZONA

**Regra validada:** o cast inteiro (soma de todas as aplicações que caem no mesmo alvo) = orçamento da classe.

> **Correção v3 (ver `AUDITORIA_BALANCEAMENTO.md` §15):** esta tabela cobre só as
> magias **contadas aqui**. As que não estão nela rodaram com `apps = 1` e
> entregaram N× o orçamento — `air fan` (15 aplicações) dava ~6.600 num cast no
> L100, com o alvo marcado em 440. A contagem por magia agora vive em
> `%APPLICATIONS` (`tools/spell_balance_report.pl`), que é a fonte única do
> número de golpes por cast usada pelo emissor de `atk`.

| magia | voc | lvl | CD | classe | aplic. | total atual | total proposto | var | por aplic. | DPS proposto |
|---|---|---|---|---|---|---|---|---|---|---|
| air vortex | air | 200 | 60s | ult | 32 | 4008 | 1032 | -74% | 32 | 17,2 |
| water blizzard | water | 200 | 60s | ult | 10 | 4015 | 1032 | -74% | 103 | 17,2 |
| earth crush | earth | 1 | 3s | filler | 3 | 692 | 7 | -99% | 2 | 2,4 |
| fire cinder | fire | 30 | 8s | core | 4 | 1584 | 86 | -95% | 22 | 10,8 |
| water rain | water | 65 | 45s | heavy | 4 | 2685 | 247 | -91% | 62 | 5,5 |
| earth aura | earth | 130 | 45s | heavy | 7 | 3778 | 427 | -89% | 61 | 9,5 |
| fire discharge | fire | 200 | 60s | ult | 12 | 4004 | 1032 | -74% | 86 | 17,2 |
| fire thunderstorm | fire | 150 | 30s | heavy | 6 | 5868 | 492 | -92% | 82 | 16,4 |
| fire star | fire | 36 | 25s | heavy | 8 | 442 | 174 | -61% | 22 | 7,0 |
| air gale | air | 30 | 15s | core | 1 | 316 | 82 | -74% | 82 | 5,5 |
| earth growth | earth | 25 | 9s | core | 1 | 408 | 72 | -82% | 72 | 8,0 |

**Extensão obrigatória da regra:** a proposta original falava só de magias de "32 hits". O simulador mostra que **zonas/DoT** (aura, blizzard, flow, rain, discharge, cinder, vortex) também multiplicam — e `earth aura` **não era contada como multi-hit pela própria ferramenta do servidor**. Aplicar a regra só aos "32 hits" deixaria `earth aura` entregando 427×7 = 2.989 por cast (8× a ultimate).

**Como implementar por magia (exemplos):**

| magia | orçamento (L100/bend48) | aplicações | por aplicação |
|---|---|---|---|
| air vortex (ult) | 697 | 32 | **22** |
| earth crush (filler) | 101 | 3 | **34** |
| earth aura (heavy) | 444 | 7 | **63** |
| fire cinder (core) | 254 | 4 | **64** |
| fire discharge (ult) | 697 | 12 | **58** |

O DPS efetivo de cada uma continua sendo `orçamento / cooldown` — nenhuma magia multi-hit ganha DPS por ter mais hits; ela ganha **área de acerto** (o que já é vantagem suficiente).

---

## 4. ECO

| voc | magias | com eco | eco ≤ L100 | aplicações extras | dano extra/cast (atual) | no modelo |
|---|---|---|---|---|---|---|
| fire | 19 | 5 | 4 | 4 | 2.316 | 376 |
| water | 18 | 5 | 5 | 5 | 3.399 | 541 |
| air | 19 | 3 | 3 | 3 | 1.523 | 351 |
| earth | **17** | **11** | **9** | **9** | **5.058** | 793 |

**Ganho real do eco na rotação** (medido ligando e desligando a aplicação extra, mantendo o mesmo kit):

| voc | DPS atual | atual s/ eco | ganho atual | % | DPS proposto | proposto s/ eco | ganho |
|---|---|---|---|---|---|---|---|
| fire | 1252,3 | 1035,7 | +216,6 | **+20,9%** | 273,1 | 273,1 | **0** |
| water | 1120,0 | 808,3 | +311,7 | **+38,6%** | 287,5 | 287,5 | **0** |
| air | 792,5 | 741,1 | +51,4 | **+6,9%** | 287,7 | 287,7 | **0** |
| earth | 1503,1 | 1024,5 | +478,6 | **+46,7%** | 286,0 | 286,0 | **0** |

**Veredito §4:** o eco é hoje a maior distorção entre vocações (terra +46,7% só por causa dele). A proposta "reduzir o eco pela metade" **não resolve**: cortar 50% ainda deixa a terra com ~+23% de vantagem. A única solução estável é **eco neutro**: a aplicação base vira 2/3 do orçamento e o eco reaplica 1/3 do total (equivalente a "50% do dano base"). O efeito visual e a mecânica continuam idênticos, e o total do cast continua dentro do orçamento — o ganho vira **exatamente 0%** (verificado nas quatro colunas "0" acima).

---

## 5. PvP

Parâmetros: **Level 100, bend 48 (= magic level 48), HP 4.605**, teto global de 0,8 s por cast agressivo.

| voc | DPS | burst 3 | burst 5 | %HP (3) | %HP (5) | maior magia | %HP (1) | casts p/ matar | casts/min |
|---|---|---|---|---|---|---|---|---|---|
| fire | 277,3 | 1320 | 2069 | **28,7%** | 44,9% | 440 | **9,6%** | 22,1 | 80,0 |
| water | 287,5 | 1320 | 2069 | 28,7% | 44,9% | 440 | 9,6% | 19,8 | 74,0 |
| air | 293,0 | 1298 | 2091 | 28,2% | 45,4% | 440 | 9,6% | 18,4 | 70,0 |
| earth | 277,3 | 1298 | 1801 | 28,2% | 39,1% | 440 | 9,6% | 19,9 | 72,0 |

- Ninguém morre de **uma** magia: a maior delas tira **9,6%** do HP.
- O burst de abertura (5 magias) tira **39–45%**: ainda são **2–3 rotações** para matar.
- DPS entre vocações: **277–293 (±3%)** — paridade atingida.

### Matriz de confronto (TTK de A sobre B)

Com a cura da água **como está hoje** (145 HPS):

| atacante → defensor | fire | water | air | earth |
|---|---|---|---|---|
| **fire** | — | 34,8s | 18,5s | 16,6s |
| **water** | 16,0s | — | 17,8s | 16,0s |
| **air** | 15,7s | 31,1s | — | 15,7s |
| **earth** | 16,6s | 34,8s | 18,5s | — |

**Água vence 100% dos confrontos** — não por dano (é a 2ª maior), mas porque 145 HPS anulam 50% do DPS de qualquer oponente. Fogo→água leva **34,8 s** contra os 16 s que a água leva para matar de volta: não é um confronto, é uma execução.

Com a cura ajustada (**mana 12→60, CD 3 s→8 s, `atk` 300→200** ⇒ ~36 HPS):

| atacante → defensor | fire | water | air | earth |
|---|---|---|---|---|
| **fire** | — | 20,6s | 18,5s | 16,6s |
| **water** | 16,0s | — | 19,3s | 16,0s |
| **air** | 15,7s | 19,3s | — | 15,7s |
| **earth** | 16,6s | 20,6s | 18,5s | — |

Agora todos os confrontos ficam entre **15,7 s e 20,6 s** — vantagem clara, mas não automática.

### Limitação honesta do §5

Como as quatro vocações agora têm DPS muito próximos, um **espelho** (fogo×fogo) é decidido por quem começa. Isso é uma consequência matemática da paridade, não um defeito da fórmula: o que decide a luta passa a ser **execução** (§6) e não o dano da vocação. Se você quiser lutas mais longas com espaço para reação, o lugar certo é a **camada defensiva** (poções de vida, curas, dodge do ar de 10% → 15–20%), não o dano.

---

## 6. EXECUÇÃO — a afirmação "3 magias = ~30% do HP"

### Prova analítica (L100, bend 48, HP 4.605)

```
core = 254   heavy = 444   ultimate = 697
core + heavy + ultimate = 1395 = 30,3% do HP (4605)
```
Em L200 (bend 62, HP 9.105): `500 + 876 + 1376 = 2752 = 30,2%`. **A afirmação é verdadeira de L75 para cima** — e é falsa abaixo disso, não por causa da fórmula, mas porque o kit ainda não tem heavy+ultimate:

| Level | burst 3 (%HP) |
|---|---|
| L25 | 11,0–19,0% |
| L50 | 20,9–28,2% |
| L75 | 24,1–28,2% |
| L100 | 28,2–28,7% |
| L150 | 28,7% |
| L200 | 30,6–34,4% |

### Simulação de execução (rotação de até 120 s)

| Level | voc | HP | DPS perfeita | DPS boa | DPS ruim | TTK perfeita | TTK boa | TTK ruim |
|---|---|---|---|---|---|---|---|---|
| L100 | fire | 4605 | 268,7 | 208,4 | 143,6 | **17,1s** | **22,1s** | **32,1s** |
| L100 | water | 4605 | 288,8 | 209,5 | 141,3 | 15,9s | 22,0s | 32,6s |
| L100 | air | 4605 | 278,4 | 231,5 | 166,7 | 16,5s | 19,9s | 27,6s |
| L100 | earth | 4605 | 285,4 | 208,7 | 106,1 | 16,1s | 22,1s | 43,4s |
| L150 | fire | 6855 | 425,5 | 327,5 | 213,6 | 16,1s | 20,9s | 32,1s |
| L200 | fire | 9105 | 581,9 | 429,7 | 265,0 | 15,6s | 21,2s | 34,4s |
| L200 | earth | 9105 | 606,9 | 418,5 | 312,0 | 15,0s | 21,8s | 29,2s |

Modelo de erro: **perfeita** = 0% de erro / 0 s de reação · **boa** = 10% das magias erradas + 0,35 s de atraso por cast · **ruim** = 30% erradas + 0,7 s.

**Veredito §6:** a razão entre execução perfeita e ruim fica entre **1,9× e 2,5×** — exatamente o que você pediu: perfeita mata em ~15–17 s, boa em ~20–23 s, ruim em ~28–44 s (e contra uma água com cura, "ruim" simplesmente **não mata**). Errar magia voltou a ter custo.

---

## 7. PvE

Base: 66 criaturas com dados completos. DPS do monstro pela fórmula do engine (`skill*attack*0.05 + attack*0.5` para melee, `min/max` para o resto) × `rateMonsterAttack`. **Mitigação estimada de 50%** (defesa/armadura do player no dano físico) — a sobrevivência real é melhor que a coluna "dano tomado".

### 7.1 Mediana de XP/segundo por faixa (a moeda de troca do PvE)

| faixa | xp/s de referência | | faixa | xp/s de referência |
|---|---|---|---|---|
| 0–14 | 38 | | 90–104 | 810 |
| 15–29 | 120 | | 105–119 | 510 |
| 30–44 | 136 | | 120–134 | 541 |
| 45–59 | 248 | | 135–149 | 668 |
| 60–74 | 492 | | 165–179 | 837 |
| 75–89 | 218 | | 225–239 | 1169 |

### 7.2 FARM TRAPS confirmados (XP/s ≥ 2× a mediana da faixa)

| criatura | faixa | HP | XP | xp/s | vs mediana | TTK | xp/HP |
|---|---|---|---|---|---|---|---|
| ALPHA Warm Cape Crab | 80–100 | 2.400 | 28.000 | 2.264 | **4,93×** | 9,4s | 11,67 |
| ALPHA Giant Snail | 90–110 | 4.200 | 44.000 | 2.538 | **3,90×** | 14,3s | 10,48 |
| ALPHA Sea Iguana | 200–230 | 27.000 | 144.000 | 3.411 | **3,13×** | 39,2s | 5,33 |
| ALPHA Giant Cricket | 130–150 | 9.600 | 44.000 | 1.733 | 2,67× | 22,4s | 4,58 |
| Giant Snail (**Caracol Gigante**) | 80–100 | 700 | 5.500 | 960 | **2,09×** | **2,7s** | **7,86** |
| Desert Crocodile | 250–300 | 12.800 | 36.500 | 2.103 | 2,03× | 14,4s | 2,85 |
| ALPHA Cockroach | 15–30 | 360 | 3.800 | 354 | 2,60× | 7,7s | 10,56 |
| ALPHA Earth Beetle | 25–35 | 900 | 7.840 | 496 | 3,65× | 12,8s | 8,71 |
| Sea Iguana | 150–200 | 4.500 | 18.000 | 1.602 | 1,91× | 8,2s | 4,00 |
| Hopper | 200–250 | 11.600 | 34.300 | 1.797 | 1,65× | 16,1s | 2,96 |

**Caranguejo Capa Quente (Warm Cape Crab): 400 HP por 3.500 XP (`xp/HP = 8,75`), morto em ~2 s no L70.** O Caracol Gigante é o mesmo caso um pouco mais tarde: 700 HP por 5.500 XP, 2,7 s. Comparação direta na MESMA faixa (60–80): uma Stone Tarantula dá 2.075 XP por 5,5 s (377 XP/s) e o Caranguejo dá 3.500 XP por 2,1 s (**1.667 XP/s**) — **4,4× mais XP por segundo**, com os dois marcados como "60–80" e "80–100" nas próprias waypoints do servidor. Não é impressão: as duas criaturas são lixo mecânico (HP de bicho de level 5–10) com XP de bicho de level 250.

**Correção recomendada:** subir HP (Caranguejo 400 → 2.600; Caracol 700 → 4.600) mantendo o XP, ou cortar o XP em ~75%. O HP é a melhor alavanca porque conserta também o "matar em 2 s" (que destrói a sensação de combate).

### 7.3 XP BAIXO DEMAIS (não vale a pena caçar)

| criatura | faixa | HP | XP | xp/s | vs mediana | TTK |
|---|---|---|---|---|---|---|
| Cockroach | 1–10 | 60 | 475 | 38 | 0,28× | 9,4s |
| Ba Sing Se Lion | 65–80 | 2.000 | 2.500 | 192 | 0,42× | 10,0s |
| Hermit Crab | 60–80 | 3.800 | 4.800 | 213 | 0,46× | 19,6s |
| Steel Shell Centipede | 80–85 | 2.300 | 2.800 | 218 | 0,48× | 9,8s |
| Vulture Bee | 105–115 | 3.000 | 3.800 | 315 | 0,48× | 9,1s |
| Sand nomad | 250–300 | 45.000 | 32.000 | 599 | 0,58× | 50,5s |
| White Scarab | 250–300 | 35.000 | 28.000 | 663 | 0,64× | 39,2s |

`Sand nomad` e `White Scarab` são muros: 45.000/35.000 HP para 32.000/28.000 XP (`xp/HP` 0,71 e 0,80) e TTK de 50 s e 39 s — **`xp/HP` cai com o HP** enquanto o XP não acompanha. Ninguém vai caçar isso.

### 7.4 Criaturas perigosas para o level sugerido (margem < 2×)

| criatura | faixa | HP do player | dano tomado no kill | margem |
|---|---|---|---|---|
| Stone-Spitting Spider | 20–30 (L25) | 1.230 | 2.263 | **0,54×** |
| Sand nomad | 250–300 (L275) | 12.480 | 20.502 | 0,61× |
| White Scarab | 250–300 (L275) | 12.480 | 16.199 | 0,77× |
| Hermit Crab | 60–80 (L70) | 3.255 | 2.429 | 1,34× |
| Forbidden Folds Book | 250–300 (L275) | 12.480 | 7.748 | 1,61× |

Com TTK de 26 s no nível 25, a Stone-Spitting Spider mata o jogador antes dele terminar o bicho. Com o modelo atual (TTK 2,6 s) ela é trivial. **Toda criatura com TTK > 15 s precisa de uma revisão de dano** — é o preço inevitável de frear o dano do jogador.

### 7.5 Melhor e pior caça por estágio

| Level | melhor | xp/s | pior | xp/s |
|---|---|---|---|---|
| 20 | Cemetery Worm | 143 | Earth Beetle | 103 |
| 40 | Hippo | 136 | Mud Bee | 119 |
| 60 | **Warm Cape Crab** | 692 | Hermit Crab | 213 |
| 80 | **Giant Snail** | 960 | Ba Sing Se Lion | 192 |
| 100 | **Giant Snail** | 960 | Elephant | 254 |
| 150 | Sea Iguana | 1.602 | Traitor | 428 |

### 7.6 Taxa de XP — referência `rateExperience = 1`

**Valor de referência de todo este documento: `rateExperience = 1`.** O `200` que está no `config.lua` é valor de **teste** e não entra em nenhuma conta — se ele fosse o valor de produção, o bend bateria o teto de 100 em menos de uma hora e o §1 inteiro teria de ser relido na coluna "bend 100". Usando a tabela de XP do próprio engine e o XP base das criaturas:

| estágio | XP para o próximo level | melhor criatura | xp/s | tempo por level | **níveis/hora (1x)** | (só p/ contraste) a 200x |
|---|---|---|---|---|---|---|
| L50 | 117.700 | Warm Cape Crab | 686 | 2,9 min | **21** | 4.200 |
| L100 | 485.200 | Giant Snail | 964 | 8,4 min | **7,1** | **1.430** |
| L200 | 1.970.200 | Hopper | 1.797 | 18 min | **3,3** | 660 |

**A 1x a curva está certa:** 21 → 7,1 → 3,3 níveis/hora, caindo conforme sobe — exatamente o desenho pedido. Em termos absolutos, chegar ao L100 custa ~15,7 M de XP acumulado (≈ 4,5 h se o ritmo do melhor spot valesse desde o L1; na prática mais, porque os estágios de baixo rendem menos xp/s) e ao L200 ~129 M.

Três consequências para o resto do documento:

1. **O bend volta a ser conquista — e isso é premissa do modelo, não ajuste à parte.** A 1x o jogador ganha ≈1 ponto de atributo por level, e é esse ritmo (junto com as pedras elementais) que produz o **bend 48 @ L100** usado em todas as matrizes do §1. A 200x o L100 valeria +1.000 níveis/hora (1.430 pontos) e o bend chegaria ao **teto de 100 em menos de uma hora**; as tabelas do §1 teriam de ser lidas na coluna "bend 100" (core **289** em vez de 254, ultimate **795** em vez de 697) e o eixo do level simplesmente deixaria de existir. Ou seja: **`rateExperience = 1` não é ajuste de XP, é o valor que valida a fórmula de dano.**
2. **Nada a corrigir em XP de criatura por causa da taxa.** As distorções reais (farm traps `Warm Cape Crab`, `Giant Snail`, etc.) vêm do **XP/HP**, não da taxa — ver §7.4/§7.5.
3. **`rateExperienceFromPlayers` (0,3) é independente** de `rateExperience` (`Player::getGainedExperience`, `sources/player.cpp:4026`): baixar a taxa de PvE para 1 **não** mexe no XP de PvP, que segue valendo 0,3× da fórmula de PvP. Se o PvP tiver de dar XP relevante, é uma linha separada.

Com o valor de referência 1, a maior alavanca de balanceamento deixa de ser a taxa de XP e volta a ser a fórmula de dano + as classes de cooldown.

### 7.7 Resistências — assimetria estrutural

| tipo de dano | usado em | quem depende dele |
|---|---|---|
| fire | 40 criaturas | fogo (47 magias) |
| earth | 42 criaturas | terra (35 magias) |
| ice | 24 criaturas | água (4 magias) |
| energy | 6 criaturas | fogo secundário (20 magias) |
| physical | 28 criaturas | — |
| **air** | **0 criaturas** | **ar (32 magias)** |
| **drown** | **0 criaturas** | **água (41 magias)** |

O engine **suporta** `airPercent` e `drownPercent` (`sources/monsters.cpp:1452,1456`) — o conteúdo é que nunca preencheu. Resultado: **água e ar atravessam a tabela de resistências inteira**. Fogo e terra são resistidos por 40+ criaturas, água e ar por zero. Dano do jogador é o mesmo em teoria e diferente na prática.

**Correção recomendada:** adicionar `airPercent`/`drownPercent` em ~30% das criaturas (na mesma proporção que `firePercent`/`earthPercent`), tornando as quatro vocações simétricas no PvE.

---

## 8. MANA

Fatos apurados no engine e no conteúdo:

| fato | valor | fonte |
|---|---|---|
| regeneração natural de mana | **0** (`gainmanaamount = 0` em todas as vocações) | `XML/vocations.xml` |
| poção grande (id 7590) | 140 × 3 a cada 333 ms = **420 mana/s** | `actions/scripts/liquids/manaPotions.lua` |
| mana ganha por level | 5 → pool ≈ 5×(level−8) | `gainmana` |
| limite de casts | grupo ATTACK compartilhado de 0,8 s ⇒ **1,25 cast/s** | `spells.cpp` + `enableCooldowns=false` |

| Level | casts/min | mana/cast | mana/s necessário | pool | oferta (poção) | folga |
|---|---|---|---|---|---|---|
| L1 | 30,0 | 0,0 | 0,0 | 0 | 420 | — |
| L25 | 75,3 | 10,6 | 13,3 | 85 | 420 | **31,6×** |
| L50 | 80,7 | 16,2 | 21,8 | 210 | 420 | **19,3×** |
| L75 | 80,0 | 27,4 | 36,6 | 335 | 420 | **11,5×** |
| L100 | 80,0 | 31,5 | 42,0 | 460 | 420 | **10,0×** |
| L150 | 80,0 | 36,3 | 48,4 | 710 | 420 | **8,7×** |
| L200 | 80,0 | 38,4 | 51,2 | 960 | 420 | **8,2×** |

**Veredito §8: mana não limita nada.** A demanda é 8–30× menor que a oferta da poção. O **cooldown sozinho** limita o jogador, e a mana é decorativa em qualquer build que leve 20 poções.

Se você quiser que a mana volte a ser uma variável de decisão, as opções são (em ordem de menor invasão):

1. **Nada.** Aceitar cooldown como único limitador (é o mais simples e o sistema fica consistente).
2. **Cortar a poção grande** de 140×3 para 60×3 (180/s) → a folga cai para 4,3× no L100 — ainda generoso, mas mana passa a doer em sequências de ultimate.
3. **Subir custos por classe** (filler ×1, core ×2, heavy ×3, ult ×4) → `mana/cast` vai a ~90 no L100, ainda dentro da oferta, mas obriga a poção a ser usada de forma ativa.

**Não recomendo** multiplicar custos arbitrários: sem cortar a poção, qualquer custo que não seja 10× maior continua irrelevante.

---

## 9. MAGIC LEVEL / ITENS (% de magic level)

### 9.1 Como funciona de verdade (correção da auditoria)

`sources/player.cpp`, `increaseCombatValues()`:

```c
int32_t totalMagicPercent = 100;
for (cada item equipado)
    if (it.abilities->increment[MAGIC_PERCENT])
        totalMagicPercent += (it.abilities->increment[MAGIC_PERCENT]) - 100;
if (totalMagicPercent > 100) {
    if (min <= 0) min = ceil(min * totalMagicPercent / 100.);   // dano mágico
    if (max <= 0) max = ceil(max * totalMagicPercent / 100.);
}
```

- **Não existe limiar em 100%. Não "dobra do nada".** O multiplicador é **linear**: `(100 + Σ(valor−100)) / 100`.
- `items.xml`: 112 itens com a chave `increasemagicpercent`, valores **101 a 120** (nunca abaixo de 100 → nunca há item que *reduza* o dano mágico).
- Conjunto realista (8 slots, média 106) → Σ = 48 → **×1,48**. Melhor conjunto possível (110/112/112/113/114/115/118/120) → Σ = 114 → **×2,14**.

| Σ(valor−100) | multiplicador |
|---|---|
| 0 | ×1,00 |
| 20 | ×1,20 |
| 48 | ×1,48 |
| 60 | ×1,60 |
| 100 | ×2,00 |
| 120 | ×2,20 |

### 9.2 Por que ainda é um problema

É um **segundo multiplicador global, invisível na interface e sem teto**, aplicado *depois* de bend × classe × área. Com o modelo novo:

```
L100, ultimate, bend 48, conjunto bom (Σ=114):
697 × 2,14 = 1.492 por cast  (16,4% do HP de um L100)
```

Não quebra o jogo (o teto é 2,2×), mas significa que **dois jogadores de mesmo level e mesmo bend podem ter 48% de diferença de dano** dependendo do equipamento — e nenhum dos dois consegue explicar de onde vem.

### 9.3 Nomenclatura (importante para não errar a implementação)

- **`bend` É o magic level do engine**: `getPlayerMagLevel(cid)` (`avatar lib.lua:208`), comprado com `/add bend` via `doPlayerAddMagicLevel`.
- Dano: `1 + 0.04·bend` (`getBendDamageBonus`). Cura: `magLevel + level/2` (`water/heal.lua`).
- Os itens de "% de magic level" **não somam bend**: eles multiplicam o dano no final. São duas coisas diferentes com nomes parecidos.

### 9.4 Recomendação

| opção | efeito |
|---|---|
| teto em `totalMagicPercent = 150` | conjunto bom = ×1,5; melhor conjunto do jogo = ×1,5 (nada de caçar item "perfeito" para 30% mais dano) |
| converter para retorno decrescente: `1 + 0,5·(1 − exp(−Σ/60))` | Σ=48 → ×1,27; Σ=120 → ×1,45 |
| deixar como está e **documentar** | aceitável, mas mantém a "sorte de item" valendo ±48% de dano |

Também vale notar a **assimetria com a cura**: no ramo de cura (`min > 0`) o código multiplica **por item** (`min = ceil(min * HEALING_PERCENT / 100)`), ou seja os bônus de cura se **multiplicam entre si**, enquanto os de dano mágico se **somam**. Três peças de cura a 110% dão ×1,33; três peças de dano a 110% dão ×1,30. É pequeno, mas é o tipo de detalhe que produz "build secreta".

---

## 10. CONCLUSÃO

### 10.1 A fórmula funciona?

**Sim, com quatro correções obrigatórias** (eco neutro, não subir `rateMonsterAttack`, cura da água, kit de level 1). Os objetivos que você definiu:

| Objetivo | Prova |
|---|---|
| Evolução rápida no começo | core escala ×3,20 do L1 ao L25 |
| Dano cresce de forma controlada depois | ×1,32–1,49 por estágio |
| Bend com impacto real, sem engolir o level | ×1,00→×1,67 (era ×1,00→×5,00) |
| Vocações com identidade e sem vantagem absurda | DPS 277–293 (±3%), mas kits diferentes (ar: burst+mobilidade, água: cura, terra: 1,4 de defesa, fogo: equilíbrio) |
| Magias fracas/médias/fortes/ultimates distintas | 101 / 254 / 444 / 697 no L100 |
| PvE com progressão e criaturas progressivamente fortes | tabela §7.5 — cada estágio tem faixa própria |
| PvP exige execução, sem one-shot | maior magia = 9,6% do HP; perfeita 17 s, boa 22 s, ruim 32 s (e ruim não mata água) |
| PvP exige combo, mana, controle, posicionamento | combo: burst de 5 = 45%, precisa de 2–3 rotações; mana/controle dependem das correções §8/§5 |

### 10.2 Tabela final de parâmetros

| # | parâmetro | atual | proposto | motivo | impacto esperado |
|---|---|---|---|---|---|
| 1 | dano por cast | ~650 (todas as classes) | `(20+1.55(L−1))×classe×área×bend` | dano era igual para CDs de 2 s e 90 s | magia padrão = 254; ultimate = 697 |
| 2 | classes por cooldown | não existe | 0.40 / 1.00 / 1.75 / 2.75 | inverter a escada (hoje a magia nova é a pior) | DPS de rotação 277–293 em todas as vocações |
| 3 | fator de bend | `1 + 0.04·bend` (×5 em bend 100) | `1 + 1.2·b/(b+80)` (×1,67) | 25 de bend valiam mais que 75 levels | bend continua valendo, level volta a importar |
| 4 | eco (L≥100) | +100% do dano do cast | **eco neutro**: base 2/3 + eco 1/3 | terra ganhava +46,7% só por ter 9 magias com eco | diferença entre vocações por eco = 0% |
| 5 | multi-hit/zona | dano × nº de aplicações | cast inteiro = orçamento da classe | `air vortex` = 4.008; `earth aura` = 3.778 por cast | vortex 1.032 (32×22); aura 427 (7×61) |
| 6 | HP por level | 30 (L100 = 3.120) | **45** (L100 = 4.605) | com 3.120 duas rotações matam | burst de 3 = 28,7% em vez de 45% |
| 7 | `rateMonsterAttack` | 1.0 | **1.0 (não subir para 1.4)** | TTK ~5× maior já multiplica o dano tomado | mantém o PvE viável; subir 1,4 tornava a Stone-Spitting Spider letal em 1 kill |
| 8 | cura da água | `atk 300`, CD 3 s, mana 12 → 145 HPS | `atk 200`, CD 8 s, mana 60 → ~36 HPS | água venceria 100% dos confrontos | todos os matchups entre 15,7 s e 20,6 s |
| 9 | `rateExperience` | 200 (valor de **teste** no `config.lua`) | **1** (produção) | o §1 pressupõe bend 48 @ L100, o que exige ≈1 ponto de atributo por level (= 1x); 200× = +1.000 níveis/h e bend 100 em <1 h | level e bend voltam a ser conquista e as matrizes do §1 ficam válidas |
| 10 | resistências de ar/água | 0 criaturas usam `airPercent`/`drownPercent` | usar em ~30% das criaturas | fogo/terra são resistidos por 40+; água/ar por ninguém | simetria de PvE entre as 4 vocações |
| 11 | itens "% magic level" | linear, sem teto (×1,48 a ×2,14) | teto em 150% (ou curva decrescente) | 48% de diferença de dano por equipamento, invisível | fecha o último multiplicador oculto |
| 12 | kit de level 1 | ar tem **0** magias; 1–2 magias por vocação | 3 fillers (CD ≤3 s) por vocação no L1–10 | DPS real de 3–5 (limitado pelo CD, não pelo cap) | TTK de uma Earth Beetle cai de 32 s para ~5 s |

### 10.3 O que NÃO mudar

- `rateMonsterAttack` (**não subir**), `rateLoot`, `rateSkill`, tabela de XP da vocação, `manamultiplier`, pontos de bend por level (a tabela de custo do `/add bend` já produz bend 43–48 no L100 e está boa).
- O sistema de eco como mecânica — só o valor da reaplicação.
- Os efeitos visuais, condições, `exhaustion` por magia e áreas das magias.

### 10.4 Listas de ação (para a etapa de implementação)

**Magias com atk a AUMENTAR:** todas as 74 (a curva está 3–50× acima do alvo), priorizando as discrepantes da §2.3 — `earth crush`, `earth leech`, `water rain`, `earth aura`, `fire thunderstorm`, `fire cinder`, `water blizzard`, `air vortex`, `fire discharge`.

**Magias com atk a REDUZIR:** `water bloodbending` (250) e revisar `earth metalwall`/`air deflection`/`fire conflagration` — as quatro ultra-últimas de 90 s recebem o maior orçamento do jogo (1.295–1.727) e devem ser confirmadas uma a uma.

**Cooldowns a corrigir** (classe errada para o papel da magia): `earth leech` (L55, CD 3 s, filler com dano de core e cura embutida), `fire cinder` (CD 8 s com 4 ticks), `earth crush` (L1 com 3 hits), `water rain` (CD 45 s com 4 ondas).

**Custos de mana:** só mexer se você aceitar a correção §8.2 (cortar a poção). Sozinhos, os custos são irrelevantes.

**Vocações acima/abaixo da curva:** no L100, **ar** está +5% (maior DPS *e* 10% de dodge) e **terra** −5% em dano (mas compensa com 1,4 de defesa/armadura — que **não reduz dano mágico**, ou seja, não compensa em PvP). Antes do L25, **ar está muito abaixo** (zero magias no L1). Os ajustes são de **distribuição de classes** por vocação (ar precisa de fillers; terra precisa de mais heavies), não de multiplicador.

**Criaturas acima/abaixo da curva:** farm traps = Warm Cape Crab, Giant Snail, Desert Crocodile, Sea Iguana, Hopper + todas as versões ALPHA; muros = Sand nomad, White Scarab, Hermit Crab, Steel Shell Centipede, Vulture Bee, Ba Sing Se Lion; perigosas = Stone-Spitting Spider, Forbidden Folds Book, Sand nomad, White Scarab.

### 10.5 Onde esta validação é otimista (limites do modelo)

1. A rotação simulada sempre usa a **magia de maior dano pronta**, sem posicionamento, interrupções, CC ou gasto de tempo andando entre spawns.
2. PvP sem resistências/absorb de item, sem poções de vida no meio e sem o dodge/heal do adversário além do modelado.
3. Dano dos monstros com **mitigação estimada em 50%** — a sobrevivência real é melhor.
4. O "XP/s" assume condição ideal de caça (kill + 3 s de deslocamento); vale como **comparação relativa** entre criaturas, não como taxa absoluta.
5. A conversão final de alvo→`atk` por magia depende da função de dano de cada script (`spellsInfo`), que só deve ser tocada na etapa de implementação.

**Implementado.** O modelo de dano saiu do papel (ver `AUDITORIA_BALANCEAMENTO.md` §14): `avatar lib.lua`, `spellStages.lua`, `201-spellsExausted.lua` (73 magias) e `tools/spell_balance_report.pl` (`--model`). Ficaram pendentes as 4 correções que não são `atk`: HP 30→45 (`vocations.xml`), `rateExperience = 1` em produção, cura da água e kit de level 1 — além de P1/P11/P12/P16/P17.
