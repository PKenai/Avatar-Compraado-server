-- Lumina - Quest: matar 100 Besouros Luminosos (quest id 30)
-- Storages: 49300 = status, 49301 = progresso
-- Reward: 25 platinum coins (2152) + 50.000 exp
-- Title: "Exploradora da Caverna" (achievement 27)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49300
local PROGRESS_STORAGE = 49301
local NEEDED = 100
local REWARD_ITEM = 2152
local REWARD_COUNT = 25
local REWARD_EXP = 50000
local QUEST_NAME = "A Caverna de Lumina"
local MISSION_NAME = "Limpar a Caverna"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Lumina\"'
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
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. MISSION_NAME)
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
    selfSay("Ola! Voce tambem ve aquele brilho na caverna? Eu sou a {Lumina} e preciso de uma ajuda especial.", cid)
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
                selfSay("You already limpou a caverna! Thank you, agora posso estudar os besouros em paz.", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Incredible! Voce eliminou os 100 besouros! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Still need " .. (NEEDED - progress) .. " besouros luminosos. Cuidado, eles sao mais perigosos do que parecem!", cid)
                end
            else
                selfSay("Encontrei uma caverna cheia de besouros brilhantes, mas eles estao bloqueando a entrada! Voce pode me {ajudar} a limpar o caminho?", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "caverna") or msgcontains(msg, "besouro") or msgcontains(msg, "lumina") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " besouros luminosos. Cuidado, eles sao mais perigosos do que parecem!", cid)
            else
                selfSay("Eu sou a {Lumina}! Amo estudar insetos brilhantes, mas os besouros da caverna estao perigosos. Preciso que voce limpe a entrada pra mim!", cid)
            end
        else
            selfSay("I didn't understand. Voce quer saber sobre a {caverna}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Here are your 25 platinum coins e 50 mil experience. Voce agora e a Luz da Caverna!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Alright, come back when you want to receive your reward.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
