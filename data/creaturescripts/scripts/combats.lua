local function isInPvpZone(cid)
local pos = getCreaturePosition(cid)
	if getTileInfo(pos).hardcore then
		return true 
	end
return false
end

function onCombat(cid, target)
	if isPlayer(cid) and isPlayer(target) then 
		if getTileInfo(getCreaturePosition(cid)).protection then
			return false
		end
	end 
	if isInWarGround(cid) and isInWarGround(target) then 
		if not getComecou() then 
			return false
		end 
		if getPlayerStorageValue(cid, "timeWar") == getPlayerStorageValue(target, "timeWar") then 
			return false
		end
	end 
return true
end