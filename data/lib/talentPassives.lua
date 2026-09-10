-- ============================================================
-- TALENT PASSIVES LIBRARY
-- Sistema de passivas especiais da arvore de talentos.
-- Fire Burn, Air Evasion, Water HealCrit, Earth Path bonuses.
-- ============================================================

TalentPassives = {}

-- Storage keys
local STORAGE_BURN_CD      = "talentBurnCooldown"   -- timestamp do ultimo proc de burn
local STORAGE_DODGE_PCT    = "talentDodgePercent"    -- % de esquiva (0-10, valor em %)
local STORAGE_BURN_RANK    = "talentBurnRank"        -- 0=nenhum, 1=0.5%, 2=1.0%
local STORAGE_HEALCRIT_PCT = "talentHealCritPercent" -- % de crit na cura (0 a 30)
local STORAGE_CDR_PCT      = "talentCooldownReduction" -- % de reducao de cooldown

-- ============================================================
-- BURN SYSTEM (Fire Bender passive)
-- Rank 1: 0.5% do HP maximo por segundo durante 5 segundos (5 ticks de 1s)
-- Rank 2: 1.0% do HP maximo por segundo durante 5 segundos
-- Cooldown: 20 segundos entre procs
-- ============================================================

local BURN_TICK_INTERVAL = 1000  -- 1 segundo em ms
local BURN_TICKS         = 5     -- 5 ticks
local BURN_COOLDOWN_SECS = 20    -- 20 segundos de cooldown global por caster

-- Tabela interna de burns ativos: [targetId] = { ticks, damagePerTick, sourceId }
local activeBurns = {}

local function applyBurnTick(targetId, ticks, dmgPerTick, sourceId)
    if not isCreature(targetId) then
        activeBurns[targetId] = nil
        return
    end

    -- Aplica 1 tick de dano
    doCreatureAddHealth(targetId, -dmgPerTick)
    doSendMagicEffect(getCreaturePosition(targetId), CONST_ME_HITBYFIRE)

    local remaining = ticks - 1
    if remaining > 0 then
        activeBurns[targetId] = { ticks = remaining, dmg = dmgPerTick, source = sourceId }
        addEvent(function()
            applyBurnTick(targetId, remaining, dmgPerTick, sourceId)
        end, BURN_TICK_INTERVAL)
    else
        activeBurns[targetId] = nil
    end
end

-- Chamado em proficiencyCombat ao Fire bender causar dano
function TalentPassives.tryTriggerBurn(attackerId, targetId, damage)
    if not isPlayer(attackerId) or not isCreature(targetId) then return end

    local rank = getPlayerStorageValue(attackerId, STORAGE_BURN_RANK)
    if type(rank) ~= "number" or rank < 1 then return end

    -- Verifica cooldown (20s)
    local now = os.time()
    local lastBurn = getPlayerStorageValue(attackerId, STORAGE_BURN_CD)
    if type(lastBurn) == "number" and (now - lastBurn) < BURN_COOLDOWN_SECS then
        return
    end

    -- Calcula dano por tick
    local maxHp = getCreatureMaxHealth(targetId)
    local pct = (rank == 2) and 1.0 or 0.5  -- 0.5% ou 1.0% por tick
    local dmgPerTick = math.max(1, math.floor(maxHp * pct / 100))

    -- Registra cooldown
    setPlayerStorageValue(attackerId, STORAGE_BURN_CD, now)

    -- Se o alvo ja esta queimando, nao acumula — apenas renova ao maximo
    -- (sobrescreve com o novo proc que sempre sera o "maximo" permitido pelo rank)
    activeBurns[targetId] = nil  -- cancela anterior (nao acumula)

    -- Agenda os ticks
    addEvent(function()
        applyBurnTick(targetId, BURN_TICKS, dmgPerTick, attackerId)
    end, BURN_TICK_INTERVAL)

    -- Efeito visual de ignição
    doSendMagicEffect(getCreaturePosition(targetId), CONST_ME_HITBYFIRE)
end

-- ============================================================
-- DODGE / EVASION SYSTEM (Air Bender passive)
-- Chance de esquivar COMPLETAMENTE todo dano recebido.
-- Rank 1 (1 ponto): 5% de dodge
-- Rank 2 (2 pontos): 10% de dodge
-- Chamado em proficiencyCombat quando Air bender RECEBE dano.
-- ============================================================

