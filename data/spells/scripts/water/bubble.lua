local chanceFrozzen = 10
local timeFrozzen = 2000

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_DROWNDAMAGE)
setCombatParam(combat, COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_ICE)
setCombatParam(combat, COMBAT_PARAM_EFFECT, 75)


function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = (level+((level * 0.5)/3)*2.7)+5
    local max = (level+((level * 0.5)/3)*3.0)+5

    return -min, -max
end
setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")

function onTargetCreature(cid, target)
    if math.random(1, 100) <= chanceFrozzen then
        doFrozzenCreature(target, timeFrozzen)            
    end
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")


function onCastSpell(cid, var)
    if getSpellCancels(cid, "water") == true then
        return false
    end

  if getPlayerExaust(cid, "water", "bubble") == false then
    return false
  end

    doPlayerAddExaust(cid, "water", "bubble", waterExausted.bubble)
  if getPlayerHasStun(cid) then
        return true
    end
  return doCombat(cid, combat, var) 
end

