function onLogout(cid, forceLogout)
	-- Clean up party damage meter data (DPS) when a party leader logs out
	if type(g_partyDamage) == "table" and type(partyDamageCleanup) == "function" then
		partyDamageCleanup(cid)
	end
	-- Clean up magic meter data
	if type(magicMeterCleanup) == "function" then
		magicMeterCleanup(cid)
	end
	-- Clean up fly/surf per-cid cache
	if type(flySystemCleanup) == "function" then
		flySystemCleanup(cid)
	end
	if not getTileInfo(getCreaturePosition(cid)).protection and exhaustion.check(cid, "npodedeslogar") and getPlayerGroupId(cid) <= 4 then 
		doPlayerSendCancel(cid, "You cant logout now.")
		return false 
	end
	if not forceLogout and getPlayerStorageValue(cid, "ativoBot") == 1 and os.time()-4 < getPlayerStorageValue(cid, "horarioBot") then
		doPlayerSendCancel(cid, getLangString(cid, "You cant logout now, you have an anti-bot question active.", "Voce nao pode deslogar antes de responder ao !antibot."))
		return false 
	end
	if restoreAppaOutfit then
		pcall(function() restoreAppaOutfit(cid) end)
	end
	local posicao = getThingPos(cid)
	doSendMagicEffect({x=posicao.x+1, y=posicao.y+1, z=posicao.z}, 119)
	
	pcall(function() dismountPlayer(cid) end)
	local guid = getPlayerGUID(cid)
	if getPlayerStorageValue(cid, "isPromoted") == 1 then
		addEvent(function(guid) db.executeQuery('UPDATE `players` SET `questpromotion` = "1" WHERE `id` = "'..guid..'"') end, 100, guid)
	end
	pcall(function() addPlayerTimeOnline(cid, os.time()-getPlayerStorageValue(cid, "timeLogin")) end)
	pcall(function() db.executeQuery("UPDATE `players` SET `broadcasting` = 0, `viewers` = 0 WHERE `id` = " .. getPlayerGUID(cid) .. " LIMIT 1") end)

	-- Fishing System: limpa o estado de pesca se deslogou no meio do minigame
	if type(FishingSystem) == "table" and type(FishingSystem.onLogout) == "function" then
		pcall(FishingSystem.onLogout, cid)
	end

	-- Cooking System: limpa o estado de cozinha se deslogou no meio do minigame
	if type(CookingSystem) == "table" and type(CookingSystem.onLogout) == "function" then
		pcall(CookingSystem.onLogout, cid)
	end
	return true
end
