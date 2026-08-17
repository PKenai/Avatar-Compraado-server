-- Aiano - Quest do Tesouro do Defensor da montanha
-- Historia: Aiano estava subindo a montanha quando encontrou um monstro enorme
-- e branco, o "Defensor da montanha", que nao deixaria ninguem tomar o tesouro
-- dele. Aiano convence o jogador a tentar roubar uma peca do tesouro.
-- Ao derrotar o Defensor e pegar o bau (action 50001), o jogador volta ao
-- Aiano e escolhe UMA peca do Set da Montanha.
--
-- Storages (string, por player):
--   "aianoQuest" = 0 (nao iniciou) / 1 (em andamento) / 2 (recompensa dada)
--   "aianoKill"  = 1 quando o player derrota o Defensor (defensorMontanha.lua)
--   "aianoChest" = 1 quando o player usa o bau 50001 (recompensa100k.lua)
--
-- Requisitos: level 120+ e a missao so pode ser feita UMA vez por player.
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
    { id = 13401, article = "o",     name = "capacete", palavras = {"capacete", "elmo", "cap"} },
    { id = 13402, article = "a",     name = "armadura", palavras = {"armadura"} },
    { id = 13403, article = "a",     name = "calca",    palavras = {"calca", "calcas"} },
    { id = 13404, article = "a",     name = "bota",     palavras = {"bota", "botas"} },
    { id = 13405, article = "o",     name = "escudo",   palavras = {"escudo"} },
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
        selfSay("Ainda nao e a sua hora, aventureiro. A montanha so aceita guerreiros de level 120 ou mais. Volte quando for mais forte!", cid)
        return true
    end
    talkState[cid] = 1
    local name = playerName(cid)

    if questCompleted(cid) then
        selfSay("Ola, " .. name .. "! Ja te entreguei uma peca do tesouro do guardiao. Nao tenho mais nada para oferecer.", cid)
    elseif rewardReady(cid) then
        selfSay("Ola, " .. name .. "! Enquanto eu corria daquele guardiao, consegui pegar algumas pecas de roupa de guerreiros que foram derrotados por ele. Voce teve coragem de ir la, entao merece algo. Qual peca do set da montanha voce quer? {capacete}, {armadura}, {calca}, {bota} ou {escudo}?", cid)
        talkState[cid] = 2
    elseif questStarted(cid) then
        selfSay("Ola, " .. name .. "! O guardiao e um monstro enorme e branco, o Defensor da montanha. Derrote-o e pegue o bau do tesouro dele!", cid)
    else
        selfSay("Ola, " .. name .. "! Eu estava subindo a montanha quando encontrei um monstro enorme e branco. Ele se apresentou como Defensor da montanha e disse que nao permitiria que eu tomasse o tesouro dele. Voce gostaria de tentar ir la roubar uma das pecas do tesouro?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Ainda nao e a sua hora, aventureiro. Volte quando tiver level 120 ou mais!", cid)
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
                selfSay("Voce ja recebeu sua peca do set da montanha, " .. name .. "! O guardiao nao me deixaria roubar outra.", cid)
            elseif ready then
                selfSay("Qual peca do set da montanha voce quer? {capacete}, {armadura}, {calca}, {bota} ou {escudo}?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                selfSay("Voce ja aceitou o desafio! Derrote o Defensor da montanha e pegue o bau do tesouro dele. Boa sorte!", cid)
            else
                selfSay("Otimo! O guardiao e um monstro enorme e branco chamado Defensor da montanha, e ele guarda o tesouro no topo da montanha. Derrote-o e pegue o bau do tesouro dele!", cid)
                setPlayerStorageValue(cid, QUEST_STORAGE, 1)
                setPlayerStorageValue(cid, QUEST_SYSTEM_STORAGE, 1)
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest: Roube uma peca do tesouro do Defensor da montanha!")
            end
        elseif msgcontains(msg, "nao") or msgcontains(msg, "no") then
            if completed then
                selfSay("Tudo bem, " .. name .. ". Obrigado por tudo!", cid)
            else
                selfSay("Entendido, " .. name .. ". Se mudar de ideia, volte a falar comigo.", cid)
            end
        elseif msgcontains(msg, "defensor") or msgcontains(msg, "montanha") or msgcontains(msg, "tesouro")
            or msgcontains(msg, "guardiao") or msgcontains(msg, "bau") or msgcontains(msg, "peca") then
            if completed then
                selfSay("Voce ja tem sua peca do set da montanha, " .. name .. ". Nao posso ajudar de novo.", cid)
            elseif ready then
                selfSay("Voce conseguiu! Enquanto eu corria, peguei pecas de roupa de guerreiros derrotados pelo guardiao. Qual peca do set da montanha voce quer?", cid)
                talkState[talkUser] = 2
            elseif questStarted(cid) then
                selfSay("O guardiao e um monstro enorme e branco, o Defensor da montanha. Derrote-o e pegue o bau do tesouro dele, " .. name .. "!", cid)
            else
                selfSay("Eu estava subindo a montanha quando encontrei um monstro enorme e branco. Ele se apresentou como Defensor da montanha e disse que nao permitiria que eu tomasse o tesouro dele. Voce gostaria de tentar ir la roubar uma das pecas do tesouro?", cid)
            end
        else
            selfSay("Nao entendi. Voce quer tentar roubar uma das pecas do tesouro do Defensor da montanha?", cid)
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
                selfSay("Aqui esta, " .. name .. "! " .. chosen.article .. " " .. chosen.name .. " da montanha. Que ele te proteja como protegeu o guardiao!", cid)
                talkState[talkUser] = 1
            else
                selfSay("Calma, " .. name .. "! Voce ainda nao trouxe o tesouro do Defensor da montanha. Derrote-o e pegue o bau primeiro!", cid)
                talkState[talkUser] = 1
            end
        else
            selfSay("Qual peca? {capacete}, {armadura}, {calca}, {bota} ou {escudo}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
