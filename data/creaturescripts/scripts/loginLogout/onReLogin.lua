-- ============================================================================
--  RE-LOGIN: fechar o client sem deslogar e entrar de novo
-- ----------------------------------------------------------------------------
--  Quando o client fecha sem deslogar, o personagem continua ONLINE no
--  servidor (e' por isso que o client reclama "already online or logging").
--  Ao voltar, ProtocolGame::connect() roda com reLogin = true: reaproveita o
--  MESMO objeto de Player e NAO dispara nenhum script do evento "login"
--  (login.lua, market_login.lua, firstlogin.lua) - de proposito, e' pra ser um
--  "resume" e nao um login novo.
--
--  So' que, do jeito que estava (este arquivo nao estava nem registrado no
--  creaturescripts.xml), o "resume" voltava com tudo o que ficou pendurado da
--  sessao que morreu:
--    * doCreatureSetNoMove(true) do voo de Appa/planar nunca era liberado ->
--      o jogador entrava PARALIZADO (nao andava de jeito nenhum);
--    * veneno/fogo/paralisia/bleeding aplicados por monstro ou campo enquanto
--      ele estava "online sem client" continuavam rolando -> entrava
--      ENVENENADO;
--    * os efeitos dos talentos nao eram reaplicados (o bloco de login roda as
--      cegas no onLogin) e o condition de atributos seguia com os valores da
--      sessao antiga;
--    * "timeLogin" continuava sendo o horario do login original, o que furava
--      o guard de 5s do opcode 230 (market) e fazia a janela do market abrir
--      sozinha no relog.
--
--  Aqui roda a normalizacao minima do relogin. Nao mexe em nada que seja estado
--  legitimo de jogo: posicao, vida/mana atuais, itens, exaustao, PZ lock.
-- ============================================================================

-- Estados de sessao: sem client conectado, quem aplicou (monstro, campo, spell)
-- nao esta mais agindo sobre ele. Sao estados que o jogador espera "limpos" ao
-- voltar; se ele realmente estiver em cima de um campo/monstro, o estado volta
-- no tique seguinte, ai' sim por conta do jogo.
-- Nomes (e nao valores) das constantes: assim a lista nao depende da ordem de
-- carregamento de data/lib em relacao a este arquivo - se CONDITION_POISON
-- ainda nao existisse no load, a tabela viraria {nil,...} e o for nao rodaria
-- nada, silenciosamente.
local SESSION_CONDITION_NAMES = {
    "CONDITION_POISON",
    "CONDITION_FIRE",
    "CONDITION_ENERGY",
    "CONDITION_BLEEDING",
    "CONDITION_PARALYZE",
    "CONDITION_DROWN",
    "CONDITION_FREEZING",
    "CONDITION_DAZZLED",
    "CONDITION_CURSED",
    "CONDITION_DRUNK",
}

local function sessionConditionValue(name)
    local value = rawget(_G, name)
    if type(value) == "number" then
        return value
    end
    return nil
end

