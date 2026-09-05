-- Coral - Quest: matar 200 Carangueijos Ermitaos (quest id 33)
-- Storages: 49330 = status, 49331 = progresso
-- Reward: 60 platinum coins (2152) + 140.000 exp
-- Title: "Resgatador de Conchas" (achievement 30)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49330
local PROGRESS_STORAGE = 49331
local NEEDED = 200
local REWARD_ITEM = 2152
local REWARD_COUNT = 60
local REWARD_EXP = 140000
local QUEST_NAME = "A Praia da Coral"
local MISSION_NAME = "Proteger os Carangueijos"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questProgress(cid)
    local p = getPlayerStorageValue(cid, PROGRESS_STORAGE)
    if p < 0 then p = 0 end
    return math.min(p, NEEDED)
end

local function sendNotification(cid, title, message, color, soundType)
    local payload = '{\"title\":\"' .. title .. '\",\"message\":\"' .. message ..
        '\",\"color\":\"' .. color .. '\",\"duration\":5000'
    if soundType then
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Coral\"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
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
    talkState[cid] = 1
    selfSay("Ola! Voce gosta de carangueijos? Porque eu adoro! Mas uns {ermitaos} perigosos estao incomodando os mansos da praia.", cid)
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local started = questStarted(cid)
    local completed = questCompleted(cid)
    local progress = questProgress(cid)

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            if completed then
                selfSay("You already salvou os carangueijos! Thank you, voce e meu heroi da praia!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Incredible! Voce eliminou os 200 carangueijos ermitaos! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Still need " .. (NEEDED - progress) .. " carangueijos ermitaos. Eles estao bravos nas rochas!", cid)
                end
            else
                selfSay("Eu encontrei um carangueijo ermitao de casca dourada na praia! Mas os ermitaos perigosos estao atacando os mansos. Voce pode me {ajudar} a proteger os carangueijos mansos?", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "carangueijo") or msgcontains(msg, "ermitao") or msgcontains(msg, "praia") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " carangueijos ermitaos. Eles estao bravos nas rochas!", cid)
            else
                selfSay("Eu sou a {Coral}! Amo carangueijos, mas os ermitaos perigosos estao atacando os mansos na praia. Voce pode me ajudar a proteger eles?", cid)
            end
        else
            selfSay("I didn't understand. Voce quer me {ajudar} com os carangueijos?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Here are your 60 platinum coins e 140 mil experience! Voce agora e o Coletor de Conchas!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Alright, volte quando quiser receber sua recompensa!", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
