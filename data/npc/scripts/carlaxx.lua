-- Carla - Quest: matar 50 Baratas (quest id 39)
-- Historia: o templo da cidade esta sendo invadido por baratas e Carla precisa que voce extermina-las.
-- Storages (data/questSystem/quests.xml):
--   49390 = status da quest (1 = em andamento, 2 = completa)
--   49391 = kills acumulados (progresso)
-- Recompensa: 200 gold coins (2148)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49390
local PROGRESS_STORAGE = 49391
local NEEDED = 50
local REWARD_ITEM = 2148
local REWARD_COUNT = 200
local QUEST_NAME = "A Praga das Baratas"
local MISSION_NAME = "Exterminar baratas"

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
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Carla"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Carla] startQuest cid=" .. cid)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    local pos = getCreaturePosition(cid)
    if pos then
        doSendMagicEffect(pos, 199)
    end
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Carla] completeQuest cid=" .. cid)
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
    selfSay("Nossa, que nojo! O {templo} da cidade ta cheio de barata, eu to passando mal! Voce e forte, nao e? Me {ajuda} a limpar isso!", cid)
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
                selfSay("Voce ja resolveu o problema das baratas, obrigada mesmo! Nao sei o que eu faria sem voce.", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Eba! Voce matou todas as 50 baratas! Toma sua grana, voco merece!", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Faltam ainda " .. (NEEDED - progress) .. " baratas. Corre la no {templo} e mata essas praga!", cid)
                end
            else
                selfSay("Demais! Mata 50 baratas la no {templo} e volta aqui que eu te dou 200 gold! Bora!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "barata") or msgcontains(msg, "templo") or msgcontains(msg, "ajuda") or msgcontains(msg, "invasa") or msgcontains(msg, "praga") then
            if started and not completed then
                selfSay("Faltam ainda " .. (NEEDED - progress) .. " baratas. Corre la no {templo} e mata essas praga!", cid)
            else
                selfSay("O {templo} ta uma zona, cheio de barata por tudo! Mata 50 delas pra mim que eu te pago 200 gold. Topa?", cid)
            end
        else
            selfSay("To falando das {baratas} do {templo}! Ta cheio delas, quer me ajudar a limpar?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Toma, 200 gold coins! Voce e um craque, valeu demais pela ajuda!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Tranquilo, quando quiser vir pegar sua grana eu to aqui.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
