-- ============================================================
-- CAMILA - NPC Costureira de Capas (Tier Upgrade)
-- Sistema de Tier de Capas com Costura e Linho
-- Tier fica no ITEM (doItemSetAttribute / getItemAttribute)
-- ============================================================

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local MAX_TIER = 10
local NUM_OPTIONS = 5
local TIER_OPCODE = 111
local LINHO_ITEM_ID = 19099

-- Semente inicial de aleatoriedade
math.randomseed(os.time() + (tonumber(tostring({}):sub(8)) or 0))
for i = 1, 5 do math.random() end

local function getRandomNumber(min, max)
    math.randomseed(os.time() + math.floor(os.clock() * 1000000) + (tonumber(tostring({}):sub(8)) or 0) + math.random(1, 10000))
    math.random()
    return math.random(min, max)
end

local function getRandomPercent()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000) + (tonumber(tostring({}):sub(8)) or 0) + math.random(1, 10000))
    math.random()
    return math.random(1, 10000) / 10000.0 -- 0.0001 a 1.0000
end

-- Tecnicas de ponto para costura
local STITCH_TECHNIQUES = {
    [1] = "Straight Stitch",
    [2] = "Cross Stitch",
    [3] = "Invisible Stitch",
    [4] = "Zig-Zag Stitch",
    [5] = "French Knot",
}

-- Fator de dificuldade por capa (da mais simples a mais valiosa)
local CAPE_DIFFICULTY_FACTOR = {
    [1] = 1.00, -- Capa de viajante (base mais acessivel)
    [2] = 0.95, -- Capa reforcada
    [3] = 0.90, -- Capa resistente
    [4] = 0.85, -- Capa aprimorada
    [5] = 0.80, -- Capa nobre
    [6] = 0.75, -- Capa de protecao
    [7] = 0.70, -- Capa majestosa
    [8] = 0.65, -- Capa gloriosa
    [9] = 0.60, -- Capa soberana
    [10] = 0.50, -- Capa das nacoes (mais desafiadora)
}

-- Chance base de sucesso por tier
local BASE_WIN_CHANCES = {
    [0] = 0.85,  -- T0 -> T1: 85%
    [1] = 0.80,  -- T1 -> T2: 80%
    [2] = 0.75,  -- T2 -> T3: 75%
    [3] = 0.68,  -- T3 -> T4: 68%
    [4] = 0.50,  -- T4 -> T5: 50%
    [5] = 0.20,  -- T5 -> T6: 20%
    [6] = 0.12,  -- T6 -> T7: 12%
    [7] = 0.06,  -- T7 -> T8:  6%
    [8] = 0.03,  -- T8 -> T9:  3%
    [9] = 0.015, -- T9 -> T10: 1.5%
}

local function getWinChance(capeIdx, currentTier)
    local base = BASE_WIN_CHANCES[currentTier] or 0.01
    local factor = CAPE_DIFFICULTY_FACTOR[capeIdx] or 1.0
    return math.max(0.002, base * factor)
end

-- Custo fixo para T5+ (em gold). Abaixo do T5 usa formula baseada no craftCost.
local FIXED_COSTS = {
    [5] = 500000,    -- T5 -> T6:  500k
    [6] = 1000000,   -- T6 -> T7:  1kk
    [7] = 2000000,   -- T7 -> T8:  2kk
    [8] = 3000000,   -- T8 -> T9:  3kk
    [9] = 4000000,   -- T9 -> T10: 4kk
}

-- Converte server itemId -> client spriteId
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

-- Storage pra dados da conversa
local CONVO_BASE = 49310
-- CONVO_BASE + 0 = estado da conversa
-- CONVO_BASE + 1 = itemId da capa escolhida
-- CONVO_BASE + 2 = tier atual
-- CONVO_BASE + 3 = custo em gold
-- CONVO_BASE + 4 = indice da capa na lista
-- CONVO_BASE + 5 = tecnica/ponto escolhido (1-5)
-- CONVO_BASE + 6 = quantidade de linho necessaria

