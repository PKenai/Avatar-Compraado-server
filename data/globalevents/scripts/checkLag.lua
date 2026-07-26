local function isGM(cid)
return getPlayerGroupId(cid) >= 3
end 

local function isAttackingHitbox(cid)
local testPos = getCreaturePosition(cid)
 if testPos.x >= 442 and testPos.y >= 88 and testPos.z == 8 and testPos.x <= 449 and testPos.y <= 94 then 
	return true
end
if getTileInfo(testPos).protection then 
	return true 
end
local target = getCreatureTarget(cid)
if not target or target == 0 then 
	return false 
end
return target and getCreatureName(target) == "Target"
end 
local function isRecentLogged(cid)
	return os.time()-getPlayerLastLoginSaved(cid) <= 5
end 

function onThink(interval)
local totalLagado = 0
local totalChecado = 0
local checados = {}
	for _, pid in ipairs(getPlayersOnline()) do
		if not isAttackingHitbox(pid) and not isRecentLogged(pid) then 
			totalChecado = totalChecado+1
			table.insert(checados, pid)
			if getPlayerPong(pid) >= 7800 then 
				totalLagado = totalLagado+1
			end 
		end 
	end 
	if totalChecado >= 10 and totalLagado >= (totalChecado/2) then 
		for i =1, #checados do 
			if isCreature(checados[i]) then 
				setPlayerStorageValue(checados[i], "ddoskick", 1) 
				setPlayerStorageValue(checados[i], "hasPassiveDeathActive", os.time())
				doRemoveCreature(checados[i])
			end 
		end 
		setExpBackupToPlayers(1)
        addEvent(sendBackupExpToAllPlayersOnline, 10000)
        addEvent(sendBackupExpToAllPlayersOnline, 60000)
        addEvent(sendBackupExpToAllPlayersOnline, 120000)
        addEvent(sendBackupExpToAllPlayersOnline, 180000)
        addEvent(sendBackupExpToAllPlayersOnline, 300000)
        addEvent(sendBackupExpToAllPlayersOnline, 600000)
	end

  return true
end