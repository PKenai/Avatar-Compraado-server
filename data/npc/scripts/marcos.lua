-- Marcos - Quest: matar 150 Hippos (quest id 35)
-- Storages: 49350 = status, 49351 = progresso
-- Recompensa: 50 platinum coins (2152) + 100.000 exp
-- Titulo: "Domador de Hipos" (conquista 32)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49350
local PROGRESS_STORAGE = 49351
local NEEDED = 150
local REWARD_ITEM = 2152
local REWARD_COUNT = 50
local REWARD_EXP = 100000
local QUEST_NAME = "O Rio dos Hipos"
local MISSION_NAME = "Conter os Hipos"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Marcos\"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    sendNotification(cid, QUEST_NAME, "Missao concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
    selfSay("Ei, voce parece ser um cara que sabe lidar com animais grandes. Preciso de ajuda com uns {hipos} que estao vagueando pelo rio.", cid)
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
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            if completed then
                selfSay("Voce ja controlou os hipos! O rio esta seguro novamente!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Voce derrotou os 150 hipos! O rio esta limpo! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " hipos. Eles estao espalhados pelo rio, cuidado!", cid)
                end
            else
                selfSay("Esses hipos estao espalhados pelo rio e atacam quem tenta atravessar. Mate 150 deles pra mim!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "hipo") or msgcontains(msg, "rio") or msgcontains(msg, "ajuda") or msgcontains(msg, "animal") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " hipos. Eles estao espalhados pelo rio, cuidado!", cid)
            else
                selfSay("Eu sou o {Marcos}! Cuido do rio da vila, mas uns hipos invadiram e estao atacando todos que tentam passar. Voce pode me ajudar?", cid)
            end
        else
            selfSay("Nao entendi. Voce quer me {ajudar} com os hipos do rio?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui estao seus 50 platinum coins e 100 mil de experiencia! Voce agora e o Domador de Hipos!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Tudo bem, volte quando quiser receber sua recompensa.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
