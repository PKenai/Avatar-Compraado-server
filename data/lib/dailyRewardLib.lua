-- ============================================================================
-- Daily Reward Library (data/lib/dailyRewardLib.lua)
-- ----------------------------------------------------------------------------
-- Sistema de recompensas diarias com ciclo de7 dias.
-- O servidor controla quais itens sao recompensas, o storage do jogador,
-- e envia os dados ao client via Extended Opcode.
--
-- Storage keys:
--   "dailyReward_cycleStart"  = timestamp (os.time()) do inicio do ciclo atual
--   "dailyReward_claimed"     = string "1,2,3" (dias ja coletados, 0-indexed)
--   "dailyReward_lastReset"   = timestamp do ultimo reset automatico de ciclo
-- ============================================================================

DAILY_REWARD_OPCODE = 170

-- Recompensas dos7 dias (server item IDs - o client converte pra clientId)
-- Edite esta tabela para trocar os itens de recompensa
DAILY_REWARD_REWARDS = {
    -- Dia 1: 1x Treino elemental (500 cargas)
    { itemId = 18341, count = 1 },  
    
    -- Dia 2: 30 minutos de Experiencia Bonus
    { 
        itemId = 18867,
        name = "30m EXP Bonus",
        warn = "Essa experiencia nao acumula com outras, caso você pegue-a sua experiencia bonus atual será resetada, deseja continuar?",
        action = function(cid)
            local DURATION = 30 * 60 -- 30 minutos
            local endTime = os.time() + DURATION
            setPlayerStorageValue(cid, "hasExpScroll", endTime)
            doCreatureAddBuffWithTime(cid, 11, DURATION * 1000)
            doSendMagicEffect(getThingPos(cid), 13)
            sendBlueMessage(cid, "Seu bônus de experiência de 30 minutos foi ativado!")
        end
    },   
    
    -- Dia 3: 50x item 15014
    { itemId = 15014, count = 50 },   
    
    -- Dia 4: 1x Treino elemental (500 cargas)
    { itemId = 18341, count = 1 },  
    
    -- Dia 5: 50x item 15014
    { itemId = 15014, count = 50 },  
    
    -- Dia 6: 30 minutos de Experiencia Bonus
    { 
        itemId = 18867,
        name = "30m EXP Bonus",
        warn = "Essa experiencia nao acumula com outras, caso você pegue-a sua experiencia bonus atual será resetada, deseja continuar?",
        action = function(cid)
            local DURATION = 30 * 60 -- 30 minutos
            local endTime = os.time() + DURATION
            setPlayerStorageValue(cid, "hasExpScroll", endTime)
            doCreatureAddBuffWithTime(cid, 11, DURATION * 1000)
            doSendMagicEffect(getThingPos(cid), 13)
            sendBlueMessage(cid, "Seu bônus de experiência de 30 minutos foi ativado!")
        end
    }, 
    
    -- Dia 7: demon armor
    { itemId = 19004, count = 1 },  
}

-- Tempo maximo do ciclo em segundos (7 dias em horas * minutos * segundos)
local CYCLE_DURATION = 7 * 24 * 60 * 60

-- ============================================================================
-- Funcoes auxiliares
-- ============================================================================

local function getTodayTimestamp()
    -- Retorna o timestamp do inicio do dia atual (00:00:00)
    local now = os.time()
    local date = os.date("*t", now)
    date.hour = 0; date.min = 0; date.sec = 0
    return os.time(date)
end

-- ============================================================================
-- API publica
-- ============================================================================

--- Retorna os dados do daily reward de um jogador.
-- Calcula o dia atual, quais foram coletados, quais foram perdidos.
-- @param cid number Player creature ID
-- @return table { days = {...}, currentDay = n, canClaim = bool, cycleComplete = bool }
function dailyRewardGetData(cid)
    local cycleStart = getPlayerStorageValue(cid, "dailyReward_cycleStart")
    local claimedStr = getPlayerStorageValue(cid, "dailyReward_claimed")
    local todayTs = getTodayTimestamp()

    -- Se nao tem ciclo, inicia um novo
    if cycleStart == -1 or cycleStart == nil or cycleStart == 0 then
        cycleStart = todayTs
        setPlayerStorageValue(cid, "dailyReward_cycleStart", cycleStart)
        setPlayerStorageValue(cid, "dailyReward_claimed", "")
    end

    -- Dias desde o inicio do ciclo (0-indexed)
    local daysSinceStart = math.floor((todayTs - cycleStart) / (24 * 60 * 60))
    local currentDay = math.min(daysSinceStart, 6)

    -- Parse dos dias ja coletados
    local claimed = {}
    if claimedStr and claimedStr ~= "" then
        for dayStr in string.gmatch(claimedStr, "(%d+)") do
            claimed[tonumber(dayStr)] = true
        end
    end

    -- Se passou dos 7 dias, reseta o ciclo
    if daysSinceStart >=7 then
        -- Inicia novo ciclo
        cycleStart = todayTs
        setPlayerStorageValue(cid, "dailyReward_cycleStart", cycleStart)
        setPlayerStorageValue(cid, "dailyReward_claimed", "")
        claimed = {}
        currentDay = 0
    end

    -- Monta os dados dos 7 dias
    local days = {}
    for i = 0,6 do
        local reward = DAILY_REWARD_REWARDS[i + 1]
        local status = "future"

        if i < currentDay then
            -- Dia ja passou
            if claimed[i] then
                status = "claimed"
            else
                status = "missed"
            end
        elseif i == currentDay then
            if claimed[i] then
                status = "claimed"
            else
                status = "available"
            end
        end

        local it = ItemType(reward.itemId)
        local clientId = (it and it:getClientId()) or 0
        if clientId == 0 then clientId = reward.itemId end
        local name = reward.name or getItemNameById(reward.itemId) or ""

        table.insert(days, {
            day = i + 1,
            itemId = reward.itemId,
            clientId = clientId,
            name = name,
            count = reward.count,
            warn = reward.warn or nil,
            status = status
        })
    end

    local canClaim = (not claimed[currentDay]) and days[currentDay + 1].status == "available"
    local cycleComplete = (currentDay >= 6 and dailyRewardAllClaimed(claimed))

    return {
        days = days,
        currentDay = currentDay + 1, -- 1-indexed para o client
        canClaim = canClaim,
        cycleComplete = cycleComplete
    }
