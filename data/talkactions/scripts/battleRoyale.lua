dofile(getDataDir().."lib/battleRoyale.lua")

function onSay(cid, words, param, channel)
	local cmd = string.lower(param or "")

	if cmd == "start" or cmd == "iniciar" then
		local ok, msg = BattleRoyale.startRound()
		if not ok then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, msg)
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Battle Royale iniciado! O tornado abriu ao norte de Ba Sing Se e o Cajado de Sonam nasceu na arena.")
		end
	elseif cmd == "abort" or cmd == "stop" or cmd == "cancelar" then
		if BattleRoyale.isActive() then
			BattleRoyale.endRound(nil)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Rodada abortada. Todos foram teleportados para fora da arena.")
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Nao ha rodada ativa no momento.")
		end
	else
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, BattleRoyale.status())
	end
	return true
end