

function onSay(cid, words, param, channel)
  local param = string.explode(param, ",")

  if param[1] == nil or param[2] == nil then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Parâmetro incorreto. Digite /msg Nick, mensagem")
		return true 
	end 
	local nick = param[1]
	local texto = param[2]
	local player = getPlayerByNameWildcard(nick)
	if not player then 
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Jogador offline.")
		return true 
	end 
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_RED, "[Mensagem do Moderador]: " ..texto)
		doPlayerSendTextMessage(player, MESSAGE_STATUS_CONSOLE_RED, "[Mensagem do Moderador]: " ..texto)
  return true
end