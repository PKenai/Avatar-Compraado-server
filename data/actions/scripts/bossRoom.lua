local MIN_TENTACLES     = 8
local MAX_TENTACLES     = 10

local HEAL_AMOUNT       = 2000
local HEAL_INTERVAL     = 1000
local HEAL_RANGE        = 2
local TENTACLE_CHECK_MS = 30000

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

        local tooClose = false
        for _, boss in pairs(bossRoomState.bosses) do
            local dx = math.abs(pos.x - boss.pos.x)
            local dy = math.abs(pos.y - boss.pos.y)
            if math.max(dx, dy) < TENTACLE_MIN_DIST then
                tooClose = true
                break
            end
        end

        if not tooClose and isPosWalkable(pos) then
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

local function countPlayersInBossRoom()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    local count = 0
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                count = count + 1
            end
        end
    end
    return count
end

local function isTentacleNearAnyBoss()
    for _, boss in pairs(bossRoomState.bosses) do
        if not boss.isDead and boss.cid and isCreature(boss.cid) then
            local bossPos = getCreaturePosition(boss.cid)
            if bossPos then
                local specs = getSpectators(bossPos, HEAL_RANGE, HEAL_RANGE)
                if specs and #specs > 0 then
                    for i = 1, #specs do
                        if isMonster(specs[i]) and getCreatureName(specs[i]) == TENTACLE_NAME then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function healAllAliveBosses()
    for _, boss in pairs(bossRoomState.bosses) do
        if not boss.isDead and boss.cid and isCreature(boss.cid) then
            local bossPos = getCreaturePosition(boss.cid)
            if bossPos then
                doCreatureAddHealth(boss.cid, HEAL_AMOUNT)
                doSendAnimatedText(bossPos, "+2000", 198)
                doSendMagicEffect(bossPos, 14)
            end
        end
    end
end

local function healBossTick(timerId)
    -- Eu SOU o timer que esta' rodando: nao estou mais pendente. Zerar aqui
    -- evita que o bossRoomStopTimers (via bossRoomResetAll) chame stopEvent no
    -- proprio evento em execucao - isso apagava o no' que o executeTimer do C++
    -- ainda ia ler e derrubava o server (ver a nota em bossRoomLib.lua).
    bossRoomState.healTimerId = nil

    if not bossRoomState.active then return end

    if countPlayersInBossRoom() == 0 then
        bossRoomResetAll(timerId)
        return
    end

    if areAllBossesDead() then
        return
    end

    if isTentacleNearAnyBoss() then
        healAllAliveBosses()
    end

    bossRoomState.healTimerId = addEvent(healBossTick, HEAL_INTERVAL)
end

local function maintainTentacles()
    -- Mesma regra do healBossTick: zerar o proprio id enquanto executa.
    bossRoomState.tentacleTimerId = nil

    if not bossRoomState.active then return end
    if areAllBossesDead() then return end

    local count = countTentacles()
    local toSpawn = 0

    if count < MIN_TENTACLES then
        toSpawn = math.min(MIN_TENTACLES - count, MAX_TENTACLES - count)
    elseif count < MAX_TENTACLES then
        toSpawn = 1
    end

    for i = 1, toSpawn do
        spawnRandomTentacle()
    end

    bossRoomState.tentacleTimerId = addEvent(maintainTentacles, TENTACLE_CHECK_MS)
end

local function startBossRoomTimers()
    bossRoomState.active = true
    bossRoomState.healTimerId = addEvent(healBossTick, HEAL_INTERVAL)
    bossRoomState.tentacleTimerId = addEvent(maintainTentacles, TENTACLE_CHECK_MS)
end

local function isAnyBossAlive()
    for _, boss in pairs(bossRoomState.bosses) do
        if not boss.isDead and boss.cid and isCreature(boss.cid) then
            return true
        end
    end
    return false
end

local function isBossRoomOccupied()
    return countPlayersInBossRoom() > 0
end

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

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if item.itemid == LEVER_ON then
        if not isBossRoomOccupied() and not isAnyBossAlive() then
            bossRoomResetAll()
            doTransformItem(item.uid, LEVER_OFF)
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "A alavanca foi resetada automaticamente.")
            return true
        end
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "O boss ja esta ativo ou uma equipe esta dentro da sala! Derrote-o primeiro.")
        return true
    end

    if isBossRoomOccupied() then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Ja existe uma equipe na sala do boss. Aguarde eles sairem.")
        return true
    end

    local players = getPlayersOnEntryTiles()
    if #players == 0 then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Nenhum player nos tiles de entrada! Posicione-se nos 5 tiles primeiro.")
        return true
    end

    local currentTime = os.time()
    for i = 1, #players do
        local pid = players[i]
        local cooldown = getPlayerStorageValue(pid, BOSS_COOLDOWN_STORAGE)
        if cooldown > currentTime then
            local remaining = cooldown - currentTime
            local hours = math.floor(remaining / 3600)
            local minutes = math.floor((remaining % 3600) / 60)
            local timeMsg = ""
            if hours > 0 then
                timeMsg = string.format("%d hora(s) e %d minuto(s)", hours, minutes)
            else
                timeMsg = string.format("%d minuto(s)", math.max(1, minutes))
            end

            doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
                string.format("O jogador %s ainda possui cooldown de entrada no Boss do Pantano (%s restantes).", getPlayerName(pid), timeMsg))
            return true
        end
    end

    bossRoomResetAll()

    doTransformItem(item.uid, LEVER_ON)

    for i = 1, #players do
        local pid = players[i]
        setPlayerStorageValue(pid, BOSS_COOLDOWN_STORAGE, currentTime + BOSS_COOLDOWN_TIME)
        doTeleportThing(pid, TELEPORT_POS)
        doSendMagicEffect(TELEPORT_POS, CONST_ME_TELEPORT)
        doPlayerSendTextMessage(pid, MESSAGE_EVENT_ADVANCE,
            "Bem-vindo a sala do Homem do Pantano! Derrote os 3 bosses em ate 5 segundos de diferenca para vencer!")
    end

    for key, boss in pairs(bossRoomState.bosses) do
        boss.isDead = false
        boss.respawnTimer = nil
        local bossCid = doCreateMonster(boss.name, boss.pos, false, false)
        if bossCid and bossCid > 0 then
            boss.cid = bossCid
            doSendMagicEffect(boss.pos, CONST_ME_MEEH)
        else
            print("[BossRoom] Erro ao invocar boss parte: " .. key .. " (" .. boss.name .. ")")
        end
    end

    local initialTentacles = math.random(MIN_TENTACLES, MAX_TENTACLES)
    for i = 1, initialTentacles do
        spawnRandomTentacle()
    end

    startBossRoomTimers()

    return true
end
