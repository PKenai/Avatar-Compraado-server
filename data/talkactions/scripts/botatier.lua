-- !botatier [tier]
-- Gera uma bota aleatoria com tier aleatorio (ou o tier especificado de 1 a 10)

local BOOTS = {
    19191, 19192, 19193, 19194, 19195,
    19196, 19197, 19198, 19199, 19200,
}

local BOOT_NAMES = {
    [19191] = "Bota de viajante",
    [19192] = "Bota reforcada",
    [19193] = "Bota resistente",
    [19194] = "Bota aprimorada",
    [19195] = "Bota nobre",
    [19196] = "Bota de protecao",
    [19197] = "Bota majestosa",
    [19198] = "Bota gloriosa",
    [19199] = "Bota soberana",
    [19200] = "Bota das nacoes",
}

function onSay(cid, words, param, channel)
    -- Escolhe bota aleatoria
    local bootId = BOOTS[math.random(#BOOTS)]
    local bootName = BOOT_NAMES[bootId] or "Bota"

    -- Escolhe tier
    local tier = 0
    if param and param ~= "" then
        tier = tonumber(param) or 0
    end
    if tier <= 0 then
        tier = math.random(1, 10)
    end
    tier = math.min(tier, 10)

    -- Cria o item (retorna UID)
    local uid = doCreateItemEx(bootId, 1)
    if not uid then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Erro ao criar bota.")
        return true
    end

    -- Seta o tier no item via UID
    local ok1, err1 = pcall(doItemSetAttribute, uid, "tier", tier)
    if not ok1 then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE,
            "[TIER DEBUG] ERRO doItemSetAttribute: " .. tostring(err1))
    end

    -- Converte server itemId -> client spriteId
    local clientId = 0
    local ok, result = pcall(ItemType, bootId)
    if ok and result and not result:isNull() then
        local clientResult = result:getClientId()
        if clientResult and clientResult > 0 then clientId = clientResult end
    end
    if clientId == 0 then clientId = bootId end

    -- Da pro player PRIMEIRO (item ja existe no inventario)
    local ret = doPlayerAddItemEx(cid, uid, true)
    if ret ~= RETURNVALUE_NOERROR then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Inventario cheio.")
        return true
    end

    -- Envia pro client o opcode DEPOIS de adicionar o item
    -- Formato: set,<clientId>,<tier> (client mapeia tier -> shader name)
    doSendPlayerExtendedOpcode(cid, 111, "set," .. clientId .. "," .. tier)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
        "[TIER] Voce recebeu " .. bootName .. " com Tier " .. tier .. "!"
    )
    doSendMagicEffect(getCreaturePosition(cid), 200)

    return true
end
