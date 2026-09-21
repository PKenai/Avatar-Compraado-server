-- Rafinha - Quest: O Anel do Rafinha (quest id 25)
-- Story: Rafinha perdeu o anel do pai dentro do lago onde eles costumam
-- pescar e pede ajuda pra recupera-lo antes do pai voltar. O jogador usa a
-- vara de pescar (2580) no ponto do lago com actionid 49252 (5% de chance
-- de pescar o Anel de tubarao, 18880 - integrado no tools/fishing.lua) e
-- volta ate o Rafinha, que deixa o anel com o jogador.
-- Storages (data/questSystem/quests.xml):
--   49250 = status (1 = em andamento, 2 = anel pescado, 3 = completa)
--   49251 = progresso (1 = anel pescado; setado pelo fishing.lua)
-- Item: Anel de tubarao (18880) - fica com o jogador
-- Reward: 100.000 de experiencia + titulo "Pescador nato"
-- (achievement id 22, achievementsLib.lua)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 50
local STATUS_STORAGE = 49250
local PROGRESS_STORAGE = 49251
local FISHING_ROD = 2580
local REWARD_EXP = 100000
local QUEST_NAME = "Rafinha's Ring"
local MISSION_NAME = "Fish the ring out of the lake"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) == 1
end

local function ringCaught(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) == 2
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) == 3
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Rafinha"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    if getPlayerItemCount(cid, FISHING_ROD) < 1 then
        doPlayerAddItem(cid, FISHING_ROD, 1)
    end
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Rafinha] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 3)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    -- Titulo "Pescador nato": achievement id 22 (achievementsLib.lua), mesmo
    -- padrao manual do "Amigo dos animais" (desbloqueio via NPC).
    setPlayerStorageValue(cid, "achCreatureKill_22", 1)
    local ok = pcall(function()
        Achievements.check(cid, 22)
    end)
    if not ok then
        setPlayerStorageValue(cid, "achUnlocked_22", 1)            pcall(function()
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Achievement unlocked: You fished Rafinha's ring! Title: Born Fisher (open Achievements in the topbar to equip it).")
        end)
    end

    print("[Rafinha] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Mission completed: " .. MISSION_NAME .. "!", "#00FF00", "end")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. QUEST_NAME)
    end)
end

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Hello, I think I'll need help soon before my dad arrives!", cid)
        return true
    end
    talkState[cid] = 1
    local name = getCreatureName(cid)

    if questCompleted(cid) then
        selfSay("Hello, " .. name .. "! Thank you again for helping me with the ring! My dad loved the story I told him!", cid)
    elseif ringCaught(cid) then
        deliverQuest(cid)
        selfSay("Wow, this ring was mine a long time ago, it's not my dad's, but thank you anyway. I'll tell my dad what happened, but you can keep my shark ring, it used to be my favorite. Thank you for the help!", cid)
    elseif questStarted(cid) then
        selfSay("Hello, " .. name .. "! Have you already found my dad's ring in the lake? He's coming back soon and I can't go home without the ring...", cid)
    else
        selfSay("Hello, " .. name .. "! My dad and I used to fish in the lake nearby, but today I lost his ring in the water! He's coming back soon and I can't go home without the ring... Can you help me get the ring back before my dad returns?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("You're still too young for this adventure. Come back with level 50 or higher!", cid)
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local name = getCreatureName(cid)
    local completed = questCompleted(cid)
    local caught = ringCaught(cid)

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            if completed then
                selfSay("You already helped me, " .. name .. "! Thank you for everything!", cid)
            elseif caught then
                deliverQuest(cid)
                selfSay("Wow, this ring was mine a long time ago, it's not my dad's, but thank you anyway. I'll tell my dad what happened, but you can keep my shark ring, it used to be my favorite. Thank you for the help!", cid)
            elseif questStarted(cid) then
                selfSay("You already accepted! Use the fishing rod in the lake and try to find the ring. I will be waiting for you here!", cid)
            else
                selfSay("Thank you so much, " .. name .. "! Use this fishing rod in the lake and try to find the ring! I will be waiting for you here!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "ring") or msgcontains(msg, "lake") or msgcontains(msg, "dad")
            or msgcontains(msg, "fish") or msgcontains(msg, "help") or msgcontains(msg, "rod") then
            if completed then
                selfSay("Thank you for recovering the ring, " .. name .. "! It was a great adventure!", cid)
            elseif caught then
                selfSay("You caught the ring! Come back here to give it to me!", cid)
            elseif questStarted(cid) then
                selfSay("Use the fishing rod in the lake and try to find my dad's ring before he comes back!", cid)
            else
                selfSay("My dad and I used to fish in the lake nearby, and I lost his ring in the water! Can you help me get the ring back before my dad returns?", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about my dad's {ring} in the lake?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
