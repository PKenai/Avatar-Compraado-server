local spellName = "fire blast"
local cf = {atk = spellsInfo[spellName].atk}

--focus ready--

local MyLocal = {}

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
setCombatParam(combat, COMBAT_PARAM_EFFECT, 6)
setCombatParam(combat, COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_FIRE)
setAttackFormula(combat, COMBAT_FORMULA_LEVELMAGIC, 5, 5, 4, 7)
setCombatArea(combat, createCombatArea(AREA_CROSS1X1))

local combatFocus = createCombatObject()
setCombatParam(combatFocus, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
setCombatParam(combatFocus, COMBAT_PARAM_EFFECT, 6)
setCombatParam(combatFocus, COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_FIRE)
setAttackFormula(combatFocus, COMBAT_FORMULA_LEVELMAGIC, 5, 5, 4, 7)
setCombatArea(combatFocus, createCombatArea(AREA_CROSS1X1))

function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = (level+((level * 0.5)/2)*3.0)+math.random(20, 25)
    local max = (level+((level * 0.5)/2)*4.0)+math.random(25, 35)
	if getPlayerInWaterWithUnderwater(cid) then 
		min = min*0.5
		max = max*0.5
	end
	local dano = math.random(min, max)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
    return -dano, -dano
end
setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")

function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = ((level+((level * 0.5)/2)*3.0)+math.random(20, 25))*1.5
    local max = ((level+((level * 0.5)/2)*4.0)+math.random(25, 35))*2.0
	if getPlayerInWaterWithUnderwater(cid) then 
		min = min*0.5
		max = max*0.5
	end
	local dano = math.random(min, max)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
    return -dano, -dano
end
setCombatCallback(combatFocus, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")

-- ===== Estagios da magia: mesmo dano, area diferente =====
--   Mini  (<50)   : explode so' no alvo
--   Padrao(50-99) : cruz 3x3, exatamente o que a magia sempre foi
--   Elite (100+)  : cruz larga 7x7, a explosao toma a rua inteira
-- minMult/maxMult reproduzem o dano original: base 1/1, focus 1.5/2.0
local function createBlastStageCombat(area, minMult, maxMult)
    local combat = createCombatObject()
    setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
    setCombatParam(combat, COMBAT_PARAM_EFFECT, 6)
    setCombatParam(combat, COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_FIRE)
    setAttackFormula(combat, COMBAT_FORMULA_LEVELMAGIC, 5, 5, 4, 7)
    setCombatArea(combat, createCombatArea(area))

    function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
        local min = (level+((level * 0.5)/2)*3.0)+math.random(20, 25)
        local max = (level+((level * 0.5)/2)*4.0)+math.random(25, 35)
        min = min*minMult
        max = max*maxMult
        if getPlayerInWaterWithUnderwater(cid) then 
            min = min*0.5
            max = max*0.5
        end
        local dano = math.random(min, max)
        local atk = cf.atk
        if atk and type(atk) == "number" then 
            dano = dano * (atk/100)
            dano = dano+1
        end
        return -dano, -dano
    end
    setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
    return combat
end

local combatMini       = createBlastStageCombat(AREA_STAGE_SOLO, 1, 1)
local combatElite      = createBlastStageCombat(AREA_STAGE_ELITE_SELF, 1, 1)
local combatMiniFocus  = createBlastStageCombat(AREA_STAGE_SOLO, 1.5, 2.0)
local combatEliteFocus = createBlastStageCombat(AREA_STAGE_ELITE_SELF, 1.5, 2.0)

function onTargetCreature(cid, target)

end
setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onTargetCreatureFocus(cid, target)

end
setCombatCallback(combatFocus, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreatureFocus")


function onCastSpell(cid, var)
    if getSpellCancels(cid, "fire") == true then
        return false
    end
    if doPlayerAddExaust(cid, "fire", "blast", fireExausted.blast) == false then
      return false
    end
    if getPlayerHasStun(cid) then
        workAllCdAndAndPrevCd(cid, "fire", "blast", nil, 1)
        return true
    end

  -- Estagio 3: alem da area, o alvo principal pega fogo (Combustao)
  local target = type(var) == "number" and variantToNumber(var) or 0

  if getPlayerOverPower(cid, "fire", true, true) == true then
        workAllCdAndAndPrevCd(cid, "fire", "blast", nil, 1)
    local combatStage = pickSpellStage(cid, combatMiniFocus, combatFocus, combatEliteFocus)
    spellStageElite(cid, "fire", var, nil, target)
    return doCombat(cid, combatStage, var)
  else
        workAllCdAndAndPrevCd(cid, "fire", "blast", nil, 1)
    local combatStage = pickSpellStage(cid, combatMini, combat, combatElite)
    spellStageElite(cid, "fire", var, nil, target)
    return doCombat(cid, combatStage, var)
  end
end