-- Carla - Quest: matar 50 Baratas (quest id 39)
-- Story: o templo da cidade esta sendo invadido por baratas e Carla precisa que voce extermina-las.
-- Storages (data/questSystem/quests.xml):
--   49390 = status da quest (1 = em andamento, 2 = completa)
--   49391 = kills acumulados (progresso)
-- Reward: 200 gold coins (2148)

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
local QUEST_NAME = "The Cockroach Plague"
local MISSION_NAME = "Exterminate the cockroaches"

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
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Carla] completeQuest cid=" .. cid)
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
    selfSay("Ugh, how disgusting! The city {temple} is full of cockroaches, I feel sick! You look strong, right? {Help} me clean this mess!", cid)
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
                selfSay("You already solved the cockroach problem, thank you so much! I don't know what I would do without you.", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Yay! You killed all 50 cockroaches! Here is your money, you deserve it!", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("You still need " .. (NEEDED - progress) .. " cockroaches. Run to the {temple} and kill those pests!", cid)
                end
            else
                selfSay("Great! Kill 50 cockroaches in the {temple} and come back here, I'll give you 200 gold coins!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "cockroach") or msgcontains(msg, "temple") or msgcontains(msg, "help") or msgcontains(msg, "infestation") or msgcontains(msg, "plague") then
            if started and not completed then
                selfSay("Faltam ainda " .. (NEEDED - progress) .. " baratas. Corre la no {templo} e mata essas praga!", cid)
            else
                selfSay("The {temple} is a mess, cockroaches everywhere! Kill 50 of them for me and I'll pay you 200 gold. Deal?", cid)
            end
        else
            selfSay("I'm talking about the {cockroaches} in the {temple}! They are all over the place, will you help me clean it up?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Here, 200 gold coins! You are the best, thanks a lot for the help!", cid)
            talkState[talkUser] = 1
        else
            selfSay("No problem, come back whenever you want to pick up your money.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
