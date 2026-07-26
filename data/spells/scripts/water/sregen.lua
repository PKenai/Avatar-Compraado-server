local spellName = "water sregen"
local cf = {segundos = spellsInfo[spellName].segundos, quantia = spellsInfo[spellName].quantia}

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_AGGRESSIVE, 0)
setCombatParam(combat, COMBAT_PARAM_EFFECT, CONST_ME_MAGIC_BLUE)


local condition = createConditionObject(CONDITION_REGENERATION)
setConditionParam(condition, CONDITION_PARAM_TICKS, cf.segundos*1000)
setConditionParam(condition, CONDITION_PARAM_HEALTHGAIN, cf.quantia)
setConditionParam(condition, CONDITION_PARAM_HEALTHTICKS, 1)
setCombatCondition(combat, condition)

function onTargetCreature(cid, target)
    doSendAnimatedText(getThingPos(target), "Regen!", COLOR_LIGHTBLUE)            
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(cid, var)

    if getSpellCancels(cid, "water") == true then
        return false
    end

    if getPlayerExaust(cid, "water", "regen") == false then 
        return false
    end

    if canUseWaterSpell(cid, 1, 3, false) then
        doPlayerAddExaust(cid, "water", "regen", waterExausted.regen)
        workAllCdAndAndPrevCd(cid, "water", "heal", nil, 1)
        if getPlayerHasStun(cid) then
            return true
        end
         
        return doCombat(cid, combat, var)
    else
        return false
    end
end