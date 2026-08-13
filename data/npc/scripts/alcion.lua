-- Alcion - Quest: matar 250 Tarântulas de pedra (quest id 15)
-- Storages (data/questSystem/quests.xml):
--   49150 = status da quest (1 = em andamento, 2 = completa)
--   49151 = kills acumulados (progresso)
-- Recompensa: 30 platinum coins (2152)
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49150
local PROGRESS_STORAGE = 49151
local TARANTULAS_NEEDED = 250
local REWARD_ITEM = 2152
local REWARD_COUNT = 30
local QUEST_NAME = "Caçada de Alcion"
local MISSION_NAME = "Eliminar Tarântulas"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questProgress(cid)
    local p = getPlayerStorageValue(cid, PROGRESS_STORAGE)
    if p < 0 then p = 0 end
    return math.min(p, TARANTULAS_NEEDED)
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Alcion"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Alcion] startQuest cid=" .. cid)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    sendNotification(cid, QUEST_NAME, "Nova missão: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Alcion] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missão concluída: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
    selfSay("Olá, vejo que você parece um dobrador procurando um {desafio}, gostaria de me mostrar sua força tentando exterminar aquelas tarântulas de pedra?", cid)
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
                selfSay("Você já completou essa missão. Obrigado pela ajuda!", cid)
            elseif started then
                if progress >= TARANTULAS_NEEDED then
                    selfSay("Você exterminou as 250 tarântulas de pedra! Quer receber sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda não acabou! Me prove o quão forte você é, faltam " .. (TARANTULAS_NEEDED - progress) .. " tarântulas de pedra.", cid)
                end
            else
                selfSay("Ótimo, vá lá e elimine 250 e me prove o quão forte você é!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "desafio") or msgcontains(msg, "quest") or msgcontains(msg, "tarantula") then
            if started and not completed then
                selfSay("Ainda não acabou! Me prove o quão forte você é, faltam " .. (TARANTULAS_NEEDED - progress) .. " tarântulas de pedra.", cid)
            else
                selfSay("Sim, um {desafio}! Gostaria de me mostrar sua força exterminando aquelas tarântulas de pedra?", cid)
            end
        else
            selfSay("Não entendi. Está procurando um {desafio}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Aqui está sua recompensa: 30 platinum coins. Você provou sua força!", cid)
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
