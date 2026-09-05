-- Joana - Quest: matar 150 ursos ferozes (quest id 24)
-- Story: os ursos ferozes estao tentando invadir a casa da Joana.
-- Storages (data/questSystem/quests.xml):
--   49240 = status da quest (1 = em andamento, 2 = completa)
--   49241 = kills acumulados (progresso)
-- Reward: redhot hat (12901)
-- Titulo "Abraca urso": achievement id 21 (achievementsLib.lua), desbloqueada
-- automaticamente ao matar 150 ursos ferozes (rastreio por kill no sistema
-- de achievements, mesmo padrao do "Alpinista").
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual;
-- a contagem de kills e feita pelo sistema de quests (questSystem.lua).

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49240
local PROGRESS_STORAGE = 49241
local URSOS_NEEDED = 150
local REWARD_ITEM = 12901
local REWARD_COUNT = 1
local QUEST_NAME = "Invasão dos Ursos"
local MISSION_NAME = "Eliminar ursos ferozes"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questProgress(cid)
    local p = getPlayerStorageValue(cid, PROGRESS_STORAGE)
    if p < 0 then p = 0 end
    return math.min(p, URSOS_NEEDED)
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Joana"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Joana] startQuest cid=" .. cid)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    local pos = getCreaturePosition(cid)
    if pos then
        doSendMagicEffect(pos, 199)
    end
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Joana] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Mission completed: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
    selfSay("Hello! These fierce bears are trying to invade my house and I can't take it anymore! Can you help me hunt them?", cid)
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
                selfSay("You already salvou a minha casa dos ursos. Thank you pela ajuda!", cid)
            elseif started then
                if progress >= URSOS_NEEDED then
                    selfSay("You hunted the 150 fierce bears! Want to receive your gift?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("It's not over yet! Still need " .. (URSOS_NEEDED - progress) .. " fierce bears to end this invasion.", cid)
                end
            else
                selfSay("Great! Go there, hunt 150 fierce bears and then come back here to receive your gift!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "urso") or msgcontains(msg, "invadir") or msgcontains(msg, "invasa") or msgcontains(msg, "home") or msgcontains(msg, "help") or msgcontains(msg, "caca") then
            if started and not completed then
                selfSay("It's not over yet! Still need " .. (URSOS_NEEDED - progress) .. " fierce bears to end this invasion.", cid)
            else
                selfSay("Yes, an {invasion}! The fierce bears are trying to invade my house and I can't take it anymore. Hunt 150 of them for me!", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about the fierce bears' {invasion}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Here is your gift! With 150 fierce bears defeated, you are now officially a {Bear Hugger}! Thank you for saving my house!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Alright, volte quando quiser receber seu presente.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
