-- Astro - Quest: matar 150 Terra beetles (quest id 16)
-- Storages (data/questSystem/quests.xml):
--   49160 = status da quest (1 = em andamento, 2 = completa)
--   49161 = kills acumulados (progresso)
-- Reward: 10 platinum coins (2152)
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
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Astro] completeQuest cid=" .. cid)
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
    selfSay("Hello! There's an infestation of earth beetles in the sewer in front of my house... Can you help me exterminate these insects?", cid)
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
                selfSay("You already ended the infestation. Thank you for the help!", cid)
            elseif started then
                if progress >= BEETLES_NEEDED then
                    selfSay("You exterminated the 150 earth beetles! Want to receive your reward?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("It's not over yet! Still need " .. (BEETLES_NEEDED - progress) .. " earth beetles to end the infestation.", cid)
                end
            else
                selfSay("Great! Go to the sewer, kill 150 earth beetles and prove your courage!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "infesta") or msgcontains(msg, "bueiro") or msgcontains(msg, "terra") or msgcontains(msg, "beetle") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("It's not over yet! Still need " .. (BEETLES_NEEDED - progress) .. " earth beetles to end the infestation.", cid)
            else
                selfSay("Yes, an {infestation}! I need you to kill the 150 earth beetles in the sewer in front of my house.", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about the earth beetles' {infestation}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Here is your reward: 10 platinum coins. You saved my house!", cid)
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
