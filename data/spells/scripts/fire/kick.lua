local spellName = "fire kick"
local cf = {atk = spellsInfo[spellName].atk}

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)

local combatFocus = createCombatObject()
setCombatParam(combatFocus, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)

-- Ricochet settings (stage 2)
local RICOCHET_DISTANCE = 4  -- SQMs between bounces
local RICOCHET_MAX_TARGETS = 5  -- max creatures hit (including main)
local RICOCHET_DAMAGE_DECAY = 0.10  -- 10% less per bounce
local RICOCHET_DELAY = 200  -- ms between bounces

-- Create bounce combat objects with decreasing damage
local bounceCombats = {}
for i = 1, RICOCHET_MAX_TARGETS - 1 do
    local bounceCombat = createCombatObject()
    setCombatParam(bounceCombat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
    
    local damageMultiplier = 1 - (RICOCHET_DAMAGE_DECAY * i)
    
    _G["onGetPlayerMinMaxValuesBounce" .. i] = function(cid, level, magLevelUnused)
        local min = ((level + ((level * 0.5) / 2) * 3.5) + math.random(20, 25)) * damageMultiplier
        local max = ((level + ((level * 0.5) / 2) * 5.0) + math.random(25, 35)) * damageMultiplier
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
        if getDobrasLevel(cid) >= 2 then
            dano = dano * 1.2
        end
        dano = remakeValue(1, dano, cid)
        return -dano, -dano
    end
    setCombatCallback(bounceCombat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValuesBounce" .. i)
    
    bounceCombats[i] = bounceCombat
end

function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = (level + ((level * 0.5) / 2) * 3.5) + math.random(20, 25)
    local max = (level + ((level * 0.5) / 2) * 5.0) + math.random(25, 35)
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
    if getDobrasLevel(cid) >= 2 then
        dano = dano * 1.2
    end
    dano = remakeValue(1, dano, cid)
    return -dano, -dano
end
setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")

function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = ((level + ((level * 0.5) / 2) * 3.5) + math.random(20, 25)) * 2.25
    local max = ((level + ((level * 0.5) / 2) * 5.0) + math.random(25, 35)) * 2.25
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
    if getDobrasLevel(cid) >= 2 then
        dano = dano * 1.2
    end
    dano = remakeValue(1, dano, cid)
    return -dano, -dano
end
setCombatCallback(combatFocus, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")


function onCastSpell(cid, var)
    if getSpellCancels(cid, "fire") == true then
        return false
    end 
    if getPlayerExaust(cid, "fire", "kick") == false then
        return false
    end
    if getPlayerHasStun(cid) then
        doPlayerAddExaust(cid, "fire", "kick", fireExausted.kick)
        workAllCdAndAndPrevCd(cid, "fire", "kick", nil, 1)
        return true
    end
    local target = getCreatureTarget(cid)

    if target > 0 then
        if getDistanceBetween(getThingPos(cid), getThingPos(target)) < 5 then
                doPlayerAddExaust(cid, "fire", "kick", fireExausted.kick)
                workAllCdAndAndPrevCd(cid, "fire", "kick", nil, 1)
                local mypos = getThingPos(cid)
                doSendMagicEffect(mypos, 90)
                local targpos = getThingPos(target)
                local stage = getSpellStage(cid)
                -- Mini (<50): o chute sai curto, so' 2 rastros de chama
                doSendDistanceShoot({x=mypos.x+1, y=mypos.y, z=mypos.z}, targpos, 3)
                doSendDistanceShoot({x=mypos.x-1, y=mypos.y, z=mypos.z}, targpos, 3)
                if stage ~= SPELL_STAGE_MINI then
                    doSendDistanceShoot({x=mypos.x, y=mypos.y+1, z=mypos.z}, targpos, 3)
                    doSendDistanceShoot({x=mypos.x, y=mypos.y-1, z=mypos.z}, targpos, 3)
                end
                doSendMagicEffect({x=targpos.x+1, y=targpos.y+1, z=targpos.z}, 137)
            if getPlayerOverPower(cid, "fire", true, true) then
                -- Estagio 3 (100+): Combustao - o chute ecoa e o alvo pega fogo
                spellStageElite(cid, "fire", {pos=targpos, type=2}, combatFocus, target)
                local result = doCombat(cid, combatFocus, {pos=targpos, type=2})
                
                -- Ricochet for elite stage (also applies)
                if stage >= SPELL_STAGE_BASE then
                    doRicochet(cid, target, targpos, RICOCHET_MAX_TARGETS - 1, RICOCHET_DELAY, true)
                end
                
                return result
            else
                spellStageElite(cid, "fire", {pos=targpos, type=2}, combat, target)
                local result = doCombat(cid, combat, {pos=targpos, type=2})
                
                -- Ricochet for stage 2 (BASE and above)
                if stage >= SPELL_STAGE_BASE then
                    doRicochet(cid, target, targpos, RICOCHET_MAX_TARGETS - 1, RICOCHET_DELAY, false)
                end
                
                return result
            end
        else
            doPlayerSendCancelEf(cid, "Creature is not reachable.")
            return false
        end
    end
end

-- Ricochet function: bounces to nearby targets with decreasing damage
function doRicochet(cid, lastTarget, lastPos, bouncesLeft, delay, useFocus)
    if bouncesLeft <= 0 then
        return
    end
    
    -- Find nearby creatures within RICOCHET_DISTANCE SQMs
    local spectators = getSpectators(lastPos, RICOCHET_DISTANCE, RICOCHET_DISTANCE)
    local candidates = {}
    
    for _, spec in ipairs(spectators) do
        if isCreature(spec) and spec ~= cid and spec ~= lastTarget then
            local specPos = getThingPos(spec)
            local distance = getDistanceBetween(lastPos, specPos)
            if distance <= RICOCHET_DISTANCE and distance > 0 then
                -- Check if creature is attackable (not in protection zone, etc.)
                if not isInPz(spec) and isCreatureAlive(spec) then
                    table.insert(candidates, {creature = spec, distance = distance})
                end
            end
        end
    end
    
    -- Sort by distance (closest first)
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    
    -- Process the closest valid target
    if #candidates > 0 then
        local nextTarget = candidates[1].creature
        local nextPos = getThingPos(nextTarget)
        
        -- Schedule the bounce with delay
        addEvent(function()
            if isCreature(cid) and isCreature(nextTarget) then
                -- Visual effect: distance shoot from last position to next target
                doSendDistanceShoot(lastPos, nextPos, 3)
                
                -- Deal damage with decreasing multiplier
                local combatToUse = useFocus and bounceCombats[bouncesLeft] or bounceCombats[bouncesLeft]
                doCombat(cid, combatToUse, {pos=nextPos, type=2})
                
                -- Impact effect
                doSendMagicEffect(nextPos, 137)
                
                -- Continue bouncing with remaining hits
                doRicochet(cid, nextTarget, nextPos, bouncesLeft - 1, delay, useFocus)
            end
        end, delay)
    end
end

-- Helper function to check if creature is alive
function isCreatureAlive(creature)
    if not isCreature(creature) then
        return false
    end
    local health = getCreatureHealth(creature)
    return health and health > 0
end
