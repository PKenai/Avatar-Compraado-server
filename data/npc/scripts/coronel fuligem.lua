-- Coronel Fuligem - Quest: matar 300 Abelhas Urubu (quest id 29)
-- Storages: 49290 = status, 49291 = progresso
-- Reward: 80 platinum coins (2152) + 160.000 exp
-- Title: "O Fuligem" (achievement 26)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49290
local PROGRESS_STORAGE = 49291
local NEEDED = 300
local REWARD_ITEM = 2152
local REWARD_COUNT = 80
local REWARD_EXP = 160000
local QUEST_NAME = "A Vinganca do Coronel"
local MISSION_NAME = "Caçar Abelhas Urubu"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Coronel Fuligem\"'
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
    selfSay("Solte os cachorros! Quer dizer... voce parece ser um {soldado} de confianca. Tenho uma missao dificil pra voce.", cid)
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
                selfSay("You already cumpriu a missao. Parabens, soldado!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Incredible! Voce eliminou as 300 abelhas urubu! Quer sua recompensa, soldado?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Still need " .. (NEEDED - progress) .. " abelhas urubu. Nao fraqueje, soldado!", cid)
                end
            else
                selfSay("Essas abelhas urubu dizimaram meu batalhao no deserto. Mate 300 delas e eu te recompensarei como um verdadeiro {soldado}!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "abelha") or msgcontains(msg, "urubu") or msgcontains(msg, "batalhao") or msgcontains(msg, "deserto") or msgcontains(msg, "missao") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " abelhas urubu. Nao fraqueje, soldado!", cid)
            else
                selfSay("Eu era o lider de um batalhao no deserto. Um enxame de abelhas urubu destruiu tudo. Preciso de {vinganca}!", cid)
            end
        else
            selfSay("I didn't understand. Voce quer aceitar a {missao}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Here are your 80 platinum coins e 160 mil experience. Voce e um verdadeiro guerreiro do deserto!", cid)
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
