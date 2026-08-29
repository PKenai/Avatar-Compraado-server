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
    {itemId = 19098, name = "luva simples",            craftCost = 100},
    {itemId = 19100, name = "luva pegajosa",           craftCost = 150},
    {itemId = 19102, name = "luva funebre",            craftCost = 200},
    {itemId = 19104, name = "luva pinca vermelha",     craftCost = 300},
    {itemId = 19106, name = "luva de joaninha",        craftCost = 400},
    {itemId = 19108, name = "luvas da fera",           craftCost = 550},
    {itemId = 19110, name = "luvas tecidas",           craftCost = 750},
    {itemId = 19112, name = "luvas da rainha",         craftCost = 1000},
    {itemId = 19114, name = "luvas de teia",           craftCost = 1500},
    {itemId = 19116, name = "luvas de barro",          craftCost = 2000},
    {itemId = 19118, name = "luvas reluzentes",        craftCost = 3000},
    {itemId = 19120, name = "luvas reais",             craftCost = 4500},
    {itemId = 19122, name = "luvas metalicas",         craftCost = 6000},
    {itemId = 19124, name = "luvas gosmentas",         craftCost = 8500},
    {itemId = 19126, name = "luvas de couro cinza",    craftCost = 12000},
    {itemId = 19128, name = "luvas da terra",          craftCost = 17000},
    {itemId = 19130, name = "luvas da natureza",       craftCost = 24000},
    {itemId = 19132, name = "luvas carniceiras",       craftCost = 33000},
    {itemId = 19134, name = "luvas cascudas",          craftCost = 47000},
    {itemId = 19136, name = "luvas da rebeliao",       craftCost = 66000},
    {itemId = 19140, name = "luvas da coragem",        craftCost = 93000},
    {itemId = 19138, name = "luvas marinhas",          craftCost = 130000},
    {itemId = 19142, name = "luvas do hermitao",       craftCost = 184000},
    {itemId = 19144, name = "luvas do conhecimento",   craftCost = 258000},
    {itemId = 19146, name = "luvas da dobra obscura",  craftCost = 363000},
    {itemId = 19148, name = "luvas deserticas",        craftCost = 511000},
    {itemId = 19150, name = "luvas de pedregulho",     craftCost = 718000},
    {itemId = 19152, name = "luvas do conhecimento perdido", craftCost = 1000000},
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
        if name == glove.name or name:find(glove.name) or glove.name:find(name) then
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
    selfSay("Ola, " .. getCreatureName(cid) .. "! Meu nome e Gan Bler, o apostador.", cid)
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

        if msgcontains(msg, "melhorar") or msgcontains(msg, "apostar") or msgcontains(msg, "bet") then
            local lista = "Essas sao as luvas que aceito. Escolha pelo nome:\n\n"
            for i, glove in ipairs(GLOVES) do
                -- Le tier direto do item (se tiver no inventario)
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
            lista = lista .. "\nRegra: so aceito 1 luva de cada tipo. Digite o nome da luva."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("Qual luva voce quer apostar?", cid)
            talkState[talkUser] = 2

        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") then
            selfSay("Ja te disse, sou Gan Bler! Diz {melhorar} se quiser apostar.", cid)

        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") then
            selfSay("Vai embora! Volte quando tiver coragem.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    -- ============================================================
    -- ESTADO 2: Escolha da luva (pelo nome)
    -- ============================================================
    elseif talkState[talkUser] == 2 then

        local idx, glove = findGloveByName(msg)

        if not glove then
            selfSay("Nao conheco essa luva. Digite o nome certo.", cid)
            return true
        end

        -- Verifica se tem a luva
        local count = getPlayerItemCount(cid, glove.itemId)
        if count <= 0 then
            selfSay("Voce nao tem " .. glove.name .. " no inventario.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Verifica se tem mais de 1
        if count > 1 then
            selfSay("Voce tem " .. count .. " " .. glove.name .. ". So aceito 1 pra apostar.", cid)
            talkState[talkUser] = 1
            return true
        end

        -- Pega o tier DIRETO DO ITEM
        local gloveItem = getPlayerItemById(cid, true, glove.itemId)
        if not gloveItem or not gloveItem.uid then
            selfSay("Erro ao encontrar a luva.", cid)
            talkState[talkUser] = 1
            return true
        end

        local currentTier = getItemTier(gloveItem.uid)

        if currentTier >= MAX_TIER then
            selfSay("Essa luva ja esta no tier maximo!", cid)
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

        selfSay(glove.name .. " (Tier " .. currentTier .. " -> " .. nextTier .. ") custa " .. doNumberFormat(cost) .. " gold.", cid)
        addEvent(function()
            if isPlayer(cid) then
                selfSay("Escolha um numero de 1 a 5.", cid)
            end
        end, 1500)
        talkState[talkUser] = 3

    -- ============================================================
    -- ESTADO 3: Escolha do numero (1-5)
    -- ============================================================
    elseif talkState[talkUser] == 3 then

        local chosenNumber = tonumber(msg)
        if not chosenNumber or chosenNumber < 1 or chosenNumber > 5 then
            selfSay("Escolha um numero de 1 a 5.", cid)
            return true
        end

        setPlayerStorageValue(cid, CONVO_BASE + 5, chosenNumber)

        selfSay("Voce escolheu " .. chosenNumber .. ". Confirma? {sim} ou {nao}", cid)
        talkState[talkUser] = 4

    -- ============================================================
    -- ESTADO 4: Confirmacao
    -- ============================================================
    elseif talkState[talkUser] == 4 then

        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)
            local itemId = getPlayerStorageValue(cid, CONVO_BASE + 1)
            local idx = getPlayerStorageValue(cid, CONVO_BASE + 4)
            local chosenNumber = getPlayerStorageValue(cid, CONVO_BASE + 5)
            local glove = GLOVES[idx]

            -- Verifica gold
            if getPlayerMoney(cid) < cost then
                selfSay("Voce precisa de " .. doNumberFormat(cost) .. " gold.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Verifica se ainda tem a luva (1 unica)
            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then
                selfSay("Voce nao tem mais a luva!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end
            if count > 1 then
                selfSay("Voce tem mais de uma luva. So aceito uma de cada vez.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            -- Pega o item e le o tier DIRETO DELE
            local gloveItem = getPlayerItemById(cid, true, itemId)
            if not gloveItem or not gloveItem.uid then
                selfSay("Erro ao encontrar a luva.", cid)
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

                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("Voce acertou! " .. glove.name .. " agora e Tier " .. newTier .. "!", cid)
            else
                -- ERROU - remove luva
                doRemoveItem(gloveItem.uid, 1)

                -- Envia pro client (usa clientId, nao server itemId)
                local clientId = toClientId(gloveItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)

                doSendMagicEffect(getCreaturePosition(cid), 202)
                selfSay("Errou! O numero era " .. secretNumber .. ". Fiquei com sua " .. glove.name .. " e seu gold.", cid)
            end

            -- Limpa conversa
            talkState[talkUser] = 1
            for i = 0, 5 do
                setPlayerStorageValue(cid, CONVO_BASE + i, 0)
            end

        elseif msgcontains(msg, "nao") or msgcontains(msg, "no") then
            selfSay("Mudou de ideia? Sem problemas.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end

    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
