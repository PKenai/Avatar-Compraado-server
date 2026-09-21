-- Dona Margarida - Quest: O Coelho da Margarida (quest id 23)
-- Story: o coelho dela fugiu de medo e entrou na toca das aranhas
-- cospe pedra. O jogador encontra o Coelho da Margarida la dentro, diz
-- {resgatar} e volta pra Dona Margarida para receber a reward.
-- Storages (data/questSystem/quests.xml):
--   49230 = status da quest (1 = em andamento, 2 = coelho resgatado,
--           3 = completa / reward entregue)
--   49231 = progresso (1 = coelho resgatado; setado pelo NPC Coelho)
-- Item: Filhote de coelho (18879)
-- Reward: 1 Filhote de coelho + 20 platinum coins (2152) + 50.000 de
-- experiencia + titulo "Amigo dos animais" (achievement id 20,
-- achievementsLib.lua, desbloqueada aqui ao entregar a reward)
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
local QUEST_NAME = "Margarida's Rabbit"
local MISSION_NAME = "Rescue the rabbit"

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
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
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

    -- Titulo "Amigo dos animais": marca o progresso da achievement e deixa o
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
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Achievement unlocked: You rescued Margarida's Rabbit! Title: Friend of the Animals (open Achievements in the topbar to equip it).")
        end)
    end

    print("[Dona Margarida] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Mission completed: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
        selfSay("Hello, " .. getCreatureName(cid) .. "! What a joy to see you again. My rabbit is at home, safe and happy. Thank you for everything!", cid)
    elseif rabbitRescued(cid) then
        deliverQuest(cid)
        selfSay("You rescued my rabbit! What a relief, I was so worried! Here is your Rabbit Pet and your reward: 20 platinum coins and 50,000 experience. Thank you, " .. getCreatureName(cid) .. "!", cid)
    elseif questStarted(cid) then
        selfSay("My rabbit is still in there, in the stone-spitting spiders' den... I'm praying that he's alive! Please, find him and say {rescue}!", cid)
    else
        selfSay("Ah, " .. getCreatureName(cid) .. "! My rabbit ran away in fear and entered the stone-spitting spiders' den! I'm praying that he's still alive... Would you help me find my rabbit?", cid)
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
            selfSay("Thank you again, " .. getCreatureName(cid) .. "! If you want, you can come visit the rabbit whenever you like!", cid)
        elseif msgcontains(msg, "yes") or msgcontains(msg, "help") or msgcontains(msg, "search") then
            if rescued then
                deliverQuest(cid)
                selfSay("You rescued my rabbit! What a relief! Here is your Rabbit Pet and your reward: 20 platinum coins and 50,000 experience!", cid)
            elseif started then
                selfSay("My rabbit is still in the stone-spitting spiders' den! Find him and say {rescue} to bring him back!", cid)
            else
                selfSay("Thank you so much, " .. getCreatureName(cid) .. "! He ran away scared and went into the den of the stone-spitting spiders. When you find him, say {rescue} to him and bring him back to me!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "rabbit") or msgcontains(msg, "den") or msgcontains(msg, "spider") or msgcontains(msg, "rescue") then
            if rescued then
                selfSay("You rescued the rabbit! Come back here to receive your reward!", cid)
            elseif started then
                selfSay("My rabbit is in the stone-spitting spiders' den... Find him and say {rescue}! I'm praying that he's alive!", cid)
            else
                selfSay("My rabbit ran away in fear and entered the stone-spitting spiders' den! Would you help me find my rabbit?", cid)
            end
        else
            selfSay("I didn't understand. Are you talking about my {rabbit}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
