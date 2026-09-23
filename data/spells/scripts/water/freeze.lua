-- Water Freeze: congela o alvo no lugar, no molde do Earth Petrify.
-- O congelamento usa o doFrozzenCreature (050-function.lua), o MESMO efeito que
-- Water IceBolt / IceBeam / Blizzard usam: efeito 139 no player, 52 no monstro e
-- o texto "Frozzen!". O helper prende 3s (monstro) / 2s (player); a dobra prende
-- pelo tempo dela (cf.segundos), com imunidade de metade do tempo.
local spellName = "water freeze"
local cf = {atk = spellsInfo[spellName].atk, segundos = spellsInfo[spellName].segundos}

local MyLocal = {}
MyLocal.time = cf.segundos
MyLocal.players = {}

local combat = createCombatObject()

local combat2 = createCombatObject()
setCombatParam(combat2, COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE) -- o proprio dano de gelo ja' da' o hit de gelo

function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
    local min = (level+((level * 0.5)/4)*5)+5
    local max = (level+((level * 0.5)/4)*5.5)+10

	local dano = math.random(min, max)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
	dano = remakeValue(2, dano, cid)
    return -dano, -dano
end
setCombatCallback(combat2, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
registerSpellStageEcho(combat2)

local function removeMark(cid) -- getCreatureNoMove(cid)
  MyLocal.players[cid] = nil
end

function onTargetCreature(cid, target)
  doCombat(cid, combat2, numberToVariant(target))

  local time = MyLocal.time
  if getDobrasLevel(cid) >= 6 then -- pedra de upgrade 6: congelamento 50% mais longo
    time = time*1.5
  end
  if isPlayer(target) then
    time = time/2
  end

  -- Alvo que nao aceita prisao agora (ja congelado, ou na janela de imunidade):
  -- o helper da' o slow e o aviso padrao, sem estender a trava.
  if isDisableImmune(target) then
    doFrozzenCreature(target, 0)
    return true
  end

  doFrozzenCreature(target, time*1000)
  setCreatureNoMoveTime(target, time*1000, time*500)
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(cid, var)
    if getSpellCancels(cid, "water") == true then
        return false
    end
  local target = getCreatureTarget(cid)
  if MyLocal.players[cid] == nil then
    if getDistanceBetween(getThingPos(cid), getThingPos(target)) < 5 then
      if getPlayerExaust(cid, "water", "freeze") == false then
        return false
      end
      if cantReceiveDisable(cid, target) then
        return false
      end
      if getPlayerHasStun(cid) then
        return true
      end
      if not canUseWaterSpell(cid, 1, 3, false) then
        return false
      end
      doPlayerAddExaust(cid, "water", "freeze", waterExausted.freeze)
      doCombat(cid, combat, var)
      MyLocal.players[cid] = false
      -- limpeza garantida do marcador: o removeMark por alvo pode nao rodar
      -- (alvo morre/desaparece antes do hit) e travaria a dobra pra sempre
      addEvent(removeMark, math.max(MyLocal.time, 1)*2000, cid)
      return true
    else
      doPlayerSendCancelEf(cid, "Creature is not reachable.")
      return false
    end
  else
    doPlayerSendCancelEf(cid, "You're already using this fold.")
    return false
  end
end
