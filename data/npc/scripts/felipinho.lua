-- Felipinho - Quest: Massacre da familia do Traidor
-- Story: um cara estranho roubou o dinheirinho do pirulito do Felipinho e,
-- quando ele tentou recuperar, o homem (muito forte) deu um soco na cara dele.
-- Felipinho pede ao jogador para MASSACRAR a familia desse homem (os
-- Traidores) e devolver o dinheiro: 100k de gold.
--
-- Storages (string, por player):
--   "felipinhoQuest"  = 0 (nao iniciou) / 1 (em andamento) / 2 (reward dada)
--   "felipinhoKills"  = quantidade de Traidores mortos (max 800)
--   (o contador e incrementado por data/creaturescripts/scripts/traidorDeath.lua)
--
-- Requisitos: level 155+ (o Set de um traidor exige level 155) e a mission so
-- pode ser feita UMA vez por player.
--
-- Reward: UMA peca do Set de um traidor (ids 13636-13640), escolhida pelo
-- jogador. Para completar: matar 800 Traidores + entregar 100k de gold.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 155
local MAX_KILLS = 800
local MONEY_REQUIRED = 100000

local QUEST_STORAGE = "felipinhoQuest"
local KILLS_STORAGE = "felipinhoKills"

-- storages do quest log (data/questSystem/quests.xml, quest id 21)
local QUEST_SYSTEM_STORAGE = 49210

local SET_PIECES = {
    { id = 13636, article = "the", name = "Traitor's helmet", palavras = {"helmet", "elmo", "capacete", "cap"} },
    { id = 13637, article = "the", name = "Traitor's armor",  palavras = {"armor", "armadura"} },
    { id = 13638, article = "the", name = "Traitor's pants",  palavras = {"pants", "calça", "calca", "calcas"} },
    { id = 13639, article = "the", name = "Traitor's boots",  palavras = {"boots", "boot", "bota", "botas"} },
    { id = 13640, article = "the", name = "Traitor's shield", palavras = {"shield", "escudo"} },
}

local function questCompleted(cid)
    return getPlayerStorageValue(cid, QUEST_STORAGE) == 2
end

local function questStarted(cid)
    return getPlayerStorageValue(cid, QUEST_STORAGE) == 1
end

local function killsCount(cid)
    return getPlayerStorageValue(cid, KILLS_STORAGE)
end

local function massacreDone(cid)
    return killsCount(cid) >= MAX_KILLS
end

local function remainingPhrase(cid)
    local n = MAX_KILLS - killsCount(cid)
    if n == 1 then
        return "1 Traitor left"
    end
    return n .. " Traitors left"
end


local function hasMoney(cid)
    return getPlayerMoney(cid) >= MONEY_REQUIRED
end

local function rewardReady(cid)
    return questStarted(cid) and massacreDone(cid) and hasMoney(cid)
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
        selfSay("Wow, you are very weak! That man punched me and almost knocked me down... only warriors of level 155 or higher can face his family.", cid)
        return true
    end
    talkState[cid] = 1
    local name = playerName(cid)

    if questCompleted(cid) then
        selfSay("Hello, " .. name .. "! Thank you so much for recovering my money. Now I can buy my lollipops in peace!", cid)
    elseif rewardReady(cid) then
        selfSay("Hello, " .. name .. "! You massacred the whole family and brought my money! While fleeing, I grabbed some equipment from the Traitors. Which piece do you want? {helmet}, {armor}, {pants}, {boots} or {shield}?", cid)
        talkState[cid] = 2
    elseif questStarted(cid) then
        if not massacreDone(cid) then
            selfSay("Hello, " .. name .. "! Still " .. remainingPhrase(cid) .. " for the massacre to be complete. And don't forget to bring my money!", cid)
        else
            selfSay("Hello, " .. name .. "! The massacre was a success! Now return my money: it's 100k gold.", cid)
        end
    else
        selfSay("Hello, " .. name .. "! A strange man stole my lollipop money! I tried to get it back, but he is very strong and punched me in the face... Want to massacre this man's family for me and recover my money?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Wow, you are still too weak to face his family. Come back with level 155 or higher!", cid)
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
                selfSay("You already helped me, " .. name .. "! My lollipop family thanks you.", cid)
            elseif ready then
                selfSay("Which piece of a Traitor's set do you want? {helmet}, {armor}, {pants}, {boots} or {shield}?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                if not massacreDone(cid) then
                    selfSay("You already accepted! Massacre " .. MAX_KILLS .. " Traitors and come back with my money. Don't forget the 100k!", cid)
                else
                    selfSay("The massacre is already complete! Now return my money: 100k gold.", cid)
                end
            else
                selfSay("Great! His family are the Traitors. Massacre " .. MAX_KILLS .. " of them, get my money back and bring it to me!", cid)
                setPlayerStorageValue(cid, QUEST_STORAGE, 1)
                setPlayerStorageValue(cid, KILLS_STORAGE, 0)
                setPlayerStorageValue(cid, QUEST_SYSTEM_STORAGE, 1)
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest: Massacre " .. MAX_KILLS .. " Traidores e recupere os 100k do Felipinho!")
            end
        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            if completed then
                selfSay("Alright, " .. name .. ". Thank you very much for everything!", cid)
            else
                selfSay("Understood, " .. name .. ". If you change your mind, come back here. That punch still hurts...", cid)
            end
        elseif msgcontains(msg, "traidor") or msgcontains(msg, "família") or msgcontains(msg, "dinheiro")
            or msgcontains(msg, "pirulito") or msgcontains(msg, "soco") then
            if completed then
                selfSay("You already helped me with his family, " .. name .. ". I don't need anything else!", cid)
            elseif ready then
                selfSay("You did it! Which piece of a Traitor's set do you want?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                if not massacreDone(cid) then
                    selfSay("His family are the Traitors! Still " .. remainingPhrase(cid) .. ". Massacre them all and bring my money.", cid)
                else
                    selfSay("The massacre is over! Now return my money: 100k gold.", cid)
                end
            else
                selfSay("A strange man stole my lollipop money and punched me in the face! Want to massacre his family and recover my money?", cid)
            end
        else
            selfSay("I didn't understand. Do you want to massacre the family of the man who stole my money?", cid)
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
                doPlayerRemoveMoney(cid, MONEY_REQUIRED)
                doPlayerAddItem(cid, chosen.id, 1)
                setPlayerStorageValue(cid, QUEST_STORAGE, 2)
                setPlayerStorageValue(cid, QUEST_SYSTEM_STORAGE, 2)
                selfSay("Here it is, " .. name .. "! " .. chosen.article .. " " .. chosen.name .. ". Use it well... and thank you for recovering my money!", cid)
                talkState[talkUser] = 1
            else
                selfSay("Calm down, " .. name .. "! First massacre the " .. MAX_KILLS .. " Traitors and bring my money: 100k gold.", cid)
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
