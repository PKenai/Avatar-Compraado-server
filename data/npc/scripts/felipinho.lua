-- Felipinho - Quest: Massacre da familia do Traidor
-- Historia: um cara estranho roubou o dinheirinho do pirulito do Felipinho e,
-- quando ele tentou recuperar, o homem (muito forte) deu um soco na cara dele.
-- Felipinho pede ao jogador para MASSACRAR a familia desse homem (os
-- Traidores) e devolver o dinheiro: 100k de gold.
--
-- Storages (string, por player):
--   "felipinhoQuest"  = 0 (nao iniciou) / 1 (em andamento) / 2 (recompensa dada)
--   "felipinhoKills"  = quantidade de Traidores mortos (max 800)
--   (o contador e incrementado por data/creaturescripts/scripts/traidorDeath.lua)
--
-- Requisitos: level 155+ (o Set de um traidor exige level 155) e a missao so
-- pode ser feita UMA vez por player.
--
-- Recompensa: UMA peca do Set de um traidor (ids 13636-13640), escolhida pelo
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
    { id = 13636, article = "o", name = "elmo",        palavras = {"elmo", "capacete", "cap"} },
    { id = 13637, article = "a", name = "armadura",    palavras = {"armadura"} },
    { id = 13638, article = "a", name = "calca",       palavras = {"calca", "calcas"} },
    { id = 13639, article = "a", name = "bota",        palavras = {"bota", "botas"} },
    { id = 13640, article = "o", name = "escudo",      palavras = {"escudo"} },
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
        return "falta 1 Traidor"
    end
    return "faltam " .. n .. " Traidores"
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
        selfSay("Nossa, voce e muito fraquinho! Aquele homem me deu um soco que quase me derrubou... so guerreiros de level 155 ou mais podem encarar a familia dele.", cid)
        return true
    end
    talkState[cid] = 1
    local name = playerName(cid)

    if questCompleted(cid) then
        selfSay("Ola, " .. name .. "! Muito obrigado por ter recuperado meu dinheiro. Agora posso comprar meus pirulitos em paz!", cid)
    elseif rewardReady(cid) then
        selfSay("Ola, " .. name .. "! Voce massacrou a familia toda e trouxe meu dinheiro! Enquanto fugia, peguei uns equipamentos dos Traidores. Qual peca voce quer? {elmo}, {armadura}, {calca}, {bota} ou {escudo}?", cid)
        talkState[cid] = 2
    elseif questStarted(cid) then
        if not massacreDone(cid) then
            selfSay("Ola, " .. name .. "! Ainda " .. remainingPhrase(cid) .. " para o massacre ficar completo. E nao esqueca de trazer meu dinheiro!", cid)
        else
            selfSay("Ola, " .. name .. "! O massacre foi um sucesso! Agora me devolva meu dinheiro: sao 100k de gold.", cid)
        end
    else
        selfSay("Ola, " .. name .. "! Um cara estranho roubou o dinheirinho do meu pirulito! Eu tentei pegar de volta, mas ele e muito forte e me deu um soco na cara... Quer massacrar a familia desse homem pra mim e recuperar meu dinheiro?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Nossa, voce ainda e muito fraquinho pra encarar a familia dele. Volte com level 155 ou mais!", cid)
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
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            if completed then
                selfSay("Voce ja me ajudou, " .. name .. "! Minha familia de pirulitos agradece.", cid)
            elseif ready then
                selfSay("Qual peca do set de um traidor voce quer? {elmo}, {armadura}, {calca}, {bota} ou {escudo}?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                if not massacreDone(cid) then
                    selfSay("Voce ja aceitou! Massacre " .. MAX_KILLS .. " Traidores e volte com meu dinheiro. Nao esqueca os 100k!", cid)
                else
                    selfSay("O massacre ja esta completo! Agora me devolva meu dinheiro: 100k de gold.", cid)
                end
            else
                selfSay("Otimo! A familia dele sao os Traidores. Massacre " .. MAX_KILLS .. " deles, pegue meu dinheiro de volta e traga pra mim!", cid)
                setPlayerStorageValue(cid, QUEST_STORAGE, 1)
                setPlayerStorageValue(cid, KILLS_STORAGE, 0)
                setPlayerStorageValue(cid, QUEST_SYSTEM_STORAGE, 1)
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest: Massacre " .. MAX_KILLS .. " Traidores e recupere os 100k do Felipinho!")
            end
        elseif msgcontains(msg, "nao") or msgcontains(msg, "no") then
            if completed then
                selfSay("Tudo bem, " .. name .. ". Muito obrigado por tudo!", cid)
            else
                selfSay("Entendido, " .. name .. ". Se mudar de ideia, volta aqui. Aquele soco ainda doi...", cid)
            end
        elseif msgcontains(msg, "traidor") or msgcontains(msg, "familia") or msgcontains(msg, "dinheiro")
            or msgcontains(msg, "pirulito") or msgcontains(msg, "soco") then
            if completed then
                selfSay("Voce ja me ajudou com a familia dele, " .. name .. ". Nao preciso de mais nada!", cid)
            elseif ready then
                selfSay("Voce conseguiu! Qual peca do set de um traidor voce quer?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                if not massacreDone(cid) then
                    selfSay("A familia dele sao os Traidores! Ainda " .. remainingPhrase(cid) .. ". Massacre todos e traga meu dinheiro.", cid)
                else
                    selfSay("O massacre acabou! Agora me devolva meu dinheiro: 100k de gold.", cid)
                end
            else
                selfSay("Um cara estranho roubou o dinheirinho do meu pirulito e me deu um soco na cara! Quer massacrar a familia dele e recuperar meu dinheiro?", cid)
            end
        else
            selfSay("Nao entendi. Quer massacrar a familia do homem que roubou meu dinheiro?", cid)
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
                selfSay("Aqui esta, " .. name .. "! " .. chosen.article .. " " .. chosen.name .. " de um traidor. Use bem... e obrigado por recuperar meu dinheiro!", cid)
                talkState[talkUser] = 1
            else
                selfSay("Calma, " .. name .. "! Primeiro massacre os " .. MAX_KILLS .. " Traidores e traga meu dinheiro: 100k de gold.", cid)
                talkState[talkUser] = 1
            end
        else
            selfSay("Qual peca? {elmo}, {armadura}, {calca}, {bota} ou {escudo}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
