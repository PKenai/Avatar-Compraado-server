function onSay(cid, words, param)
	local data = '{"title":"Teste de Notificacao","message":"Este e um teste do sistema de notificacoes do Avatar!","color":"#00FF7F","duration":5000}'

	doSendPlayerExtendedOpcode(cid, 201, data)
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Notification test sent.")
	return true
end
