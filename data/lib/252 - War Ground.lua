jogadoresTeam = {{}, {}}
lastRegister = 2
warconfig = {
	positionTP = {x = 501, y = 357, z = 7},
    posPedras = {{x = 1076, y = 415, z = 7, stackpos=1}, {x = 1076, y = 416, z = 7, stackpos=1}, {x = 1076, y = 417, z = 7, stackpos=1}, {x = 1076, y = 418, z = 7, stackpos=1}, {x = 1076, y = 419, z = 7, stackpos=1}},
	posTimes = {{x = 1048, y = 417, z = 7}, {x = 1105, y = 417, z = 7}},
}
local conditionE = createConditionObject(CONDITION_INFIGHT)
setConditionParam(conditionE, CONDITION_PARAM_TICKS, 3600000)
function warCreateEvent()
	doSetStorage("comecouWar", 0)
	doSetStorage("lider1", 0)
	doSetStorage("lider2", 0)
	local specs = getSpectators(warconfig.positionTP, 1, 0)
	if specs and #specs >= 1 then 
		for i = 1, #specs do 
			local spec = specs[i]
			if getCreaturePosition(spec).x == warconfig.positionTP.x and getCreaturePosition(spec).y == warconfig.positionTP.y then 
				doTeleportThing(spec, {x=502, y=357, z=7}, true)
			end
		end
	end 
	local tp = doCreateItem(1387, 1, warconfig.positionTP)
	doSendMagicEffect(warconfig.positionTP, 10)
	doContagemRegressiva(warconfig.positionTP, 180)
	doContagemRegressiva(warconfig.posPedras[3], 180)
	doSetItemActionId(tp, 43277)
	addEvent(warStart, 180000)
	doBroadcastMessage("[Evento - War Ground] O War Ground foi aberto por 3 minutos! Para todos que desejam participar, o portal se localiza no depot de Ba Sing Se. Somente dobradores com nível maior ou igual à 50 podem entrar!")
end

function warStart()
	doSetStorage("comecouWar", 1)
	warRemoveTpa()
    warRemoveStones()
	doBroadcastMessage("[Evento - War Ground] O Evento começou. Boa sorte aos times!")
end

function getComecou()
	return getStorage("comecouWar") == 1
end

function warRemoveStones() -- removando as 2 grades que starta o evento
     for i = 1, #warconfig.posPedras do
          local pedra = getTileItemById(warconfig.posPedras[i], 17823)
          if pedra then
               doRemoveItem(pedra.uid, 1)
          end
     end
end

function warRemoveTpa() -- remove o tp criado no dp
     local t = getTileItemById(warconfig.positionTP, 1387)
     if t then
          doRemoveItem(t.uid, 1)
          doSendMagicEffect(warconfig.positionTP, CONST_ME_POFF)
     end
end

function warRegister(cid)
		local team = 1
		if lastRegister == 1 then 
			team = 2
		end 
		lastRegister = team
		doTeleportThing(cid, warconfig.posTimes[team])
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
		setPlayerStorageValue(cid, "timeWar", team)
		table.insert(jogadoresTeam[team], cid)
		registerCreatureEvent(cid, "warKill")
		setPlayerStorageValue(cid, "warKills", 0)
--		if getPlayerStorageValue(cid, "canAttackable") == 1 then 
--			setPlayerStorageValue(cid, "estavaNon", 1)
--			setPlayerStorageValue(cid, "Archangel", 0)
--			setPlayerStorageValue(cid, "canAttackable", 0)
--			doCreatureSetGuildEmblem(cid, 0)
--		end

		local teamName = {"Raava", "Vaatu"}
		doPlayerSendTextMessage(cid, 22, "Você entrou para o time "..teamName[team]..", boa sorte!")
		local totalPlayers = #getParticipantes()
		if not totalPlayers or totalPlayers < 3 then 
			doSetStorage("lider" .. team, cid)
		elseif isCreature(getStorage("lider" .. team)) then
			doPlayerJoinParty(cid, getStorage("lider" .. team))
		else 
			doSetStorage("lider" .. team, cid)
		end 
		--doAddCondition(cid, conditionE)
		--doPlayerSetPzLocked(cid, true)
