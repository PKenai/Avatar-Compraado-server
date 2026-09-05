-- Haroldo - Quest: matar 2500 Livros de Dobras Proibidas (quest id 28)
-- Storages: 49280 = status, 49281 = progresso
-- Reward: 25 crystal coins (2152 = 250.000 gold)
-- Title: "Vigia dos Segredos" (achievement 25)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49280
local PROGRESS_STORAGE = 49281
local NEEDED = 2500
local REWARD_ITEM = 2152
local REWARD_COUNT = 25
local QUEST_NAME = "O Erro de Haroldo"
local MISSION_NAME = "Destruir Livros Proibidos"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Haroldo\"'
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
    selfSay("Parece que... voce pode me ver? Nao se assuste, eu sou apenas um {professor} que cometeu um grande erro.", cid)
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
                selfSay("You already derrotou os livros. Meu erro foi corrigido. Thank you.", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Os livros foram todos destruidos! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda restam " .. (NEEDED - progress) .. " livros. Cuidado, eles sao perigosos!", cid)
                end
            else
                selfSay("Esses livros ganharam vida propria e estao causando caos. Mate 2500 deles pra mim!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "livro") or msgcontains(msg, "erro") or msgcontains(msg, "proibido") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("Ainda restam " .. (NEEDED - progress) .. " livros. Cuidado, eles sao perigosos!", cid)
            else
                selfSay("Eu era um {professor} e estudei textos proibidos. Sem querer, eles ganharam vida. Preciso de ajuda para desfazer meu erro.", cid)
            end
        else
            selfSay("I didn't understand. Voce quer saber sobre meu {erro}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Here are your 25 crystal coins. Voce salvou muita gente do meu erro. Voce agora e um Vigia dos Segredos!", cid)
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
