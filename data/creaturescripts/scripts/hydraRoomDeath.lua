-- ============================================================
-- HYDRA ROOM - Morte das Cabecas
-- Evento: HydraRoomDeath (type=death)
-- ============================================================

dofile(getDataDir() .. "lib/hydraRoomLib.lua")

local CLEANUP_DELAY = 120 * 1000   -- 2 minutos para sair apos vitoria

local function teleportPlayersOut(timerId)
    -- Eu sou o exitTimerId: zerar antes de resetar, senao o hydraRoomStopTimers
    -- para o proprio evento em execucao e o executeTimer do C++ le' um no' ja'
    -- apagado -> access violation (ver hydraRoomLib.lua).
    hydraRoomState.exitTimerId = nil

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
    -- Reseta alavanca
    for i = 1, #HYDRA_ENTRY_TILES do
        local pos = HYDRA_ENTRY_TILES[i]
        local it = getTileItemById(pos, HYDRA_LEVER_ON)
        if it and it.uid and it.uid > 0 then
            doTransformItem(it.uid, HYDRA_LEVER_OFF)
            break
        end
    end
    hydraRoomResetAll(timerId)
end

function onDeath(cid, corpse, deathList)
    if not isMonster(cid) then return true end

    local partKey = getHydraKeyByCid(cid)
    local name    = getCreatureName(cid)

    -- Fallback por nome caso o cid nao esteja mais no estado
    if not partKey then
        if name == "Green Hydra Head" then
            partKey = "green"
        elseif name == "Blue Hydra Head" then
            partKey = "blue"
        end
    end

    if not partKey or not hydraRoomState.bosses[partKey] then
        return true
    end

    local dyingBoss    = hydraRoomState.bosses[partKey]
    dyingBoss.isDead   = true
    dyingBoss.cid      = nil

    -- Cria item de morte no lugar da cabeca
    local deathItem = dyingBoss.deathItem
    local deathPos  = dyingBoss.deathPos
    if deathItem and deathPos then
        -- Remove item antigo se existir
        local oldItem = getTileItemById(deathPos, deathItem)
        if oldItem and oldItem.uid and oldItem.uid > 0 then
            doRemoveItem(oldItem.uid)
        end
        doCreateItem(deathItem, 1, deathPos)
        doSendMagicEffect(deathPos, CONST_ME_EXPLOSIONAREA)
    end

    -- Notifica players na sala
    local specs = getSpectators(HYDRA_ROOM_CENTER, HYDRA_ROOM_RANGEX, HYDRA_ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                if areAllHydrasDead() then
                    doPlayerSendTextMessage(specs[i], MESSAGE_EVENT_ADVANCE,
                        "Parabens! Ambas as cabecas da Hydra foram destruidas! O Silver Chest apareceu. Voces tem 2 minutos!")
                else
                    local otherName = (partKey == "green") and "Blue Hydra Head" or "Green Hydra Head"
                    doPlayerSendTextMessage(specs[i], MESSAGE_STATUS_WARNING,
                        "A " .. name .. " foi destruida! Derrote a " .. otherName .. " para vencer!")
                end
            end
        end
    end

    if areAllHydrasDead() then
        -- Para pulso e timer de seguranca
        if hydraRoomState.pulseTimerId then
            stopEvent(hydraRoomState.pulseTimerId)
            hydraRoomState.pulseTimerId = nil
        end
        if hydraRoomState.exitTimerId then
            stopEvent(hydraRoomState.exitTimerId)
            hydraRoomState.exitTimerId = nil
        end
        hydraRoomState.active = false

        -- Spawna bau
        hydraRoomSpawnChest()

        -- Timer de 2min para teleportar para fora
        hydraRoomState.exitTimerId = addEvent(teleportPlayersOut, CLEANUP_DELAY)
    end

    return true
end
