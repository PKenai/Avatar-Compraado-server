-- Nair - Quest: matar 2000 Panteras Negras (quest id 38)
-- Storages: 49380 = status, 49381 = progresso
-- Reward: 200 platinum coins (2152) + 1.000.000 exp
-- Title: "Cacador Noturno" (achievement 35)

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
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
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
    selfSay("Do you have the courage to face the shadows? I need a nocturnal {hunter} to eliminate a dangerous predator.", cid)
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
                selfSay("You already hunted all the black panthers! The shadows are safe again!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Incredible! You hunted the 2000 black panthers! Want your reward?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Still need " .. (NEEDED - progress) .. " black panthers. They hunt at night, be careful!", cid)
                end
            else
                selfSay("The black panthers are hunting the forest animals and terrorizing the village. Kill 2000 of them and I will pay you as a true nocturnal {hunter}!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "pantera") or msgcontains(msg, "negra") or msgcontains(msg, "sombra") or msgcontains(msg, "noite") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " black panthers. They hunt at night, be careful!", cid)
            else
                selfSay("I am {Nair}! The black panthers are hunting the forest animals and terrorizing the village. I need a nocturnal hunter to eliminate them!", cid)
            end
        else
            selfSay("I didn't understand. Do you want to be a nocturnal {hunter}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Here are your 200 platinum coins and 1 million experience! You're the most feared nocturnal hunter of the forest!", cid)
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
