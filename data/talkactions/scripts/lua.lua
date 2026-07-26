function onSay(cid, words, param) --- comando /lua By mock
	_G.cid = cid
	local f , err = loadstring(param)
	if f then
			local ret,err = pcall(f)
			if not ret then
					doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, 'Lua error:\n'..err)
			end
	else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,'Lua error:\n'..err)
	end
	return true

end 