end

--- Verifica se todos os 7 dias foram coletados
function dailyRewardAllClaimed(claimed)
    for i = 0, 6 do
        if not claimed[i] then
            return false
        end
    end
    return true
end

local function giveDailyRewardItem(cid, itemId, count)
    count = count or 1
    if doPlayerAddItemToRewardBox then
        if doPlayerAddItemToRewardBox(cid, itemId, count) then
            return true
        end
    end
    if doPlayerAddItemToDepot then
        for depotid = 1, 10 do
            if doPlayerAddItemToDepot(cid, depotid, itemId, count) then
                return true
            end
        end
    end
    doPlayerAddItem(cid, itemId, count)
    return true
end

--- Coleta a recompensa do dia atual
-- @param cid number Player creature ID
-- @return bool success, string message
function dailyRewardClaim(cid)
    local data = dailyRewardGetData(cid)

    if not data.canClaim then
        return false, "You cannot claim a reward right now."
    end

    -- Re-read after getData (which may have reset cycle) to stay consistent
    local claimedStr = getPlayerStorageValue(cid, "dailyReward_claimed")
    if claimedStr == -1 then claimedStr = "" end

    local dayIndex = data.currentDay - 1 -- 0-indexed

    -- Safety: verify the day hasn't already been claimed (double-check after re-read)
    local alreadyClaimed = false
    if claimedStr and claimedStr ~= "" then
        for dayStr in string.gmatch(claimedStr, "(%d+)") do
            if tonumber(dayStr) == dayIndex then
                alreadyClaimed = true
                break
            end
        end
    end
    if alreadyClaimed then
        return false, "Day " .. data.currentDay .. " was already claimed."
    end

    -- Adiciona o dia a lista de coletados
    if claimedStr == "" then
        claimedStr = tostring(dayIndex)
    else
        claimedStr = claimedStr .. "," .. tostring(dayIndex)
    end
    setPlayerStorageValue(cid, "dailyReward_claimed", claimedStr)

    -- Da a recompensa (funcao customizada ou item enviado para a mailbox)
    local reward = DAILY_REWARD_REWARDS[data.currentDay]
    if reward then
        if type(reward.action) == "function" then
            reward.action(cid)
        elseif reward.itemId then
            local count = reward.count or 1
            giveDailyRewardItem(cid, reward.itemId, count)
        end
    end

    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
    return true, "You claimed your Day " .. data.currentDay .. " reward!"
end

--- Envia os dados do daily reward ao client
function dailyRewardSendToClient(cid)
    local data = dailyRewardGetData(cid)
    local payload = json.encode({
        action = "dailyRewardOpen",
        days = data.days,
        currentDay = data.currentDay,
        canClaim = data.canClaim,
        cycleComplete = data.cycleComplete
    })
    doSendPlayerExtendedOpcode(cid, DAILY_REWARD_OPCODE, payload)
end

--- Envia confirmacao de claim ao client
function dailyRewardSendClaimResult(cid, success, message)
    local payload = json.encode({
        action = "dailyRewardClaimed",
        success = success,
        message = message
    })
    doSendPlayerExtendedOpcode(cid, DAILY_REWARD_OPCODE, payload)
end

--- Handle de extended opcode recebido do client
function dailyRewardHandleOpcode(cid, opcode, buffer)
    if opcode ~= DAILY_REWARD_OPCODE then return false end

    if buffer == "open" then
        dailyRewardSendToClient(cid)
    elseif buffer == "claim" then
        local success, message = dailyRewardClaim(cid)
        dailyRewardSendClaimResult(cid, success, message)
        -- Re-envia os dados atualizados
        dailyRewardSendToClient(cid)
    end

    return true
end
