-- Valdemira - Quest: A Fornecadora (quest id 40)
-- Historia: Valdemira e uma velha fazendeira que precisa de ham para
-- alimentar seus animais. O jogador deve entregar 150 hams e recebe
-- uma recompensa generosa de experiencia.
--
-- Storages (data/questSystem/quests.xml):
--   49400 = status da quest (0 = nao iniciada, 1 = em andamento, 2 = completa)
--   49401 = ham entregues (0-150)
--
-- Requisito: level 200+
-- Entrega: 150 ham (item 2671)
-- Recompensa: 2.400.000 exp (200x a exp do Vacaceronte = 200 * 12000)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

-- ============================================================
-- Configuracao
-- ============================================================
local STATUS_STORAGE  = 49400   -- 0=nao iniciada, 1=em andamento, 2=completa
local COUNT_STORAGE   = 49401   -- ham entregues (0-150)

local HAM_ITEM        = 2671    -- ham
local REQUIRED_HAM    = 150
local REWARD_EXP      = 2400000 -- 200 * 12000 (exp do Vacaceronte)
local MIN_LEVEL       = 200

local QUEST_NAME   = "A Fornecadora"
local MISSION_NAME = "Entregar 150 Ham para Valdemira"

-- ============================================================
-- Funcoes auxiliares
-- ============================================================
local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function getHamCount(cid)
    local v = getPlayerStorageValue(cid, COUNT_STORAGE)
    if type(v) ~= "number" or v < 0 then return 0 end
    return v
end

local function getPlayerLevel(cid)
    local v = getCreatureLevel(cid)
    if type(v) ~= "number" then return 0 end
    return v
end

local function sendNotification(cid, title, message, color, soundType)
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Valdemira"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, COUNT_STORAGE, 0)
    print("[Valdemira] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    print("[Valdemira] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missao concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
            "Mission completed: " .. QUEST_NAME .. "! Voce recebeu " .. REWARD_EXP .. " de experiencia!")
    end)
end

