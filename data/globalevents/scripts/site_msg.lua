function onThink(interval)
	local result = db.getResult("select * from accounts_message where account = 'global' and nivel >= 1 and `read` = 0 order by id desc limit 1")
	
	if result:getID() ~= -1 then
		local msg = result:getDataString("notificationInGame")
		local msg_id = result:getDataInt("id")
		db.executeQuery('UPDATE `accounts_message` SET `read` = 1 WHERE `id` = ' ..msg_id..';')
		for i,v in pairs (getOnlinePlayers()) do
			print'true'
			local player = getPlayerByName(v)
			if not isPlayerBattle(player) then
				doPlayerPopupFYI(player, msg)
			end
		end
	end
	return true
end