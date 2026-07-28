local spellName = "water heal"
local cf = {heal = spellsInfo[spellName].heal}
local WATER_HEAL_TARGET_STORAGE = 87654

local function isNonPvp(cid)
    return isMonster(cid) or getPlayerStorageValue(cid, "canAttackable") == 1
end

local function purify(cid)
    local conditions = {CONDITION_FIRE, CONDITION_POISON, CONDITION_ENERGY, CONDITION_LIFEDRAIN, CONDITION_PARALYZE, CONDITION_DROWN, CONDITION_DRUNK}
    local hasPurify = 0
    for x = 1, #conditions do
        if (hasCondition(cid, conditions[x])) then
            doRemoveCondition(cid, conditions[x])
            hasPurify = 1
        end
    end
    if hasPurify == 1 then
        doSendAnimatedText(getCreaturePosition(cid), "Purified!", 52)
    end
end

local function calcHeal(cid, target)
    local heal = getPlayerMagLevel(cid) + (getPlayerLevel(cid) / 2)
    heal = heal + math.random(15, 30)
    local atk = cf.heal
    if atk and type(atk) == "number" then
        heal = heal * (atk / 100)
        heal = heal + 1
    end
    if target ~= cid then
        heal = heal * 1.2
    end
    if not exhaustion.check(target, "isInCombat") then
        heal = heal * 1.5
    end
    if getDobrasLevel(cid) >= 3 then
        heal = heal * 1.2
    end
    return heal
end

local function doSendHealthPos(cid, pos)
    local player = getThingfromPos({x=pos.x, y=pos.y, z=pos.z, stackpos=253})
    if player.uid > 0 then
        if isNonPvp(cid) and not isNonPvp(player.uid) then
            -- bloqueado PvP
        else
            local heal = calcHeal(cid, player.uid)
            doCreatureAddHealth(player.uid, heal)
            purify(player.uid)
        end
    end
    doSendMagicEffect(pos, CONST_ME_MAGIC_BLUE)
end

local function doSendHealthTarget(cid, target)
    if not isPlayer(target) then
        doPlayerSendCancel(cid, "Player not found.")
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
        return false
    end
    local mypos = getCreaturePosition(cid)
    if target == cid then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You need to use Water Sheal to heal yourself.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return false
    end
    if getDistanceBetween(getCreaturePosition(target), mypos) >= 6 or not isSightClear(getCreaturePosition(target), mypos, true) then
        doPlayerSendCancel(cid, "Target is too far away.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return false
    end
    if isInWarGround(cid) and not isSameWarTeam(cid, target) then
        doPlayerSendCancel(cid, "You can't heal players from the enemy team.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return false
    end
    local heal = calcHeal(cid, target)
    doCreatureAddHealth(target, heal)
    doSendMagicEffect(getCreaturePosition(target), CONST_ME_MAGIC_BLUE)
    purify(target)
    return true
end

function onCastSpell(cid, var)
    if getSpellCancels(cid, "water") == true then
        return false
    end
    if getPlayerExaust(cid, "water", "heal") == false then
        return false
    end
    if not canUseWaterSpell(cid, 1, 3, false) then
        return false
    end

    -- Le o target da storage 87654 (setado pelo opcode 210) e limpa imediatamente
    local targetCid = getPlayerStorageValue(cid, WATER_HEAL_TARGET_STORAGE)
    setPlayerStorageValue(cid, WATER_HEAL_TARGET_STORAGE, -1)

    if targetCid and type(targetCid) == "number" and targetCid > 0 and isPlayer(targetCid) then
        -- Modo: Water Heal com target definido via opcode 210
        workAllCdAndAndPrevCd(cid, "water", "heal", nil, 1)
        if getPlayerHasStun(cid) then return true end
        doPlayerAddExaust(cid, "water", "heal", waterExausted.heal)
        doSendHealthTarget(cid, targetCid)
    else
        -- Modo normal: cura na posicao do look
        workAllCdAndAndPrevCd(cid, "water", "heal", nil, 1)
        if getPlayerHasStun(cid) then return true end
        doPlayerAddExaust(cid, "water", "heal", waterExausted.heal)
        doSendHealthPos(cid, getCreatureLookPosition(cid))

        if isPlayer(cid) and getPlayerStorageValue(cid, "nuncaUsouWaterHeal") ~= 1 then
            setPlayerStorageValue(cid, "nuncaUsouWaterHeal", 1)
            sendBlueMessage(cid, 'Dica: Você pode utilizar esta dobra de duas outras formas: Water Heal "NomeDoJogador" - para curar este jogador em específico (sio) ou Water Sheal - para utilizar em si mesmo.')
        end
    end
    return true
end