-- Astro - Quest: matar 150 Terra beetles (quest id 16)
-- Storages (data/questSystem/quests.xml):
--   49160 = status da quest (1 = em andamento, 2 = completa)
--   49161 = kills acumulados (progresso)
-- Recompensa: 10 platinum coins (2152)
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49160
local PROGRESS_STORAGE = 49161
local BEETLES_NEEDED = 150
local REWARD_ITEM = 2152
local REWARD_COUNT = 10
local QUEST_NAME = "Infestação no Bueiro"
local MISSION_NAME = "Exterminar Terra beetles"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questProgress(cid)
    local p = getPlayerStorageValue(cid, PROGRESS_STORAGE)
    if p < 0 then p = 0 end
    return math.min(p, BEETLES_NEEDED)
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Astro"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Astro] startQuest cid=" .. cid)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    sendNotification(cid, QUEST_NAME, "Nova missão: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Astro] completeQuest cid=" .. cid)
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
    selfSay("Olá! Tem uma infestação de terra beetles no bueiro na frente da minha casa... Você pode me ajudar a exterminar esses insetos?", cid)
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
                selfSay("Você já acabou com a infestação. Obrigado pela ajuda!", cid)
            elseif started then
                if progress >= BEETLES_NEEDED then
                    selfSay("Você exterminou os 150 terra beetles! Quer receber sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda não acabou! Faltam " .. (BEETLES_NEEDED - progress) .. " terra beetles para acabar com a infestação.", cid)
                end
            else
                selfSay("Ótimo! Vá até o bueiro, mate 150 terra beetles e me prove sua coragem!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "infesta") or msgcontains(msg, "bueiro") or msgcontains(msg, "terra") or msgcontains(msg, "beetle") or msgcontains(msg, "ajuda") then
            if started and not completed then
                selfSay("Ainda não acabou! Faltam " .. (BEETLES_NEEDED - progress) .. " terra beetles para acabar com a infestação.", cid)
            else
                selfSay("Sim, uma {infestação}! Preciso que você mate os 150 terra beetles do bueiro na frente da minha casa.", cid)
            end
        else
            selfSay("Não entendi. Está falando da {infestação} de terra beetles?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Aqui está sua recompensa: 10 platinum coins. Você salvou minha casa!", cid)
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
