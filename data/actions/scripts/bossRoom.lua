--[[
 * BossRoom - Sistema completo da Sala do Boss do Pantano
 *
 * Tiles de entrada: {x=807, y=517, z=5} ate {x=807, y=521, z=5} (5 tiles)
 * Posicao de teleport dos players: {x=142, y=1953, z=7}
 * Spawn do boss: {x=147, y=1940, z=7}
 * Limites da sala do boss: {x=120, y=1924, z=7} ate {x=177, y=1968, z=7}
 * Saida apos boss morrer: {x=799, y=519, z=6}
 *
 * Mecanicas:
 *   - Boss cura 2000 HP/seg se tentaculos estao a 2 SQM de distancia
 *   - Minimo 4 tentaculos, maximo 6, respawn a cada 30s
 *   - Tentaculos spawnam em qualquer posicao walkable da sala
 *   - Ao morrer, boss remove todos os tentaculos e para timers
 *   - Players teleportados para fora 1 min apos boss morrer
 *
 * Registrado em data/actions/actions.xml com actionid 50010.
]]

-- ============================================================
-- Configuracao (usa constantes globais do bossRoomLib.lua)
-- ============================================================
local TELEPORT_POS = {x = 142, y = 1953, z = 7}

local MIN_TENTACLES     = 8
local MAX_TENTACLES     = 10

local HEAL_AMOUNT        = 2000
local HEAL_INTERVAL      = 1000  -- 1 segundo
local HEAL_RANGE         = 2     -- 2 SQM
local TENTACLE_CHECK_MS  = 30000 -- 30 segundos

-- ============================================================
-- Helpers: contagem de tentaculos
-- ============================================================
local function countTentacles()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    local count = 0
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) and getCreatureName(specs[i]) == TENTACLE_NAME then
                count = count + 1
            end
        end
    end
    return count
end

-- ============================================================
-- Helpers: spawn de tentaculos em posicoes aleatorias walkable
-- ============================================================
local function isPosWalkable(pos)
    local checkPos = {x = pos.x, y = pos.y, z = pos.z, stackpos = 0}
    local ground = getThingfromPos(checkPos)
    if ground.itemid == 0 then
        return false
    end
    return isWalkable(checkPos)
end

local function getRandomWalkablePos()
    local attempts = 0
    while attempts < 200 do
        local x = math.random(BOSS_ROOM_FROM.x, BOSS_ROOM_TO.x)
        local y = math.random(BOSS_ROOM_FROM.y, BOSS_ROOM_TO.y)
        local pos = {x = x, y = y, z = BOSS_ROOM_FROM.z}

        -- Pelo menos 3 SQM de distancia do boss (nao spawnar em cima dele)
        local dx = math.abs(pos.x - BOSS_SPAWN.x)
        local dy = math.abs(pos.y - BOSS_SPAWN.y)
        if math.max(dx, dy) >= TENTACLE_MIN_DIST and isPosWalkable(pos) then
            return pos
        end

        attempts = attempts + 1
    end
    return nil
end

local function spawnRandomTentacle()
    local pos = getRandomWalkablePos()
    if pos then
        doCreateMonster(TENTACLE_NAME, pos, false, true)
    end
end

-- ============================================================
-- Boss healing: cura 2000/seg se tentaculos estao a 2 SQM
-- ============================================================
local function isTentacleNearBoss()
    if not bossRoomState.bossId or not isCreature(bossRoomState.bossId) then
        return false
    end

    local bossPos = getCreaturePosition(bossRoomState.bossId)
    if not bossPos then return false end

    local specs = getSpectators(bossPos, HEAL_RANGE, HEAL_RANGE)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) and getCreatureName(specs[i]) == TENTACLE_NAME then
                return true
            end
        end
    end
    return false
end

local function healBossTick()
    if not bossRoomState.active then return end
    if not bossRoomState.bossId or not isCreature(bossRoomState.bossId) then
        bossRoomState.healTimerId = nil
        return
    end

    if isTentacleNearBoss() then
        local bossPos = getCreaturePosition(bossRoomState.bossId)
        if bossPos then
            doCreatureAddHealth(bossRoomState.bossId, HEAL_AMOUNT)
            doSendAnimatedText(bossPos, "+2000", 198)
            doSendMagicEffect(bossPos, 14)
        end
    end

    bossRoomState.healTimerId = addEvent(healBossTick, HEAL_INTERVAL)
end