-- Retorna true se o dano deve ser cancelado (dodged)
function TalentPassives.tryDodge(cid)
    if not isPlayer(cid) then return false end

    local dodgePct = getPlayerStorageValue(cid, STORAGE_DODGE_PCT)
    if type(dodgePct) ~= "number" or dodgePct <= 0 then return false end

    -- Rola o dado
    local roll = math.random(1, 100)
    if roll <= dodgePct then
        -- Esquivou! Mostra efeito visual
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
        doSendAnimatedText(getCreaturePosition(cid), "DODGE!", 215)
        return true
    end
    return false
end

-- ============================================================
-- HEAL CRIT SYSTEM (Water Bender passive)
-- Curas em aliados tem chance de curar 50% a mais.
-- Rank 1: 15% de chance de heal critico
-- Rank 2: 30% de chance de heal critico
-- Nao funciona em self-heal.
-- ============================================================

function TalentPassives.getHealCritChance(cid)
    if not isPlayer(cid) then return 0 end
    local pct = getPlayerStorageValue(cid, STORAGE_HEALCRIT_PCT)
    if type(pct) ~= "number" or pct <= 0 then return 0 end
    return pct
end

-- Chamado nas spells de cura do Water bender (scripts de heal)
-- healValue = valor original da cura
-- healer = cid do curador, target = cid do alvo
-- Retorna o novo valor de cura (com ou sem critico)
function TalentPassives.applyHealCrit(healer, target, healValue)
    if healer == target then return healValue end  -- sem self-heal crit
    local chance = TalentPassives.getHealCritChance(healer)
    if chance <= 0 then return healValue end

    if math.random(1, 100) <= chance then
        local newHeal = math.floor(healValue * 1.5)
        doSendMagicEffect(getCreaturePosition(target), CONST_ME_MAGIC_GREEN)
        doSendAnimatedText(getCreaturePosition(target), "HEAL CRIT!", 30)
        return newHeal
    end
    return healValue
end

-- ============================================================
-- APLICAR BONUS DE TALENTO NO STORAGE (chamado por talentTree.lua)
-- ============================================================

function TalentPassives.applyEffect(cid, effectType, value, remove)
    local mult = remove and -1 or 1

    if effectType == "dodge" then
        local cur = getPlayerStorageValue(cid, STORAGE_DODGE_PCT)
        if type(cur) ~= "number" or cur < 0 then cur = 0 end
        setPlayerStorageValue(cid, STORAGE_DODGE_PCT, math.max(0, cur + (value * mult)))

    elseif effectType == "burnrank" then
        -- value = rank (1 ou 2); no remove, zera
        if remove then
            setPlayerStorageValue(cid, STORAGE_BURN_RANK, 0)
        else
            local cur = getPlayerStorageValue(cid, STORAGE_BURN_RANK)
            if type(cur) ~= "number" or cur < 0 then cur = 0 end
            if value > cur then
                setPlayerStorageValue(cid, STORAGE_BURN_RANK, value)
            end
        end

    elseif effectType == "healcrit" then
        local cur = getPlayerStorageValue(cid, STORAGE_HEALCRIT_PCT)
        if type(cur) ~= "number" or cur < 0 then cur = 0 end
        setPlayerStorageValue(cid, STORAGE_HEALCRIT_PCT, math.max(0, cur + (value * mult)))

    elseif effectType == "cooldownreduction" then
        local cur = getPlayerStorageValue(cid, STORAGE_CDR_PCT)
        if type(cur) ~= "number" or cur < 0 then cur = 0 end
        setPlayerStorageValue(cid, STORAGE_CDR_PCT, math.max(0, cur + (value * mult)))

    end
end

-- Reseta todos os passivos de talento de um player
function TalentPassives.resetAll(cid)
    setPlayerStorageValue(cid, STORAGE_DODGE_PCT, 0)
    setPlayerStorageValue(cid, STORAGE_BURN_RANK, 0)
    setPlayerStorageValue(cid, STORAGE_HEALCRIT_PCT, 0)
    setPlayerStorageValue(cid, STORAGE_CDR_PCT, 0)
end

-- Reaplica passivos no login (chamado por TalentTree.reapplyAll)
-- Nao precisa de nada aqui pois os valores ficam no storage mesmo.
-- As funcoes acima leem do storage dinamicamente.
