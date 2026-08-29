-- !luvatier [tier]
-- Gera uma luva aleatoria com tier aleatorio
-- Debug: imprime tudo no console do player

local GLOVES = {
    19098, 19100, 19102, 19104, 19106,
    19108, 19110, 19112, 19114, 19116,
    19118, 19120, 19122, 19124, 19126,
    19128, 19130, 19132, 19134, 19136,
    19140, 19138, 19142, 19144, 19146,
    19148, 19150, 19152,
}

local GLOVE_NAMES = {
    [19098] = "Luva simples",
    [19100] = "Luva pegajosa",
    [19102] = "Luva funebre",
    [19104] = "Luva pinca vermelha",
    [19106] = "Luva de joaninha",
    [19108] = "Luvas da fera",
    [19110] = "Luvas tecidas",
    [19112] = "Luvas da rainha",
    [19114] = "Luvas de teia",
    [19116] = "Luvas de barro",
    [19118] = "Luvas reluzentes",
    [19120] = "Luvas reais",
    [19122] = "Luvas metalicas",
    [19124] = "Luvas gosmentas",
    [19126] = "Luvas de couro cinza",
    [19128] = "Luvas da terra",
    [19130] = "Luvas da natureza",
    [19132] = "Luvas carniceiras",
    [19134] = "Luvas cascudas",
    [19136] = "Luvas da rebeliao",
    [19140] = "Luvas da coragem",
    [19138] = "Luvas marinhas",
    [19142] = "Luvas do hermitao",
    [19144] = "Luvas do conhecimento",
    [19146] = "Luvas da dobra obscura",
    [19148] = "Luvas deserticas",
    [19150] = "Luvas de pedregulho",
    [19152] = "Luvas do conhecimento perdido",
}

function onSay(cid, words, param, channel)
    -- Escolhe luva aleatoria
    local gloveId = GLOVES[math.random(#GLOVES)]
    local gloveName = GLOVE_NAMES[gloveId] or "Luva"

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
    local uid = doCreateItemEx(gloveId, 1)
    if not uid then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Erro ao criar item.")
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
    local ok, result = pcall(ItemType, gloveId)
    if ok and result and not result:isNull() then
        local cid = result:getClientId()
        if cid and cid > 0 then clientId = cid end
    end
    if clientId == 0 then clientId = gloveId end

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
        "[TIER] Voce recebeu " .. gloveName .. " com Tier " .. tier .. "!"
    )
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    return true
end