-- Capas vendidas pelo Tadeu (com custo em gold e quantidade de linho)
local CAPES = {
    {itemId = 19158, name = "Traveler's Cape", alt = "capa de viajante", craftCost = 5000,    linho = 10},
    {itemId = 19159, name = "Reinforced Cape", alt = "capa reforcada",  craftCost = 15000,   linho = 20},
    {itemId = 19160, name = "Tough Cape",      alt = "capa resistente", craftCost = 35000,   linho = 35},
    {itemId = 19161, name = "Improved Cape",   alt = "capa aprimorada", craftCost = 70000,   linho = 55},
    {itemId = 19162, name = "Noble Cape",      alt = "capa nobre",      craftCost = 130000,  linho = 80},
    {itemId = 19163, name = "Protective Cape", alt = "capa de protecao", craftCost = 220000, linho = 110},
    {itemId = 19164, name = "Majestic Cape",   alt = "capa majestosa",  craftCost = 380000,  linho = 140},
    {itemId = 19165, name = "Glorious Cape",   alt = "capa gloriosa",   craftCost = 650000,  linho = 170},
    {itemId = 19166, name = "Sovereign Cape",  alt = "capa soberana",   craftCost = 1000000, linho = 200},
    {itemId = 19167, name = "Nations Cape",    alt = "capa das nacoes", craftCost = 1500000, linho = 250},
}

-- ============================================================
-- TIER DO ITEM
-- ============================================================

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

-- ============================================================
-- CUSTO E CHANCE
-- ============================================================

local function getGambleCost(craftCost, currentTier)
    if FIXED_COSTS[currentTier] then
        return FIXED_COSTS[currentTier]
    end
    local cost = craftCost * 2
    cost = cost + (currentTier * craftCost * 0.5)
    if cost >= 1000000 then
        cost = math.floor(cost / 100000) * 100000
    elseif cost >= 100000 then
        cost = math.floor(cost / 10000) * 10000
    elseif cost >= 10000 then
        cost = math.floor(cost / 1000) * 1000
    elseif cost >= 1000 then
        cost = math.floor(cost / 100) * 100
    else
        cost = math.floor(cost / 10) * 10
    end
    return cost
end

local function sanitizeText(str)
    if not str then return "" end
    local s = str:lower()
    s = s:gsub("ã", "a"):gsub("á", "a"):gsub("à", "a"):gsub("â", "a")
    s = s:gsub("é", "e"):gsub("ê", "e")
    s = s:gsub("í", "i")
    s = s:gsub("ó", "o"):gsub("õ", "o"):gsub("ô", "o")
    s = s:gsub("ú", "u")
    s = s:gsub("ç", "c")
    return s
end

local function findCapeByName(name)
    local cleanName = sanitizeText(name)
    for i, cape in ipairs(CAPES) do
        local cleanCape = sanitizeText(cape.name)
        local cleanAlt = sanitizeText(cape.alt or "")
        if cleanName == cleanCape or cleanName:find(cleanCape, 1, true) or cleanCape:find(cleanName, 1, true)
           or (cleanAlt ~= "" and (cleanName == cleanAlt or cleanName:find(cleanAlt, 1, true) or cleanAlt:find(cleanName, 1, true))) then
            return i, cape
        end
    end
    return nil, nil
end

local function parseStitchChoice(msg)
    local num = tonumber(msg)
    if num and num >= 1 and num <= 5 then
        return num
    end
    local m = msg:lower()
    if m:find("straight") or m:find("reto") then return 1 end
    if m:find("cross") or m:find("cruz") then return 2 end
    if m:find("invis") then return 3 end
    if m:find("zig") or m:find("zag") then return 4 end
    if m:find("french") or m:find("franc") or m:find("knot") then return 5 end
    return nil
end

-- ============================================================
-- CALLBACKS
-- ============================================================

function onCreatureAppear(cid)       npcHandler:onCreatureAppear(cid)     end
function onCreatureDisappear(cid)    npcHandler:onCreatureDisappear(cid)  end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink()                   npcHandler:onThink()                 end
function onPlayerEndTrade(cid)       npcHandler:onPlayerEndTrade(cid)     end
function onPlayerCloseChannel(cid)   npcHandler:onPlayerCloseChannel(cid) end

