
--focus ready--

local MyLocal = {}

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
setCombatParam(combat, COMBAT_PARAM_EFFECT, CONST_ME_HITBYFIRE)
setCombatParam(combat, COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_FIRE)
setCombatParam(combat, COMBAT_PARAM_CREATEITEM, 1492)
setCombatParam(combat, COMBAT_PARAM_AGGRESSIVE, false)

function onCastSpell(cid, var)
    if getSpellCancels(cid, "fire") == true then
        return false
    end

    if not getPlayerCanWalk({player = cid, position = var.pos, checkPZ = true, checkHouse = true, checkWater = true}) then
        doPlayerSendCancelEf(cid, "It isn't possible use this fold here.")
        return false
    end

    if doPlayerAddExaust(cid, "fire", "field", fireExausted.field) == false then
      return false
    end
    if getPlayerHasStun(cid) then
        workAllCdAndAndPrevCd(cid, "fire", "field", nil, 1)
      return true
    end

    getPlayerOverPower(cid, "fire", true, true)
    workAllCdAndAndPrevCd(cid, "fire", "field", nil, 1)
  return doCombat(cid, combat, var)
end
