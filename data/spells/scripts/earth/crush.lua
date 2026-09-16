local spellName = "earth crush"
local cf = {atk = spellsInfo[spellName].atk}


local combat1 = createCombatObject()
setCombatParam(combat1, COMBAT_PARAM_TYPE, COMBAT_EARTHDAMAGE)
setCombatParam(combat1, COMBAT_PARAM_EFFECT, 287)

local combat2 = createCombatObject()
setCombatParam(combat2, COMBAT_PARAM_TYPE, COMBAT_EARTHDAMAGE)
setCombatParam(combat2, COMBAT_PARAM_EFFECT, 287)

local condition = createConditionObject(CONDITION_DRUNK)
setConditionParam(condition, CONDITION_PARAM_TICKS, 5000)
setCombatCondition(combat2, condition)

local t = {combat2, combat1, combat1}

-- 3x3 area centered on the player, hits all 8 surrounding squares
local arr = {
  {1, 1, 1},
  {1, 3, 1},
  {1, 1, 1}
}

local area = createCombatArea(arr)
setCombatArea(combat1, area)
setCombatArea(combat2, area)

for x = 1, 2 do
  function onGetPlayerMinMaxValues(cid, level, magLevel)
      local min = (level+(magLevel/4)*1.7)*1.4
      local max = (level+(magLevel/4)*2)*1.6
	if getPlayerInWaterWithUnderwater(cid) then 
		min = min*0.6
		max = max*0.6
	end
	local dano = math.random(min, max) + math.random(4, 8)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
	dano = dano*0.7
	if getDobrasLevel(cid) >= 1 then
		dano = dano*1.2
	end
	dano = remakeAirEarth(cid, dano)
    return -dano, -dano
  end
  setCombatCallback(t[x], CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
end

-- ===== Estagios da magia: mesma formula, area e numero de ondas diferentes =====
--   Mini  (<50)   : so' a cruz em volta do corpo (4 tiles)
--   Padrao(50-99) : o 3x3 de sempre, 3 ondas
--   Elite (100+)  : 5x5 rachando o chao + uma quarta onda e o alvo preso
-- A ordem espelha o t original: [1] com o CONDITION_DRUNK, [2] e [3] secos.
local function createCrushStageCombat(areaTable, withDrunk, fissure)
  local combat = createCombatObject()
  setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_EARTHDAMAGE)
  setCombatParam(combat, COMBAT_PARAM_EFFECT, 287)

  if withDrunk then
    local condition = createConditionObject(CONDITION_DRUNK)
    setConditionParam(condition, CONDITION_PARAM_TICKS, 5000)
    setCombatCondition(combat, condition)
  end

  setCombatArea(combat, createCombatArea(areaTable))

  function onGetPlayerMinMaxValues(cid, level, magLevel)
      local min = (level+(magLevel/4)*1.7)*1.4
      local max = (level+(magLevel/4)*2)*1.6
	if getPlayerInWaterWithUnderwater(cid) then 
		min = min*0.6
		max = max*0.6
	end
	local dano = math.random(min, max) + math.random(4, 8)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
	dano = dano*0.7
	if getDobrasLevel(cid) >= 1 then
		dano = dano*1.2
	end
	dano = remakeAirEarth(cid, dano)
    return -dano, -dano
  end
  setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")

  -- Fissura (estagio 3): quem e' pego pelo tremor fica preso no chao rachado
  if fissure then
    function onTargetCreatureFissure(cid, target)
      doSlow(cid, target, 40, 1200)
    end
    setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreatureFissure")
  end

  return combat
end

local tMini = {
  createCrushStageCombat(AREA_STAGE_MINI_PLUS, true, false),
  createCrushStageCombat(AREA_STAGE_MINI_PLUS, false, false),
  createCrushStageCombat(AREA_STAGE_MINI_PLUS, false, false)
}

local tElite = {
  createCrushStageCombat(AREA_STAGE_ELITE_SQUARE, true, true),
  createCrushStageCombat(AREA_STAGE_ELITE_SQUARE, false, true),
  createCrushStageCombat(AREA_STAGE_ELITE_SQUARE, false, true),
  createCrushStageCombat(AREA_STAGE_ELITE_SQUARE, false, true)
}

local function earthCrush(cid, times, combats)
	local playerPos = getCreaturePosition(cid)
	if times == 0 or not isCreature(cid) or isInPz(cid) or getTileInfo(playerPos).protection then 
		return false 
	end
	-- Hit all 8 squares around the player using the area
	doCombat(cid, combats[times], {type=2, pos=playerPos})
	addEvent(earthCrush, 500, cid, times-1, combats)
end 


function onCastSpell(cid, var)
  if getSpellCancels(cid, "earth") == true then
        return false
    end
    if doPlayerAddExaust(cid, "earth", "crush", earthExausted.crush) == false then
      return false
    end
  if getPlayerHasStun(cid) then
        return true
    end
	-- Estagio 3 (100+): o chao racha numa quarta onda
	local combats = pickSpellStage(cid, tMini, t, tElite)
	earthCrush(cid, isSpellElite(cid) and 4 or 3, combats)
  return true
end
