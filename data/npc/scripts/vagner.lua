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
    [1] = {name = "Ferro",      desc = "Ferro comum, barato mas frágil"},
    [2] = {name = "Bronze",     desc = "Bronze resistente, boa durabilidade"},
    [3] = {name = "Aco",        desc = "Aco temperado, forte e flexivel"},
    [4] = {name = "Titanio",    desc = "Titanio leve mas extremamente resistente"},
    [5] = {name = "Adamantio",  desc = "Adamantio lendario, indestrutivel"},
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
    {itemId = 19191, name = "bota de viajante",  craftCost = 3000},
    {itemId = 19192, name = "bota reforcada",   craftCost = 9000},
    {itemId = 19193, name = "bota resistente",  craftCost = 22000},
    {itemId = 19194, name = "bota aprimorada",  craftCost = 45000},
    {itemId = 19195, name = "bota nobre",       craftCost = 85000},
    {itemId = 19196, name = "bota de protecao", craftCost = 150000},
    {itemId = 19197, name = "bota majestosa",   craftCost = 250000},
    {itemId = 19198, name = "bota gloriosa",    craftCost = 425000},
    {itemId = 19199, name = "bota soberana",    craftCost = 680000},
    {itemId = 19200, name = "bota das nacoes",  craftCost = 1000000},
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
        if cleanName == cleanBoot or cleanName:find(cleanBoot, 1, true) or cleanBoot:find(cleanName, 1, true) then
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
    selfSay("Hmph! Outro aventureiro querendo que eu forje suas botas? Eu sou Vagner, o melhor ferreiro de solhas deste continente! Mas nao e qualquer um que eu ajudo. Quer que eu tente {reforcar} sua bota? Primeiro preciso ver se voce entende de metais!", cid)
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

        if msgcontains(msg, "reforcar") or msgcontains(msg, "melhorar") or msgcontains(msg, "apostar") then
            local lista = "Botas que aceito forjar:\n\n"
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
            lista = lista .. "\nRegra: so forjo 1 bota por vez. Escolha pelo nome."
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, lista)
            selfSay("Pra forjar a solha, voce precisa escolher o metal certo! Se acertar, a bota fica mais forte. Se errar... bem, o metal derrete e voce perde a bota. Qual bota voce quer que eu tente forjar?", cid)
            talkState[talkUser] = 2

        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") or msgcontains(msg, "ola") then
            selfSay("Ja te disse, sou Vagner! Diz {reforcar} se quiser testar suas botas.", cid)

        elseif msgcontains(msg, "tchau") or msgcontains(msg, "bye") then
            selfSay("Vai embora! E nao volta sem botas de verdade!", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        end

    -- ESTADO 2: Escolha da bota
    elseif talkState[talkUser] == 2 then

        local idx, boot = findBootByName(msg)

        if not boot then
            selfSay("Nao conheco essa bota. Digite o nome certo.", cid)
            return true
        end

        local count = getPlayerItemCount(cid, boot.itemId)
        if count <= 0 then
            selfSay("Voce nao tem " .. boot.name .. " no inventario.", cid)
            talkState[talkUser] = 1
            return true
        end

        if count > 1 then
            selfSay("Voce tem " .. count .. " " .. boot.name .. ". So forjo uma por vez.", cid)
            talkState[talkUser] = 1
            return true
        end

        local bootItem = getPlayerItemById(cid, true, boot.itemId)
        if not bootItem or not bootItem.uid then
            selfSay("Erro ao encontrar a bota.", cid)
            talkState[talkUser] = 1
            return true
        end

        local currentTier = getItemTier(bootItem.uid)

        if currentTier >= MAX_TIER then
            selfSay("Essa bota ja esta no tier maximo! Nao tem como forjar mais.", cid)
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

        selfSay(boot.name .. " (Tier " .. currentTier .. " -> " .. nextTier .. ") custara " .. doNumberFormat(cost) .. " gold.", cid)
        addEvent(function()
            if isPlayer(cid) then
                selfSay("Agora escolha o metal pra solha! {1} Ferro, {2} Bronze, {3} Aco, {4} Titanio ou {5} Adamantio?", cid)
            end
        end, 1500)
        talkState[talkUser] = 3

    -- ESTADO 3: Escolha do metal
    elseif talkState[talkUser] == 3 then

        local chosenMetal = tonumber(msg)
        if not chosenMetal or chosenMetal < 1 or chosenMetal > 5 then
            selfSay("Escolha um metal de 1 a 5: {Ferro}, {Bronze}, {Aco}, {Titanio} ou {Adamantio}?", cid)
            return true
        end

        local metalName = METALS[chosenMetal].name
        setPlayerStorageValue(cid, CONVO_BASE + 5, chosenMetal)

        selfSay("Voce escolheu " .. metalName .. "! Se esse metal nao combinar com a bota, ela derrete. Confirma? {sim} ou {nao}", cid)
        talkState[talkUser] = 4

    -- ESTADO 4: Confirmacao
    elseif talkState[talkUser] == 4 then

        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            local cost = getPlayerStorageValue(cid, CONVO_BASE + 3)
            local itemId = getPlayerStorageValue(cid, CONVO_BASE + 1)
            local idx = getPlayerStorageValue(cid, CONVO_BASE + 4)
            local chosenMetal = getPlayerStorageValue(cid, CONVO_BASE + 5)
            local boot = BOOTS[idx]

            if getPlayerMoney(cid) < cost then
                selfSay("Voce precisa de " .. doNumberFormat(cost) .. " gold pra eu forjar!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local count = getPlayerItemCount(cid, itemId)
            if count <= 0 then
                selfSay("Voce nao tem mais a bota!", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end
            if count > 1 then
                selfSay("Voce tem mais de uma bota. Guarde as outras.", cid)
                talkState[talkUser] = 1
                setPlayerStorageValue(cid, CONVO_BASE, 0)
                return true
            end

            local bootItem = getPlayerItemById(cid, true, itemId)
            if not bootItem or not bootItem.uid then
                selfSay("Erro ao encontrar a bota.", cid)
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
                selfSay("O " .. metalName .. " assentou perfeitamente na solha! Sua " .. boot.name .. " agora e Tier " .. newTier .. "! Hmph, ate que voce sabe escolher.", cid)
            else
                -- FALHA
                doRemoveItem(bootItem.uid, 1)

                local clientId = toClientId(bootItem.itemid)
                doSendPlayerExtendedOpcode(cid, TIER_OPCODE, "clear," .. clientId)

                doSendMagicEffect(getCreaturePosition(cid), 201)
                selfSay("Droga! O " .. metalName .. " nao aguentou o calor da forja e a solha derreteu! Sua " .. boot.name .. " foi prospace. Devia ter escolhido outro metal...", cid)
            end

            talkState[talkUser] = 1
            for i = 0, 5 do
                setPlayerStorageValue(cid, CONVO_BASE + i, 0)
            end

        elseif msgcontains(msg, "nao") or msgcontains(msg, "no") then
            selfSay("Covarde! Volte quando tiver coragem de arriscar.", cid)
            talkState[talkUser] = 1
            setPlayerStorageValue(cid, CONVO_BASE, 0)
        end

    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