-- ============================================================
-- Callbacks
-- ============================================================
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    local name = getCreatureName(cid)
    local level = getPlayerLevel(cid)

    -- Verificar level minimo
    if level < MIN_LEVEL then
        selfSay("Desculpe, " .. name .. ". O que eu preciso e trabalho pesado. Voce ainda e novo demais para me ajudar. Volte quando estiver level " .. MIN_LEVEL .. " ou mais.", cid)
        return true
    end

    if questCompleted(cid) then
        selfSay("Ola, " .. name .. "! Muito obrigada por todos os hams! Meus animais estao bem alimentados graças a voce. Voce e um grande aliado!", cid)
    elseif questStarted(cid) then
        local count = getHamCount(cid)
        local remaining = REQUIRED_HAM - count
        if remaining <= 0 then
            selfSay("Ola, " .. name .. "! Voce trouxe todos os hams! Entregue-os para mim agora e receba sua recompensa! Diga {entregar}!", cid)
        else
            selfSay("Ola, " .. name .. "! Voce ja trouxe " .. count .. " hams. Ainda faltam " .. remaining .. ". Traga os hams e diga {entregar} quando tiver todos!", cid)
        end
    else
        selfSay("Ola, " .. name .. "! Sou a Valdemira, a velha fazendeira das montanhas. Meus animais estao passando fome e preciso de muita comida. Voce pode me trazer 150 hams? Prometo uma recompensa generosa! Diga {aceitar} se quiser me ajudar!", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local name = getCreatureName(cid)
    local level = getPlayerLevel(cid)
    local count = getHamCount(cid)
    local completed = questCompleted(cid)
    local started = questStarted(cid)

    -- Verificar level minimo
    if level < MIN_LEVEL then
        selfSay("Voce ainda e novo demais, " .. name .. ". Volte quando estiver level " .. MIN_LEVEL .. " ou mais!", cid)
        return true
    end

    if talkState[talkUser] == 1 then
        -- Aceitar a quest
        if msgcontains(msg, "aceitar") or msgcontains(msg, "sim") or msgcontains(msg, "yes") or msgcontains(msg, "ajudar") or msgcontains(msg, "ajuda") then
            if completed then
                selfSay("Voce ja me ajudou com tudo, " .. name .. "! Todos os meus animais estao alimentados. Obrigada!", cid)
            elseif started then
                selfSay("Voce ja comecou a me ajudar! Traga os hams e diga {entregar} quando tiver todos os 150!", cid)
            else
                selfSay("Muito obrigada, " .. name .. "! Va caçar Vacacerontes e traga 150 hams para mim. Quando tiver todos, volte e diga {entregar}!", cid)
                startQuest(cid)
            end

        -- Contexto da quest
        elseif msgcontains(msg, "ham") or msgcontains(msg, "comida") or msgcontains(msg, "animal") or msgcontains(msg, "fome") or msgcontains(msg, "vacaceronte") then
            if completed then
                selfSay("Todos os meus animais estao bem alimentados agora! Obrigada de coracao, " .. name .. "!", cid)
            elseif started then
                selfSay("Voce ja trouxe " .. count .. " de " .. REQUIRED_HAM .. " hams. Continue caçando os Vacacerontes e traga os hams para mim!", cid)
            else
                selfSay("Meus animais estao passando fome! Preciso de 150 hams para alimenta-los. Voce pode me ajudar? Diga {aceitar}!", cid)
            end

        -- Entregar ham
        elseif msgcontains(msg, "entregar") or msgcontains(msg, "entrega") or msgcontains(msg, "trazer") then
            if completed then
                selfSay("Voce ja entregou tudo, " .. name .. "! Obrigada por tudo!", cid)
            elseif not started then
                selfSay("Voce ainda nao comecou a me ajudar! Diga {aceitar} se quiser comecar!", cid)
            else
                local currentCount = getHamCount(cid)
                local playerHamCount = getPlayerItemCount(cid, HAM_ITEM)
                if playerHamCount > 0 then
                    doPlayerRemoveItem(cid, HAM_ITEM, playerHamCount)
                end
                local newCount = currentCount + playerHamCount
                if newCount > REQUIRED_HAM then
                    newCount = REQUIRED_HAM
                end
                setPlayerStorageValue(cid, COUNT_STORAGE, newCount)

                if newCount >= REQUIRED_HAM then
                    -- Tem todos os hams, entregar recompensa
                    deliverQuest(cid)
                    selfSay("INCRAVEL, " .. name .. "! Voce trouxe todos os " .. REQUIRED_HAM .. " hams! Aqui esta sua recompensa: " .. REWARD_EXP .. " de experiencia! Voce e um heroi para mim e meus animais!", cid)
                else
                    local remaining = REQUIRED_HAM - newCount
                    selfSay("Voce entregou " .. playerHamCount .. " hams! Agora tem " .. newCount .. " de " .. REQUIRED_HAM .. ". Ainda faltam " .. remaining .. ". Volte quando tiver mais hams!", cid)
                    if playerHamCount > 0 then
                        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
                    end
                end
            end

        -- Verificar progresso
        elseif msgcontains(msg, "quanto") or msgcontains(msg, "progresso") or msgcontains(msg, "falta") then
            if completed then
                selfSay("Voce ja completou a missao! Todos os animais estao alimentados!", cid)
            elseif started then
                local remaining = REQUIRED_HAM - count
                selfSay("Voce ja trouxe " .. count .. " de " .. REQUIRED_HAM .. " hams. Ainda faltam " .. remaining .. ". Continue caçando!", cid)
            else
                selfSay("Voce ainda nao comecou! Diga {aceitar} para comecar a me ajudar!", cid)
            end

        else
            selfSay("Nao entendi. Voce esta falando dos {hams} para os meus {animais}? Diga {aceitar} para comecar ou {entregar} para entregar os hams!", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
