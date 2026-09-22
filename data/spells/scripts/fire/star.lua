local spellName = "fire star"
local cf = {atk = spellsInfo[spellName].atk}

local MyLocal = {}
MyLocal.players = {}

-- Dano por hit: fórmula base dividida por 8 para manter o dano total igual
local function calcDano(cid, isFocus)
    if not isCreature(cid) then return 0 end
    local level = isPlayer(cid) and getPlayerLevel(cid) or 50
    local magLevel = level * 0.5

    local min = (level + ((level * 0.5) / 2) * 4.5) + math.random(30, 40)
    local max = (level + ((level * 0.5) / 2) * 5.2) + math.random(40, 55)

    if getPlayerInWaterWithUnderwater(cid) then
        min = min * 0.5
        max = max * 0.5
    end

    local dano = math.random(min, max)

    -- Focus multiplier semelhante ao original (1.5x~2x)
    if isFocus then
        dano = dano * math.random(15, 20) / 10
    end

    local atk = cf.atk
    if atk and type(atk) == "number" then
        dano = dano * (atk / 100)
        dano = dano + 1
    end

    -- Divide o dano em 8 hits, mantendo o total igual ao original
    dano = dano / 8
    dano = remakeValue(1, dano, cid)
    return dano
end

local function removeTable(cid)
    if isCreature(cid) then
        if getDobrasLevel(cid) >= 8 then
            doPlayerAddExaust(cid, "fire", "star", fireExausted.star - 5)
        else
            doPlayerAddExaust(cid, "fire", "star", fireExausted.star)
        end
        MyLocal.players[cid] = nil
    end
end

-- Efeitos visuais por hit: alterna entre projéteis de fogo para criar sensação de metralhadora
local shootTypes = {
    CONST_ANI_FIRE,
    CONST_ANI_REDSTAR,
    CONST_ANI_FIRE,
    CONST_ANI_REDSTAR,
    CONST_ANI_FIRE,
    CONST_ANI_REDSTAR,
    CONST_ANI_FIRE,
    CONST_ANI_REDSTAR,
}

local hitEffects = {
    CONST_ME_HITBYFIRE,
    CONST_ME_POFF,
    CONST_ME_HITBYFIRE,
    CONST_ME_POFF,
    CONST_ME_HITBYFIRE,
    CONST_ME_POFF,
    CONST_ME_HITBYFIRE,
    CONST_ME_HITBYFIRE,
}

local function doSingleHit(cid, targetId, hitIndex, isFocus)
    if not isCreature(cid) or isInPz(cid) then return end
    if not isCreature(targetId) then return end

    local myPos = getCreaturePosition(cid)
    local targetPos = getCreaturePosition(targetId)

    -- Checa distância e linha de visão
    if getDistanceBetween(myPos, targetPos) > 6 or not isSightClear(myPos, targetPos, true) then
        return
    end

    -- Proteção
    if getTileInfo(myPos).protection then return end

    local dano = calcDano(cid, isFocus)

    -- Projétil visual
    doSendDistanceShoot(myPos, targetPos, shootTypes[hitIndex] or CONST_ANI_FIRE)

    -- Aplica dano direto no alvo com pequeno delay para coincidir com o projétil
    addEvent(function()
        if not isCreature(targetId) then return end
        doTargetCombatHealth(cid, targetId, COMBAT_FIREDAMAGE, -dano, -dano, hitEffects[hitIndex] or CONST_ME_HITBYFIRE)
    end, 150)
end

local function startGatling(cid, target, hitNum, isFocus)
    if not isCreature(cid) or isInPz(cid) then return end
    if hitNum > 8 then return end

    doSingleHit(cid, target, hitNum, isFocus)

    if hitNum < 8 then
        addEvent(startGatling, 150, cid, target, hitNum + 1, isFocus)
    end
end

function onCastSpell(cid, var)
    if getSpellCancels(cid, "fire") == true then
        return false
    end

    if MyLocal.players[cid] ~= nil then
        doPlayerSendCancelEf(cid, "You're already using this fold.")
        return false
    end

    if getPlayerExaust(cid, "fire", "star", fireExausted.star) == false then
        return false
    end

    -- Precisa de alvo
    local target = getCreatureTarget(cid)
    if not isCreature(target) then
        doPlayerSendCancelEf(cid, "You need a target to use this fold.")
        return false
    end

    if getPlayerHasStun(cid) then
        workAllCdAndAndPrevCd(cid, "fire", "star", nil, 1)
        removeTable(cid)
        return true
    end

    local isFocus = getPlayerOverPower(cid, "fire", true, true)

    MyLocal.players[cid] = true

    -- Efeito inicial no caster (carregando energia)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_EXPLOSIONHIT)

    -- Inicia sequência de 8 hits com intervalo de 150ms
    startGatling(cid, target, 1, isFocus)

    -- Remove lock após todos os hits terminarem (8 hits * 150ms + buffer)
    addEvent(removeTable, 8 * 150 + 200, cid)

    workAllCdAndAndPrevCd(cid, "fire", "star", 3, 1)
    return true
end
