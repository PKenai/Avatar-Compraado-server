local function isInBloodCastle(cid)
	local pos = getCreaturePosition(cid)
	if pos.z == 14 and pos.x < 135 and pos.x > 119 and pos.y > 143 and pos.y < 151 then 
		return true 
	end 
	return false
end
local function isInOptionalZone(cid)
local pos = getCreaturePosition(cid)
	if getTileInfo(pos).optional then
		return true 
	end
return false
end

local function isInPz(cid)
local pos = getCreaturePosition(cid)
	if getTileInfo(pos).protection then
		return true 
	end
return false
end


function onPush(cid, target, ground, position)
	if isInOptionalZone(target) or isInOptionalZone(cid) or isInBloodCastle(cid) or isInBloodCastle(target) then 
		return false 
	end 
	if isInPz(cid) and isInPz(target) then 
		return true 
	end 
	if getPlayerStorageValue(cid, "canAttackable") == 1 and getPlayerStorageValue(target, "canAttackable") ~= 1 then 
		return false
	end 
	return true
end 