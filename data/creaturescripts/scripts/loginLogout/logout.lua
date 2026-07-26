function onLogout(cid, forceLogout)
	if not getTileInfo(getCreaturePosition(cid)).protection and exhaustion.check(cid, "npodedeslogar") and getPlayerGroupId(cid) <= 4 then 
		doPlayerSendCancel(cid, "You cant logout now.")
		return false 
	end
	if not forceLogout and getPlayerStorageValue(cid, "ativoBot") == 1 and os.time()-4 < getPlayerStorageValue(cid, "horarioBot") then
		doPlayerSendCancel(cid, getLangString(cid, "You cant logout now, you have an anti-bot question active.", "Voc� n�o pode deslogar antes de responder ao !antibot."))
		return false 
	end
	if restoreAppaOutfit then
		restoreAppaOutfit(cid)
	end
	        local posicao = getThingPos(cid)
    		doSendMagicEffect({x=posicao.x+1, y=posicao.y+1, z=posicao.z}, 119)
  event.logout(cid)
    dismountPlayer(cid)
	local guid = getPlayerGUID(cid)
	if getPlayerStorageValue(cid, "isPromoted") == 1 then
		addEvent(function(guid) db.executeQuery('UPDATE `players` SET `questpromotion` = "1" WHERE `id` = "'..guid..'"') end, 100, guid)
	end
  	addPlayerTimeOnline(cid, os.time()-getPlayerStorageValue(cid, "timeLogin"))
  	db.executeQuery("UPDATE `players` SET `broadcasting` = 0, `viewers` = 0 WHERE `id` = " .. getPlayerGUID(cid) .. " LIMIT 1")
    return true
end