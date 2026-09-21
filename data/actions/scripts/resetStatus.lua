--------- FUNCTIONS ------------
local function onAddAtributo(cid, atributo, quantia)
	if atributo == "health" then                     
		setCreatureMaxHealth(cid, getCreatureMaxHealth(cid, true)+(50*quantia))
        doCreatureAddHealth(cid, 1)
	elseif atributo == "bend" then 
        doPlayerAddMagicLevel(cid, quantia)
	elseif atributo == "dodge" then 
		local oldDodge = getPlayerStorageValue(cid, "getPointsInDodge")
		if oldDodge < 1 then 
			oldDodge = 0
		end 
		local novoDodge = oldDodge+quantia
		setPlayerStorageValue(cid, "getPointsInDodge", novoDodge)
		if type(PlayerSpeed) == "table" and PlayerSpeed.setSource then
			PlayerSpeed.setSource(cid, "agi", novoDodge * 6)
		else
			doChangeSpeed(cid, 6*quantia)
		end
	elseif atributo == "speed" then 
		--doChangeSpeed(cid, 2*quantia)
	end 

end
local function getAgility(cid)
return getPlayerStorageValue(cid, "getPointsInDodge")
end 
local function getVitality(cid)
return getPlayerStorageValue(cid, "healthvalue")
end 
local function getManality(cid)
return getPlayerStorageValue(cid, "speedvalue")
end 
function resetAtributos(cid)
	-- Zera pontos de pedras elementais no MySQL
	local guid = getPlayerGUID(cid)
	db.executeQuery("UPDATE pedra_elemental SET pontos = 0 WHERE player_id = " .. guid)

	-- Agilidade e' uma fonte de velocidade: zerar a fonte devolve exatamente o
	-- que ela tinha posto.
	if type(PlayerSpeed) == "table" and PlayerSpeed.setSource then
		PlayerSpeed.setSource(cid, "agi", 0)
	elseif getAgility(cid) > 0 then
		doChangeSpeed(cid, -(6*(getAgility(cid))))
	end
	if getVitality(cid) > 1 then 
		local novaHealth = getCreatureMaxHealth(cid, true)-(50*(getVitality(cid)))
		local myHealth = getCreatureHealth(cid)
		if myHealth > novaHealth then 
			doCreatureAddHealth(cid, -(myHealth - novaHealth))
		elseif myHealth > 4 then
			doCreatureAddHealth(cid, -1) 
		else 
			doCreatureAddHealth(cid, 1) 
		end 
		setCreatureMaxHealth(cid, novaHealth)
	end 
	if getManality(cid) > 1 then 
		local novaMana = getCreatureMaxMana(cid, true)-(20*(getManality(cid)))
		local myMana = getCreatureMana(cid)
		if myMana > novaMana then 
			doCreatureAddMana(cid, -(myMana - novaMana))
		elseif myMana > 4 then
			doCreatureAddMana(cid, -1) 
		else 
			doCreatureAddMana(cid, 1) 
		end 
		setCreatureMaxMana(cid, novaMana)
	end 
	-- Avatar: bend de TREINO (varinha) e independente do bend de STATUS (pontos).
	-- Preserva o ml ganho treinando; so o bend comprado com pontos e resetado.
	local statusBend = getPlayerStorageValue(cid, "bendvalue")
	if type(statusBend) ~= "number" or statusBend < 0 then
		statusBend = 0
	end
	local trainingBend = getPlayerMagLevel(cid, true) - statusBend
	if trainingBend < 0 then
		trainingBend = 0
	end
	local atributosList = {"speed", "health", "bend", "dodge"}
	for i = 1, #atributosList do 
		local storageAtributo = atributosList[i] .. "value"
		setPlayerStorageValue(cid, storageAtributo, 0)
	end 
		setPlayerStorageValue(cid, "getPointsInDodge", 0)
		local lastLevel = getPlayerStorageValue(cid, 188100)
		lastLevel = lastLevel > 0 and lastLevel or 1
		setPlayerStorageValue(cid, "pendentes", lastLevel+4)
		--doSendPlayerExtendedOpcode(cid, 40, getAtributosString(cid))
		--exhaustion.set(cid, "lastReset", (60*60)*24)
		--doSendMagicEffect(getCreaturePosition(cid), 29)
		--doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Seus atributos foram resetados.")
		doPlayerResetMagicLevel(cid, trainingBend)
return true
end 

function onUse(cid, item, fromPosition, itemEx, toPosition)
	if not getTileInfo(getCreaturePosition(cid)).protection then 
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "É necessário estar em uma zona protegida (PZ) para resetar seus atributos.")
		return false 
	end 
	if getPlayerStorageValue(cid, "ativoBot") == 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você precisa responder ao Anti-Bot primeiro.")
		return false 
	end
    doRemoveItem(item.uid, 1)
	resetAtributos(cid)
  return true
end
