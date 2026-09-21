-- Senhor dos Repolhos - Quest: Os Repolhos Roubados (quest id 26)
-- Story: Um arruaceiro roubou os repolhos do Senhor dos Repolhos e
-- espalhou pela cidade. O jogador clica nos repolhos no chao (item 18929)
-- para incrementar o contador (o repolho NAO e coletado, fica no chao
-- para outras pessoas pegarem). Ao falar com o NPC, ele entrega rewards
-- em 5 tiers conforme o jogador vai recuperando repolhos.
--
-- Storages (data/questSystem/quests.xml):
--   49260 = status da quest (0 = nao iniciada, 1 = em andamento, 2 = completa)
--   49261 = total de repolhos recuperados pelo player (0-50)
--   49262 = ultimo tier de reward resgatado (0-5)
--   cabbage_<actionId> = repolhos individuais coletados (string storage por repolho)
--
-- Repolhos: item 18929 no chao, com action IDs unicos.
-- Cada repolho tem uma action ID. Ao clicar, o script checa se o player
-- ja coletou aquele repolho especifico e incrementa o contador.
--
-- Tiers de reward:
--   Tier 1:  1 repolho  -> 10.000 exp + 2 crystal coins
--   Tier 2: 10 repolhos -> 30.000 exp + 2 crystal coins
--   Tier 3: 20 repolhos -> 75.000 exp + 2 crystal coins
--   Tier 4: 35 repolhos -> 150.000 exp + 2 crystal coins
--   Tier 5: 50 repolhos -> 250.000 exp + 2 crystal coins + titulo "Repolhudo"
--
-- Titulo "Repolhudo": achievement id 23 (achievementsLib.lua)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

-- ============================================================
-- Configuracao
-- ============================================================
local STATUS_STORAGE    = 49260   -- 0=nao iniciada, 1=em andamento, 2=completa
local COUNT_STORAGE     = 49261   -- total de repolhos recuperados (0-50)
local TIER_STORAGE      = 49262   -- ultimo tier resgatado (0-5)

local QUEST_NAME   = "The Stolen Cabbages"
local MISSION_NAME = "Recover the stolen cabbages"

local TOTAL_CABBAGES = 50
local ACHIEVEMENT_REPOLHUDO = 23  -- conquista "Repolhudo" (achievementsLib.lua)

-- Tiers: { minCabbages, exp, crystalCoins }
local TIERS = {
    { min = 1,  exp = 10000,  coins = 2  },
    { min = 10, exp = 30000,  coins = 2  },
    { min = 20, exp = 75000,  coins = 2  },
    { min = 35, exp = 150000, coins = 2  },
    { min = 50, exp = 250000, coins = 2  },
}

-- ============================================================
-- Funcoes auxiliares
-- ============================================================
local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function getCabbageCount(cid)
    local v = getPlayerStorageValue(cid, COUNT_STORAGE)
    if type(v) ~= "number" or v < 0 then return 0 end
    return v
end

local function getLastTier(cid)
    local v = getPlayerStorageValue(cid, TIER_STORAGE)
    if type(v) ~= "number" or v < 0 then return 0 end
    return v
end

-- Retorna o index do proximo tier disponivel (1-5), ou nil se nao ha nenhum
local function getNextTier(cid)
    local count = getCabbageCount(cid)
    local lastTier = getLastTier(cid)
    for i = lastTier + 1, #TIERS do
        if count >= TIERS[i].min then
            return i
        end
    end
    return nil
end

-- Retorna o proximo tier minimo necessario
local function getNextTierMin(cid)
    local lastTier = getLastTier(cid)
    if lastTier >= #TIERS then return nil end
    return TIERS[lastTier + 1].min
end

local function sendNotification(cid, title, message, color, soundType)
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Senhor dos repolhos"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, COUNT_STORAGE, 0)
    setPlayerStorageValue(cid, TIER_STORAGE, 0)
    print("[Senhor dos repolhos] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function claimReward(cid, tier)
    local t = TIERS[tier]
    if not t then return end

    -- Dar rewards
    if t.exp > 0 then
        doPlayerAddExperience(cid, t.exp)
    end
    if t.coins > 0 then
        doPlayerAddItem(cid, 2160, t.coins)  -- crystal coin
    end

    setPlayerStorageValue(cid, TIER_STORAGE, tier)

    -- Se e o tier 5 (completo), marcar quest como completa e desbloquear titulo
    if tier == #TIERS then
        setPlayerStorageValue(cid, STATUS_STORAGE, 2)
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

        -- Titulo "Repolhudo": achievement id 23
        setPlayerStorageValue(cid, "achCreatureKill_" .. ACHIEVEMENT_REPOLHUDO, 1)
        local ok = pcall(function()
            Achievements.check(cid, ACHIEVEMENT_REPOLHUDO)
        end)
        if not ok then
            setPlayerStorageValue(cid, "achUnlocked_" .. ACHIEVEMENT_REPOLHUDO, 1)
            pcall(function()
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                    "Achievement unlocked: Repolhudo! Title: Repolhudo (open Achievements in the topbar to equip it).")
            end)
        end

        sendNotification(cid, QUEST_NAME, "Mission completed: All 50 cabbages recovered!", "#00FF00", "end")
        pcall(function()
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. QUEST_NAME)
        end)
    else
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
    end
