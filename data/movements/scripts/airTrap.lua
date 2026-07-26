local function sendInfoTime(cid, times)
if not isCreature(cid) then return false end 

  if times > 0 then 
    doSendAnimatedText(getCreaturePosition(cid), times, 110, cid)
    addEvent(sendInfoTime, 1000, cid, times-1)
  end 
end 

local combat = createCombatObject()
setCombatArea(combat, createCombatArea({{1}}))
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_AIRDAMAGE)

local skulls = {1,3,4,5,6}


local function isNonPvp(cid)
if isPlayer(cid) and getPlayerLevel(cid) < 50 then
	return true
end
return getPlayerStorageValue(cid, "canAttackable") == 1
end 

local function isInPvpZone(cid)
local pos = getCreaturePosition(cid)
	if getTileInfo(pos).hardcore then
		return true 
	end
return false
end

local function isInSameGuild(cid, target)
if isPlayer(target) and not (isInPvpZone(target) and not castleWar.isOnCastle(target)) then
	local cidGuild = getPlayerGuildId(cid)
	local targGuild = getPlayerGuildId(target)
	if cidGuild > 0 and cidGuild == targGuild then
		return true
	end
end
	return false
end

local function isSameParty(cid, target)
	if isPlayer(target) and isInParty(target) and isInParty(cid) and getPlayerParty(cid) == getPlayerParty(target) then 
		return true
	end
	if isInSameGuild(cid, target) then
		return true
	end
	return false
end

local function isImune(cid, creature)
  if isMonster(creature) or isMonster(cid) then 
    return false 
  end
	if getTileInfo(getCreaturePosition(cid)).protection or getTileInfo(getCreaturePosition(cid)).optional then
		return true
	end
  if isSameParty(cid, creature) then
    return true
  end 
  local modes = getPlayerModes(cid)
  if isInArray(skulls, getCreatureSkullType(creature)) then
    return false
  end   
  if (modes.secure == SECUREMODE_OFF) then
    return false
  end
  return true
end

function onStepIn(cid, item, position, fromPosition)
 if exhaustion.check(cid, "airtrapped") or (isNonPvp(cid) and not getTileInfo(position).hardcore) then 
return true 
end
    if not(item.actionid == cid) then
        if not (isPlayer(item.actionid)) then
            doRemoveItem(item.uid)
            return true
        end
		if isNonPvp(item.actionid) and isPlayer(cid) and not getTileInfo(position).hardcore then 
			return true 
		end
 
        local currentParty = getPlayerParty(item.actionid)
 
        if (currentParty ~= nil) then
            local members = getPartyMembers(currentParty)
 
            for index, member in pairs(members) do
 
                if (member == cid) then
                    return true
                end
            end
        end
		if isImune(item.actionid, cid) then 
			return true 
		end
 
		doPlayerCancelFollow(cid)
		doSendAnimatedText(position, "Traped!", COLOR_GREY)
		setCreatureNoMoveTime(cid, 3*1000)
		if isPlayer(cid) then 
			sendInfoTime(cid, 3)
        end 
		exhaustion.set(cid, "airtrapped", 2)
		doCombat(item.actionid, combat, {type=2, pos=getThingPos(cid)})
    end
 
  return true
end



function onStepOut(cid, item, position, lastPosition, fromPosition, toPosition)
	if item.actionid == cid then
		return true
	end
	if not (isPlayer(item.actionid)) then
        doRemoveItem(item.uid)
		return true
	end
	if getPlayerStorageValue(cid, 16154) == 1 then 
		return true 
	end
	if tonumber(fromPosition.x) and tonumber(toPosition.x) and getDistanceBetween(toPosition, fromPosition) > 4 then 
		return true 
	end

	if isNonPvp(item.actionid) and isPlayer(cid) and not getTileInfo(position).hardcore then 
		return true 
	end
 
	local currentParty = getPlayerParty(item.actionid)
 
    if (currentParty ~= nil) then
		local members = getPartyMembers(currentParty)
		for index, member in pairs(members) do
			if (member == cid) then
				return true
			end
		end
    end
	if isImune(item.actionid, cid) then 
		return true 
	end

  if getCreatureNoMove(cid) and getDistanceBetween(fromPosition, getThingPos(cid)) < 2 then 
    setPlayerStorageValue(cid, 16154, 1)
    doTeleportThing(cid, fromPosition, false)
    setPlayerStorageValue(cid, 16154, -1)
	exhaustion.set(cid, "stopDashs", 1)
	return false 
  end
  return true
end