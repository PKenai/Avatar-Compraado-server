function onUse(cid, item, fromPosition, itemEx, toPosition)
	local hp = -(getCreatureMaxHealth(cid)*(0.5))
	if item.itemid == 8046 then
		doTeleportThing(cid, {x=1484, y=750, z=5})
		doCreatureAddHealth(cid, hp)
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
	end
  	return false 
end