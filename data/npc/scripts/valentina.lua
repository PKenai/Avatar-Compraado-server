-- ============================================================
-- VALENTINA - NPC Encantadora de Capacetes (Tier Upgrade)
-- Pergunta qual lua aparecera. Acerta = tier sobe.
-- Erra = capacete estilhaça.
-- ============================================================

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local MAX_TIER = 10
local TIER_OPCODE = 111

math.randomseed(os.time() + (tonumber(tostring({}):sub(8)) or 0))
for i = 1, 5 do math.random() end

local function getRandomPercent()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000) + (tonumber(tostring({}):sub(8)) or 0) + math.random(1, 10000))
    math.random()
    return math.random(1, 10000) / 10000.0
end

local MOON_NAMES = {
    [1] = "Lua Nova",
    [2] = "Lua Crescente",
    [3] = "Lua Cheia",
    [4] = "Lua Minguante",
    [5] = "Lua Oculta",
}

local BASE_WIN_CHANCES = {
    [0] = 0.85, [1] = 0.80, [2] = 0.75, [3] = 0.68, [4] = 0.50,
    [5] = 0.20, [6] = 0.12, [7] = 0.06, [8] = 0.03, [9] = 0.015,
}

local HELMET_DIFFICULTY = {
    [1] = 1.00, [2] = 0.95, [3] = 0.90, [4] = 0.85, [5] = 0.80,
    [6] = 0.75, [7] = 0.70, [8] = 0.65, [9] = 0.60, [10] = 0.50,
}

local FIXED_COSTS = {
    [5] = 500000, [6] = 1000000, [7] = 2000000, [8] = 3000000, [9] = 4000000,
}

local HELMETS = {
    {itemId = 19180, name = "capacete de viajante",  craftCost = 3500},
    {itemId = 19181, name = "capacete reforcado",   craftCost = 10000},
    {itemId = 19182, name = "capacete resistente",  craftCost = 25000},
    {itemId = 19183, name = "capacete aprimorado",  craftCost = 50000},
    {itemId = 19184, name = "capacete nobre",       craftCost = 95000},
    {itemId = 19185, name = "capacete de protecao", craftCost = 165000},
    {itemId = 19186, name = "capacete majestoso",   craftCost = 280000},
    {itemId = 19187, name = "capacete glorioso",    craftCost = 475000},
    {itemId = 19188, name = "capacete soberano",    craftCost = 750000},
    {itemId = 19189, name = "capacete das nacoes",  craftCost = 1100000},
}

local CONVO_BASE = 49350

local function toClientId(serverId)
    if serverId and serverId > 0 then
        local ok, result = pcall(ItemType, serverId)
        if ok and result and not result:isNull() then
            local cid = result:getClientId()
            if cid and cid > 0 then return cid end
        end
    end
    return serverId or 0
end

local function getItemTier(uid)
    local tier = getItemAttribute(uid, "tier")
    if tier == nil or tier == "" then return 0 end
    tier = tonumber(tier) or 0
    if tier > MAX_TIER then return 0 end
    return tier
end

local function setItemTier(uid, tier)
    tier = math.min(math.max(tier, 0), MAX_TIER)
    doItemSetAttribute(uid, "tier", tier)
end

local function getGambleCost(craftCost, currentTier)
    if FIXED_COSTS[currentTier] then return FIXED_COSTS[currentTier] end
    local cost = craftCost * 2 + (currentTier * craftCost * 0.5)
    if cost >= 1000000 then cost = math.floor(cost / 100000) * 100000
    elseif cost >= 100000 then cost = math.floor(cost / 10000) * 10000
    elseif cost >= 10000 then cost = math.floor(cost / 1000) * 1000
    elseif cost >= 1000 then cost = math.floor(cost / 100) * 100
    else cost = math.floor(cost / 10) * 10 end
    return cost
end

local function getWinChance(idx, tier)
    local base = BASE_WIN_CHANCES[tier] or 0.01
    local factor = HELMET_DIFFICULTY[idx] or 1.0
    return math.max(0.002, base * factor)
end

local function sanitizeText(str)
    if not str then return "" end
    local s = str:lower()
    s = s:gsub("ã", "a"):gsub("á", "a"):gsub("à", "a"):gsub("â", "a")
    s = s:gsub("é", "e"):gsub("ê", "e"):gsub("í", "i")
    s = s:gsub("ó", "o"):gsub("õ", "o"):gsub("ô", "o"):gsub("ú", "u"):gsub("ç", "c")
    return s
end

local function findHelmetByName(name)
    local cleanName = sanitizeText(name)
    for i, h in ipairs(HELMETS) do
        local cleanH = sanitizeText(h.name)
        if cleanName == cleanH or cleanName:find(cleanH, 1, true) or cleanH:find(cleanName, 1, true) then
            return i, h
        end
    end
    return nil, nil
end

function onCreatureAppear(cid)       npcHandler:onCreatureAppear(cid)     end
function onCreatureDisappear(cid)    npcHandler:onCreatureDisappear(cid)  end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink()                   npcHandler:onThink()                 end
function onPlayerEndTrade(cid)       npcHandler:onPlayerEndTrade(cid)     end
function onPlayerCloseChannel(cid)   npcHandler:onPlayerCloseChannel(cid) end

