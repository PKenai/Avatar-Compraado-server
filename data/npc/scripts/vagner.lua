-- ============================================================
-- VAGNER - NPC Ferreiro de Botas (Tier Upgrade)
-- Sistema: "A Prova do Ferreiro"
-- Vagner e um ferreiro grumpy que testa se voce sabe
-- escolher o metal certo pra solhar a bota.
-- Se acertar: tier sobe. Se errar: bota derrete.
-- ============================================================

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local MAX_TIER = 10
local TIER_OPCODE = 111

-- Semente inicial
math.randomseed(os.time() + (tonumber(tostring({}):sub(8)) or 0))
for i = 1, 5 do math.random() end

local function getRandomPercent()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000) + (tonumber(tostring({}):sub(8)) or 0) + math.random(1, 10000))
    math.random()
    return math.random(1, 10000) / 10000.0
end

-- Metais disponiveis pra forjar a solha
local METALS = {
    [1] = {name = "Iron",       desc = "Common iron, cheap but brittle"},
    [2] = {name = "Bronze",     desc = "Resistant bronze, good durability"},
    [3] = {name = "Steel",      desc = "Tempered steel, strong and flexible"},
    [4] = {name = "Titanium",   desc = "Lightweight titanium, extremely durable"},
    [5] = {name = "Adamantium", desc = "Legendary adamantium, indestructible"},
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

-- Fator de dificuldade por bota (da mais simples a mais valiosa)
local BOOT_DIFFICULTY = {
    [1] = 1.00,  -- Bota de viajante
    [2] = 0.95,  -- Bota reforcada
    [3] = 0.90,  -- Bota resistente
    [4] = 0.85,  -- Bota aprimorada
    [5] = 0.80,  -- Bota nobre
    [6] = 0.75,  -- Bota de protecao
    [7] = 0.70,  -- Bota majestosa
    [8] = 0.65,  -- Bota gloriosa
    [9] = 0.60,  -- Bota soberana
    [10] = 0.50, -- Bota das nacoes
}

-- Custo fixo pra T5+
local FIXED_COSTS = {
    [5] = 500000,
    [6] = 1000000,
    [7] = 2000000,
    [8] = 3000000,
    [9] = 4000000,
}

-- Botas aceitas
local BOOTS = {
    {itemId = 19191, name = "Traveler's Boots", alt = "bota de viajante",  craftCost = 3000},
    {itemId = 19192, name = "Reinforced Boots", alt = "bota reforcada",   craftCost = 9000},
    {itemId = 19193, name = "Tough Boots",      alt = "bota resistente",  craftCost = 22000},
    {itemId = 19194, name = "Improved Boots",   alt = "bota aprimorada",  craftCost = 45000},
    {itemId = 19195, name = "Noble Boots",      alt = "bota nobre",       craftCost = 85000},
    {itemId = 19196, name = "Protective Boots", alt = "bota de protecao", craftCost = 150000},
    {itemId = 19197, name = "Majestic Boots",   alt = "bota majestosa",   craftCost = 250000},
    {itemId = 19198, name = "Glorious Boots",   alt = "bota gloriosa",    craftCost = 425000},
    {itemId = 19199, name = "Sovereign Boots",  alt = "bota soberana",    craftCost = 680000},
    {itemId = 19200, name = "Nations Boots",    alt = "bota das nacoes",  craftCost = 1000000},
}

-- Convesation storage
local CONVO_BASE = 49340

-- Funcoes auxiliares
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

local function getWinChance(bootIdx, currentTier)
    local base = BASE_WIN_CHANCES[currentTier] or 0.01
    local factor = BOOT_DIFFICULTY[bootIdx] or 1.0
    return math.max(0.002, base * factor)
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

local function findBootByName(name)
    local cleanName = sanitizeText(name)
    for i, boot in ipairs(BOOTS) do
        local cleanBoot = sanitizeText(boot.name)
        local cleanAlt = sanitizeText(boot.alt or "")
        if cleanName == cleanBoot or cleanName:find(cleanBoot, 1, true) or cleanBoot:find(cleanName, 1, true)
           or (cleanAlt ~= "" and (cleanName == cleanAlt or cleanName:find(cleanAlt, 1, true) or cleanAlt:find(cleanName, 1, true))) then
            return i, boot
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
    for i = 0, 4 do
        setPlayerStorageValue(cid, CONVO_BASE + i, 0)
    end
    selfSay("Hmph! Another adventurer wanting me to forge their boots? I am Vagner, the best solesmith on this continent! But I do not help just anyone. Want me to try to {forge} your boots? First I must see if you know your metals!", cid)
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then return false end

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local msg = msg:lower()

    -- ESTADO 1: Apresentacao
    if talkState[talkUser] == 1 then

        if msgcontains(msg, "forge") or msgcontains(msg, "reinforce") or msgcontains(msg, "boots") or msgcontains(msg, "reforcar") or msgcontains(msg, "melhorar") then
            local lista = "Boots accepted for forging:\n\n"
            for i, boot in ipairs(BOOTS) do
                local count = getPlayerItemCount(cid, boot.itemId)
                local tierText = ""
                if count > 0 then
                    local item = getPlayerItemById(cid, true, boot.itemId)
                    if item and item.uid then
                        local tier = getItemTier(item.uid)
                        if tier > 0 then
                            tierText = " [Tier " .. tier .. "]"
                        end
                    end
                end
                local cost = getGambleCost(boot.craftCost, 0)
                lista = lista .. i .. ") " .. boot.name .. tierText .. " - " .. doNumberFormat(cost) .. " gold\n"
            end
            lista = lista .. "\nRule: only 1 pair of boots at a time. Choose by name."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("To forge the sole, you must choose the right metal! If you guess right, the boots grow stronger. If you fail... well, the metal melts and you lose the boots. Which boots do you want me to forge?", cid)
            talkState[talkUser] = 2

        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") or msgcontains(msg, "hello") then
            selfSay("I already told you, I am Vagner! Say {forge} if you want to test your boots.", cid)

        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") or msgcontains(msg, "farewell") then
            selfSay("Get lost! And do not come back without real boots!", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    -- ESTADO 2: Escolha da bota
    elseif talkState[talkUser] == 2 then

        local idx, boot = findBootByName(msg)

        if not boot then
            selfSay("I do not recognize those boots. Please type the correct name.", cid)
            return true
        end

        local count = getPlayerItemCount(cid, boot.itemId)
        if count <= 0 then
            selfSay("You do not have " .. boot.name .. " in your inventory.", cid)
            talkState[talkUser] = 1
            return true
        end

        if count > 1 then
            selfSay("You have " .. count .. " " .. boot.name .. ". I only forge one at a time.", cid)
            talkState[talkUser] = 1
            return true
        end

        local bootItem = getPlayerItemById(cid, true, boot.itemId)
        if not bootItem or not bootItem.uid then
            selfSay("Error finding the boots.", cid)
            talkState[talkUser] = 1
            return true
        end

        local currentTier = getItemTier(bootItem.uid)

        if currentTier >= MAX_TIER then
            selfSay("These boots are already at the maximum tier! Cannot forge them any further.", cid)
            talkState[talkUser] = 1
            return true
        end

        local cost = getGambleCost(boot.craftCost, currentTier)
        local nextTier = currentTier + 1

        setPlayerStorageValue(cid, CONVO_BASE, 1)
        setPlayerStorageValue(cid, CONVO_BASE + 1, boot.itemId)
        setPlayerStorageValue(cid, CONVO_BASE + 2, currentTier)
        setPlayerStorageValue(cid, CONVO_BASE + 3, cost)
        setPlayerStorageValue(cid, CONVO_BASE + 4, idx)

        selfSay(boot.name .. " (Tier " .. currentTier .. " -> " .. nextTier .. ") will cost " .. doNumberFormat(cost) .. " gold.", cid)
        addEvent(function()
            if isPlayer(cid) then
                selfSay("Now choose the metal for the sole! {1} Iron, {2} Bronze, {3} Steel, {4} Titanium or {5} Adamantium?", cid)
            end
        end, 1500)
        talkState[talkUser] = 3

    -- ESTADO 3: Escolha do metal
    elseif talkState[talkUser] == 3 then

        local chosenMetal = tonumber(msg)
        if not chosenMetal then
            local m = msg:lower()
            if m:find("iron") or m:find("ferro") then chosenMetal = 1
            elseif m:find("bronze") then chosenMetal = 2
            elseif m:find("steel") or m:find("aco") then chosenMetal = 3
            elseif m:find("titan") then chosenMetal = 4
            elseif m:find("adamant") then chosenMetal = 5
            end
        end
        if not chosenMetal or chosenMetal < 1 or chosenMetal > 5 then
            selfSay("Choose a metal from 1 to 5: {Iron}, {Bronze}, {Steel}, {Titanium} or {Adamantium}?", cid)
            return true
        end

        local metalName = METALS[chosenMetal].name
        setPlayerStorageValue(cid, CONVO_BASE + 5, chosenMetal)

        selfSay("You chose " .. metalName .. "! If this metal does not bond with the boots, they will melt. Confirm? {yes} or {no}", cid)
        talkState[talkUser] = 4

    -- ESTADO 4: Confirmacao
    elseif talkState[talkUser] == 4 then

        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)
            local itemId = getPlayerStorageValue(cid, CONVO_BASE + 1)
            local idx = getPlayerStorageValue(cid, CONVO_BASE + 4)
            local chosenMetal = getPlayerStorageValue(cid, CONVO_BASE + 5)
            local boot = BOOTS[idx]

            if getPlayerMoney(cid) < cost then
                selfSay("You need " .. doNumberFormat(cost) .. " gold for me to forge!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then
                selfSay("You no longer have the boots!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end
            if count > 1 then
                selfSay("You have more than one pair of boots. Store the others.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local bootItem = getPlayerItemById(cid, true, itemId)
            if not bootItem or not bootItem.uid then
                selfSay("Error finding the boots.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local realTier = getItemTier(bootItem.uid)
            doPlayerRemoveMoney(cid, cost)

            -- CALCULA CHANCE
            local winChance = getWinChance(idx, realTier)
            local roll = getRandomPercent()
            local metalName = METALS[chosenMetal].name

            if roll <= winChance then
                -- SUCESSO
                local newTier = math.min(realTier + 1, MAX_TIER)
                setItemTier(bootItem.uid, newTier)

                local clientId = toClientId(bootItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "set," .. clientId .. "," .. newTier)

                doSendMagicEffect(getCreaturePosition(cid), 200)
                selfSay("The " .. metalName .. " bonded flawlessly to the sole! Your " .. boot.name .. " is now Tier " .. newTier .. "! Hmph, you actually know how to choose.", cid)
            else
                -- FALHA
                doRemoveItem(bootItem.uid, 1)

                local clientId = toClientId(bootItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)

                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("Blast it! The " .. metalName .. " could not endure the forge heat and the sole melted! Your " .. boot.name .. " is ruined. You should have picked another metal...", cid)
            end

            talkState[talkUser] = 1
            for i = 0, 5 do
                setPlayerStorageValue(cid, CONVO_BASE + i, 0)
            end

        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            selfSay("Coward! Come back when you have the courage to take a risk.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end

    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
