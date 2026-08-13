function onUse(cid, item, fromPosition, itemEx, toPosition)
	local hp = -(getCreatureMaxHealth(cid)*(0.5))
	local hpp = -(getCreatureMaxHealth(cid)*(0.75))
	if (((getPlayerLevel(cid) >= 260))) then
		if item.itemid == 8046 then
			doTeleportThing(cid, {x=1400, y=737, z=7})
			doCreatureAddHealth(cid, hp)
			doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
		end
	else
		doCreatureSay(cid, "Seu sangue é impuro! Você precisa de Level 260+  para entrar na The Duke Of The Depths.", TALKTYPE_ORANGE_1, false, cid)
		doCreatureAddHealth(cid, hpp)
		doSendMagicEffect(getThingPos(cid), 0)
	end 
  	return false 
end