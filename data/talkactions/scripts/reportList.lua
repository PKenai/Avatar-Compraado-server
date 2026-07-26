

function onSay(cid, words, param, channel)
	if not #reportsEnviados or #reportsEnviados == 0 then 
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Nenhum report novo no sistema.")
		return true 
	end 
	local inicio = 1
	if #reportsEnviados >= 12 then 
		inicio = #reportsEnviados-10
	end
	for i = inicio, #reportsEnviados do 
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, reportsEnviados[i])
		if i ~= #reportsEnviados then 
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "________________________")
		end
	end 
  return true
end