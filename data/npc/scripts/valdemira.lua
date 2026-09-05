-- Valdemira - Quest: A Supplier (quest id 40)
-- Story: Valdemira e uma velha fazendeira que precisa de ham para
-- alimentar seus animais. O jogador deve entregar 150 hams e recebe
-- uma reward generosa experience.
--
-- Storages (data/questSystem/quests.xml):
--   49400 = status da quest (0 = nao iniciada, 1 = em andamento, 2 = completa)
--   49401 = ham entregues (0-150)
--
-- Requirement: level 200+
-- Delivery: 150 ham (item 2671)
-- Reward: 2.400.000 exp (200x a exp do Vacaceronte = 200 * 12000)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

-- ============================================================
-- Configuracao
-- ============================================================
local STATUS_STORAGE  = 49400   -- 0=nao iniciada, 1=em andamento, 2=completa
local COUNT_STORAGE   = 49401   -- ham entregues (0-150)

local HAM_ITEM        = 2671    -- ham
local REQUIRED_HAM    = 150
local REWARD_EXP      = 2400000 -- 200 * 12000 (exp do Vacaceronte)
local MIN_LEVEL       = 200

local QUEST_NAME   = "A Fornecadora"
local MISSION_NAME = "Entregar 150 Ham para Valdemira"

-- ============================================================
-- Funcoes auxiliares
-- ============================================================
local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function getHamCount(cid)
    local v = getPlayerStorageValue(cid, COUNT_STORAGE)
    if type(v) ~= "number" or v < 0 then return 0 end
    return v
end

local function getPlayerLevel(cid)
    local v = getCreatureLevel(cid)
    if type(v) ~= "number" then return 0 end
    return v
end

local function sendNotification(cid, title, message, color, soundType)
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Valdemira"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, COUNT_STORAGE, 0)
    print("[Valdemira] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    print("[Valdemira] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Mission completed: " .. MISSION_NAME .. "!", "#00FF00", "end")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
            "Mission completed: " .. QUEST_NAME .. "! Voce recebeu " .. REWARD_EXP .. " experience!")
    end)
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
    local level = getPlayerLevel(cid)

    -- Verificar level minimo
    if level < MIN_LEVEL then
        selfSay("Sorry, " .. name .. ". What I need is hard work. You're still too young to help me. Come back when you're level " .. MIN_LEVEL .. " or higher.", cid)
        return true
    end

    if questCompleted(cid) then
        selfSay("Hello, " .. name .. "! Thank you so much for all the hams! My animals are well fed thanks to you. You're a great ally!", cid)
    elseif questStarted(cid) then
        local count = getHamCount(cid)
        local remaining = REQUIRED_HAM - count
        if remaining <= 0 then
            selfSay("Hello, " .. name .. "! You brought all the hams! Deliver them to me now and receive your reward! Say {deliver}!", cid)
        else
            selfSay("Hello, " .. name .. "! You already brought " .. count .. " hams. Still need " .. remaining .. ". Bring the hams and say {deliver} when you have all of them!", cid)
        end
    else
        selfSay("Hello, " .. name .. "! I am Valdemira, the old farmer from the mountains. My animals are starving and I need lots of food. Can you bring me 150 hams? I promise a generous reward! Say {accept} if you want to help me!", cid)
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
    local level = getPlayerLevel(cid)
    local count = getHamCount(cid)
    local completed = questCompleted(cid)
    local started = questStarted(cid)

    -- Verificar level minimo
    if level < MIN_LEVEL then
        selfSay("You're still too young, " .. name .. ". Come back when you're level " .. MIN_LEVEL .. " or higher!", cid)
        return true
    end

    if talkState[talkUser] == 1 then
        -- Aceitar a quest
        if msgcontains(msg, "accept") or msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "help") or msgcontains(msg, "help") then
            if completed then
                selfSay("You already helped me with everything, " .. name .. "! All my animals are fed. Thank you!", cid)
            elseif started then
                selfSay("You already comecou a me ajudar! Traga os hams e diga {entregar} quando tiver todos os 150!", cid)
            else
                selfSay("Muito obrigada, " .. name .. "! Go hunt Vacacerontes and bring me 150 hams. When you have all of them, come back and say {deliver}!", cid)
                startQuest(cid)
            end

        -- Contexto da quest
        elseif msgcontains(msg, "ham") or msgcontains(msg, "food") or msgcontains(msg, "animal") or msgcontains(msg, "hunger") or msgcontains(msg, "vacaceronte") then
            if completed then
                selfSay("All my animals are well fed now! Thank you from the heart, " .. name .. "!", cid)
            elseif started then
                selfSay("You already brought " .. count .. " of " .. REQUIRED_HAM .. " hams. Keep hunting the Vacacerontes and bring the hams to me!", cid)
            else
                selfSay("My animals are starving! I need 150 hams to feed them. Can you help me? Say {accept}!", cid)
            end

        -- Entregar ham
        elseif msgcontains(msg, "deliver") or msgcontains(msg, "deliver") or msgcontains(msg, "bring") then
            if completed then
                selfSay("You already delivered everything, " .. name .. "! Thank you for everything!", cid)
            elseif not started then
                selfSay("You haven't started helping me yet! Say {accept} if you want to start!", cid)
            else
                local currentCount = getHamCount(cid)
                local playerHamCount = getPlayerItemCount(cid, HAM_ITEM)
                if playerHamCount > 0 then
                    doPlayerRemoveItem(cid, HAM_ITEM, playerHamCount)
                end
                local newCount = currentCount + playerHamCount
                if newCount > REQUIRED_HAM then
                    newCount = REQUIRED_HAM
                end
                setPlayerStorageValue(cid, COUNT_STORAGE, newCount)

                if newCount >= REQUIRED_HAM then
                    -- Tem todos os hams, entregar reward
                    deliverQuest(cid)
                    selfSay("AMAZING, " .. name .. "! You brought all the " .. REQUIRED_HAM .. " hams! Here is your reward: " .. REWARD_EXP .. " experience! You're a hero to me and my animals!", cid)
                else
                    local remaining = REQUIRED_HAM - newCount
                    selfSay("You delivered " .. playerHamCount .. " hams! Now you have " .. newCount .. " of " .. REQUIRED_HAM .. ". Still need " .. remaining .. ". Come back when you have more hams!", cid)
                    if playerHamCount > 0 then
                        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
                    end
                end
            end

        -- Verificar progresso
        elseif msgcontains(msg, "how much") or msgcontains(msg, "progress") or msgcontains(msg, "missing") then
            if completed then
                selfSay("You already completed the mission! All animals are fed!", cid)
            elseif started then
                local remaining = REQUIRED_HAM - count
                selfSay("You already brought " .. count .. " of " .. REQUIRED_HAM .. " hams. Still need " .. remaining .. ". Keep hunting!", cid)
            else
                selfSay("You haven't started yet! Say {accept} to start helping me!", cid)
            end

        else
            selfSay("I didn't understand. Are you talking about the {hams} for my {animals}? Say {accept} to start or {deliver} to deliver the hams!", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
