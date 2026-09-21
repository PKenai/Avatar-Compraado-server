-- ============================================================
-- ROBSON - NPC Armeiro e Curtidor de Calças (Tier Upgrade)
-- Sistema de Tier de Calças
-- Tier fica no ITEM (doItemSetAttribute / getItemAttribute)
-- Sem necessidade de escolher números: confirmação direta
-- ============================================================

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local MAX_TIER = 10
local TIER_OPCODE = 111

-- Semente inicial de aleatoriedade
math.randomseed(os.time() + (tonumber(tostring({}):sub(8)) or 0))
for i = 1, 5 do math.random() end

local function getRandomPercent()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000) + (tonumber(tostring({}):sub(8)) or 0) + math.random(1, 10000))
    math.random()
    return math.random(1, 10000) / 10000.0 -- 0.0001 a 1.0000
end

-- Fator de dificuldade por calça (da mais simples a mais valiosa)
local PANTS_DIFFICULTY_FACTOR = {
    [1] = 1.00, -- Calca de viajante
    [2] = 0.95, -- Calca reforcada
    [3] = 0.90, -- Calca resistente
    [4] = 0.85, -- Calca aprimorada
    [5] = 0.80, -- Calca nobre
    [6] = 0.75, -- Calca de protecao
    [7] = 0.70, -- Calca majestosa
    [8] = 0.65, -- Calca gloriosa
    [9] = 0.60, -- Calca soberana
    [10] = 0.50, -- Calca das nacoes
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

local function getWinChance(pantsIdx, currentTier)
    local base = BASE_WIN_CHANCES[currentTier] or 0.01
    local factor = PANTS_DIFFICULTY_FACTOR[pantsIdx] or 1.0
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
local CONVO_BASE = 49320
-- CONVO_BASE + 0 = estado da conversa
-- CONVO_BASE + 1 = itemId da calça escolhida
-- CONVO_BASE + 2 = tier atual
-- CONVO_BASE + 3 = custo em gold
-- CONVO_BASE + 4 = indice da calça na lista

-- Calças aceitas pelo Robson (vendidas pelo Tadeu)
local PANTS = {
    {itemId = 19169, name = "Traveler's Pants", alt = "calca de viajante",  craftCost = 4000},
    {itemId = 19170, name = "Reinforced Pants", alt = "calca reforcada",   craftCost = 12000},
    {itemId = 19171, name = "Tough Pants",      alt = "calca resistente",  craftCost = 28000},
    {itemId = 19172, name = "Improved Pants",   alt = "calca aprimorada",  craftCost = 55000},
    {itemId = 19173, name = "Noble Pants",      alt = "calca nobre",       craftCost = 100000},
    {itemId = 19174, name = "Protective Pants", alt = "calca de protecao", craftCost = 175000},
    {itemId = 19175, name = "Majestic Pants",   alt = "calca majestosa",   craftCost = 300000},
    {itemId = 19176, name = "Glorious Pants",   alt = "calca gloriosa",    craftCost = 500000},
    {itemId = 19177, name = "Sovereign Pants",  alt = "calca soberana",    craftCost = 800000},
    {itemId = 19178, name = "Nations Pants",    alt = "calca das nacoes",  craftCost = 1200000},
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
-- CUSTO
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

local function findPantsByName(name)
    local cleanName = sanitizeText(name)
    for i, p in ipairs(PANTS) do
        local cleanPant = sanitizeText(p.name)
        local cleanAlt = sanitizeText(p.alt or "")
        if cleanName == cleanPant or cleanName:find(cleanPant, 1, true) or cleanPant:find(cleanName, 1, true)
           or (cleanAlt ~= "" and (cleanName == cleanAlt or cleanName:find(cleanAlt, 1, true) or cleanAlt:find(cleanName, 1, true))) then
            return i, p
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
    selfSay("Hello, " .. getCreatureName(cid) .. "! I am Robson, master armorer and tanner. I can {reinforce} your pants to upgrade their Tier! Would you like to improve your armor?", cid)
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

        if msgcontains(msg, "reinforce") or msgcontains(msg, "upgrade") or msgcontains(msg, "improve") or msgcontains(msg, "pants") or msgcontains(msg, "reforco") or msgcontains(msg, "reforcar") or msgcontains(msg, "melhorar") or msgcontains(msg, "aprimorar") or msgcontains(msg, "calca") then
            local lista = "Pants accepted for Tier reinforcement:\n\n"
            for i, p in ipairs(PANTS) do
                local count = getPlayerItemCount(cid, p.itemId)
                local tierText = ""
                if count > 0 then
                    local item = getPlayerItemById(cid, true, p.itemId)
                    if item and item.uid then
                        local tier = getItemTier(item.uid)
                        if tier > 0 then
                            tierText = " [Tier " .. tier .. "]"
                        end
                    end
                end
                local cost = getGambleCost(p.craftCost, 0)
                lista = lista .. i .. ") " .. p.name .. tierText .. " - " .. doNumberFormat(cost) .. " gold\n"
            end
            lista = lista .. "\nRule: only 1 pair of pants at a time. Type the name of the pants."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("I use tempered plates to reinforce the resistance of your piece. However, the forging pressure is extreme: if it fails, the pants will tear and be destroyed! Which pants do you want me to try to reinforce?", cid)
            talkState[talkUser] = 2

        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") or msgcontains(msg, "hello") then
            selfSay("Hello! Say {reinforce} to see which pants we can enhance.", cid)

        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") or msgcontains(msg, "farewell") then
            selfSay("Farewell! Come back whenever you need sturdier armor.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    -- ============================================================
    -- ESTADO 2: Escolha da Calça (pelo nome)
    -- ============================================================
    elseif talkState[talkUser] == 2 then

        local idx, pant = findPantsByName(msg)

        if not pant then
            selfSay("I do not recognize those pants. Please type the correct name of the piece.", cid)
            return true
        end

        -- Verifica se tem a calça
        local count = getPlayerItemCount(cid, pant.itemId)
        if count <= 0 then
            selfSay("You do not have " .. pant.name .. " in your inventory.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Verifica se tem mais de 1
        if count > 1 then
            selfSay("You have " .. count .. " " .. pant.name .. ". Store the others, I only take one at a time.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Pega o item e le o tier direto dele
        local pantItem = getPlayerItemById(cid, true, pant.itemId)
        if not pantItem or not pantItem.uid then
            selfSay("Error locating the pants.", cid)
            talkState[talkUser] = 1
            return true
        end

        local currentTier = getItemTier(pantItem.uid)

        if currentTier >= MAX_TIER then
            selfSay("These pants have already reached the maximum possible Tier!", cid)
            talkState[talkUser] = 1
            return true
        end

        local cost = getGambleCost(pant.craftCost, currentTier)
        local nextTier = currentTier + 1

        -- Salva dados da conversa
        setPlayerStorageValue(cid, CONVO_BASE, 1)
        setPlayerStorageValue(cid, CONVO_BASE + 1, pant.itemId)
        setPlayerStorageValue(cid, CONVO_BASE + 2, currentTier)
        setPlayerStorageValue(cid, CONVO_BASE + 3, cost)
        setPlayerStorageValue(cid, CONVO_BASE + 4, idx)

        selfSay("Reinforcing your " .. pant.name .. " (Tier " .. currentTier .. " -> " .. nextTier .. ") will cost " .. doNumberFormat(cost) .. " gold. If it fails, they will rupture and be lost. Confirm the process? {yes} or {no}", cid)
        talkState[talkUser] = 3

    -- ============================================================
    -- ESTADO 3: Confirmacao Direta (sem escolha de numero)
    -- ============================================================
    elseif talkState[talkUser] == 3 then

        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)
            local itemId = getPlayerStorageValue(cid, CONVO_BASE + 1)
            local idx = getPlayerStorageValue(cid, CONVO_BASE + 4)
            local pant = PANTS[idx]

            -- Verifica gold
            if getPlayerMoney(cid) < cost then
                selfSay("You need " .. doNumberFormat(cost) .. " gold to perform the reinforcement.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Verifica se ainda tem a calça (1 única)
            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then
                selfSay("You no longer have the pants in your inventory!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end
            if count > 1 then
                selfSay("You have more than one pair of pants. Keep only one.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Pega o item e le o tier real
            local pantItem = getPlayerItemById(cid, true, itemId)
            if not pantItem or not pantItem.uid then
                selfSay("Error locating the item.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local realTier = getItemTier(pantItem.uid)

            -- Cobra o gold
            doPlayerRemoveMoney(cid, cost)

            -- ============================================================
            -- CALCULA CHANCE (escalonada por calça e tier)
            -- ============================================================
            local winChance = getWinChance(idx, realTier)
            local roll = getRandomPercent()

            if roll <= winChance then
                -- SUCESSO - seta tier no item
                local newTier = math.min(realTier + 1, MAX_TIER)
                setItemTier(pantItem.uid, newTier)

                -- Envia pro client
                local clientId = toClientId(pantItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "set," .. clientId .. "," .. newTier)

                doSendMagicEffect(getCreaturePosition(cid), 200)
                selfSay("Excellent work! The welding and plate reinforcement held up flawlessly! Your " .. pant.name .. " is now Tier " .. newTier .. "!", cid)
            else
                -- FALHA - destroi a calça
                doRemoveItem(pantItem.uid, 1)

                -- Envia pro client
                local clientId = toClientId(pantItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)

                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("Damn it! The structure could not withstand the forging pressure and the fabric shattered... Your " .. pant.name .. " was destroyed in the process. I am truly sorry!", cid)
            end

            -- Limpa conversa
            talkState[talkUser] = 1
            for i = 0, 4 do
                setPlayerStorageValue(cid, CONVO_BASE + i, 0)
            end

        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            selfSay("Understood. Prudence is always a wise choice when dealing with valuable items.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end

    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