end

function isInWarGround(cid)
	local pos = getCreaturePosition(cid)
	return pos.z == 7 and pos.x > 1036 and pos.y > 391 and pos.x < 1116 and pos.y < 440
end

function warKill(cid, target)
	if isInWarGround(cid) then 
		if getPlayerStorageValue(cid, "timeWar") ~= getPlayerStorageValue(target, "timeWar") then 
			setPlayerStorageValue(cid, "warKills", getPlayerStorageValue(cid, "warKills")+1)
		end
	end 
end

function rewardWarplayer(cid)
	doCreatureAddHealth(cid, getCreatureMaxHealth(cid)-getCreatureHealth(cid), true)
	doCreatureAddMana(cid, getCreatureMaxMana(cid)-getCreatureMana(cid))
	doTeleportThing(cid, bloodconfig.templo)
	doPlayerSetPzLocked(cid, false)
	doCreatureSetNoMove(cid, false)
	setPlayerStorageValue(cid, "timeWar", 0)
	local warKills = getPlayerStorageValue(cid, "warKills")
	if warKills <= 50000 then 
		--doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Você não matou ninguém no War Ground, portanto não receberá recompensa. Boa sorte na próxima vez!")
		local myLevel = getPlayerLevel(cid)
		local finalExp = myLevel * 35
		finalExp = finalExp * 75
		doPlayerAddExperience(cid, finalExp)
		doSendAnimatedText(getCreaturePosition(cid), finalExp, 215)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Pela sua participação no War Ground, você recebeu "..finalExp.." pontos de EXP!")
	else 
		local myLevel = getPlayerLevel(cid)
		local finalExp = myLevel * 35
		finalExp = finalExp * (warKills+5)
		doPlayerAddExperience(cid, finalExp)
		doSendAnimatedText(getCreaturePosition(cid), finalExp, 215)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Você derrotou "..warKills.." jogadores no War Ground e recebeu "..finalExp.." pontos de EXP!")
	 end 
--	if getPlayerStorageValue(cid, "estavaNon") == 1 then 
--		setPlayerStorageValue(cid, "estavaNon", 0)
--		setPlayerStorageValue(cid, "Archangel", 1)
--		setPlayerStorageValue(cid, "canAttackable", 1)
--		doCreatureSetGuildEmblem(cid, 1)
--	end 
	--doRemoveCondition(cid, CONDITION_INFIGHT)
		if isInParty(cid) then 
			doPlayerLeaveParty(cid, true)
		end
end

function getParticipantes()
local specs = getSpectators({x=1076, y=417, z=7}, 37, 37)
local participantes = {}
	if specs and #specs ~= 0 then 
		for i = 1, #specs do 
			if isPlayer(specs[i]) and getPlayerGroupId(specs[i]) <= 2 then 
				table.insert(participantes, specs[i])
			end 
		end 
	end 
	return participantes
end 

function checkWarEnd()
	if getStorage("comecouWar") == 0 then 
		return true
	end
	local isAliveOne = false
	local isAliveTwo = false
	local participantes = getParticipantes()
	for i = 1, #participantes do 
		if getPlayerStorageValue(participantes[i], "timeWar") == 1 then 
			isAliveOne = true
		elseif getPlayerStorageValue(participantes[i], "timeWar") == 2 then
			isAliveTwo = true
		end
	end
	
	if not isAliveOne or not isAliveTwo then 
		for i = 1, #participantes do 
			rewardWarplayer(participantes[i])
		end 
		doSetStorage("comecouWar", 0)
		if not isAliveOne then 
			doBroadcastMessage("[Evento - War Ground] O time Vaatu foi o vencedor da guerra de hoje!")
		else 
			doBroadcastMessage("[Evento - War Ground] O time Raava foi o vencedor da guerra de hoje!")
		end
	end 
end

function isSameWarTeam(cid, target)
	return isInWarGround(cid) and isInWarGround(target) and getPlayerStorageValue(cid, "timeWar") == getPlayerStorageValue(target, "timeWar")
end