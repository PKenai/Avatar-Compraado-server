================================================================================
SISTEMA BOMBERMAN - MODULOS DO CLIENT (OTClient)
================================================================================

Existem 2 modulos opcionais para o client:

  1. bomberman_button  -> botao "BOMB" (janelinha na tela para soltar a bomba)
  2. bomberman_music   -> musica do evento por AREA (estilo shader)

SEM os modulos, o sistema continua funcionando 100% no servidor:
  * Soltar bomba: digite !bomb
  * A musica nao toca (precisa do modulo bomberman_music)

================================================================================
1) BOTAO "BOMB"
================================================================================

Copie a pasta "bomberman_button" para a pasta de modulos do client:

    <pasta_do_client>/modules/bomberman_button/

(ou seja: <client>/modules/bomberman_button/bomberman_button.lua)

Reinicie o client. Quando a partida de Bomberman comecar, a janelinha "BOMB"
aparece no canto inferior direito da tela. Clique nela para soltar a bomba.

Opcodes: 160 = servidor -> client (abre/fecha), 161 = client -> servidor (clique).

================================================================================
2) MUSICA DO EVENTO (por area, estilo shader)
================================================================================

Copie a pasta "bomberman_music" para a pasta de modulos do client:

    <pasta_do_client>/modules/bomberman_music/

(ou seja: <client>/modules/bomberman_music/bomberman_music.lua
          <client>/modules/bomberman_music/bomberman_music.otmod)

O arquivo de musica precisa existir em:

    <client>/data/sounds/Bombermanevent/theme.ogg

Comportamento: enquanto o jogador estiver dentro da area
{x = 1459, y = 7, z = 7} ate {x = 1604, y = 170, z = 7}, o tema toca em loop.
Ao sair da area, a musica para (igual ao shader da Appa).

LOOP_MS dentro do bomberman_music.lua e a duracao do theme.ogg (~2:54).
Se voce trocar a musica, ajuste LOOP_MS para a nova duracao.

Opcode: 162 = servidor -> client ("play" / "stop").

================================================================================
LADO DO SERVIDOR (ja implementado):
================================================================================

    data/lib/bomberman.lua                      - nucleo do sistema (fila, arenas,
                                                  partida, explosao, power-ups e
                                                  musica da area)
    data/globalevents/scripts/bomberman.lua     - onStartup (inicializa)
    data/globalevents/globalevents.xml          - registro
    data/talkactions/scripts/bomberman.lua      - !joinbombermanevent / !leavebombermanevent / !bomb
    data/talkactions/talkactions.xml            - registro
    data/movements/scripts/bomberman.lua        - power-ups 18373-18377 e chute da bomba
    data/movements/movements.xml                - registro
    data/creaturescripts/scripts/bomberman.lua  - login/logout/morte/opcode
    data/creaturescripts/creaturescripts.xml    - registro
    data/creaturescripts/scripts/loginLogout/login.lua - registro dos eventos por jogador
================================================================================