function onReLogin(cid)
    if not isPlayer(cid) then
        return true
    end

    -- 1) Estados pendurados da sessao anterior
    for i = 1, #SESSION_CONDITION_NAMES do
        local conditionType = sessionConditionValue(SESSION_CONDITION_NAMES[i])
        if conditionType then
            pcall(doRemoveCondition, cid, conditionType)
        end
    end

    -- 1b) Trava de movimento: libera SEMPRE no relogin. Quem trava e' o voo do
    -- Appa (appaFlight.lua -> doCreatureSetNoMove) e a flag fica no objeto do
    -- Player, que aqui e' o mesmo de antes: sem isso o personagem entra sem
    -- conseguir dar um passo. restoreAppaOutfit tambem devolve o outfit normal.
    if type(restoreAppaOutfit) == "function" then
        pcall(restoreAppaOutfit, cid)
    end
    pcall(doCreatureSetNoMove, cid, false)

    -- 1c) MONTARIA DESATIVADA: no relogin o objeto do player e' o MESMO, entao
    -- "mounted" continua true e o speed da montaria continua no varSpeed (o
    -- engine so' tira no dismount). Aqui o player sai do modo montado.
    if type(dismountPlayer) == "function" and getPlayerStorageValue(cid, "inMount") == 1 then
        pcall(dismountPlayer, cid)
    end
    pcall(doPlayerSetMounted, cid, false)

    -- 2) Nunca voltar com vida/mana acima do maximo (relog no meio de um efeito
    -- que mexia no maximo deixava o numero "estourado" na tela)
    if getCreatureHealth(cid) > getCreatureMaxHealth(cid) then
        doCreatureAddHealth(cid, -(getCreatureHealth(cid) - getCreatureMaxHealth(cid)))
    end
    if getCreatureMana(cid) > getCreatureMaxMana(cid) then
        doCreatureAddMana(cid, -(getCreatureMana(cid) - getCreatureMaxMana(cid)))
    end

    -- 3) Carimbo de login: logout.lua usa pra somar o tempo online e o opcode
    -- 230 (market) pra ignorar pedido de market nos 5s seguintes ao login.
    -- Como aqui nao vai ter logout, o tempo da sessao anterior tem que ser
    -- contado AGORA - senao o trecho entre o login original e o relog se perde.
    local lastLogin = getPlayerStorageValue(cid, "timeLogin")
    if type(lastLogin) == "number" and lastLogin > 0 and type(addPlayerTimeOnline) == "function" then
        pcall(addPlayerTimeOnline, cid, os.time() - lastLogin)
    end
    setPlayerStorageValue(cid, "timeLogin", os.time())

    -- 4) Talentos: os efeitos eram reaplicados so' no onLogin. Como aqui o
    -- Player e' o mesmo, o condition de atributos ficava com os valores da
    -- sessao anterior - reaplica do zero (idempotente) e reenvia o JSON.
    if type(TalentTree) ~= "table" then
        dofile(getDataDir().."lib/talentTree.lua")
    end
    if type(TalentTree) == "table" then
        TalentTree.reapplyAll(cid)
        TalentTree.sendData(cid)
    end

    -- 4b) Fontes de velocidade que vivem em storage (agilidade/montaria).
    -- No relogin o objeto e' o MESMO e o varSpeed tambem, entao cada fonte
    -- so' corrige se o valor do storage mudou - e nunca apaga o que as
    -- conditions (haste/paralyze) tem dentro do acumulador.
    if type(PlayerSpeed) == "table" then
        if PlayerSpeed.refreshFromStorages then
            PlayerSpeed.refreshFromStorages(cid)
        end
        if PlayerSpeed.sweep then
            PlayerSpeed.sweep()
        end
    end

    -- 5) O client recarregou e a barra de buffs comecou vazia: reenvia os buffs
    -- persistentes (experience scroll etc) que continuam valendo no servidor.
    if type(restorePersistentBuffs) == "function" then
        pcall(restorePersistentBuffs, cid)
    end

    -- 5b) Statue Donation: a bencao da nacao (12h) e das abas globais (8h) vive
    -- na tabela do banco, nao no storage do player - reaplica o icone com o
    -- tempo que falta e REMOVE o que nao vale mais (bencao expirada, ou resetada
    -- pela staff enquanto o client estava fechado). Aqui o objeto do Player e' o
    -- MESMO e o client recarregou a barra de buffs vazia, entao vai com
    -- force = true: sem isso o modo "cru" (opcode 100) acharia que o icone ja'
    -- estava aplicado e nao reenviaria nada.
    if type(StatueDonation) == "table" and type(StatueDonation.applyBuffs) == "function" then
        pcall(StatueDonation.applyBuffs, cid, true)
    end
    -- 5c) Manda o ESTADO da estatua tambem (nacao ativa + pools). O client
    -- guarda o ultimo estado que recebeu: sem este pacote a janela reaberta
    -- (ou o texto de ajuda) ficaria com o pool/bencao da sessao que morreu.
    if type(StatueDonation) == "table" and type(StatueDonation.sendState) == "function" then
        pcall(StatueDonation.sendState, cid)
    end

    -- 6) Diagnostico (definido em login.lua): mostra no console do client o
    -- bitfield de icones e as condicoes ativas do personagem no relogin.
    if LOGIN_STATE_DEBUG ~= false and type(loginStateReport) == "function" then
        pcall(loginStateReport, cid, "relog+0s")
        addEvent(function(cid) loginStateReport(cid, "relog+3s") end, 3000, cid)
    end

    return true
end
