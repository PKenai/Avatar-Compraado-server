-- ============================================================
-- GAN Bler - NPC Apostador de Tier
-- Copiado do sistema do Canary (opentibiabr/canary)
-- Tier fica no ITEM (doItemSetAttribute / getItemAttribute)
-- Nao em player storage.
-- ============================================================

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local MAX_TIER = 10
local NUM_OPTIONS = 5
local TIER_OPCODE = 111

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

-- Chance de GANHAR por tier atual (fixa, independente da luva)
local WIN_CHANCES = {
    [0] = 0.80,  -- T0 -> T1: 80%
    [1] = 0.75,  -- T1 -> T2: 75%
    [2] = 0.70,  -- T2 -> T3: 70%
    [3] = 0.65,  -- T3 -> T4: 65%
    [4] = 0.50,  -- T4 -> T5: 50%
    [5] = 0.15,  -- T5 -> T6: 15%
    [6] = 0.10,  -- T6 -> T7: 10%
    [7] = 0.05,  -- T7 -> T8:  5%
    [8] = 0.02,  -- T8 -> T9:  2%
    [9] = 0.01,  -- T9 -> T10: 1%
}

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

-- Storage pra dados da conversa (nao confundir com tier do item)
local CONVO_BASE = 49300
-- CONVO_BASE + 0 = estado da conversa
-- CONVO_BASE + 1 = itemId da luva escolhida
-- CONVO_BASE + 2 = tier atual
-- CONVO_BASE + 3 = custo
-- CONVO_BASE + 4 = indice da luva na lista
-- CONVO_BASE + 5 = numero escolhido (1-5)

-- Luvas da forja do Vincente
local GLOVES = {
    {itemId = 19098, name = "Simple Gloves",           alt = "luva simples",            craftCost = 100},
    {itemId = 19100, name = "Sticky Gloves",           alt = "luva pegajosa",           craftCost = 150},
    {itemId = 19102, name = "Funeral Gloves",          alt = "luva funebre",            craftCost = 200},
    {itemId = 19104, name = "Red Claw Gloves",         alt = "luva pinca vermelha",     craftCost = 300},
    {itemId = 19106, name = "Ladybug Gloves",          alt = "luva de joaninha",        craftCost = 400},
    {itemId = 19108, name = "Beast Gloves",            alt = "luvas da fera",           craftCost = 550},
    {itemId = 19110, name = "Woven Gloves",            alt = "luvas tecidas",           craftCost = 750},
    {itemId = 19112, name = "Queen's Gloves",          alt = "luvas da rainha",         craftCost = 1000},
    {itemId = 19114, name = "Web Gloves",              alt = "luvas de teia",           craftCost = 1500},
    {itemId = 19116, name = "Mud Gloves",              alt = "luvas de barro",          craftCost = 2000},
    {itemId = 19118, name = "Shining Gloves",          alt = "luvas reluzentes",        craftCost = 3000},
    {itemId = 19120, name = "Royal Gloves",            alt = "luvas reais",             craftCost = 4500},
    {itemId = 19122, name = "Metallic Gloves",         alt = "luvas metalicas",         craftCost = 6000},
    {itemId = 19124, name = "Slimy Gloves",            alt = "luvas gosmentas",         craftCost = 8500},
    {itemId = 19126, name = "Gray Leather Gloves",     alt = "luvas de couro cinza",    craftCost = 12000},
    {itemId = 19128, name = "Earth Gloves",            alt = "luvas da terra",          craftCost = 17000},
    {itemId = 19130, name = "Nature Gloves",           alt = "luvas da natureza",       craftCost = 24000},
    {itemId = 19132, name = "Butcher Gloves",          alt = "luvas carniceiras",       craftCost = 33000},
    {itemId = 19134, name = "Crusty Gloves",           alt = "luvas cascudas",          craftCost = 47000},
    {itemId = 19136, name = "Rebellion Gloves",        alt = "luvas da rebeliao",       craftCost = 66000},
    {itemId = 19140, name = "Courage Gloves",          alt = "luvas da coragem",        craftCost = 93000},
    {itemId = 19138, name = "Marine Gloves",           alt = "luvas marinhas",          craftCost = 130000},
    {itemId = 19142, name = "Hermit's Gloves",         alt = "luvas do hermitao",       craftCost = 184000},
    {itemId = 19144, name = "Knowledge Gloves",        alt = "luvas do conhecimento",   craftCost = 258000},
    {itemId = 19146, name = "Dark Bending Gloves",     alt = "luvas da dobra obscura",  craftCost = 363000},
    {itemId = 19148, name = "Desert Gloves",           alt = "luvas deserticas",        craftCost = 511000},
    {itemId = 19150, name = "Pebble Gloves",           alt = "luvas de pedregulho",     craftCost = 718000},
    {itemId = 19152, name = "Lost Knowledge Gloves",   alt = "luvas do conhecimento perdido", craftCost = 1000000},
}

