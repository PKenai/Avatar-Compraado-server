function onLogin(cid)
	local result = db.getResult("select * from accounts_message where account = '" .. getPlayerAccount(cid) .. "' and nivel >= 1 and `read` = 0 order by id desc limit 1")
	if result:getID() ~= -1 then
		local msg = result:getDataString("mensagem")
		local msg_id = result:getDataInt("id")	
		doPlayerPopupFYI(cid, msg)
		db.executeQuery('UPDATE `accounts_message` SET `read` = 1 WHERE `id` = ' ..msg_id..';')
	end
    return true
end