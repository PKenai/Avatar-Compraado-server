function onStepIn(cid, item, position, fromPosition)
	if isPlayerPzLocked(cid) then
		doTeleportThing(cid, fromPosition, false)
      	doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You cant pass with battle locked.")
		return false
	end
	if getPlayerLevel(cid) < 125 then
		doTeleportThing(cid, fromPosition, false)
		doCreatureSay(cid, "Você precisa de Level 125+  para entrar na Spark of Destruction Quest.", TALKTYPE_ORANGE_1, false, cid)
		return false
	else
		doTeleportThing(cid, {x=808, y=751, z=9})	
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
		doSendMagicEffect(position, CONST_ME_TELEPORT)
	end 
	return true
end