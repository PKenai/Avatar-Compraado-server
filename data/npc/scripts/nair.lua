-- Nair - Quest: matar 2000 Panteras Negras (quest id 38)
-- Storages: 49380 = status, 49381 = progresso
-- Recompensa: 200 platinum coins (2152) + 1.000.000 exp
-- Titulo: "Cacador Noturno" (conquista 35)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49380
local PROGRESS_STORAGE = 49381
local NEEDED = 2000
local REWARD_ITEM = 2152
local REWARD_COUNT = 200
local REWARD_EXP = 1000000
local QUEST_NAME = "A Pantera das Sombras"
local MISSION_NAME = "Caçar as Panteras Negras"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Nair\"'
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
    selfSay("Voce tem coragem de enfrentar as sombras? Preciso de um {caçador} noturno pra eliminar um predador perigoso.", cid)
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
                selfSay("Voce ja caçou todas as panteras negras! As sombras estao seguras novamente!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Incrivel! Voce caçou as 2000 panteras negras! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " panteras negras. Elas caçam a noite, va com cuidado!", cid)
                end
            else
                selfSay("As panteras negras estao caçando os animais da floresta e aterrorizando a vila. Mate 2000 delas e eu te pagarei como um verdadeiro {caçador} noturno!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "pantera") or msgcontains(msg, "negra") or msgcontains(msg, "sombra") or msgcontains(msg, "noite") or msgcontains(msg, "ajuda") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " panteras negras. Elas caçam a noite, va com cuidado!", cid)
            else
                selfSay("Eu sou a {Nair}! As panteras negras estao caçando os animais da floresta e aterrorizando a vila. Preciso de um caçador noturno pra elimina-las!", cid)
            end
        else
            selfSay("Nao entendi. Voce quer ser um {caçador} noturno?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui estao seus 200 platinum coins e 1 milhao de experiencia! Voce e o cacador noturno mais temido da floresta!", cid)
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
