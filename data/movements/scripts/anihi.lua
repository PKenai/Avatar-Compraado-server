function onStepIn(cid, item, position, fromPosition)
	if isPlayerPzLocked(cid) then
		doTeleportThing(cid, fromPosition, false)
      	doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You cant pass with battle locked.")
		return false
	end
	if getPlayerLevel(cid) < 100 then
		doTeleportThing(cid, fromPosition, false)
		doCreatureSay(cid, "Você precisa de Level 100+  para entrar na Quest dos Quatro Elementos.", TALKTYPE_ORANGE_1, false, cid)
		return false
	else
		doTeleportThing(cid, {x=778, y=235, z=9})	
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
		doSendMagicEffect(position, CONST_ME_TELEPORT)
	end 
	return true
end