--[[
 * dailyHunt.lua (creaturescript)
 *
 * Registrado em data/creaturescripts/creaturescripts.xml como:
 *   <event type="kill"             name="DailyHunt"       value="dailyHunt.lua"/>
 *   <event type="extendedopcode"   name="DailyHuntOpcode" value="dailyHunt.lua"/>
 *
 * O player precisa registrar os dois eventos no login
 * (data/creaturescripts/scripts/loginLogout/login.lua).
]]

dofile(getDataDir() .. "lib/bossSystem.lua")
dofile(getDataDir() .. "lib/dailyHunt.lua")

function onKill(cid, target, lastHit)
	if not isPlayer(cid) then
		return true
	end
	if not isMonster(target) or isSummon(target) then
		return true
	end

	local name = getCreatureName(target)
	if type(name) ~= "string" then
		return true
	end

	-- Boss ALPHA morto: libera o slot de boss ativo do dono
	-- A luva NAO e' entregue aqui: ela esta na loot table do proprio boss
	-- (chance ~4% calculada no gerador). Esta mensagem so' informa.
	if BossSystem.isBossName(name) then
		local entry = BossSystem.onBossKilled(target)
		if entry then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
				name .. " foi derrotado! (a luva dele tinha 4% de chance no loot)")
		end
		return true
	end

	DailyHunt.onMonsterKill(cid, name)
	return true
end

function onExtendedOpcode(cid, opcode, buffer)
	if opcode ~= DailyHunt.opcode then
		return true
	end
	if not isPlayer(cid) then
		return true
	end

	buffer = buffer or ""

	-- anti-abuso: um client modificado pode mandar "request" centenas de vezes
	-- por segundo e o servidor monta o pacote inteiro a cada vez. Limita a um
	-- pedido por segundo por jogador (o login ja' manda a lista de qualquer forma).
	if buffer == "request" then
		local now = os.time()
		local last = tonumber(getPlayerStorageValue(cid, "DailyHunt_Req")) or 0
		if now - last >= 1 then
			setPlayerStorageValue(cid, "DailyHunt_Req", now)
			DailyHunt.sendDataToClient(cid)
		end
	elseif buffer == "claim" then
		DailyHunt.claim(cid)
	elseif buffer == "reroll" then
		DailyHunt.reroll(cid)
	else
		-- "claim:<slot>": premio (Moeda Avatar) da task concluida que o
		-- jogador selecionou clicando na linha da janela
		local slot = buffer:match("^claim:%s*(%d+)$")
		if slot then
			DailyHunt.claimTask(cid, tonumber(slot))
		end
	end

	return true
end
