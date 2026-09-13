# Spells proprias dos monstros

Cada monstro do servidor tem uma spell assinatura com nome, elemento, formato e visual proprios,
listadas abaixo do mais fraco ao mais forte pelo dano do `<attack>`.
O motor e' unico (`data/spells/scripts/monster/monsterSpell.lua`) e le' a configuracao em
`data/lib/monsterSpellBook.lua`; o dano de cada uma vem do `<attack min max>` no XML do monstro.

| # | Monstro | Spell | Elemento | Formato | Dano | O que faz |
|---|---------|-------|----------|---------|------|-----------|
| 1 | Cockroach | **Carapace Scuttle** | earth | nova raio 1 | -4 a -9 | bate a carapaça no chão e abre uma rachadura 3x3 em volta dele |
| 2 | Earth Beetle | **Beetle Tremor** | earth | nova raio 1 | -4 a -9 | tremor curto de terra 3x3 em volta do besouro |
| 3 | Cemetery Worm | **Grave Burrow** | poison | burst raio 1 | -6 a -15 | some no chão e explode terra de cemitério no alvo (3x3 + veneno) *(aplica poison)* |
| 4 | Giant Snail | **Slime Trail** | poison | beam 3 sqm | -8 a -16 | deixa um rastro de limo venenoso em linha (3 sqm) *(aplica poison)* |
| 5 | Warm Cape Crab | **Scalding Tide** | water | nova raio 2 | -10 a -20 | água quente das fontes do Cabo jorra 5x5 em volta dele |
| 6 | Momo | **Little Fury** | physical | blast | -20 a -40 | Momo avança raivoso no alvo (é summonável, então essa ele usa de verdade) |
| 7 | Earth Ladybug | **Ladybug Quake** | earth | wave 3 sqm larg 1 | -20 a -40 | onda de terra 3x3 que avança na direção em que ela olha |
| 8 | Giant Cricket | **Chirp Screech** | physical | nova raio 2 | -30 a -60 | estridula tão alto que o som machuca em 5x5 |
| 9 | Fierce Bear | **Bear Maul** | physical | breath 2 sqm | -40 a -80 | patada dupla que abre em cone curto na frente dele |
| 10 | Hippo | **River Crush** | physical | nova raio 2 | -40 a -80 | esmaga o chão com a bocarra: 5x5 de poeira e impacto |
| 11 | Mud Bee | **Mud Swarm** | poison | rain raio 2 | -40 a -80 | enxame de lama envenenada caindo em volta do alvo (6 impactos) *(aplica poison)* |
| 12 | Gleaming Beetle | **Gleam Flash** | energy | nova raio 2 | -40 a -80 | a carapaça brilhante solta um clarão elétrico 5x5 |
| 13 | Mud Man | **Mud Grasp** | earth | burst raio 2 | -50 a -100 | mãos de lama agarram o alvo, explosão de terra 5x5 |
| 14 | Sea Iguana | **Tidal Snap** | water | wave 4 sqm larg 1 | -50 a -90 | mordida que puxa uma onda junto (corredor de água de 4 sqm) |
| 15 | Stone Tarantula | **Venom Web** | poison | nova raio 2 | -60 a -120 | dispara teia venenosa em todas as direções (5x5 + veneno) *(aplica poison)* |
| 16 | Steel Shell Centipede | **Steel Coil** | physical | wave 3 sqm larg 1 | -60 a -120 | se enrola e chicoteia o ar com o corpo de aço (onda 3x3) |
| 17 | Elephant | **Tusk Stampede** | physical | wave 4 sqm larg 1 | -60 a -110 | corre embalado e a tromba/ presas abrem um corredor de 4 sqm |
| 18 | Ba Sing Se Lion | **Ba Sing Se Roar** | fire | nova raio 3 | -60 a -120 | rugido flamejante de Mura de Ba Sing Se: 7x7 de fogo ao redor dele |
| 19 | Earth Woodpecker | **Stone Peck** | physical | beam 4 sqm | -70 a -140 | bica o chão e a pedra voa em linha reta (4 sqm) |
| 20 | Stone-Spitting Spider | **Stone Spit** | earth | blast | -80 a -150 | cospe uma pedra no alvo; o impacto de terra é o dano real |
| 21 | Vulture Bee | **Carrion Sting** | poison | rain raio 2 | -80 a -140 | nuvem de ferroadas de carniça em volta do alvo (6 impactos + veneno) *(aplica poison)* |
| 22 | Hermit Crab | **Shell Smash** | physical | burst raio 1 | -90 a -180 | se fecha e despenca a concha gigante em cima do alvo (3x3) |
| 23 | Jaguar | **Jaguar Maul** | physical | burst raio 1 | -120 a -220 | bote curto com as duas patas no alvo (3x3 de impacto) |
| 24 | Earth Mordecai | **Mordecai's Landslide** | earth | breath 4 sqm | -140 a -200 | deslizamento de terra em cone de 4 sqm na direção em que ele olha |
| 25 | Swamp Tentacles | **Tentacle Drag** | water | beam 3 sqm | -150 a -300 | três tentáculos batem em linha, tentando arrastar o alvo pro pântano |
| 26 | Traitor | **Backstab Dust** | earth | blast | -150 a -250 | ataque traiçoeiro pelas costas, com estilhaço de terra no alvo |
| 27 | Guardian Beetle | **Guardian's Tremor** | earth | nova raio 3 | -150 a -250 | golpeia o chão como guardião: tremor 7x7 em volta dele |
| 28 | Desert Crocodile | **Sandwater Ambush** | water | breath 4 sqm | -180 a -300 | emergir da areia molhada num bote em cone de 4 sqm |
| 29 | Uncontrolled Knowledge | **Whispered Madness** | death | nova raio 3 | -180 a -300 | sussurros que enlouquecem: 7x7 de dano de morte + maldição *(aplica curse)* |
| 30 | Hopper | **Hopper Cyclone** | air | nova raio 3 | -180 a -300 | salta e gira criando um ciclone de ar 7x7 em volta dele |
| 31 | Vacaceronte | **Charging Horns** | physical | beam 5 sqm | -200 a -350 | carregada com os chifres, atropelando tudo em 5 sqm de linha |
| 32 | Rock-Eating Cockroach | **Rock Crunch** | physical | burst raio 2 | -250 a -380 | mastiga pedra e cospe o cascalho no alvo, estourando 5x5 |
| 33 | White Scarab | **Sacred Sandstorm** | earth | rain raio 3 | -250 a -400 | tempestade de areia sagrada caindo em volta do alvo (8 impactos) |
| 34 | Forbidden Folds Book | **Forbidden Chapter** | death | rain raio 2 | -280 a -450 | folhas que viram lâminas caem do céu em volta do alvo (6 impactos + maldição) *(aplica curse)* |
| 35 | Black Panther | **Panther Pounce** | physical | burst raio 2 | -300 a -500 | salto longo caindo em cima do alvo com explosão 5x5 |
| 36 | Mountain Defender | **Mountain Slam** | earth | nova raio 3 | -300 a -600 | arranca um pedaço da montanha e espatifa no chão: 7x7 |
| 37 | Swamp Man Arm | **Swamp Slam** | physical | wave 3 sqm larg 1 | -350 a -600 | braçada de pântano que abre uma onda de lama de 3 sqm |
| 38 | Trenix | **Trenix Inferno** | fire | breath 4 sqm | -450 a -650 | baforada de fogo em cone de 4 sqm que deixa queimando *(aplica burn)* |
| 39 | Swamp Man Head | **Swamp Miasma** | poison | nova raio 3 | -500 a -900 | nuvem de gás do pântano 7x7 em volta da cabeça + envenenamento *(aplica poison)* |
| 40 | Swamp Monster | **Swamp Devour** | poison | breath 4 sqm | -500 a -900 | abre a boca e engole a área num cone de 4 sqm venenoso *(aplica poison)* |
| 41 | Blue Hydra Head | **Blue Hydra Storm** | energy | rain raio 2 | -700 a -1400 | cabeça azul chama raios do céu em volta do alvo (7 descargas) |
| 42 | Green Hydra Head | **Green Hydra Spores** | poison | nova raio 3 | -700 a -1400 | solta esporos corrosivos em 7x7 que continuam corroendo depois *(aplica corrode)* |

## Bichos de ambiente (sem spell)

Estes nao tem spell nenhuma e sao passivos no XML (`<flag hostile="0"/>`,
`<strategy attack="0"/>`): nao escolhem alvo e nao atacam o player. A entrada aqui
e' so' o registro de que a spell deles foi removida.

| Monstro | Spell que foi removida |
|---------|------------------------|
| Bee | Sting Barrage |
| Chicken | Feather Flurry |
| Crab | Pinching Tide |
| Frog | Bubble Blast |
| Rabbit | Panic Dash |
| Sheep | Wool Cloud |
| Swan | Wing Gust |
| Wild Wolf | Pack Howl |
