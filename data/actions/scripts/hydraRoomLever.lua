-- ============================================================
-- HYDRA ROOM - Alavanca
-- ActionID: 50020
-- Cooldown de 24h por player (quem estava nos entry tiles)
-- ============================================================

dofile(getDataDir() .. "lib/hydraRoomLib.lua")

local CLEANUP_DELAY   = 30 * 60 * 1000  -- 30 min timeout de seguranca
local PULSE_INTERVAL  = 1500             -- ms entre pulsos de dano
local PULSE_MIN_DMG   = -800
local PULSE_MAX_DMG   = -2200
local PULSE_FOCUS_CHANCE = 30            -- % de chance de focar o player

-- ============================================================
-- DANO PULSANTE
-- ============================================================
local function doHydraPulseDamage()
    if not hydraRoomState.active then return end
    if areAllHydrasDead() then return end

    local playerCount = hydraCountPlayersInRoom()
    if playerCount == 0 then
        hydraRoomResetAll()
        return
    end

    local specs = getSpectators(HYDRA_ROOM_CENTER, HYDRA_ROOM_RANGEX, HYDRA_ROOM_RANGEY)
    local players = {}
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) and isCreature(specs[i]) then
                table.insert(players, specs[i])
            end
        end
    end

    if #players > 0 then
        -- Quantos pulsos neste tick: 2 a 4
        local pulseCount = math.random(2, 4)

        for _ = 1, pulseCount do
            local usePoison    = math.random(1, 2) == 1
            local combatType   = usePoison and COMBAT_EARTHDAMAGE or COMBAT_ENERGYDAMAGE
            local effect       = usePoison and CONST_ME_POISONAREA or CONST_ME_ENERGYHIT

            local focusPlayer  = math.random(1, 100) <= PULSE_FOCUS_CHANCE
            local targetPos    = nil

            if focusPlayer then
                local p = players[math.random(1, #players)]
                if isCreature(p) then
                    local pp = getCreaturePosition(p)
                    if pp then
                        targetPos = {
                            x = pp.x + math.random(-2, 2),
                            y = pp.y + math.random(-2, 2),
                            z = pp.z
                        }
                    end
                end
            end

            if not targetPos then
                targetPos = {
                    x = math.random(HYDRA_ROOM_FROM.x + 1, HYDRA_ROOM_TO.x - 1),
                    y = math.random(HYDRA_ROOM_FROM.y + 1, HYDRA_ROOM_TO.y - 1),
                    z = HYDRA_ROOM_FROM.z
                }
            end

            local dmg = math.random(PULSE_MIN_DMG, PULSE_MAX_DMG)

            -- Usa o primeiro player como "atacante" para evitar cid=0
            local attackerCid = players[1]
            doSendMagicEffect(targetPos, effect)
            doAreaCombatHealth(attackerCid, combatType, targetPos, 0, dmg, dmg, effect)
        end
    end

    -- Agenda proximo pulso apenas se ainda ativo
    if hydraRoomState.active and not areAllHydrasDead() then
        hydraRoomState.pulseTimerId = addEvent(doHydraPulseDamage, PULSE_INTERVAL)
    end
end

-- ============================================================
-- HELPERS
-- ============================================================
local function isBossRoomOccupied()
    return hydraCountPlayersInRoom() > 0
end

local function isAnyHydraAlive()
    for _, boss in pairs(hydraRoomState.bosses) do
        if not boss.isDead and boss.cid and isCreature(boss.cid) then
            return true
        end
    end
    return false
end

local function getPlayersOnEntryTiles()
    local players = {}
    local seen = {}
    for i = 1, #HYDRA_ENTRY_TILES do
        local pos = HYDRA_ENTRY_TILES[i]
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

local function resetLeverItem()
    for i = 1, #HYDRA_ENTRY_TILES do
        local pos = HYDRA_ENTRY_TILES[i]
        local it  = getTileItemById(pos, HYDRA_LEVER_ON)
        if it and it.uid and it.uid > 0 then
            doTransformItem(it.uid, HYDRA_LEVER_OFF)
            return
        end
    end
end

local function teleportPlayersOut(timerId)
    -- Eu sou o timeoutTimerId: zerar antes de resetar, senao o
    -- hydraRoomStopTimers chama stopEvent no proprio evento em execucao e o
    -- executeTimer do C++ le' um no' apagado -> crash (ver hydraRoomLib.lua).
    hydraRoomState.timeoutTimerId = nil

    local specs = getSpectators(HYDRA_ROOM_CENTER, HYDRA_ROOM_RANGEX, HYDRA_ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                doTeleportThing(specs[i], HYDRA_EXIT_POS)
                doSendMagicEffect(HYDRA_EXIT_POS, CONST_ME_TELEPORT)
                doPlayerSendTextMessage(specs[i], MESSAGE_EVENT_ADVANCE,
                    "Tempo esgotado! Voces foram teleportados para fora da sala da Hydra.")
            end
        end
    end
    resetLeverItem()
    hydraRoomResetAll(timerId)
end

-- ============================================================
-- ALAVANCA
-- ============================================================
function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- Se a alavanca ja esta ativada
    if item.itemid == HYDRA_LEVER_ON then
        if not isBossRoomOccupied() and not isAnyHydraAlive() then
            hydraRoomResetAll()
            doTransformItem(item.uid, HYDRA_LEVER_OFF)
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "A alavanca foi resetada automaticamente.")
        else
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "A Hydra ja esta ativa ou uma equipe esta dentro da sala!")
        end
        return true
    end

    -- Sala ocupada?
    if isBossRoomOccupied() then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Ja existe uma equipe na sala da Hydra. Aguarde.")
        return true
    end

    -- Players nos entry tiles?
    local players = getPlayersOnEntryTiles()
    if #players == 0 then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Nenhum player nos tiles de entrada! Posicione-se nos 5 tiles primeiro.")
        return true
    end

    -- Verifica cooldown de cada player
    local currentTime = os.time()
    for i = 1, #players do
        local pid      = players[i]
        local cooldown = tonumber(getPlayerStorageValue(pid, HYDRA_LEVER_COOLDOWN_STORAGE)) or -1
        if cooldown > currentTime then
            local remaining = cooldown - currentTime
            local hours     = math.floor(remaining / 3600)
            local minutes   = math.floor((remaining % 3600) / 60)
            local timeMsg
            if hours > 0 then
                timeMsg = string.format("%dh %dmin", hours, minutes)
            else
                timeMsg = string.format("%d minuto(s)", math.max(1, minutes))
            end
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
                string.format("O jogador %s ainda possui cooldown (%s restantes) para entrar na sala da Hydra.",
                    getPlayerName(pid), timeMsg))
            return true
        end
    end

    -- Tudo ok: limpa e ativa sala
    hydraRoomResetAll()
    doTransformItem(item.uid, HYDRA_LEVER_ON)

    -- Aplica cooldown e teleporta cada player
    for i = 1, #players do
        local pid = players[i]
        setPlayerStorageValue(pid, HYDRA_LEVER_COOLDOWN_STORAGE, currentTime + HYDRA_LEVER_COOLDOWN_TIME)
        doTeleportThing(pid, HYDRA_TELEPORT_POS)
        doSendMagicEffect(HYDRA_TELEPORT_POS, CONST_ME_TELEPORT)
        doPlayerSendTextMessage(pid, MESSAGE_EVENT_ADVANCE,
            "Bem-vindo a sala da Hydra! Derrote as duas cabecas para vencer!")
    end

    -- Spawna as duas cabecas
    for key, boss in pairs(hydraRoomState.bosses) do
        boss.isDead = false
        boss.cid    = nil
        local bossCid = doCreateMonster(boss.name, boss.pos, false, false)
        if bossCid and bossCid > 0 then
            boss.cid = bossCid
            doSendMagicEffect(boss.pos, CONST_ME_MEEH)
        else
            print("[HydraRoom] Erro ao invocar: " .. key .. " (" .. boss.name .. ")")
        end
    end

    -- Inicia dano pulsante
    hydraRoomState.active       = true
    hydraRoomState.pulseTimerId = addEvent(doHydraPulseDamage, PULSE_INTERVAL)

    -- Timer de seguranca de 30 min: usa timeoutTimerId separado
    hydraRoomState.timeoutTimerId = addEvent(teleportPlayersOut, CLEANUP_DELAY)

    return true
end
