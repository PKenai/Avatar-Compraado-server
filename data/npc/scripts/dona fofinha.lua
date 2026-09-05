-- Dona Fofinha - Quest: matar 150 Elefantes (quest id 31)
-- Storages: 49310 = status, 49311 = progresso
-- Reward: 70 platinum coins (2152) + 120.000 exp
-- Title: "Protetora da Horta" (achievement 28)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49310
local PROGRESS_STORAGE = 49311
local NEEDED = 150
local REWARD_ITEM = 2152
local REWARD_COUNT = 70
local REWARD_EXP = 120000
local QUEST_NAME = "A Horta da Dona Fofinha"
local MISSION_NAME = "Proteger a Hortela"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Dona Fofinha\"'
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
    selfSay("Ai, meu Deus! Voce parece ser forte! Preciso de ajuda com uns {elefantes} que estao acabando com minha horta!", cid)
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
                selfSay("You already salvou minha horta! Thank you, querido!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Wow! Voce eliminou os 150 elefantes! Minha horta esta salva! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Still need " .. (NEEDED - progress) .. " elefantes. Eles estao destruindo tudo, apressa!", cid)
                end
            else
                selfSay("Plantei uma horta enorme e esses elefantes estao passando por cima de tudo! Voce pode me {ajudar} a proteger minha horta?", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "elefante") or msgcontains(msg, "horta") or msgcontains(msg, "destrui") or msgcontains(msg, "help") then
            if started and not completed then
                selfSay("Still need " .. (NEEDED - progress) .. " elefantes. Eles estao destruindo tudo, apressa!", cid)
            else
                selfSay("Ai, minha {horta}! Esses elefantes grandes estao passando por cima de tudo que eu plantei! Me ajuda a espantar esses bichos?", cid)
            end
        else
            selfSay("I didn't understand. Voce quer me {ajudar} com os elefantes da horta?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Here are your 70 platinum coins e 120 mil experience! Voce agora e o Protetor da Hortela!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Alright, volte quando quiser receber sua recompensa, querido!", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
