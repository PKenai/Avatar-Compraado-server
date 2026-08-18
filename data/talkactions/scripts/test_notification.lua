function onSay(cid, words, param)
	local data = '{"title":"Teste de Notificação","message":"Este é um teste do sistema de notificações do Avatar!","color":"#00FF7F","duration":5000}'

	doSendPlayerExtendedOpcode(cid, 201, data)
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Notification test sent.")
	return true
end
