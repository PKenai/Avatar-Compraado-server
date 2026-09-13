local spellName = "fire cinder"
local cf = {atk = (spellsInfo[spellName] and spellsInfo[spellName].atk) or 52}

-- Fire Cinder: Magia de level baixo. Lança uma faísca de brasa ardente no alvo,
-- causando dano direto e queimando-o por 3 segundos (3 ticks de dano).

local function calcDano(cid, multiplier)
    if not isCreature(cid) then return 0 end
    local level = isPlayer(cid) and getPlayerLevel(cid) or 50
    local magLevel = isPlayer(cid) and getPlayerMagLevel(cid) or 10

    local min = (level + (magLevel / 2) * 2.5) + math.random(5, 15)
    local max = (level + (magLevel / 2) * 3.0) + math.random(15, 25)

    if getPlayerInWaterWithUnderwater(cid) then
        min = min * 0.5
        max = max * 0.5
    end

    local dano = math.random(min, max)
    local atk = cf.atk
    if atk and type(atk) == "number" then
        dano = dano * (atk / 100)
        dano = dano + 1
    end
    if multiplier then
        dano = dano * multiplier
    end
    dano = remakeValue(1, dano, cid)
    return dano
end

local function doBurnTick(cid, target, ticksLeft, isFocus)
    if not isCreature(cid) or not isCreature(target) then return end

    local tickDano = calcDano(cid, isFocus and 1.5 or 1.0)
    -- Dano de queimadura é menor que o hit inicial (~60%)
    tickDano = math.max(1, math.floor(tickDano * 0.6))

    doTargetCombatHealth(cid, target, COMBAT_FIREDAMAGE, -tickDano, -tickDano, CONST_ME_HITBYFIRE)
    doSendMagicEffect(getCreaturePosition(target), CONST_ME_FIRE)

    if ticksLeft > 1 then
        addEvent(doBurnTick, 1000, cid, target, ticksLeft - 1, isFocus)
    end
end

function onCastSpell(cid, var)
    if getSpellCancels(cid, "fire") == true then
        return false
    end

    if getPlayerExaust(cid, "fire", "cinder", fireExausted.cinder) == false then
        return false
    end

    local target = getCreatureTarget(cid)
    if not isCreature(target) then
        doPlayerSendCancelEf(cid, "You need a target to use this fold.")
        doPlayerAddExaust(cid, "fire", "cinder", 1)
        return false
    end

    if getPlayerHasStun(cid) then
        workAllCdAndAndPrevCd(cid, "fire", "cinder", nil, 1)
        doPlayerAddExaust(cid, "fire", "cinder", fireExausted.cinder)
        return true
    end

    local isFocus = getPlayerOverPower(cid, "fire", true, true)
    local myPos = getCreaturePosition(cid)
    local targetPos = getCreaturePosition(target)

    if getDistanceBetween(myPos, targetPos) > 6 or not isSightClear(myPos, targetPos, true) then
        doPlayerSendCancelEf(cid, "Target is out of range.")
        return false
    end

    -- Projétil visual: faísca de brasa
    doSendDistanceShoot(myPos, targetPos, CONST_ANI_FIRE)

    -- Hit inicial: dano direto após o projétil chegar
    addEvent(function()
        if not isCreature(target) then return end
        local hitDano = calcDano(cid, isFocus and 1.8 or 1.0)
        doTargetCombatHealth(cid, target, COMBAT_FIREDAMAGE, -hitDano, -hitDano, CONST_ME_HITBYFIRE)
        doSendMagicEffect(targetPos, CONST_ME_EXPLOSIONHIT)

        -- Inicia DoT de queimadura: 3 ticks, 1 por segundo
        local burnTicks = isFocus and 5 or 3
        addEvent(doBurnTick, 800, cid, target, burnTicks, isFocus)
    end, 200)

    doPlayerAddExaust(cid, "fire", "cinder", fireExausted.cinder)
    workAllCdAndAndPrevCd(cid, "fire", "cinder", nil, 1)
    return true
end
