-- Silas - Quest: matar 1500 Conhecimentos Descontrolados (quest id 37)
-- Storages: 49370 = status, 49371 = progresso
-- Recompensa: 150 platinum coins (2152) + 750.000 exp
-- Titulo: "Mao de Ferro" (conquista 34)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49370
local PROGRESS_STORAGE = 49371
local NEEDED = 1500
local REWARD_ITEM = 2152
local REWARD_COUNT = 150
local REWARD_EXP = 750000
local QUEST_NAME = "O Conhecimento Proibido"
local MISSION_NAME = "Conter o Caos"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Silas\"'
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
    selfSay("Voce ve esses seres estranhos por ai? Sao {conhecimentos} que escaparam. Preciso de alguem com Mao de Ferro pra resolve isso.", cid)
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
                selfSay("Voce ja contein o caos! O conhecimento esta sob controle novamente!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Voce derrotou os 1500 conhecimentos descontrolados! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " conhecimentos descontrolados. Eles estao espalhados por toda parte!", cid)
                end
            else
                selfSay("Esses seres de conhecimento proibido estao causando caos. Mate 1500 deles e eu te pagarei como um verdadeiro combatente!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "conhecimento") or msgcontains(msg, "proibido") or msgcontains(msg, "caos") or msgcontains(msg, "ajuda") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " conhecimentos descontrolados. Eles estao espalhados por toda parte!", cid)
            else
                selfSay("Eu sou o {Silas}! Um conhecimento proibido escapou e esta criando seres descontrolados por toda parte. Preciso de ajuda pra conter o caos!", cid)
            end
        else
            selfSay("Nao entendi. Voce quer me {ajudar} a conter o caos?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui estao seus 150 platinum coins e 750 mil de experiencia! Voce agora e Mao de Ferro!", cid)
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
