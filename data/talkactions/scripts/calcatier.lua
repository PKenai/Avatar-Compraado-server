-- !calcatier [tier]
-- Gera uma calca aleatoria com tier aleatorio (ou o tier especificado de 1 a 10)

local PANTS = {
    19169, 19170, 19171, 19172, 19173,
    19174, 19175, 19176, 19177, 19178,
}

local PANT_NAMES = {
    [19169] = "Calca de viajante",
    [19170] = "Calca reforcada",
    [19171] = "Calca resistente",
    [19172] = "Calca aprimorada",
    [19173] = "Calca nobre",
    [19174] = "Calca de protecao",
    [19175] = "Calca majestosa",
    [19176] = "Calca gloriosa",
    [19177] = "Calca soberana",
    [19178] = "Calca das nacoes",
}

function onSay(cid, words, param, channel)
    -- Escolhe calca aleatoria
    local pantId = PANTS[math.random(#PANTS)]
    local pantName = PANT_NAMES[pantId] or "Calca"

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
    local uid = doCreateItemEx(pantId, 1)
    if not uid then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Erro ao criar calca.")
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
    local ok, result = pcall(ItemType, pantId)
    if ok and result and not result:isNull() then
        local clientResult = result:getClientId()
        if clientResult and clientResult > 0 then clientId = clientResult end
    end
    if clientId == 0 then clientId = pantId end

    -- Da pro player PRIMEIRO (item ja existe no inventario)
    local ret = doPlayerAddItemEx(cid, uid, true)
    if ret ~= RETURNVALUE_NOERROR then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Inventario cheio.")
        return true
    end

    -- Envia pro client o opcode DEPOIS de adicionar o item
    doSendPlayerExtendedOpcode(cid, 111, "set," .. clientId .. "," .. tier)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
        "[TIER] Voce recebeu " .. pantName .. " com Tier " .. tier .. "!"
    )
    doSendMagicEffect(getCreaturePosition(cid), 200)

    return true
end
