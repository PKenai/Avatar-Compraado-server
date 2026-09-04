function onUse(cid, item, fromPosition, itemEx, toPosition)
    if not isPlayer(cid) then
        return false
    end

    local currentTime = os.time()
    local nextAllowedUse = getPlayerStorageValue(cid, CHEST_COOLDOWN_STORAGE)

    if nextAllowedUse > currentTime then
        local remaining = nextAllowedUse - currentTime
        local minutes = math.ceil(remaining / 60)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
            string.format("Voce ja resgatou sua recompensa deste bau recentemente. Aguarde %d minuto(s) para poder abrir novamente.", minutes))
        return true
    end

    doPlayerAddItem(cid, REWARD_CRYSTAL_COIN, REWARD_CRYSTAL_COUNT)
    doPlayerAddItem(cid, REWARD_PLATINUM_COIN, REWARD_PLATINUM_COUNT)

    setPlayerStorageValue(cid, CHEST_COOLDOWN_STORAGE, currentTime + CHEST_COOLDOWN_TIME)

    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_GREEN)
    doSendMagicEffect(fromPosition, CONST_ME_TREASURE)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
        "Parabens! Voce recebeu 2 crystal coins e 50 platinum coins como recompensa por derrotar o Homem do Pantano!")

    return true
end
