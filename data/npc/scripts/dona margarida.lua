-- Dona Margarida - Quest: O Coelho da Margarida (quest id 23)
-- Historia: o coelho dela fugiu de medo e entrou na toca das aranhas
-- cospe pedra. O jogador encontra o Coelho da Margarida la dentro, diz
-- {resgatar} e volta pra Dona Margarida para receber a recompensa.
-- Storages (data/questSystem/quests.xml):
--   49230 = status da quest (1 = em andamento, 2 = coelho resgatado,
--           3 = completa / recompensa entregue)
--   49231 = progresso (1 = coelho resgatado; setado pelo NPC Coelho)
-- Item: Filhote de coelho (18879)
-- Recompensa: 1 Filhote de coelho + 20 platinum coins (2152) + 50.000 de
-- experiencia + titulo "Amigo dos animais" (conquista id 20,
-- achievementsLib.lua, desbloqueada aqui ao entregar a recompensa)
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49230
local PROGRESS_STORAGE = 49231
local REWARD_ITEM = 18879      -- Filhote de coelho
local REWARD_COINS = 2152      -- platinum coin
local REWARD_COIN_COUNT = 20
local REWARD_EXP = 50000
local QUEST_NAME = "O Coelho da Margarida"
local MISSION_NAME = "Resgatar o coelho"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function rabbitRescued(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 3
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Dona Margarida"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Dona Margarida] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Nova missão: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local ACHIEVEMENT_RABBIT = 20  -- conquista "Amigo dos animais" (achievementsLib.lua)

local function deliverQuest(cid)
    doPlayerAddItem(cid, REWARD_ITEM, 1)
    doPlayerAddItem(cid, REWARD_COINS, REWARD_COIN_COUNT)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 3)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    -- Titulo "Amigo dos animais": marca o progresso da conquista e deixa o
    -- Achievements.check desbloquear (envia a notificacao e atualiza o client).
    -- Se a lib nao estiver disponivel no estado do NPC, desbloqueia direto;
    -- o client sincroniza ao abrir o painel de Conquistas ou no proximo login.
    setPlayerStorageValue(cid, "achCreatureKill_" .. ACHIEVEMENT_RABBIT, 1)
    local ok = pcall(function()
        Achievements.check(cid, ACHIEVEMENT_RABBIT)
    end)
    if not ok then
        setPlayerStorageValue(cid, "achUnlocked_" .. ACHIEVEMENT_RABBIT, 1)
        pcall(function()
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Conquista desbloqueada: Resgatou o Coelho da Margarida! Titulo: Amigo dos animais (abra Conquistas na topbar para equipar).")
        end)
    end

    print("[Dona Margarida] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missão concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. QUEST_NAME)
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
    if questCompleted(cid) then
        selfSay("Olá, " .. getCreatureName(cid) .. "! Que alegria ver você de novo. Meu coelho está em casa, salvo e feliz. Obrigada por tudo!", cid)
    elseif rabbitRescued(cid) then
        deliverQuest(cid)
        selfSay("Você resgatou o meu coelho! Que alívio, eu estava tão preocupada! Aqui está o seu Filhote de coelho e a sua recompensa: 20 platinum coins e 50.000 de experiência. Obrigada, " .. getCreatureName(cid) .. "!", cid)
    elseif questStarted(cid) then
        selfSay("Meu coelho ainda esta lá dentro, na toca das aranhas cospe pedra... Estou rezando pra que ele esteja vivo! Por favor, encontre ele e diga {resgatar}!", cid)
    else
        selfSay("Ah, " .. getCreatureName(cid) .. "! Meu coelho fugiu de medo e entrou na toca das aranhas cospe pedra! Estou rezando pra que ele ainda esteja vivo... Você me ajudaria a procurar o meu coelho?", cid)
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
    local rescued = rabbitRescued(cid)
    local completed = questCompleted(cid)

    if talkState[talkUser] == 1 then
        if completed then
            selfSay("Obrigada de novo, " .. getCreatureName(cid) .. "! Se quiser, pode vir visitar o coelho quando quiser!", cid)
        elseif msgcontains(msg, "sim") or msgcontains(msg, "yes") or msgcontains(msg, "ajudar") or msgcontains(msg, "ajuda") or msgcontains(msg, "procurar") then
            if rescued then
                deliverQuest(cid)
                selfSay("Você resgatou o meu coelho! Que alívio! Aqui está o seu Filhote de coelho e a sua recompensa: 20 platinum coins e 50.000 de experiência!", cid)
            elseif started then
                selfSay("Meu coelho ainda está na toca das aranhas cospe pedra! Encontre ele e diga {resgatar} pra traze-lo de volta!", cid)
            else
                selfSay("Muito obrigada, " .. getCreatureName(cid) .. "! Ele fugiu de medo e entrou na toca das aranhas cospe pedra. Quando o encontrar, diga {resgatar} pra ele e traga ele de volta pra mim!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "coelho") or msgcontains(msg, "toca") or msgcontains(msg, "aranha") or msgcontains(msg, "resgatar") then
            if rescued then
                selfSay("Você resgatou o coelho! Volte aqui pra receber sua recompensa!", cid)
            elseif started then
                selfSay("Meu coelho está na toca das aranhas cospe pedra... Encontre ele e diga {resgatar}! Estou rezando pra que ele esteja vivo!", cid)
            else
                selfSay("Meu coelho fugiu de medo e entrou na toca das aranhas cospe pedra! Você me ajudaria a procurar o meu coelho?", cid)
            end
        else
            selfSay("Não entendi. Está falando do meu {coelho}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
