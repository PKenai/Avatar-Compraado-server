function onStepIn(cid, item, position, fromPosition)
	if isPlayerPzLocked(cid) then
		doTeleportThing(cid, fromPosition, false)
      	doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You cant pass with battle locked.")
		return false
	end
	if getPlayerLevel(cid) < 125 then
		doTeleportThing(cid, fromPosition, false)
		doCreatureSay(cid, "Você precisa de Level 125+  para entrar na Lost Avatar Quest.", TALKTYPE_ORANGE_1, false, cid)
		return false
	else
		doTeleportThing(cid, {x=757, y=368, z=10})	
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
		doSendMagicEffect(position, CONST_ME_TELEPORT)
	end 
	return true
end