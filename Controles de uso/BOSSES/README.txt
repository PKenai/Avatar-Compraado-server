========================================
  BOSSES ALPHA - editor do sistema de bosses (Avatar Server)
========================================

COMO USAR
---------
1. Dois cliques em  bosses.bat
2. Escolha o editor no menu (cada um volta pro menu depois de terminar).

O QUE CADA EDITOR FAZ
---------------------
[1]  Listar           -> todos os bosses ALPHA com a meta de kills da task diaria,
                         a luva que dropam e a chance REAL de drop (a do xml nao e'
                         a porcentagem final - ver DETALHES).
[2]  Ficha            -> vida, xp, speed, look, flags, defesas, ataques e loot
                         do boss, com a % real de cada item.
[3]  Status           -> vida, experiencia, speed, armor, defense, strategy attack,
                         targetdistance e runonhealth. Mostra o valor atual e pede
                         o novo ("hoje esta' com X, quer trocar pra quanto?").
[4]  Loot             -> o mais importante aqui: pede a porcentagem REAL desejada
                         e calcula sozinho o chance= que produz esse resultado.
                         [1] muda so' o boss escolhido (imediato)
                         [2] muda GLOVE_CHANCE no gerador (vale para todos
                             depois de um [9] Regerar)
[5]  Tuning           -> HP/EXP/SPEED/MELEE/ELEM/DEF/GOLD_MULT, GLOVE_CHANCE,
                         CRYSTAL_CHANCE, CRYSTAL_COUNTMAX, MIN_KILLS, MAX_KILLS, EXP_FOR_MAX_KILLS.
                         Vale para TODOS os bosses: depois use o [9] Regerar.
                         As opcoes 8 e 9 pedem a % real e convertem.
[6]  Metas de kills   -> lista a meta da task diaria de cada criatura e permite
                         alterar uma (o teto do design e' 1000).
[7]  Sorteio diario   -> quais criaturas podem cair na task diaria do player.
                         Criaturas de evento/quest (pantano, hydra, dummy) ficam
                         fora: pedir 1000 kills delas seria impossivel.
[8]  Tile do portal   -> troca o itemID e o actionID do tile que invoca o boss.
                         Mantem bossSystem.lua, bossConfig.lua e movements.xml
                         em sincronia (a opcao [3] so' conserta o registro).
[9]  Regerar          -> roda tools\generate_bosses.py e recria TODOS os bosses
                         a partir dos monstros ofensivos.
[10] Diagnostico      -> checa arquivos, registro no monsters.xml, xml invalido,
                         chave de storage, luvas que nao existem no items.xml,
                         registro do movements/globalevent, chance da luva fora
                         dos 4%, bosses dessincronizados do gerador, tamanho do
                         sorteio diario, metas acima de 1000 e a versao do
                         bossConfig em relacao ao gerador.

COMO O SISTEMA FUNCIONA (resumo)
--------------------------------
1. O player mata criaturas ofensivas. A task diaria dele pede N kills de cada uma
   (N sai da forca da criatura: MIN_KILLS ate MAX_KILLS).
2. Ao completar uma task, o player recebe um storage do dia ligado aquela criatura
   e passa a poder invoca-la.
3. Pisando no tile do portal (itemID 19333/19334 ou QUALQUER item com o actionID 50030),
   o servidor procura ao redor do tile a criatura correspondente, spawna o boss
   ALPHA dela ao lado do player e consome o acesso (uma vez por task).
4. O boss ALPHA tem 20% mais tamanho no cliente, contorno vermelho pulsante e
   chance de 4% de dropar a luva completa daquela criatura (+ 10k = 1 crystal coin).
5. O boss some sozinho depois de 30 minutos (globalevent bossSystem.lua).

ARQUIVOS TOCADOS
----------------
tools\generate_bosses.py            (SOMENTE leitura: e' a fonte de verdade dos bosses)
data\monster\bosses\*.xml           (os bosses ALPHA - modo [3]/[4] e o [9])
data\monster\bosses\bosses.xml      (lista dos bosses - so' o [9])
data\monster\monsters.xml           (registro dos bosses - so' o [9])
data\lib\bossConfig.lua             (tabela criatura -> boss/luva/meta - [6] e [9])
data\lib\bossSystem.lua             (constantes do tile - modo [8])
data\movements\movements.xml        (registro do StepIn do portal - modo [8])

BACKUP
------
Todo arquivo alterado ganha um  <arquivo>.bak  do lado dele antes de gravar.
A opcao [9] Regerar faz mais que isso: copia a pasta inteira dos bosses para
data\monster\bosses.bak_<data_hora> antes de sobrescrever.

DETALHES QUE IMPEDEM ESTRAGAR ALGO
----------------------------------
- O "chance=" do xml NAO e' a porcentagem final. Em sources/monsters.cpp o servidor
  corta a chance pela metade (chance 2..9999 -> ceil(chance/2)) e depois o sorteio
  estoura 16 bits (depende do rateLoot do config.lua). Com o rateLoot atual (0.1)
  a chance efetiva e' praticamente  chance/1250  - ou seja chance="4000" droppa
  ~3,2% e nao 4%. Por isso os bosses usam chance="5000" (~4,00%).
  Consequencia chata: a faixa 5001..9999 de chance efetiva e' INALCANCAVEL; depois
  de 5000 o proximo degrau e' 10000 (que ja' da ~15%). O editor avisa quando existe
  essa diferenca e mostra sempre a % real do lado do chance=.
- O gerador e' a fonte de verdade: editar um boss na mao funciona, mas o proximo
  [9] Regerar sobrescreve. Se for mexer em muitos bosses de uma vez, mexa nas
  constantes ([5] Tuning) e regere.
- A tabela de metas ([6]) e' RECALCULADA pelo [9] Regerar. Para mudar em massa,
  mude MIN_KILLS/MAX_KILLS/EXP_FOR_MAX_KILLS no [5].
- O itemID 19333 nao existe no items.xml deste servidor. Se ele tambem nao existir
  no items.otb (o que o RME enxerga), use o ACTIONID 50030 em um item que ja' exista
  no mapa - funciona do mesmo jeito. O [10] Diagnostico avisa disso.
- Chave de storage vai para player_storage.key (VARCHAR(32)): o nome do boss entra
  sanitizado ("Boss_Black_Panther"). Um nome novo muito longo estouraria a coluna,
  por isso o [10] confere.
- Os xml dos monstros sao lidos no boot: depois de editar, REINICIE o servidor.
  (A task diaria e o tile sao lua e entram com /reload ou relog.)
- Se o xml ficar invalido, o servidor nao sobe. O [10] valida antes e todo arquivo
  mexido tem .bak do lado.
