-- Silas - Quest: matar 1500 Conhecimentos Descontrolados (quest id 37)
-- Storages: 49370 = status, 49371 = progresso
-- Reward: 150 platinum coins (2152) + 750.000 exp
-- Title: "Mao de Ferro" (achievement 34)

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
local QUEST_NAME = "The Forbidden Knowledge"
local MISSION_NAME = "Contain the Chaos"

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
    selfSay("Do you see those strange beings out there? They are {knowledge} that escaped. I need someone with an Iron Hand to sort this out.", cid)
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
                selfSay("You already contained the chaos! The knowledge is under control again!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("You defeated all 1500 uncontrolled knowledge beings! Do you want your reward?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("You still need " .. (NEEDED - progress) .. " uncontrolled knowledge beings. They are scattered everywhere!", cid)
                end
            else
                selfSay("Those forbidden knowledge beings are causing chaos. Kill 1500 of them and I will pay you like a true fighter!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "knowledge") or msgcontains(msg, "forbidden") or msgcontains(msg, "chaos") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " conhecimentos descontrolados. Eles estao espalhados por toda parte!", cid)
            else
                selfSay("I am {Silas}! A forbidden knowledge escaped and is creating uncontrolled beings everywhere. I need help to contain the chaos!", cid)
            end
        else
            selfSay("I didn't understand. Do you want to {help} me contain the chaos?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Here are your 150 platinum coins and 750,000 experience! You are now the Iron Hand!", cid)
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
