-- Aiano - Quest do Tesouro do Defensor da montanha
-- Story: Aiano estava subindo a montanha quando encontrou um monstro enorme
-- e branco, o "Defensor da montanha", que nao deixaria ninguem tomar o tesouro
-- dele. Aiano convence o jogador a tentar roubar uma peca do tesouro.
-- Ao derrotar o Defensor e pegar o bau (action 50001), o jogador volta ao
-- Aiano e escolhe UMA peca do Set da Montanha.
--
-- Storages (string, por player):
--   "aianoQuest" = 0 (nao iniciou) / 1 (em andamento) / 2 (reward dada)
--   "aianoKill"  = 1 quando o player derrota o Defensor (defensorMontanha.lua)
--   "aianoChest" = 1 quando o player usa o bau 50001 (reward100k.lua)
--
-- Requisitos: level 120+ e a mission so pode ser feita UMA vez por player.
-- O NPC e carregado automaticamente pelo nome (data/npc/Aiano.xml) quando o
-- spawn dele e colocado no mapa.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 120

local QUEST_STORAGE = "aianoQuest"
local KILL_STORAGE = "aianoKill"
local CHEST_STORAGE = "aianoChest"

-- storages do quest log (data/questSystem/quests.xml, quest id 22)
local QUEST_SYSTEM_STORAGE = 49220

local SET_PIECES = {
    { id = 13401, article = "the", name = "mountain helmet", palavras = {"helmet", "elmo", "capacete", "cap"} },
    { id = 13402, article = "the", name = "mountain armor",  palavras = {"armor", "armadura"} },
    { id = 13403, article = "the", name = "mountain pants",  palavras = {"pants", "calça", "calca", "calcas"} },
    { id = 13404, article = "the", name = "mountain boots",  palavras = {"boots", "boot", "bota", "botas"} },
    { id = 13405, article = "the", name = "mountain shield", palavras = {"shield", "escudo"} },
}

local function questCompleted(cid)
    return getPlayerStorageValue(cid, QUEST_STORAGE) == 2
end

local function questStarted(cid)
    return getPlayerStorageValue(cid, QUEST_STORAGE) == 1
end

local function killedDefensor(cid)
    return getPlayerStorageValue(cid, KILL_STORAGE) == 1
end

local function grabbedChest(cid)
    return getPlayerStorageValue(cid, CHEST_STORAGE) == 1
end

local function rewardReady(cid)
    return questStarted(cid) and killedDefensor(cid) and grabbedChest(cid)
end

local function playerName(cid)
    return getCreatureName(cid)
end

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("It's not your time yet, adventurer. The mountain only accepts warriors of level 120 or higher. Come back when you're stronger!", cid)
        return true
    end
    talkState[cid] = 1
    local name = playerName(cid)

    if questCompleted(cid) then
        selfSay("Hello, " .. name .. "! I already gave you a piece of the guardian's treasure. I have nothing else to offer.", cid)
    elseif rewardReady(cid) then
        selfSay("Hello, " .. name .. "! While fleeing from that guardian, I managed to grab some clothing from warriors defeated by him. You had the courage to go there, so you deserve something. Which piece of the mountain set do you want? {helmet}, {armor}, {pants}, {boots} or {shield}?", cid)
        talkState[cid] = 2
    elseif questStarted(cid) then
        selfSay("Hello, " .. name .. "! The guardian is a huge white monster, the Mountain Defender. Defeat it and take its treasure chest!", cid)
    else
        selfSay("Hello, " .. name .. "! I was climbing the mountain when I found a huge white monster. He introduced himself as the Mountain Defender and said he would not allow me to take his treasure. Would you like to try to go there and steal one of the treasure pieces?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("It's not your time yet, adventurer. Come back when you're level 120 or higher!", cid)
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end
    local name = playerName(cid)
    local completed = questCompleted(cid)
    local ready = rewardReady(cid)

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
            if completed then
                selfSay("You already received your piece of the mountain set, " .. name .. "! The guardian wouldn't let me steal another.", cid)
            elseif ready then
                selfSay("Which piece of the mountain set do you want? {helmet}, {armor}, {pants}, {boots} or {shield}?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                selfSay("You already accepted the challenge! Defeat the Mountain Defender and take its treasure chest. Good luck!", cid)
            else
                selfSay("Great! The guardian is a huge white monster called the Mountain Defender, and he guards the treasure at the top of the mountain. Defeat it and take its treasure chest!", cid)
                setPlayerStorageValue(cid, QUEST_STORAGE, 1)
                setPlayerStorageValue(cid, QUEST_SYSTEM_STORAGE, 1)
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest: Steal a piece of the Mountain Defender's treasure!")
            end
        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            if completed then
                selfSay("Alright, " .. name .. ". Thank you for everything!", cid)
            else
                selfSay("Understood, " .. name .. ". If you change your mind, come talk to me again.", cid)
            end
        elseif msgcontains(msg, "defensor") or msgcontains(msg, "montanha") or msgcontains(msg, "tesouro")
            or msgcontains(msg, "guardião") or msgcontains(msg, "baú") or msgcontains(msg, "peça") then
            if completed then
                selfSay("You already have your piece of the mountain set, " .. name .. ". I can't help again.", cid)
            elseif ready then
                selfSay("You did it! While fleeing, I grabbed pieces of clothing from warriors defeated by the guardian. Which piece of the mountain set do you want?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                selfSay("The guardian is a huge white monster, the Mountain Defender. Defeat it and take its treasure chest, " .. name .. "!", cid)
            else
                selfSay("I was climbing the mountain when I found a huge white monster. He introduced himself as the Mountain Defender and said he would not allow me to take his treasure. Would you like to try to go there and steal one of the treasure pieces?", cid)
            end
        else
            selfSay("I didn't understand. Do you want to try to steal one of the Mountain Defender's treasure pieces?", cid)
        end
    elseif talkState[talkUser] == 2 then
        local chosen = nil
        for _, piece in ipairs(SET_PIECES) do
            local match = false
            for _, palavra in ipairs(piece.palavras) do
                if msgcontains(msg, palavra) then
                    match = true
                    break
                end
            end
            if match then
                chosen = piece
                break
            end
        end

        if chosen then
            if ready then
                doPlayerAddItem(cid, chosen.id, 1)
                setPlayerStorageValue(cid, QUEST_STORAGE, 2)
                setPlayerStorageValue(cid, QUEST_SYSTEM_STORAGE, 2)
                selfSay("Here it is, " .. name .. "! " .. chosen.article .. " " .. chosen.name .. ". May it protect you as it protected the guardian!", cid)
                talkState[talkUser] = 1
            else
                selfSay("Calm down, " .. name .. "! You still haven't brought the Mountain Defender's treasure. Defeat it and take the chest first!", cid)
                talkState[talkUser] = 1
            end
        else
            selfSay("Which piece? {helmet}, {armor}, {pants}, {boots} or {shield}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
