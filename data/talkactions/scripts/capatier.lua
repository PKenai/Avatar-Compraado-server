-- !capatier [tier]
-- Gera uma capa aleatoria com tier aleatorio (ou o tier especificado de 1 a 10)

local CAPES = {
    19158, 19159, 19160, 19161, 19162,
    19163, 19164, 19165, 19166, 19167,
}

local CAPE_NAMES = {
    [19158] = "Capa de viajante",
    [19159] = "Capa reforcada",
    [19160] = "Capa resistente",
    [19161] = "Capa aprimorada",
    [19162] = "Capa nobre",
    [19163] = "Capa de protecao",
    [19164] = "Capa majestosa",
    [19165] = "Capa gloriosa",
    [19166] = "Capa soberana",
    [19167] = "Capa das nacoes",
}

function onSay(cid, words, param, channel)
    -- Escolhe capa aleatoria
    local capeId = CAPES[math.random(#CAPES)]
    local capeName = CAPE_NAMES[capeId] or "Capa"

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
    local uid = doCreateItemEx(capeId, 1)
    if not uid then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Erro ao criar capa.")
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
    local ok, result = pcall(ItemType, capeId)
    if ok and result and not result:isNull() then
        local clientResult = result:getClientId()
        if clientResult and clientResult > 0 then clientId = clientResult end
    end
    if clientId == 0 then clientId = capeId end

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
        "[TIER] Voce recebeu " .. capeName .. " com Tier " .. tier .. "!"
    )
    doSendMagicEffect(getCreaturePosition(cid), 201)

    return true
end