-- ============================================================
-- Manutencao de tentaculos: manter 4-6, respawn a cada 30s
-- ============================================================
local function maintainTentacles()
    if not bossRoomState.active then return end
    if not bossRoomState.bossId or not isCreature(bossRoomState.bossId) then
        bossRoomState.tentacleTimerId = nil
        return
    end

    local count = countTentacles()
    local toSpawn = 0

    if count < MIN_TENTACLES then
        -- Faltam tentaculos, spawnar o necessario (sem exceder max)
        toSpawn = math.min(MIN_TENTACLES - count, MAX_TENTACLES - count)
    elseif count < MAX_TENTACLES then
        -- Abaixo do maximo, spawnar 1 para repor
        toSpawn = 1
    end

    for i = 1, toSpawn do
        spawnRandomTentacle()
    end

    bossRoomState.tentacleTimerId = addEvent(maintainTentacles, TENTACLE_CHECK_MS)
end

-- ============================================================
-- Iniciar timers da sala
-- ============================================================
local function startBossRoomTimers()
    bossRoomState.active = true
    bossRoomState.healTimerId = addEvent(healBossTick, HEAL_INTERVAL)
    bossRoomState.tentacleTimerId = addEvent(maintainTentacles, TENTACLE_CHECK_MS)
end

-- ============================================================
-- Checa se o boss esta vivo na sala
-- ============================================================
local function isBossAlive()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) and getCreatureName(specs[i]) == BOSS_NAME then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- Checa se ja tem players na sala do boss (protecao contra dupla entrada)
-- ============================================================
local function isBossRoomOccupied()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- Coleta players nos tiles de entrada
-- ============================================================
local function getPlayersOnEntryTiles()
    local players = {}
    local seen = {}
    for i = 1, #ENTRY_TILES do
        local pos = ENTRY_TILES[i]
        local specs = getSpectators(pos, 0, 0)
        if specs and #specs > 0 then
            for j = 1, #specs do
                if isPlayer(specs[j]) and not seen[specs[j]] then
                    seen[specs[j]] = true
                    table.insert(players, specs[j])
                end
            end
        end
    end
    return players
end

-- ============================================================
-- Reseta a alavanca (volta para off)
-- ============================================================
local function resetLever()
    for i = 1, #ENTRY_TILES do
        local pos = ENTRY_TILES[i]
        local item = getTileItemById(pos, LEVER_ON)
        if item and item.uid and item.uid > 0 then
            doTransformItem(item.uid, LEVER_OFF)
            return true
        end
    end
    local searchPos = {x = 808, y = 519, z = 5}
    local item = getTileItemById(searchPos, LEVER_ON)
    if item and item.uid and item.uid > 0 then
        doTransformItem(item.uid, LEVER_OFF)
        return true
    end
    return false
end

-- ============================================================
-- onUse - Alavanca da sala do boss
-- ============================================================
function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- Se a alavanca esta ON mas o boss nao existe mais, reseta automaticamente
    if item.itemid == LEVER_ON then
        if not isBossAlive() then
            bossRoomStopTimers()
            doTransformItem(item.uid, LEVER_OFF)
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "A alavanca foi resetada automaticamente.")
            return true
        end
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "O boss ja esta ativo! Derrote-o primeiro.")
        return true
    end

    -- Verifica se ja tem players na sala do boss
    if isBossRoomOccupied() then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Ja existe uma equipe na sala do boss. Aguarde eles sairem.")
        return true
    end

    -- Coleta players nos tiles de entrada
    local players = getPlayersOnEntryTiles()
    if #players == 0 then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Nenhum player nos tiles de entrada! Posicione-se nos 5 tiles primeiro.")
        return true
    end

    -- Transforma a alavanca para "on"
    doTransformItem(item.uid, LEVER_ON)

    -- Para qualquer timer anterior (seguranca)
    bossRoomStopTimers()

    -- Teleporta todos os players para dentro da sala
    for i = 1, #players do
        doTeleportThing(players[i], TELEPORT_POS)
        doSendMagicEffect(TELEPORT_POS, CONST_ME_TELEPORT)
        doPlayerSendTextMessage(players[i], MESSAGE_EVENT_ADVANCE, "Bem-vindo a sala do Boss do Pantano! Prepare-se!")
    end

    -- Spawn do boss
    local boss = doCreateMonster(BOSS_NAME, BOSS_SPAWN, false, false)
    if not boss then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Erro ao invocar o boss. Contate um administrador.")
        doTransformItem(item.uid, LEVER_OFF)
        return true
    end

    bossRoomState.bossId = boss

    -- Spawn inicial de tentaculos (entre 4 e 6)
    local initialTentacles = math.random(MIN_TENTACLES, MAX_TENTACLES)
    for i = 1, initialTentacles do
        spawnRandomTentacle()
    end

    -- Efeito na posicao do boss
    doSendMagicEffect(BOSS_SPAWN, CONST_ME_MEEH)

    -- Inicia os timers de cura e manutencao
    startBossRoomTimers()

    return true
end
