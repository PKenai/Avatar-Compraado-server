local spellName = "earth pull"
local cf = {atk = spellsInfo[spellName].atk}

local MyLocal = {}
MyLocal.earthId = 13846
MyLocal.time = 3

local combat = createCombatObject()
local combat2 = createCombatObject()
setCombatParam(combat2, COMBAT_PARAM_TYPE, COMBAT_EARTHDAMAGE)
setCombatParam(combat2, COMBAT_PARAM_EFFECT, 34)

function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = (level+((level * 0.5)/5)*4.0)+math.random(2, 3)
    local max = (level+((level * 0.5)/5)*4.3)+math.random(3, 4)
	if getPlayerInWaterWithUnderwater(cid) then 
		min = min * 0.6
		max = max * 0.6
	end
	local dano = math.random(min, max)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
	if getDobrasLevel(cid) >= 5 then
		dano = dano*1.2
	end
	dano = remakeAirEarth(cid, dano)
    return -dano, -dano
end
setCombatCallback(combat2, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
registerSpellStageEcho(combat2)

function onTargetCreature(cid, target)
  local playerPos = getCreaturePos(cid)
  local targetPos = getCreaturePos(target)

  -- Guarda: posições devem ser tabelas válidas
  if type(playerPos) ~= "table" or type(targetPos) ~= "table" then
    return false
  end

  -- Congela a posição do item ANTES de qualquer movimento
  local itemPos = {x = targetPos.x, y = targetPos.y, z = targetPos.z}

  if getDistanceBetween(playerPos, targetPos) > 7 then
    doPlayerSendCancelEf(cid, "The target is too far.")
    return false
  end
  if getDistanceBetween(playerPos, targetPos) > 1 and getPlayerStorageValue(target, "playerOnAir") == 1 then							
	doPushCreature(target, getDirectionTo(targetPos, playerPos), 1, 500, false, true)
  elseif getDistanceBetween(playerPos, targetPos) > 1 then
    doPushCreature(target, getDirectionTo(targetPos, playerPos))
  end
  doCombat(cid, combat2, numberToVariant(target))
  -- Monstro: o "rocks" nasce no tile do alvo e o sprite do personagem esconde o
  -- item (item de chao desenha atras de criatura); e o empurrao acima nao
  -- acontece quando o bicho esta colado (targetdistance=1). Sem este tiro a
  -- conjuracao do monstro ficava invisivel - so sobrava o dano. A pedra que voa
  -- do conjurador ate o alvo deixa o earth pull do monstro visivel na tela.
  if isMonster(cid) then
    doSendDistanceShoot(playerPos, itemPos, CONST_ANI_LARGEROCK)
  end
  doCreateItem(MyLocal.earthId, itemPos)
  addEvent(removeTileItemById, MyLocal.time*1000, itemPos, MyLocal.earthId)
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(cid, var)
    if getSpellCancels(cid, "earth") == true then
        return false
    end
     if getPlayerExaust(cid, "earth", "pull") == false then
    return false
  end
  doPlayerAddExaust(cid, "earth", "pull", earthExausted.pull)
  if getPlayerHasStun(cid) then
        return true
    end
  doCombat(cid, combat, var)
  return true                                                                                                                                                                                           
end     





