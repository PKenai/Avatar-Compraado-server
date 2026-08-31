-- !capacetier [tier]
-- Gera um capacete aleatorio com tier aleatorio (ou o tier especificado de 1 a 10)

local HELMETS = {
    19180, 19181, 19182, 19183, 19184,
    19185, 19186, 19187, 19188, 19189,
}

local HELMET_NAMES = {
    [19180] = "Capacete de viajante",
    [19181] = "Capacete reforcado",
    [19182] = "Capacete resistente",
    [19183] = "Capacete aprimorado",
    [19184] = "Capacete nobre",
    [19185] = "Capacete de protecao",
    [19186] = "Capacete majestoso",
    [19187] = "Capacete glorioso",
    [19188] = "Capacete soberano",
    [19189] = "Capacete das nacoes",
}

function onSay(cid, words, param, channel)
    -- Escolhe capacete aleatorio
    local helmetId = HELMETS[math.random(#HELMETS)]
    local helmetName = HELMET_NAMES[helmetId] or "Capacete"

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
    local uid = doCreateItemEx(helmetId, 1)
    if not uid then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Erro ao criar capacete.")
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
    local ok, result = pcall(ItemType, helmetId)
    if ok and result and not result:isNull() then
        local clientResult = result:getClientId()
        if clientResult and clientResult > 0 then clientId = clientResult end
    end
    if clientId == 0 then clientId = helmetId end

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
        "[TIER] Voce recebeu " .. helmetName .. " com Tier " .. tier .. "!"
    )
    doSendMagicEffect(getCreaturePosition(cid), 200)

    return true
end
