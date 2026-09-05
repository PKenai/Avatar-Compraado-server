-- John - Quest: entregar uma pena de pica-pau da terra (quest id 19)
-- Item: pena de pica-pau da terra (18873) - drop do monstro Pica-pau da terra
-- Reward: Saia de penas (18872)
-- Storages (data/questSystem/quests.xml):
--   49190 = status da quest (1 = em andamento, 2 = completa)
--
-- John so fala com jogadores de level 70 ou maior.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 70
local STATUS_STORAGE = 49190
local FEATHER_ITEM = 18873
local SKIRT_ITEM = 18872
local QUEST_NAME = "A Pena de John"
local MISSION_NAME = "Entregar a pena"

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function hasFeather(cid)
    return getPlayerItemCount(cid, FEATHER_ITEM) >= 1
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"John"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[John] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[John] completeQuest cid=" .. cid)
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
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("You shouldn't even be here, be careful, disappear!", cid)
        return true
    end
    talkState[cid] = 1
    if getPlayerStorageValue(cid, STATUS_STORAGE) < 1 then
        startQuest(cid)
    end
    selfSay("Hello! I'm John. My hobby is making clothing from animal items, and now I need a {feather} from an earth woodpecker. Can you get one for me?", cid)
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("You shouldn't even be here, be careful, disappear!", cid)
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    if talkState[talkUser] == 1 then
        if questCompleted(cid) then
            selfSay("Thanks for the feather! I already made the {skirt} with it. Enjoy!", cid)
        elseif msgcontains(msg, "pena") or msgcontains(msg, "saia") or msgcontains(msg, "deliver") or msgcontains(msg, "hobby") or msgcontains(msg, "pica-pau") or msgcontains(msg, "help") or msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            if hasFeather(cid) then
                doPlayerRemoveItem(cid, FEATHER_ITEM, 1)
                doPlayerAddItem(cid, SKIRT_ITEM, 1)
                completeQuest(cid)
                selfSay("What a beautiful feather! My hobby is making clothing from animal items, and with this feather I made this {skirt}. Here, I'm giving it to you as a gift, even though I think it doesn't match you very well!", cid)
            else
                selfSay("You don't have the feather yet! Go after an earth woodpecker and bring me a {feather} from an earth woodpecker.", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about the {feather} from an earth woodpecker?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