end

local function formatReward(tier)
    local t = TIERS[tier]
    if not t then return "" end
    local parts = {}
    if t.exp > 0 then table.insert(parts, t.exp .. " experience") end
    if t.coins > 0 then table.insert(parts, t.coins .. " crystal coins") end
    if tier == #TIERS then table.insert(parts, "the Repolhudo title") end
    return table.concat(parts, " + ")
end

-- ============================================================
-- Callbacks
-- ============================================================
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    local name = getCreatureName(cid)
    local count = getCabbageCount(cid)

    if questCompleted(cid) then
        selfSay("Hello, " .. name .. "! All my cabbages are back thanks to you! Thank you so much, you are a hero to me!", cid)
    elseif questStarted(cid) then
        local nextTier = getNextTier(cid)
        if nextTier then
            selfSay("Hello, " .. name .. "! I see you already recovered " .. count .. " cabbages! I can give you a reward now! Say {reward} to receive it!", cid)
        else
            local nextMin = getNextTierMin(cid)
            selfSay("Hello, " .. name .. "! You already recovered " .. count .. " cabbages! You need " .. (nextMin - count) .. " more for the next reward. Keep looking for the cabbages scattered around the city!", cid)
        end
    else
        selfSay("Hello, " .. name .. "! Help! A heartless troublemaker stole all my cabbages and scattered them around the city! I grew those cabbages with so much care... Can you help me {recover} the cabbages?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local name = getCreatureName(cid)
    local count = getCabbageCount(cid)
    local completed = questCompleted(cid)
    local started = questStarted(cid)

    if talkState[talkUser] == 1 then
        -- Aceitar a quest
        if msgcontains(msg, "yes") or msgcontains(msg, "help") or msgcontains(msg, "recover") then
            if completed then
                selfSay("You already helped me with everything, " .. name .. "! All my cabbages are back. Thank you!", cid)
            elseif started then
                selfSay("You already started searching! Go and find the cabbages scattered around the city. Click them to register the pickup. When you have enough cabbages, come back and say {reward}!", cid)
            else
                selfSay("Thank you so much, " .. name .. "! Go around the city and click the cabbages lying on the ground. Every cabbage you find will be counted. Come back when you have recovered some and say {reward} to get your rewards!", cid)
                startQuest(cid)
            end

        -- Reclamar de repolhos / contexto
        elseif msgcontains(msg, "cabbage") or msgcontains(msg, "cabbages") or msgcontains(msg, "stolen") or msgcontains(msg, "troublemaker") or msgcontains(msg, "scattered") or msgcontains(msg, "city") or msgcontains(msg, "grew") then
            if completed then
                selfSay("Now all my cabbages are back! A troublemaker won't bring me down that easily!", cid)
            elseif started then
                selfSay("My cabbages are still scattered out there! You already recovered " .. count .. " of " .. TOTAL_CABBAGES .. ". Keep looking and click them when you find them!", cid)
            else
                selfSay("A heartless troublemaker stole all my cabbages and scattered them across the city! I grew those cabbages with so much care... Can you help me {recover} them?", cid)
            end

        -- Entregar reward
        elseif msgcontains(msg, "reward") or msgcontains(msg, "rewards") then
            if completed then
                selfSay("You already received all the rewards, " .. name .. "! Thank you for everything!", cid)
            elseif not started then
                selfSay("You haven't started helping me yet! Say {yes} if you want to start recovering my cabbages!", cid)
            else
                local nextTier = getNextTier(cid)
                if nextTier then
                    local rewardText = formatReward(nextTier)
                    claimReward(cid, nextTier)
                    selfSay("Incredible, " .. name .. "! You already recovered " .. getCabbageCount(cid) .. " cabbages! Here is your reward: " .. rewardText .. "!", cid)
                else
                    local nextMin = getNextTierMin(cid)
                    if nextMin then
                        selfSay("You haven't reached the next reward tier yet! You have " .. count .. " cabbages and you need " .. nextMin .. " for the next reward. Keep searching!", cid)
                    else
                        selfSay("You already received all available rewards, " .. name .. "! Thank you!", cid)
                    end
                end
            end

        else
            selfSay("I didn't understand. Are you talking about my {cabbages} that were {stolen}? Say {yes} to help me {recover} them, or {reward} to see your rewards!", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
