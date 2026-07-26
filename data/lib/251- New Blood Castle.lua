bloodconfig = {
     templo = {x = 505, y = 342, z = 7}, -- templo

     posGuarda = {x = 127, y = 156, z = 13}, -- Onde o guarda do portão vai nascer

     positionTP = {x = 501, y = 357, z = 7}, -- Onde o tp será criado

     positionEvento = {x = 128, y = 221, z = 13}, -- Para onde o tp vai levar

     posPedras = {{x = 126, y = 220, z = 13, stackpos=1}, {x = 127, y = 220, z = 13, stackpos=1}, {x = 128, y = 220, z = 13, stackpos=1}, {x = 129, y = 220, z = 13, stackpos=1}}, -- Posições das pedras que bloqueiam a entrada do evento

     idDasParedes = 1547, -- ID das paredes que vao ser removidas quando o Guarda morrer (todas devem ter o mesmo id)

     estatua = {x = 127, y = 130, z = 13}, -- Posicao onde o arcanjo vai ser criado

     posParedes = {
		{x = 125, y = 154, z = 13},
		{x = 126, y = 154, z = 13}, -- Posições das paredes que ficam atrás do guarda
		{x = 127, y = 154, z = 13}, -- Posições das paredes que ficam atrás do guarda
		{x = 128, y = 154, z = 13}, -- Posições das paredes que ficam atrás do guarda
		{x = 129, y = 154, z = 13}, -- Posições das paredes que ficam atrás do guarda
		}, -- Posições das paredes que ficam atrás do guarda

     fromPos = {x = 114, y = 128, z = 13}, -- Canto superior esquerdo da área do seu evento ---- Deve ser uma área quadrada ou retangular, de forma que todo o evento fique dentro dela.
     toPos = {x = 146, y = 245, z = 13}, -- Canto inferior direito da área do seu evento
	 bloodParticipantes = {}
}

function doContagemRegressiva(pos, times)
	if times >= 1 then 
		doSendAnimatedText(pos, times, 215)
		addEvent(doContagemRegressiva, 1000, pos, times-1)
	end 
end 

function bloodCreateEvent()
	local specs = getSpectators(bloodconfig.positionTP, 1, 0)
	if specs and #specs >= 1 then 
		for i = 1, #specs do 
			local spec = specs[i]
			if getCreaturePosition(spec).x == bloodconfig.positionTP.x and getCreaturePosition(spec).y == bloodconfig.positionTP.y then 
				doTeleportThing(spec, {x = 502, y = 357, z = 7}, true)
			end
		end
	end 
	local tp = doCreateItem(1387, 1, bloodconfig.positionTP)
	doSendMagicEffect(bloodconfig.positionTP, 10)
	doContagemRegressiva(bloodconfig.positionTP, 180)
	doContagemRegressiva({x=127, y=220, z=13}, 180)
	doSetItemActionId(tp, 58914)
	addEvent(bloodStart, 180000) 
	doBroadcastMessage("[Evento - Blood Castle] O Blood Castle foi aberto por 3 minutos! Para todos que desejam participar, o portal se localiza no depot de Ba Sing Se. Somente dobradores com nível maior ou igual à 50 podem entrar!")
end

function bloodOnEnter(cid)
	return setPlayerStorageValue(cid, "bloodKills", 0)
end

function bloodGetKills(cid)
	local kills = getPlayerStorageValue(cid, "bloodKills")
	return kills >= 1 and kills or 0
end

function bloodAddKills(cid, amount)
	local kills = getPlayerStorageValue(cid, "bloodKills")
	if kills < 0 then
		kills = 0
	end	
	return setPlayerStorageValue(cid, "bloodKills", kills+amount)
end 

function doPlayerAddEventPoints(cid, amount)
	--doPlayerAddItem(cid, 6527, amount)
	if amount == 3 then 
		doPlayerAddItem(cid, 12831, 1)
	end 
	return true
end 

function getPlayerEventPoints(cid)
	local points = getPlayerStorageValue(cid, "eventPoints")
	return points >= 1 and points or 0
end 

function bloodRemoveStones() -- removando as 2 grades que starta o evento
     for i = 1, #bloodconfig.posPedras do
          local pedra = getTileItemById(bloodconfig.posPedras[i], 1547)
          if pedra then
               doRemoveItem(pedra.uid, 1)
          end
     end
end

function bloodPutStones() -- colocando as 2 grades que starta o evento
     for i = 1, #bloodconfig.posPedras do
          local pedra = getTileItemById(bloodconfig.posPedras[i], 1547)
          if not pedra then
               doCreateItem(1547, 1, pedra)
          end
     end
end

function bloodRemoveTpa() -- remove o tp criado no dp
     local t = getTileItemById(bloodconfig.positionTP, 1387)
     if t then
          doRemoveItem(t.uid, 1)
          doSendMagicEffect(bloodconfig.positionTP, CONST_ME_POFF)
     end
end

function bloodGetPlayers()
	local jogadores = {}
     for _, pid in pairs(getPlayersOnline()) do
          if isInArea(getThingPos(pid), bloodconfig.fromPos, bloodconfig.toPos) then
			table.insert(jogadores, pid)
		  end
     end
 return jogadores
end

function bloodRemovePlayers()
	local jogadores = bloodGetPlayers()
	local teleportou = 0
		if #jogadores >= 1 then 
			teleportou = 1
			for i = 1, #jogadores do 
				local pid = jogadores[i]
				doTeleportThing(pid, bloodconfig.templo, false)
				local bloodKills = bloodGetKills(pid)
				if bloodKills <= 0 then 
					doPlayerSendTextMessage(pid, MESSAGE_STATUS_CONSOLE_BLUE, "Você não matou monstros no Blood Castle, portanto não receberá recompensa. Boa sorte na próxima vez!")
				else 
					local myLevel = getPlayerLevel(pid)
					local finalExp = myLevel * 30
					finalExp = finalExp * (bloodKills+5)
					doPlayerAddExperience(pid, finalExp)
					doSendAnimatedText(getCreaturePosition(pid), finalExp, 215)
					doPlayerSendTextMessage(pid, MESSAGE_STATUS_CONSOLE_BLUE, "Você derrotou "..bloodKills.." monstros no Blood Castle e recebeu um bônus de "..finalExp.." pontos de EXP!")
				end 
			end
		end
	if teleportou == 1 then 
		doSendMagicEffect(bloodconfig.templo, 10)
	end 
end

function bloodStart()
	bloodRemoveTpa()
    bloodRemoveStones()
	doBroadcastMessage("[Evento - Blood Castle] O Evento começou. Boa sorte à todos os participantes!")
    if not isMonster(getTopCreature(bloodconfig.posGuarda).uid) then
       doCreateMonster("Blood Guard", bloodconfig.posGuarda)
    end
end

function bloodPutWalls()
     for i = 1, #bloodconfig.posParedes do
          doCreateItem(bloodconfig.idDasParedes, 1, bloodconfig.posParedes[i])
     end
end

function bloodRemoveWalls()
     for i = 1, #bloodconfig.posParedes do
          local wall = getTileItemById(bloodconfig.posParedes[i], bloodconfig.idDasParedes)
          if wall then
               doRemoveThing(wall.uid, 1)
          end
     end
end

function bloodCreateAngel()
     if not isMonster(getTopCreature(bloodconfig.estatua).uid) then
          doCreateMonster("Beelzeboss", bloodconfig.estatua)
     end
end