-- Katata - Quest: recuperar a Colmeia de barro (quest id 17)
-- Storages (data/questSystem/quests.xml):
--   49170 = status da quest (1 = em andamento, 2 = completa)
--   49171 = progresso (1 = colmeia encontrada no bau; tambem e o storage
--           do "1x so" do bau da colmeia, actionid 49175)
-- Item: Colmeia de barro (18869)
-- Reward: 20 platinum coins (2152) + 40.000 de experiencia
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49170
local PROGRESS_STORAGE = 49171
local COLMEIA_ITEM = 18869
local REWARD_ITEM = 2152
local REWARD_COUNT = 20
local REWARD_EXP = 40000
local QUEST_NAME = "Katata's Honey"
local MISSION_NAME = "Recover the clay beehive"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function hasColmeia(cid)
    return getPlayerItemCount(cid, COLMEIA_ITEM) >= 1
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Katata"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Katata] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerRemoveItem(cid, COLMEIA_ITEM, 1)
    doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Katata] completeQuest cid=" .. cid)
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
    selfSay("Zzz... Ah! You there! I was sleeping and had my honey stolen... I'm sure it was the mud bees! Without my hive, I'll starve!", cid)
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

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            if completed then
                selfSay("You already brought my hive back. Thank you, now I can go back to eating honey!", cid)
            elseif hasColmeia(cid) then
                deliverQuest(cid)
                selfSay("You brought my hive back! Here is your reward: 20 platinum coins and 40,000 experience!", cid)
            elseif started then
                selfSay("I still don't have my hive! Go after the mud bees and recover it, or I'll starve!", cid)
            else
                selfSay("Great! Go to the mud bees' den and recover my hive!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "hive") or msgcontains(msg, "honey") or msgcontains(msg, "bee") or msgcontains(msg, "hunger") or msgcontains(msg, "help") then
            if hasColmeia(cid) then
                selfSay("You recovered my hive! Say you want to return it to receive your reward.", cid)
            elseif started then
                selfSay("My hive is still with the mud bees... Recover it, or I'll starve!", cid)
            else
                selfSay("The mud bees stole my honey while I was sleeping! Recover my hive for me, or I'll starve!", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about my {hive}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
