--[[
 * dailyhunt.lua (talkaction) -- !dailyhunt [reroll|boss|reset|claim]
 *
 *   !dailyhunt            -> atualiza a janela do cliente
 *   !dailyhunt reroll     -> usa o re-roll do dia (troca ate 3 criaturas)
 *   !dailyhunt claim <n>  -> resgata o premio da task concluida do slot n (1..5)
 *   !dailyhunt claim      -> resgata os premios de marco em % de exp
 *   !dailyhunt boss       -> lista os bosses que o jogador liberou hoje
 *   !dailyhunt reset      -> (grupo >= 6) apaga a lista e sorteia de novo
]]

dofile(getDataDir() .. "lib/bossSystem.lua")
dofile(getDataDir() .. "lib/dailyHunt.lua")

function onSay(cid, words, param, channel)
	-- aceita "reroll", "boss", "reset", "claim" e "claim 3" / "claim:3"
	local action, arg = (param or ""):lower():gsub(":", " "):match("^(%a+)%s*(%d*)$")
	action = action or ""

	if action == "reroll" then
		DailyHunt.reroll(cid)
		return true
	end

	if action == "claim" then
		local slot = tonumber(arg)
		if slot then
			DailyHunt.claimTask(cid, slot)
		else
			DailyHunt.claim(cid)
		end
		return true
	end

	if action == "boss" then
		local list = BossSystem.getAccessList(cid)
		if #list == 0 then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
				"Você não tem nenhum boss liberado hoje. Complete uma task diária para liberar o portal ALPHA.")
			return true
		end
		local names = {}
		for _, name in ipairs(list) do
			table.insert(names, BossSystem.bossFor(name) or name)
		end
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Bosses liberados hoje: " .. table.concat(names, ", ") ..
			". Pise no tile do portal (item 19333/19334 / actionID 50030) na área da criatura.")
		return true
	end

	if action == "reset" then
		if getPlayerGroupId(cid) < 6 then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Comando disponível apenas para administradores.")
			return true
		end
		DailyHunt.generate(cid)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Sua task diária foi sorteada novamente.")
		return true
	end

	DailyHunt.sendDataToClient(cid)
	return true
end
