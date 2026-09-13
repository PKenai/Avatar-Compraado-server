-- ============================================================
-- HYDRA ROOM - Silver Chest
-- ActionID: 50021 / ItemID: 28873
-- Recompensa: 20k gold por player (cooldown 5h)
-- ============================================================

dofile(getDataDir() .. "lib/hydraRoomLib.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if not isPlayer(cid) then return false end

    local currentTime    = os.time()
    local nextAllowedUse = tonumber(getPlayerStorageValue(cid, HYDRA_CHEST_COOLDOWN_STORAGE)) or -1

    if nextAllowedUse > currentTime then
        local remaining = nextAllowedUse - currentTime
        local hours     = math.floor(remaining / 3600)
        local minutes   = math.ceil((remaining % 3600) / 60)
        local timeMsg
        if hours > 0 then
            timeMsg = string.format("%dh %dmin", hours, minutes)
        else
            timeMsg = string.format("%d minuto(s)", math.max(1, minutes))
        end
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
            string.format("Voce ja resgatou sua recompensa recentemente. Aguarde %s.", timeMsg))
        return true
    end

    -- Entrega 20k: 200 platinum coins (100gp cada)
    doPlayerAddItem(cid, HYDRA_REWARD_PLAT_ITEM, HYDRA_REWARD_PLAT_COUNT)

    setPlayerStorageValue(cid, HYDRA_CHEST_COOLDOWN_STORAGE, currentTime + HYDRA_CHEST_COOLDOWN_TIME)

    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_GREEN)
    doSendMagicEffect(fromPosition, CONST_ME_TREASURE)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
        "Parabens! Voce recebeu 20.000 gold como recompensa por derrotar a Hydra!")

    return true
end
