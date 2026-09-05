-- Carlos - Quest: matar 200 Centopeias Carapaca de Aco (quest id 27)
-- Storages: 49270 = status, 49271 = progresso
-- Reward: 50 platinum coins (2152)
-- Title: "Forjador de Aco" (achievement 24)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49270
local PROGRESS_STORAGE = 49271
local NEEDED = 200
local REWARD_ITEM = 2152
local REWARD_COUNT = 50
local QUEST_NAME = "A Carapaca de Carlos"
local MISSION_NAME = "Recolher Carapacas de Aco"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Carlos\"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
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
    selfSay("Hey, you seem like a tough guy. I need help with some {centipedes} that are getting in the way of my work.", cid)
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
                selfSay("You already helped me with the centipedes. Thanks, partner!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Nice! You defeated the 200 centipedes! Want your reward?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Still need " .. (NEEDED - progress) .. " centipedes. Go out there and bring me those carapaces!", cid)
                end
            else
                selfSay("Alright! Go out there and bring me 200 steel carapaces from those centipedes. I need them to forge some armor.", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "centopeia") or msgcontains(msg, "carapaca") or msgcontains(msg, "help") or msgcontains(msg, "desafio") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " centipedes. Go out there and bring me those carapaces!", cid)
            else
                selfSay("I need steel carapaces from centipedes for my forge. Want to {help} me?", cid)
            end
        else
            selfSay("I didn't understand. Do you want to {help} me with the centipedes?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Here are your 50 platinum coins. You're a true steel forger!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Alright, volte quando quiser pegar sua recompensa.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
