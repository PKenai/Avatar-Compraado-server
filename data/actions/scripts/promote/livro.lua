function onUse(cid, item, fromPosition, itemEx, toPosition)
	doTeleportThing(cid,  {x = 1162, y = 724, z = 10})
	doSendMagicEffect({x = 1162, y = 724, z = 10}, CONST_ME_TELEPORT)
return true
end