function onGreet(cid)
    talkState[cid] = 1
    for i = 0, 6 do
        setPlayerStorageValue(cid, CONVO_BASE + i, 0)
    end
    selfSay("Hello, " .. getCreatureName(cid) .. "! Your clothes could use some improvements, they are quite out of style. Want me to {sew} your cape?", cid)
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then return false end

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local msg = msg:lower()

    -- ============================================================
    -- ESTADO 1: Apresentacao / Explicacao
    -- ============================================================
    if talkState[talkUser] == 1 then

        if msgcontains(msg, "sew") or msgcontains(msg, "tailor") or msgcontains(msg, "costura") or msgcontains(msg, "costurar") or msgcontains(msg, "improve") or msgcontains(msg, "melhorar") or msgcontains(msg, "fashion") or msgcontains(msg, "moda") then
            local lista = "Capes accepted for tailoring (Cost in Gold and Linen):\n\n"
            for i, cape in ipairs(CAPES) do
                local count = getPlayerItemCount(cid, cape.itemId)
                local tierText = ""
                if count > 0 then
                    local item = getPlayerItemById(cid, true, cape.itemId)
                    if item and item.uid then
                        local tier = getItemTier(item.uid)
                        if tier > 0 then
                            tierText = " [Tier " .. tier .. "]"
                        end
                    end
                end
                local cost = getGambleCost(cape.craftCost, 0)
                lista = lista .. i .. ") " .. cape.name .. tierText .. " - " .. doNumberFormat(cost) .. " gold + " .. cape.linho .. "x linen\n"
            end
            lista = lista .. "\nRule: only 1 cape at a time. Type the name of the cape."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("Look, I'm a beginner tailor... I can try to stitch and upgrade the tier of your cape with {linen}, but since I'm still learning, if the stitching fails I might end up tearing your cape and you'll lose it! Which cape do you want me to sew?", cid)
            talkState[talkUser] = 2

        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") or msgcontains(msg, "hello") then
            selfSay("Your outfit could use some improvements, it's quite out of style! Say {sew} if you want to enhance your cape.", cid)

        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") or msgcontains(msg, "farewell") then
            selfSay("Bye-bye! Come back when you want to look stylish.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    -- ============================================================
    -- ESTADO 2: Escolha da capa (pelo nome)
    -- ============================================================
    elseif talkState[talkUser] == 2 then

        local idx, cape = findCapeByName(msg)

        if not cape then
            selfSay("I do not recognize that cape. Please type the correct name.", cid)
            return true
        end

        -- Verifica se tem a capa
        local count = getPlayerItemCount(cid, cape.itemId)
        if count <= 0 then
            selfSay("You do not have " .. cape.name .. " in your inventory.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Verifica se tem mais de 1
        if count > 1 then
            selfSay("You have " .. count .. " " .. cape.name .. ". I only accept one at a time so I do not get confused.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Pega o tier DIRETO DO ITEM
        local capeItem = getPlayerItemById(cid, true, cape.itemId)
        if not capeItem or not capeItem.uid then
            selfSay("Error finding the cape.", cid)
            talkState[talkUser] = 1
            return true
        end

        local currentTier = getItemTier(capeItem.uid)

        if currentTier >= MAX_TIER then
            selfSay("This cape is already at the maximum tier of elegance!", cid)
            talkState[talkUser] = 1
            return true
        end

        local cost = getGambleCost(cape.craftCost, currentTier)
        local nextTier = currentTier + 1
        local linhoReq = cape.linho

        -- Salva dados da conversa
        setPlayerStorageValue(cid, CONVO_BASE, 1)
        setPlayerStorageValue(cid, CONVO_BASE + 1, cape.itemId)
        setPlayerStorageValue(cid, CONVO_BASE + 2, currentTier)
        setPlayerStorageValue(cid, CONVO_BASE + 3, cost)
        setPlayerStorageValue(cid, CONVO_BASE + 4, idx)
        setPlayerStorageValue(cid, CONVO_BASE + 6, linhoReq)

        selfSay(cape.name .. " (Tier " .. currentTier .. " -> " .. nextTier .. ") requires " .. doNumberFormat(cost) .. " gold and " .. linhoReq .. "x linen.", cid)
        addEvent(function()
            if isPlayer(cid) then
                selfSay("Which stitch technique should I use? {1} - Straight Stitch, {2} - Cross Stitch, {3} - Invisible Stitch, {4} - Zig-Zag Stitch or {5} - French Knot?", cid)
            end
        end, 1500)
        talkState[talkUser] = 3

    -- ============================================================
    -- ESTADO 3: Escolha do Ponto / Tecnica
    -- ============================================================
    elseif talkState[talkUser] == 3 then

        local chosenChoice = parseStitchChoice(msg)
        if not chosenChoice then
            selfSay("Choose a stitch from 1 to 5: {Straight Stitch}, {Cross Stitch}, {Invisible Stitch}, {Zig-Zag Stitch} or {French Knot}.", cid)
            return true
        end

        local stitchName = STITCH_TECHNIQUES[chosenChoice]
        setPlayerStorageValue(cid, CONVO_BASE + 5, chosenChoice)

        local linhoReq = getPlayerStorageValue(cid, CONVO_BASE + 6)
        local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)

        selfSay("You chose to use the {" .. stitchName .. "}. The service will cost " .. doNumberFormat(cost) .. " gold and " .. linhoReq .. "x linen. Remember that if the stitch fails, the cape will tear! Confirm? {yes} or {no}", cid)
        talkState[talkUser] = 4

    -- ============================================================
    -- ESTADO 4: Confirmacao
    -- ============================================================
    elseif talkState[talkUser] == 4 then

        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)
            local itemId = getPlayerStorageValue(cid, CONVO_BASE + 1)
            local idx = getPlayerStorageValue(cid, CONVO_BASE + 4)
            local chosenNumber = getPlayerStorageValue(cid, CONVO_BASE + 5)
            local linhoReq = getPlayerStorageValue(cid, CONVO_BASE + 6)
            local cape = CAPES[idx]

            -- Verifica gold
            if getPlayerMoney(cid) < cost then
                selfSay("You need " .. doNumberFormat(cost) .. " gold for the tailoring.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Verifica Linho
            local playerLinho = getPlayerItemCount(cid, LINHO_ITEM_ID)
            if playerLinho < linhoReq then
                selfSay("You need " .. linhoReq .. "x linen for this cape (you only have " .. playerLinho .. ").", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Verifica se ainda tem a capa (1 unica)
            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then
                selfSay("You no longer have the cape in your inventory!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end
            if count > 1 then
                selfSay("You have more than one cape. Store the others and keep only one.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Pega o item e le o tier DIRETO DELE
            local capeItem = getPlayerItemById(cid, true, itemId)
            if not capeItem or not capeItem.uid then
                selfSay("Error finding the cape.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local realTier = getItemTier(capeItem.uid)

            -- Cobra gold e Linho
            doPlayerRemoveMoney(cid, cost)
            doPlayerRemoveItem(cid, LINHO_ITEM_ID, linhoReq)

            -- ============================================================
            -- CALCULA CHANCE (escalonada por capa e tier)
            -- ============================================================
            local winChance = getWinChance(idx, realTier)
            local roll = getRandomPercent()
            local won = false
            local secretNumber

            if roll <= winChance then
                won = true
                secretNumber = chosenNumber
            else
                local otherOptions = {}
                for i = 1, NUM_OPTIONS do
                    if i ~= chosenNumber then
                        table.insert(otherOptions, i)
                    end
                end
                secretNumber = otherOptions[getRandomNumber(1, #otherOptions)]
            end

            if won then
                -- ACERTOU - seta tier NO ITEM
                local newTier = math.min(realTier + 1, MAX_TIER)
                setItemTier(capeItem.uid, newTier)

                -- Envia pro client (usa clientId, nao server itemId)
                local clientId = toClientId(capeItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "set," .. clientId .. "," .. newTier)

                doSendMagicEffect(getCreaturePosition(cid), 200)
                selfSay("Perfect! The " .. STITCH_TECHNIQUES[chosenNumber] .. " settled into the fabric flawlessly! Your " .. cape.name .. " is now Tier " .. newTier .. "!", cid)
            else
                -- ERROU - rasgou a capa (remove item)
                doRemoveItem(capeItem.uid, 1)

                -- Envia pro client (usa clientId, nao server itemId)
                local clientId = toClientId(capeItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)

                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("Oh no! The correct stitch for this fabric was the " .. STITCH_TECHNIQUES[secretNumber] .. ", and the " .. STITCH_TECHNIQUES[chosenNumber] .. " ended up tearing your " .. cape.name .. "... Sorry for the loss!", cid)
            end

            -- Limpa conversa
            talkState[talkUser] = 1
            for i = 0, 6 do
                setPlayerStorageValue(cid, CONVO_BASE + i, 0)
            end

        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            selfSay("Changed your mind? Alright, better keep your linen if you do not feel like risking it.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end

    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