function onGreet(cid)
    talkState[cid] = 1
    for i = 0, 5 do setPlayerStorageValue(cid, CONVO_BASE + i, 0) end
    selfSay("Saudacoes... Meu nome e Valentina. Eu canalizo a energia da lua nos capacetes. Quer que eu tente {encantar} o seu?", cid)
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then return false end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    if not talkState[talkUser] or talkState[talkUser] <= 0 then talkState[talkUser] = 1 end
    local msg = msg:lower()

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "encantar") or msgcontains(msg, "melhorar") then
            local lista = "Capacetes que aceito encantar:\n\n"
            for i, h in ipairs(HELMETS) do
                local count = getPlayerItemCount(cid, h.itemId)
                local tierText = ""
                if count > 0 then
                    local item = getPlayerItemById(cid, true, h.itemId)
                    if item and item.uid then
                        local tier = getItemTier(item.uid)
                        if tier > 0 then tierText = " [Tier " .. tier .. "]" end
                    end
                end
                lista = lista .. i .. ") " .. h.name .. tierText .. " - " .. doNumberFormat(getGambleCost(h.craftCost, 0)) .. " gold\n"
            end
            lista = lista .. "\nSo encanto 1 por vez. Escolha pelo nome."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("Lembre-se: se a energia for canalizada com a fase errada da lua, o capacete pode se quebrar. Qual capacete voce quer encantar?", cid)
            talkState[talkUser] = 2
        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") then
            selfSay("Diga {encantar} se quiser encantar seu capacete.", cid)
        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") then
            selfSay("Que a lua guie seus passos.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    elseif talkState[talkUser] == 2 then
        local idx, helmet = findHelmetByName(msg)
        if not helmet then selfSay("Nao conheco esse capacete.", cid); return true end
        local count = getPlayerItemCount(cid, helmet.itemId)
        if count <= 0 then selfSay("Voce nao tem " .. helmet.name .. ".", cid); talkState[talkUser] = 1; return true end
        if count > 1 then selfSay("So aceito uma por vez.", cid); talkState[talkUser] = 1; return true end
        local item = getPlayerItemById(cid, true, helmet.itemId)
        if not item or not item.uid then selfSay("Erro.", cid); talkState[talkUser] = 1; return true end
        local tier = getItemTier(item.uid)
        if tier >= MAX_TIER then selfSay("Ja esta no maximo!", cid); talkState[talkUser] = 1; return true end
        local cost = getGambleCost(helmet.craftCost, tier)
        setPlayerStorageValue(cid, CONVO_BASE, 1)
        setPlayerStorageValue(cid, CONVO_BASE + 1, helmet.itemId)
        setPlayerStorageValue(cid, CONVO_BASE + 2, tier)
        setPlayerStorageValue(cid, CONVO_BASE + 3, cost)
        setPlayerStorageValue(cid, CONVO_BASE + 4, idx)
        selfSay(helmet.name .. " (Tier " .. tier .. " -> " .. (tier+1) .. ") custa " .. doNumberFormat(cost) .. " gold.", cid)
        addEvent(function()
            if isPlayer(cid) then
                selfSay("Qual lua aparecera hoje? {1} Lua Nova, {2} Crescente, {3} Cheia, {4} Minguante ou {5} Oculta?", cid)
            end
        end, 1500)
        talkState[talkUser] = 3

    elseif talkState[talkUser] == 3 then
        local choice = tonumber(msg)
        if not choice or choice < 1 or choice > 5 then
            selfSay("Escolha de 1 a 5.", cid)
            return true
        end
        setPlayerStorageValue(cid, CONVO_BASE + 5, choice)
        selfSay("Voce escolheu " .. MOON_NAMES[choice] .. ". Confirma? {sim} ou {nao}", cid)
        talkState[talkUser] = 4

    elseif talkState[talkUser] == 4 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)
            local itemId = getPlayerStorageValue(cid, CONVO_BASE + 1)
            local idx = getPlayerStorageValue(cid, CONVO_BASE + 4)
            local choice = getPlayerStorageValue(cid, CONVO_BASE + 5)
            local helmet = HELMETS[idx]
            if getPlayerMoney(cid) < cost then selfSay("Precisa de " .. doNumberFormat(cost) .. " gold.", cid); talkState[talkUser] = 1; setPlayerStorageValue(cid, CONVO_BASE, 0); return true end
            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then selfSay("Voce nao tem mais o capacete!", cid); talkState[talkUser] = 1; setPlayerStorageValue(cid, CONVO_BASE, 0); return true end
            local item = getPlayerItemById(cid, true, itemId)
            if not item or not item.uid then selfSay("Erro.", cid); talkState[talkUser] = 1; setPlayerStorageValue(cid, CONVO_BASE, 0); return true end
            local realTier = getItemTier(item.uid)
            doPlayerRemoveMoney(cid, cost)
            local winChance = getWinChance(idx, realTier)
            local roll = getRandomPercent()
            if roll <= winChance then
                local newTier = math.min(realTier + 1, MAX_TIER)
                setItemTier(item.uid, newTier)
                local clientId = toClientId(item.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "set," .. clientId .. "," .. newTier)
                doSendMagicEffect(getCreaturePosition(cid), 200)
                selfSay("A lua " .. MOON_NAMES[choice] .. " brilhou! " .. helmet.name .. " agora e Tier " .. newTier .. "!", cid)
            else
                doRemoveItem(item.uid, 1)
                local clientId = toClientId(item.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)
                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("A " .. MOON_NAMES[choice] .. " nao era a certa... O capacete estilhaçou.", cid)
            end
            talkState[talkUser] = 1
            for i = 0, 5 do setPlayerStorageValue(cid, CONVO_BASE + i, 0) end
        elseif msgcontains(msg, "nao") or msgcontains(msg, "no") then
            selfSay("Volte quando estiver pronto.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
