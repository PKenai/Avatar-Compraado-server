-- Victor - Quest: matar 1000 Oncas (quest id 36)
-- Storages: 49360 = status, 49361 = progresso
-- Recompensa: 100 platinum coins (2152) + 500.000 exp
-- Titulo: "Cacador de Felinos" (conquista 33)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49360
local PROGRESS_STORAGE = 49361
local NEEDED = 1000
local REWARD_ITEM = 2152
local REWARD_COUNT = 100
local REWARD_EXP = 500000
local QUEST_NAME = "A Selva das Oncas"
local MISSION_NAME = "Caçar as Onças"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Victor\"'
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
    selfSay("Voce parece ser um {caçador} de verdade. Tenho um trabalho perigoso pra voce na selva. Interessado?", cid)
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
                selfSay("Voce ja caçou todas as oncas! A selva esta mais segura agora!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Incrivel! Voce caçou as 1000 oncas! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " oncas. Eas selva e perigosa, va com cuidado!", cid)
                end
            else
                selfSay("As oncas estao atacando os viajantes na selva. Mate 1000 delas e eu te recompensarei como um verdadeiro {caçador}!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "onca") or msgcontains(msg, "selva") or msgcontains(msg, "caçador") or msgcontains(msg, "ajuda") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " oncas. A selva e perigosa, va com cuidado!", cid)
            else
                selfSay("Eu sou o {Victor}! As oncas da selva estao ficando agressivas e atacando viajantes. Preciso de um caçador corajoso pra elimina-las.", cid)
            end
        else
            selfSay("Nao entendi. Voce quer aceitar o trabalho de {caçador}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui estao seus 100 platinum coins e 500 mil de experiencia! Voce e um cacador de felinos nato!", cid)
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
