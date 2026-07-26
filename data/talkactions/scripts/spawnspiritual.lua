function onSay(cid, words, param, channel)
	if(param == "") then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /spawnspiritual monsterName")
		return true
	end

	local position, effect = getCreaturePosition(cid), CONST_ME_MAGIC_BLUE
	errors(false)
	local ret = doCreateSpiritualMonster(param, position, false, true)
	errors(true)

	if(tonumber(ret) == nil) then
		effect = CONST_ME_POFF
		doPlayerSendDefaultCancel(cid, (not ret and RETURNVALUE_NOTPOSSIBLE or RETURNVALUE_NOTENOUGHROOM))
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Could not spawn Spiritual " .. param .. ".")
	else
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Spawned Spiritual " .. param .. ".")
	end

	doSendMagicEffect(position, effect)
	return true
end
