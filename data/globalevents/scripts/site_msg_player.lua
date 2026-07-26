function onThink(interval)
	for i,v in pairs (getOnlinePlayers()) do
		local player = getPlayerByName(v)
		local result = db.getResult("select * from accounts_message where account = '" .. getPlayerAccount(player) .. " ' and nivel >= 1 and `read` = 0 order by id desc limit 1")	
		if result:getID() ~= -1 then
			local msg = result:getDataString("mensagem")
			local msg_id = result:getDataInt("id")
			db.executeQuery('UPDATE `accounts_message` SET `read` = 1 WHERE `id` = ' ..msg_id..';')			
			if not isPlayerBattle(player) then
				doPlayerPopupFYI(player, msg)
			end
		end
	end
	return true
end