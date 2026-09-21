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
    [19098] = "Simple Glove",
    [19100] = "Sticky Glove",
    [19102] = "Funeral Glove",
    [19104] = "Red Pincer Glove",
    [19106] = "Ladybug Glove",
    [19108] = "Beast Gloves",
    [19110] = "Woven Gloves",
    [19112] = "Queen's Gloves",
    [19114] = "Web Gloves",
    [19116] = "Mud Gloves",
    [19118] = "Gleaming Gloves",
    [19120] = "Royal Gloves",
    [19122] = "Metallic Gloves",
    [19124] = "Slimy Gloves",
    [19126] = "Grey Leather Gloves",
    [19128] = "Earth Gloves",
    [19130] = "Nature Gloves",
    [19132] = "Butcher Gloves",
    [19134] = "Tough Gloves",
    [19136] = "Rebellion Gloves",
    [19140] = "Courage Gloves",
    [19138] = "Marine Gloves",
    [19142] = "Hermit's Gloves",
    [19144] = "Knowledge Gloves",
    [19146] = "Dark Fold Gloves",
    [19148] = "Desert Gloves",
    [19150] = "Boulder Gloves",
    [19152] = "Lost Knowledge Gloves",
}

function onSay(cid, words, param, channel)
    -- Escolhe luva aleatoria
    local gloveId = GLOVES[math.random(#GLOVES)]
    local gloveName = GLOVE_NAMES[gloveId] or "Glove"

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
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Failed to create item.")
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
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Inventory full.")
        return true
    end

    -- Envia pro client o opcode DEPOIS de adicionar o item
    -- Formato: set,<clientId>,<tier> (client mapeia tier -> shader name)
    doSendPlayerExtendedOpcode(cid, 111, "set," .. clientId .. "," .. tier)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
        "[TIER] You received " .. gloveName .. " with Tier " .. tier .. "!"
    )
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    return true
end
