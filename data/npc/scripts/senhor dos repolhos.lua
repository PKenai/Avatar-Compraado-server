-- Senhor dos Repolhos - Quest: Os Repolhos Roubados (quest id 26)
-- Story: Um arruaceiro roubou os repolhos do Senhor dos Repolhos e
-- espalhou pela cidade. O jogador clica nos repolhos no chao (item 18929)
-- para incrementar o contador (o repolho NAO e coletado, fica no chao
-- para outras pessoas pegarem). Ao falar com o NPC, ele entrega rewards
-- em 5 tiers conforme o jogador vai recuperando repolhos.
--
-- Storages (data/questSystem/quests.xml):
--   49260 = status da quest (0 = nao iniciada, 1 = em andamento, 2 = completa)
--   49261 = total de repolhos recuperados pelo player (0-50)
--   49262 = ultimo tier de reward resgatado (0-5)
--   cabbage_<actionId> = repolhos individuais coletados (string storage por repolho)
--
-- Repolhos: item 18929 no chao, com action IDs unicos.
-- Cada repolho tem uma action ID. Ao clicar, o script checa se o player
-- ja coletou aquele repolho especifico e incrementa o contador.
--
-- Tiers de reward:
--   Tier 1:  1 repolho  -> 10.000 exp + 2 crystal coins
--   Tier 2: 10 repolhos -> 30.000 exp + 2 crystal coins
--   Tier 3: 20 repolhos -> 75.000 exp + 2 crystal coins
--   Tier 4: 35 repolhos -> 150.000 exp + 2 crystal coins
--   Tier 5: 50 repolhos -> 250.000 exp + 2 crystal coins + titulo "Repolhudo"
--
-- Titulo "Repolhudo": achievement id 23 (achievementsLib.lua)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

-- ============================================================
-- Configuracao
-- ============================================================
local STATUS_STORAGE    = 49260   -- 0=nao iniciada, 1=em andamento, 2=completa
local COUNT_STORAGE     = 49261   -- total de repolhos recuperados (0-50)
local TIER_STORAGE      = 49262   -- ultimo tier resgatado (0-5)

local QUEST_NAME   = "Os Repolhos Roubados"
local MISSION_NAME = "Recuperar os repolhos roubados"

local TOTAL_CABBAGES = 50
local ACHIEVEMENT_REPOLHUDO = 23  -- conquista "Repolhudo" (achievementsLib.lua)

-- Tiers: { minCabbages, exp, crystalCoins }
local TIERS = {
    { min = 1,  exp = 10000,  coins = 2  },
    { min = 10, exp = 30000,  coins = 2  },
    { min = 20, exp = 75000,  coins = 2  },
    { min = 35, exp = 150000, coins = 2  },
    { min = 50, exp = 250000, coins = 2  },
}

-- ============================================================
-- Funcoes auxiliares
-- ============================================================
local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function getCabbageCount(cid)
    local v = getPlayerStorageValue(cid, COUNT_STORAGE)
    if type(v) ~= "number" or v < 0 then return 0 end
    return v
end

local function getLastTier(cid)
    local v = getPlayerStorageValue(cid, TIER_STORAGE)
    if type(v) ~= "number" or v < 0 then return 0 end
    return v
end

-- Retorna o index do proximo tier disponivel (1-5), ou nil se nao ha nenhum
local function getNextTier(cid)
    local count = getCabbageCount(cid)
    local lastTier = getLastTier(cid)
    for i = lastTier + 1, #TIERS do
        if count >= TIERS[i].min then
            return i
        end
    end
    return nil
end

-- Retorna o proximo tier minimo necessario
local function getNextTierMin(cid)
    local lastTier = getLastTier(cid)
    if lastTier >= #TIERS then return nil end
    return TIERS[lastTier + 1].min
end

local function sendNotification(cid, title, message, color, soundType)
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Senhor dos repolhos"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, COUNT_STORAGE, 0)
    setPlayerStorageValue(cid, TIER_STORAGE, 0)
    print("[Senhor dos repolhos] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "New mission: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function claimReward(cid, tier)
    local t = TIERS[tier]
    if not t then return end

    -- Dar rewards
    if t.exp > 0 then
        doPlayerAddExperience(cid, t.exp)
    end
    if t.coins > 0 then
        doPlayerAddItem(cid, 2160, t.coins)  -- crystal coin
    end

    setPlayerStorageValue(cid, TIER_STORAGE, tier)

    -- Se e o tier 5 (completo), marcar quest como completa e desbloquear titulo
    if tier == #TIERS then
        setPlayerStorageValue(cid, STATUS_STORAGE, 2)
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

        -- Titulo "Repolhudo": achievement id 23
        setPlayerStorageValue(cid, "achCreatureKill_" .. ACHIEVEMENT_REPOLHUDO, 1)
        local ok = pcall(function()
            Achievements.check(cid, ACHIEVEMENT_REPOLHUDO)
        end)
        if not ok then
            setPlayerStorageValue(cid, "achUnlocked_" .. ACHIEVEMENT_REPOLHUDO, 1)
            pcall(function()
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                    "Conquista desbloqueada: Repolhudo! Titulo: Repolhudo (abra Conquistas na topbar para equipar).")
            end)
        end

        sendNotification(cid, QUEST_NAME, "Missao concluida: Todos os 50 repolhos recuperados!", "#00FF00", "end")
        pcall(function()
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. QUEST_NAME)
        end)
    else
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
    end
