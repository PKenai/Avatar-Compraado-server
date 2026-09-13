BOSS_ROOM_FROM = BOSS_ROOM_FROM or {x = 120, y = 1924, z = 7}
BOSS_ROOM_TO   = BOSS_ROOM_TO   or {x = 177, y = 1968, z = 7}
ROOM_CENTER    = ROOM_CENTER    or {x = 149, y = 1946, z = 7}
ROOM_RANGEX    = ROOM_RANGEX    or 30
ROOM_RANGEY    = ROOM_RANGEY    or 23

TENTACLE_NAME     = TENTACLE_NAME     or "Swamp Tentacles"
TENTACLE_MIN_DIST = TENTACLE_MIN_DIST or 3

LEVER_ON  = LEVER_ON  or 1946
LEVER_OFF = LEVER_OFF or 1945

ENTRY_TILES = ENTRY_TILES or {
    {x = 807, y = 517, z = 5},
    {x = 807, y = 518, z = 5},
    {x = 807, y = 519, z = 5},
    {x = 807, y = 520, z = 5},
    {x = 807, y = 521, z = 5},
}

EXIT_POS = EXIT_POS or {x = 799, y = 519, z = 6}
TELEPORT_POS = TELEPORT_POS or {x = 142, y = 1953, z = 7}

CHEST_ITEMID   = 18878
CHEST_ACTIONID = 50011
CHEST_POS      = {x = 145, y = 1944, z = 7}

REWARD_CRYSTAL_COIN  = 2160
REWARD_CRYSTAL_COUNT = 2
REWARD_PLATINUM_COIN = 2152
REWARD_PLATINUM_COUNT = 50

BOSS_COOLDOWN_STORAGE  = 50010
BOSS_COOLDOWN_TIME     = 5 * 3600

CHEST_COOLDOWN_STORAGE = 50011
CHEST_COOLDOWN_TIME    = 1 * 3600

SYNC_DEATH_WINDOW = 5000

bossRoomState = bossRoomState or {
    active = false,
    bosses = {
        head = {
            name = "Swamp Man Head",
            pos = {x = 145, y = 1939, z = 7},
            cid = nil,
            isDead = false,
            respawnTimer = nil,
            label = "A cabeça",
        },
        leftArm = {
            name = "Swamp Man Arm",
            pos = {x = 143, y = 1941, z = 7},
            cid = nil,
            isDead = false,
            respawnTimer = nil,
            label = "O braço esquerdo",
        },
        rightArm = {
            name = "Swamp Man Arm",
            pos = {x = 148, y = 1941, z = 7},
            cid = nil,
            isDead = false,
            respawnTimer = nil,
            label = "O braço direito",
        },
    },
    healTimerId = nil,
    tentacleTimerId = nil,
    exitTimerId = nil,
}

function bossRoomRemoveChest()
    local item = getTileItemById(CHEST_POS, CHEST_ITEMID)
    if item and item.uid and item.uid > 0 then
        doRemoveItem(item.uid)
        return true
    end
    return false
end

function bossRoomSpawnChest()
    bossRoomRemoveChest()
    local chest = doCreateItem(CHEST_ITEMID, 1, CHEST_POS)
    if chest and chest > 0 then
        doSetItemActionId(chest, CHEST_ACTIONID)
        doSendMagicEffect(CHEST_POS, CONST_ME_MAGIC_BLUE)
        return true
    end
    return false
end

function bossRoomRemoveTentacles()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) and getCreatureName(specs[i]) == TENTACLE_NAME then
                doRemoveCreature(specs[i])
            end
        end
    end
end

function bossRoomRemoveAllMonsters()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) then
                doRemoveCreature(specs[i])
            end
        end
    end
end

--[[
  NUNCA chamar stopEvent() no evento que esta' rodando agora.

  No C++ o LuaInterface::executeTimer guarda o iterador do evento, chama o
  callback e SO' DEPOIS le' esse iterador pra liberar as referencias
  (luascript.cpp, no fim de executeTimer). O stopEvent() apaga a entrada do
  m_timerEvents (luaStopEvent -> erase), entao parar a si mesmo deixa o iterador
  apontando pra um no' ja' liberado: a leitura seguinte estoura um access
  violation e o server cai na hora (sem mensagem nenhuma no console).

  Por isso quem roda como timer zera o proprio *TimerId na PRIMEIRA linha do
  callback (ele nao esta' mais "pendente" - esta' executando). Assim este
  bossRoomStopTimers nao acha mais o id e nao chama stopEvent nele.
  runningEventId (opcional) e' o cinto de seguranca pra quem preferir passar.
]]
function bossRoomStopTimers(runningEventId)
    bossRoomState.active = false
    if bossRoomState.healTimerId and bossRoomState.healTimerId ~= runningEventId then
        stopEvent(bossRoomState.healTimerId)
        bossRoomState.healTimerId = nil
    end
    if bossRoomState.tentacleTimerId and bossRoomState.tentacleTimerId ~= runningEventId then
        stopEvent(bossRoomState.tentacleTimerId)
        bossRoomState.tentacleTimerId = nil
    end
    if bossRoomState.exitTimerId and bossRoomState.exitTimerId ~= runningEventId then
        stopEvent(bossRoomState.exitTimerId)
        bossRoomState.exitTimerId = nil
    end

    for key, boss in pairs(bossRoomState.bosses) do
        if boss.respawnTimer and boss.respawnTimer ~= runningEventId then
            stopEvent(boss.respawnTimer)
            boss.respawnTimer = nil
        end
        boss.cid = nil
        boss.isDead = false
    end
end

-- runningEventId = o id do timer que esta' chamando isso (se for um timer)
function bossRoomResetAll(runningEventId)
    bossRoomStopTimers(runningEventId)
    bossRoomRemoveAllMonsters()
    bossRoomRemoveChest()
end

function areAllBossesDead()
    for key, boss in pairs(bossRoomState.bosses) do
        if not boss.isDead then
            return false
        end
    end
    return true
end

function getBossKeyByCid(cid)
    for key, boss in pairs(bossRoomState.bosses) do
        if boss.cid == cid then
            return key
        end
    end
    return nil
end

function respawnBossPart(partKey)
    if not bossRoomState.active then return end
    local boss = bossRoomState.bosses[partKey]
    if not boss or not boss.isDead then return end

    boss.respawnTimer = nil

    if areAllBossesDead() then return end

    local newCid = doCreateMonster(boss.name, boss.pos, false, false)
    if newCid and newCid > 0 then
        boss.cid = newCid
        boss.isDead = false
        doSendMagicEffect(boss.pos, CONST_ME_TELEPORT)

        local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
        if specs and #specs > 0 then
            for i = 1, #specs do
                if isPlayer(specs[i]) then
                    doPlayerSendTextMessage(specs[i], MESSAGE_STATUS_WARNING,
                        boss.label .. " do Homem do Pântano se regenerou! Todos devem morrer em até 5 segundos de diferença!")
                end
            end
        end
    end
end
