-- Olavo - Quest: Passaro do Olavo (quest id 41)
-- Historia: O passaro do Olavo fugiu e ele quer saber onde esta.
-- O jogador encontra o passaro, fala "oeste" com ele, volta ao Olavo
-- e diz "oeste" pra completar a quest e ganhar acesso a alavanca secreta.
-- Storages:
--   49410 = status da quest (0 = nao iniciada, 1 = em andamento / passaro encontrado,
--           2 = completa / recompensa entregue)
--   49411 = passaro encontrado (1 = sim)
-- Recompensa: 10 platinum coins (2152) + 10000 experiencia

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49410
local BIRD_FOUND_STORAGE = 49411
local REWARD_COINS = 2152
local REWARD_COIN_COUNT = 10
local REWARD_EXP = 10000
local QUEST_NAME = "Passaro do Olavo"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function birdFound(cid)
    return getPlayerStorageValue(cid, BIRD_FOUND_STORAGE) >= 1
end

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    if questCompleted(cid) then
        selfSay("Ola, " .. getCreatureName(cid) .. "! Obrigado por ter encontrado meu passaro. A alavanca continua la, se quiser usar!", cid)
    elseif birdFound(cid) then
        selfSay("Voce encontrou meu passaro?! Onde ele foi? Me diga {oeste} ou {leste}!", cid)
    elseif questStarted(cid) then
        selfSay("Voce ainda nao encontrou meu passaro? Procure por ai, ele deve estar perto! Fale com ele e descubra pra onde foi.", cid)
    else
        selfSay("Ola, " .. getCreatureName(cid) .. "! Meu passaro fugiu e eu nao sei onde ele esta. Voce poderia me ajudar a encontrar? Ele nao anda muito longe...", cid)
    end
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
    local found = birdFound(cid)

    if talkState[talkUser] == 1 then
        if completed then
            selfSay("Obrigado de novo, " .. getCreatureName(cid) .. "! A alavanca continua la se quiser explorar o segredo!", cid)
        elseif msgcontains(msg, "sim") or msgcontains(msg, "ajudar") or msgcontains(msg, "ajuda") or msgcontains(msg, "procurar") then
            if found then
                selfSay("Voce encontrou meu passaro! Onde ele foi? Fale {oeste} ou {leste}!", cid)
            elseif started then
                selfSay("Continue procurando! Fale com o passaro pra descobrir pra onde ele foi, e depois volte e me diga!", cid)
            else
                selfSay("Muito obrigado, " .. getCreatureName(cid) .. "! Meu passaro fugiu, deve estar por perto. Encontre ele, fale com ele pra saber onde foi, e depois volte e me diga!", cid)
                setPlayerStorageValue(cid, STATUS_STORAGE, 1)
                setPlayerStorageValue(cid, BIRD_FOUND_STORAGE, 0)
                print("[Olavo] startQuest cid=" .. cid)
            end
        elseif msgcontains(msg, "oeste") then
            if completed then
                selfSay("Voce ja completou a quest! Obrigado por tudo!", cid)
            elseif found then
                -- Completou a quest!
                doPlayerAddItem(cid, REWARD_COINS, REWARD_COIN_COUNT)
                doPlayerAddExperience(cid, REWARD_EXP)
                setPlayerStorageValue(cid, STATUS_STORAGE, 2)
                doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
                print("[Olavo] completeQuest cid=" .. cid)
                selfSay("Oeste! Ah, entao ele foi pra oeste! Muito obrigado, " .. getCreatureName(cid) .. "! Voce me salvou! Tenho um segredo pra te contar... Existe uma alavanca escondida nessa ilha, mas voce tera que procurar por si mesmo. Dizem que quando essa alavanca e mexida, um local secreto se abre. Va la e descubra!", cid)
            else
                selfSay("Oeste? Hmm, voce ainda nao encontrou meu passaro. Va falar com ele primeiro pra saber pra onde ele foi!", cid)
            end
        elseif msgcontains(msg, "leste") then
            if completed then
                selfSay("Voce ja completou a quest! Obrigado por tudo!", cid)
            elseif found then
                selfSay("Leste? Hmm... meu passaro nao gosta de frio. Tem certeza que ele foi pro leste? Tente falar com ele de novo!", cid)
            else
                selfSay("Leste? Hmm, voce ainda nao encontrou meu passaro. Va falar com ele primeiro!", cid)
            end
        elseif msgcontains(msg, "passaro") or msgcontains(msg, "alavanca") or msgcontains(msg, "secreto") then
            if completed then
                selfSay("A alavanca continua la! Va la e descubra o segredo!", cid)
            elseif found then
                selfSay("Voce encontrou o passaro! Agora me diga: ele foi {oeste} ou {leste}?", cid)
            elseif started then
                selfSay("Procure meu passaro por ai! Fale com ele pra saber praonde foi!", cid)
            else
                selfSay("Meu passaro fugiu! Voce pode me ajudar a encontrar? Procure por ai, ele nao vai longe!", cid)
            end
        else
            selfSay("Nao entendi. Voce esta falando do meu {passaro}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