end

local function formatReward(tier)
    local t = TIERS[tier]
    if not t then return "" end
    local parts = {}
    if t.exp > 0 then table.insert(parts, t.exp .. " experiencia") end
    if t.coins > 0 then table.insert(parts, t.coins .. " crystal coins") end
    if tier == #TIERS then table.insert(parts, "titulo Repolhudo") end
    return table.concat(parts, " + ")
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
    local count = getCabbageCount(cid)

    if questCompleted(cid) then
        selfSay("Hello, " .. name .. "! Meus repolhos estao todos de volta gracas a voce! Muito obrigado, voce e um heroi para mim!", cid)
    elseif questStarted(cid) then
        local nextTier = getNextTier(cid)
        if nextTier then
            selfSay("Hello, " .. name .. "! Vejo que voce ja recuperou " .. count .. " repolhos! Posso te dar uma recompensa agora! Fale {recompensa} para receber!", cid)
        else
            local nextMin = getNextTierMin(cid)
            selfSay("Hello, " .. name .. "! You already recuperou " .. count .. " repolhos! Faltam " .. (nextMin - count) .. " para a proxima recompensa. Continue procurando os repolhos espalhados pela cidade!", cid)
        end
    else
        selfSay("Hello, " .. name .. "! Help! Um arruaceiro desalmado roubou todos os meus repolhos e saiu espalhando pela cidade! Eu cultivei esses repolhos com tanto carinho... Voce pode me ajudar a {recuperar} os repolhos?", cid)
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
    local count = getCabbageCount(cid)
    local completed = questCompleted(cid)
    local started = questStarted(cid)

    if talkState[talkUser] == 1 then
        -- Aceitar a quest
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "help") or msgcontains(msg, "recuperar") or msgcontains(msg, "help") then
            if completed then
                selfSay("You already helped me with everything, " .. name .. "! Todos os meus repolhos estao de volta. Thank you!", cid)
            elseif started then
                selfSay("You already comecou a procurar! Va la e encontre os repolhos espalhados pela cidade. Clique neles para registrar a coleta. Quando tiver repolhos suficientes, volte e fale {recompensa}!", cid)
            else
                selfSay("Muito obrigado, " .. name .. "! Va pela cidade e clique nos repolhos que estao no chao. Cada repolho que voce encontrar sera contabilizado. Volte quando tiver recuperado alguns e fale {recompensa} para ganhar recompensas!", cid)
                startQuest(cid)
            end

        -- Reclamar de repolhos / contexto
        elseif msgcontains(msg, "repolho") or msgcontains(msg, "repolhos") or msgcontains(msg, "roub") or msgcontains(msg, "arruaceiro") or msgcontains(msg, "espalh") or msgcontains(msg, "cidade") or msgcontains(msg, "cultivei") then
            if completed then
                selfSay("Agora meus repolhos estao todos de volta! Um arruaceiro nao vai me derrubar facilmente!", cid)
            elseif started then
                selfSay("Os meus repolhos ainda estao espalhados por ai! You already recuperou " .. count .. " of " .. TOTAL_CABBAGES .. ". Continue procurando e clique neles quando encontrar!", cid)
            else
                selfSay("Um arruaceiro desalmado roubou todos os meus repolhos e saiu espalhando pela cidade! Eu cultivei esses repolhos com tanto carinho... Voce pode me ajudar a {recuperar} os repolhos?", cid)
            end

        -- Entregar reward
        elseif msgcontains(msg, "recompensa") or msgcontains(msg, "recompensas") then
            if completed then
                selfSay("You already recebeu todas as recompensas, " .. name .. "! Thank you por tudo!", cid)
            elseif not started then
                selfSay("Voce ainda nao comecou a me ajudar! Diga {sim} se quiser comecar a recuperar os meus repolhos!", cid)
            else
                local nextTier = getNextTier(cid)
                if nextTier then
                    local rewardText = formatReward(nextTier)
                    claimReward(cid, nextTier)
                    selfSay("Increivel, " .. name .. "! You already recuperou " .. getCabbageCount(cid) .. " repolhos! Here is your reward: " .. rewardText .. "!", cid)
                else
                    local nextMin = getNextTierMin(cid)
                    if nextMin then
                        selfSay("Ainda nao atingiu o proximo nivel de recompensa! Voce tem " .. count .. " repolhos e precisa de " .. nextMin .. " para a proxima recompensa. Continue procurando!", cid)
                    else
                        selfSay("You already recebeu todas as recompensas disponiveis, " .. name .. "! Thank you!", cid)
                    end
                end
            end

        else
            selfSay("I didn't understand. Voce esta falando dos meus {repolhos} que foram {roubados}? Diga {sim} para me ajudar a {recuperar} ou {recompensa} para ver suas recompensas!", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
