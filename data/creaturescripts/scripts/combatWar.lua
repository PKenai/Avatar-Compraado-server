local function isInPvpZone(cid)
local pos = getCreaturePosition(cid)
	if getTileInfo(pos).hardcore then
		return true 
	end
return false
end

local function isInSameGuild(cid, target)
local cidGuild = getPlayerGuildId(cid)
local targGuild = getPlayerGuildId(target)
if cidGuild > 0 and cidGuild == targGuild then
	return true
end
return false
end

function onCombat(cid, target)
if isMonster(cid) or isMonster(target) or isNpc(target) then 
return true
end 
	if (castleWar.isOnCastle(cid) and not isInPvpZone(cid)) or (castleWar.isOnCastle(target) and not isInPvpZone(target)) then 
		return false 
	end 
	if not (isInPvpZone(target) and not castleWar.isOnCastle(target)) and isInSameGuild(cid, target) then 
		return false
	end
return true
end