-- ============================================================
-- TIER DO ITEM (copiado do Canary item.cpp)
-- ============================================================

-- Le o tier do item (igual Item::getTier() do Canary)
local function getItemTier(uid)
    local tier = getItemAttribute(uid, "tier")
    if tier == nil or tier == "" then return 0 end
    tier = tonumber(tier) or 0
    if tier > MAX_TIER then return 0 end
    return tier
end

-- Seta o tier no item (igual Item::setTier() do Canary)
local function setItemTier(uid, tier)
    tier = math.min(math.max(tier, 0), MAX_TIER)
    doItemSetAttribute(uid, "tier", tier)
end

-- ============================================================
-- CUSTO E CHANCE
-- ============================================================

local function getGambleCost(craftCost, currentTier)
    -- T5+ tem custo fixo independente da luva
    if FIXED_COSTS[currentTier] then
        return FIXED_COSTS[currentTier]
    end
    -- T0-T4: custo baseado no craftCost da luva
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

local function findGloveByName(name)
    local name = name:lower()
    for i, glove in ipairs(GLOVES) do
        local gname = glove.name:lower()
        local galt = (glove.alt or ""):lower()
        if name == gname or name:find(gname, 1, true) or gname:find(name, 1, true)
           or (galt ~= "" and (name == galt or name:find(galt, 1, true) or galt:find(name, 1, true))) then
            return i, glove
        end
    end
    return nil, nil
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
    for i = 0, 5 do
        setPlayerStorageValue(cid, CONVO_BASE + i, 0)
    end
    selfSay("Hello, " .. getCreatureName(cid) .. "! My name is Gan Bler, the gambler.", cid)
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
    -- ESTADO 1: Apresentacao
    -- ============================================================
    if talkState[talkUser] == 1 then

        if msgcontains(msg, "gamble") or msgcontains(msg, "bet") or msgcontains(msg, "upgrade") or msgcontains(msg, "improve") or msgcontains(msg, "gloves") or msgcontains(msg, "melhorar") or msgcontains(msg, "apostar") then
            local lista = "These are the gloves I accept. Choose by name:\n\n"
            for i, glove in ipairs(GLOVES) do
                local count = getPlayerItemCount(cid, glove.itemId)
                local tierText = ""
                if count > 0 then
                    local item = getPlayerItemById(cid, true, glove.itemId)
                    if item and item.uid then
                        local tier = getItemTier(item.uid)
                        if tier > 0 then
                            tierText = " [Tier " .. tier .. "]"
                        end
                    end
                end
                local cost = getGambleCost(glove.craftCost, 0)
                lista = lista .. i .. ") " .. glove.name .. tierText .. " - " .. doNumberFormat(cost) .. " gold\n"
            end
            lista = lista .. "\nRule: only 1 pair of gloves at a time. Type the name of the gloves."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("Which gloves do you want to gamble on?", cid)
            talkState[talkUser] = 2

        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") or msgcontains(msg, "hello") then
            selfSay("I already told you, I am Gan Bler! Say {gamble} if you want to test your luck.", cid)

        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") or msgcontains(msg, "farewell") then
            selfSay("Get lost! Come back when you find some courage.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    -- ============================================================
    -- ESTADO 2: Escolha da luva (pelo nome)
    -- ============================================================
    elseif talkState[talkUser] == 2 then

        local idx, glove = findGloveByName(msg)

        if not glove then
            selfSay("I do not recognize those gloves. Please type the correct name.", cid)
            return true
        end

        -- Verifica se tem a luva
        local count = getPlayerItemCount(cid, glove.itemId)
        if count <= 0 then
            selfSay("You do not have " .. glove.name .. " in your inventory.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Verifica se tem mais de 1
        if count > 1 then
            selfSay("You have " .. count .. " " .. glove.name .. ". I only take one at a time to gamble.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Pega o tier DIRETO DO ITEM
        local gloveItem = getPlayerItemById(cid, true, glove.itemId)
        if not gloveItem or not gloveItem.uid then
            selfSay("Error locating the gloves.", cid)
            talkState[talkUser] = 1
            return true
        end

        local currentTier = getItemTier(gloveItem.uid)

        if currentTier >= MAX_TIER then
            selfSay("These gloves are already at the maximum tier!", cid)
            talkState[talkUser] = 1
            return true
        end

        local cost = getGambleCost(glove.craftCost, currentTier)
        local nextTier = currentTier + 1

        -- Salva dados da conversa
        setPlayerStorageValue(cid, CONVO_BASE, 1)
        setPlayerStorageValue(cid, CONVO_BASE + 1, glove.itemId)
        setPlayerStorageValue(cid, CONVO_BASE + 2, currentTier)
        setPlayerStorageValue(cid, CONVO_BASE + 3, cost)
        setPlayerStorageValue(cid, CONVO_BASE + 4, idx)

        selfSay(glove.name .. " (Tier " .. currentTier .. " -> " .. nextTier .. ") costs " .. doNumberFormat(cost) .. " gold.", cid)
        addEvent(function()
            if isPlayer(cid) then
                selfSay("Choose a number from 1 to 5.", cid)
            end
        end, 1500)
        talkState[talkUser] = 3

    -- ============================================================
    -- ESTADO 3: Escolha do numero (1-5)
    -- ============================================================
    elseif talkState[talkUser] == 3 then

        local chosenNumber = tonumber(msg)
        if not chosenNumber or chosenNumber < 1 or chosenNumber > 5 then
            selfSay("Choose a number from 1 to 5.", cid)
            return true
        end

        setPlayerStorageValue(cid, CONVO_BASE + 5, chosenNumber)

        selfSay("You chose " .. chosenNumber .. ". Confirm? {yes} or {no}", cid)
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
            local glove = GLOVES[idx]

            -- Verifica gold
            if getPlayerMoney(cid) < cost then
                selfSay("You need " .. doNumberFormat(cost) .. " gold.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Verifica se ainda tem a luva (1 unica)
            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then
                selfSay("You no longer have the gloves!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end
            if count > 1 then
                selfSay("You have more than one pair of gloves. I only take one at a time.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Pega o item e le o tier DIRETO DELE
            local gloveItem = getPlayerItemById(cid, true, itemId)
            if not gloveItem or not gloveItem.uid then
                selfSay("Error locating the gloves.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local realTier = getItemTier(gloveItem.uid)

            -- Cobra gold
            doPlayerRemoveMoney(cid, cost)

            -- ============================================================
            -- CALCULA CHANCE (fixa por tier)
            -- ============================================================
            local winChance = WIN_CHANCES[realTier] or 0.01
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
                setItemTier(gloveItem.uid, newTier)

                -- Envia pro client (usa clientId, nao server itemId)
                local clientId = toClientId(gloveItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "set," .. clientId .. "," .. newTier)

                doSendMagicEffect(getCreaturePosition(cid), 200)
                selfSay("You won! " .. glove.name .. " is now Tier " .. newTier .. "!", cid)
            else
                -- ERROU - remove luva
                doRemoveItem(gloveItem.uid, 1)

                -- Envia pro client (usa clientId, nao server itemId)
                local clientId = toClientId(gloveItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)

                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("You lost! The number was " .. secretNumber .. ". I keep your " .. glove.name .. " and your gold.", cid)
            end

            -- Limpa conversa
            talkState[talkUser] = 1
            for i = 0, 5 do
                setPlayerStorageValue(cid, CONVO_BASE + i, 0)
            end

        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            selfSay("Changed your mind? No problem.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end

    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
