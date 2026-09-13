local CLEANUP_DELAY = 120 * 1000

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

local function teleportPlayersOut(timerId)
    -- Este callback E' o exitTimerId: zerar antes de resetar, senao o
    -- bossRoomStopTimers chama stopEvent no proprio evento em execucao e o
    -- executeTimer do C++ le' um no' ja' apagado -> access violation (crash).
    bossRoomState.exitTimerId = nil

    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                doTeleportThing(specs[i], EXIT_POS)
                doSendMagicEffect(EXIT_POS, CONST_ME_TELEPORT)
                doPlayerSendTextMessage(specs[i], MESSAGE_EVENT_ADVANCE,
                    "Tempo esgotado! Voces foram teleportados para fora da sala do boss.")
            end
        end
    end

    resetLever()
    bossRoomResetAll(timerId)
end

function onDeath(cid, corpse, deathList)
    if not isMonster(cid) then
        return true
    end

    local partKey = getBossKeyByCid(cid)
    local creatureName = getCreatureName(cid)

    if not partKey then
        if creatureName == "Swamp Man Head" then
            partKey = "head"
        elseif creatureName == "Swamp Man Arm" then
            if not bossRoomState.bosses.leftArm.isDead then
                partKey = "leftArm"
            else
                partKey = "rightArm"
            end
        elseif creatureName == "Swamp Monster" then
            partKey = "head"
        end
    end

    if not partKey or not bossRoomState.bosses[partKey] then
        return true
    end

    local dyingBoss = bossRoomState.bosses[partKey]
    dyingBoss.isDead = true
    dyingBoss.cid = nil

    if areAllBossesDead() then
        for _, b in pairs(bossRoomState.bosses) do
            if b.respawnTimer then
                stopEvent(b.respawnTimer)
                b.respawnTimer = nil
            end
        end

        bossRoomRemoveTentacles()

        if bossRoomState.healTimerId then
            stopEvent(bossRoomState.healTimerId)
            bossRoomState.healTimerId = nil
        end
        if bossRoomState.tentacleTimerId then
            stopEvent(bossRoomState.tentacleTimerId)
            bossRoomState.tentacleTimerId = nil
        end

        bossRoomSpawnChest()

        local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
        if specs and #specs > 0 then
            for i = 1, #specs do
                if isPlayer(specs[i]) then
                    doPlayerSendTextMessage(specs[i], MESSAGE_EVENT_ADVANCE,
                        "Parabens! O Homem do Pantano foi totalmente derrotado! O bau de recompensas apareceu. Voces tem 2 minutos para abrir o bau antes de serem teleportados!")
                end
            end
        end

        bossRoomState.exitTimerId = addEvent(teleportPlayersOut, CLEANUP_DELAY)

    else
        dyingBoss.respawnTimer = addEvent(respawnBossPart, SYNC_DEATH_WINDOW, partKey)

        local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
        if specs and #specs > 0 then
            for i = 1, #specs do
                if isPlayer(specs[i]) then
                    doPlayerSendTextMessage(specs[i], MESSAGE_STATUS_WARNING,
                        dyingBoss.label .. " do Homem do Pantano foi derrotado(a)! Mate os membros restantes em no maximo 5 segundos ou ele(a) se regenerara!")
                end
            end
        end
    end

    return true
end
