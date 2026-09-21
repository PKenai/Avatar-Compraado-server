-- Rogerio - Quest: As Fotos de Rogerio (quest id 20)
-- Story: Rogerio tira fotos das paisagens quando um Mordecasca da terra
-- rouba as fotos. O jogador recupera as fotos (drop condicional das
-- Mordecascas, so quando esta na quest) e devolve ao Rogerio.
-- Storages (data/questSystem/quests.xml):
--   49200 = status da quest (1 = em andamento, 2 = completa)
--   49201 = progresso (quantas fotos o jogador ja possui, 0-3)
--
-- Item: Foto (18877). O drop da foto e condicionado a quest e e feito pelo
-- evento RogerioLoot (data/creaturescripts/scripts/rogerioLoot.lua).
--
-- Rogerio so fala com jogadores de level 115 ou maior.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 115

local STATUS_STORAGE = 49200
local PROGRESS_STORAGE = 49201

local PHOTO_ITEM = 18877
local PHOTOS_NEEDED = 3

-- Recompensa (ajuste como quiser)
local REWARD_ITEM = 2152   -- platinum coin
local REWARD_COUNT = 100
local REWARD_EXP = 1000000

local QUEST_NAME = "Rogerio's Photos"
local MISSION_NAME = "Recover the stolen photos"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function photosCount(cid)
    return getPlayerItemCount(cid, PHOTO_ITEM)
end

local function hasEnoughPhotos(cid)
    return photosCount(cid) >= PHOTOS_NEEDED
end

-- Mantem o progresso do quest log (client: modules/game_quests) sincronizado
-- com as fotos que o jogador carrega no inventario.
local function syncProgress(cid)
    local current = math.min(photosCount(cid), PHOTOS_NEEDED)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, current)
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Rogerio"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    print("[Rogerio] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerRemoveItem(cid, PHOTO_ITEM, PHOTOS_NEEDED)
    doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, PHOTOS_NEEDED)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Rogerio] completeQuest cid=" .. cid)
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
        selfSay("It's not your time yet, adventurer. These landscapes can only be captured by those with the courage of level 115 or higher. Come back when you're stronger!", cid)
        return true
    end
    talkState[cid] = 1
    syncProgress(cid)

    if questCompleted(cid) then
        selfSay("Hello, " .. getCreatureName(cid) .. "! Thank you for recovering my photos. Now I can go back to shooting the landscapes in peace!", cid)
    elseif hasEnoughPhotos(cid) then
        selfSay("Hello, " .. getCreatureName(cid) .. "! I see you recovered my photos! Say you want to return them to receive your reward.", cid)
    elseif questStarted(cid) then
        selfSay("Hello, " .. getCreatureName(cid) .. "! I still don't have my photos... The Earth Mordecais took everything I had captured. Get them back for me!", cid)
    else
        selfSay("Hello, " .. getCreatureName(cid) .. "! I'm Rogerio, a landscape photographer. I was taking photos of the region when an Earth Mordecai appeared and stole all my photos! Can you help me recover them?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("It's not your time yet, adventurer. Come back when you're level 115 or higher!", cid)
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
                selfSay("You already returned my photos, " .. getCreatureName(cid) .. "! Thank you again, now I can go back to photographing the landscapes!", cid)
            elseif hasEnoughPhotos(cid) then
                deliverQuest(cid)
                selfSay("My photos! What a joy to see them back! Here is your reward: " .. REWARD_COUNT .. " platinum coins and " .. REWARD_EXP .. " experience. Thank you, " .. getCreatureName(cid) .. "!", cid)
            elseif started then
                selfSay("I still don't have my photos! Still need " .. (PHOTOS_NEEDED - photosCount(cid)) .. " to complete the album. Go after the Earth Mordecai and recover them!", cid)
            else
                selfSay("Great! The Earth Mordecais stole my photos while I was shooting the landscapes. Hunt them down and recover the " .. PHOTOS_NEEDED .. " photos they took!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "photo") or msgcontains(msg, "photos") or msgcontains(msg, "mordecai") or msgcontains(msg, "landscape") or msgcontains(msg, "stolen") or msgcontains(msg, "recover") or msgcontains(msg, "help") or msgcontains(msg, "album") then
            if hasEnoughPhotos(cid) then
                selfSay("You recovered my photos! Say you want to return them to receive your reward.", cid)
            elseif started then
                selfSay("I was taking photos of the landscapes when an Earth Mordecai showed up and stole everything! You still need " .. (PHOTOS_NEEDED - photosCount(cid)) .. " photos for me. Hunt the Earth Mordecais!", cid)
            else
                selfSay("I was taking photos of the landscapes when an Earth Mordecai showed up and stole all my photos! Will you help me get them back?", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about my {photos} that the Earth Mordecai stole?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
