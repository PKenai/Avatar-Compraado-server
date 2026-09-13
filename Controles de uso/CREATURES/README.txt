========================================
  CRIATURAS - editores de monstros (Avatar Server)
========================================

COMO USAR
---------
1. Dois cliques em  criaturas.bat
2. Escolha o editor no menu (cada um volta pro menu depois de terminar).

O QUE CADA EDITOR FAZ
---------------------
[1] Listar / buscar  -> lista as criaturas de monsters.xml
                        ( "!" = o xml daquela criatura nao foi encontrado )
[2] Ficha            -> vida, xp, speed, look, flag, ataques, defesas, loot e a
                        magia assinatura da criatura
[3] Status           -> vida, experiencia, speed, armor, defense, strategy attack,
                        targetdistance e runonhealth. Mostra o valor atual e pede
                        o novo ("hoje esta' com X, quer trocar pra quanto?").
[4] Dano             -> altera min/max/interval/chance/range de um ataque
                        ja' existente
[5] Loot             -> lista o loot com a chance em % (12.5 = 12500/100000) e
                        adiciona/remove itens
[6] Outfit           -> troca o <look type=".."> (outfit de criatura) ou
                        <look typeEx=".."> (item, ex: estatuas/dummy) e o corpse
[7] Magias           -> [A] adicionar magia
                          [1] magia assinatura (lista pronta do gerador)
                          [2] ataque elementar simples (fogo, agua, terra, ar,
                              gelo, energia, morte, sagrado, veneno, drenos...)
                          [3] suporte (cura em area, regen, speed, invisivel...)
                        [R] remover um ataque
                        [L] ver a lista de magias prontas
                        [B] trocar so' a entrada do monsterSpellBook.lua
[8] Renomear         -> troca o nome da criatura em TUDO: conteudo do xml,
                        nome do arquivo xml, monsters.xml, todos os spawns
                        (data\world\*.xml) e a chave no monsterSpellBook.lua.
                        No fim procura outras referencias e avisa.
[9] Duplicar         -> cria uma criatura nova copiando outra (xml + monsters.xml
                        + entrada do livro de spells)

ARQUIVOS TOCADOS
----------------
data\monster\monsters.xml          (registro das criaturas)
data\monster\<pasta>\<Nome>.xml    (a criatura em si)
data\world\*.xml                   (spawns - so' no renomear)
data\lib\monsterSpellBook.lua      (magia assinatura)
tools\gen_monster_spells.py        (SOMENTE leitura: e' a lista de magias prontas)

BACKUP
------
Todo arquivo alterado ganha um  <arquivo>.bak  do lado dele antes de gravar.

DETALHES QUE IMPEDEM ESTRAGAR ALGO
----------------------------------
- A magia do monstro e' descoberta pelo NOME de quem conjura
  (data\spells\scripts\monster\monsterSpell.lua le' monsterSpellBook.lua).
  Consequencia: existe UMA entrada por criatura e o formato dela
  (nova / burst / wave / beam / breath / blast / rain) vale para todas as magias
  daquela criatura que usam esse motor. O editor avisa quando ja' existe.
- O dano da magia vem do <attack min max> no xml. O editor pede o dano MEDIO e
  escreve min = 80% e max = 120% (ex: media 30 -> min=-24 max=-36).
- Chance de loot no servidor vai de 0 a 100000 (100000 = sempre). O editor pede
  em % e converte.
- Os nomes exatos de ataque aceitos pelo servidor estao em sources\monsters.cpp
  (melee, physical, fire, water, earth, air, ice, energy, poison, death, holy,
  lifedrain, manadrain, healing, speed, invisible, drunk...).
- Depois de qualquer edicao: reinicie o servidor (xml e lua sao lidos no boot).
