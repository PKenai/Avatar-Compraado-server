-- Tong Lee - Quest: exterminar 300 Leoes de ba sin se (quest id 18)
-- Storages (data/questSystem/quests.xml):
--   49180 = status da quest (1 = em andamento, 2 = completa)
--   49181 = kills acumulados (progresso)
-- Recompensa: 100.000 de experiencia + 50 platinum coins (2152)
--            + 1x Armadura do Rugido (12810)
--
-- Historia: Tong Lee encontrou o santuario dos leoes, mas nao liga
-- para o santuario: ele tem muito medo dos leoes e so quer extermina-los.
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49180
local PROGRESS_STORAGE = 49181
local LIONS_NEEDED = 300
local REWARD_EXP = 100000
local REWARD_COIN = 2152
local REWARD_COIN_COUNT = 50
local REWARD_ARMOR = 12810
local QUEST_NAME = "Exterminio dos Leoes"
local MISSION_NAME = "Exterminar os Leoes"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questProgress(cid)
    local p = getPlayerStorageValue(cid, PROGRESS_STORAGE)
    if p < 0 then p = 0 end
    return math.min(p, LIONS_NEEDED)
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Tong Lee"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Tong Lee] startQuest cid=" .. cid)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Tong Lee] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missao concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
    selfSay("Ah, voce por aqui! Eu sou Tong Lee. Eu encontrei esse santuario dos leoes, mas quer saber? Eu nao estou nem ai para o santuario! Aqueles leoes me aterrorizam... Eu quero e {exterminar} todos eles!", cid)
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
        if completed then
            selfSay("Voce ja exterminou os leoes. Obrigado pela ajuda!", cid)
        elseif started then
            if progress >= LIONS_NEEDED then
                selfSay("Voce exterminou os 300 leoes! Quer receber sua recompensa?", cid)
                talkState[talkUser] = 2
            else
                selfSay("Ainda nao acabou! Faltam " .. (LIONS_NEEDED - progress) .. " leoes para eu poder dormir em paz.", cid)
            end
        elseif msgcontains(msg, "extermin") or msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            selfSay("Entao voce vai me ajudar?", cid)
            talkState[talkUser] = 3
        elseif msgcontains(msg, "santuario") or msgcontains(msg, "leao") or msgcontains(msg, "leoe") or msgcontains(msg, "medo") or msgcontains(msg, "ajuda") then
            selfSay("Eu achei esse {santuario} cheio de leoes, mas nao ligo para ele! O que eu quero e {exterminar} todos aqueles leoes. Quer me ajudar?", cid)
        else
            selfSay("Nao entendi. Esta falando do {santuario} dos leoes?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_COIN, REWARD_COIN_COUNT)
            doPlayerAddItem(cid, REWARD_ARMOR, 1)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui esta sua recompensa: 100.000 de experiencia, 50 platinum coins e a Armadura do Rugido. Agora posso viver em paz!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Tudo bem, volte quando quiser receber sua recompensa.", cid)
            talkState[talkUser] = 1
        end
    elseif talkState[talkUser] == 3 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            selfSay("Boa sorte! Va ate o santuario, mate 300 leoes de ba sin se e depois volte para mim!", cid)
            startQuest(cid)
            talkState[talkUser] = 1
        else
            selfSay("Tudo bem, se mudar de ideia e so me chamar.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
