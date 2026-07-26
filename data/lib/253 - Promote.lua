-- FIRE OFENSIVE START -- 
local function doBurn(cid, combat, var, times)
	if times <= 0 then
		return false 
	end 
local target = variantToNumber(var)
return isCreature(cid) and isCreature(target) and not isInPz(cid) and not isInPz(target) and doCombat(cid, combat, var) and addEvent(doBurn, 1000, cid, combat, var, times-1)
end

local function fireKick(cid, target, isEnd, combat, combatBurn)
	if not isCreature(cid) or not isCreature(target) or isInPz(cid) or isInPz(target) then return false end
	if not isSightClear(getCreaturePosition(cid), getCreaturePosition(target), true) then return false end
	local mypos = getThingPos(cid)
	local targpos = getThingPos(target)
	doSendDistanceShoot(mypos, targpos, 3)
	doSendMagicEffect(targpos, 6)
	if isEnd then
		doBurn(cid, combatBurn, numberToVariant(target), 6)
	end
	return doCombat(cid, combat, numberToVariant(target))
end

function tryPromoteAtkFire(cid, target, combats)
	exhaustion.set(cid, "promoteAtkExh", 6)
	for i = 1, 3 do 
		addEvent(fireKick, 430*i, cid, target, i == 3, combats[1], combats[2])
	end
end
-- FIRE OFENSIVE END --

-- EARTH OFENSIVE START -- 

local xizes1 = {0, -1, -1, 0} -- cima pra esquerda, esquerda pra baixo
local yizes1 = {-1, 0, 0, 1} -- cima pra esquerda, esquerda pra baixo
local xizes2 = {0, 1, 1, 0} -- baixo pra direita, direita pra cima
local yizes2 = {1, 0, 0, -1} -- baixo pra direita, direita pra cima

local function shardsWork(cid, state, times, combat)
	if not isCreature(cid) or isInPz(cid) then return false end
		local pos = getCreaturePosition(cid)
        doSendDistanceShoot({x=pos.x+xizes1[state], y=pos.y+yizes1[state], z=pos.z}, {x=pos.x+xizes1[state+1], y=pos.y+yizes1[state+1], z=pos.z}, 11)
        doSendDistanceShoot({x=pos.x+xizes2[state], y=pos.y+yizes2[state], z=pos.z}, {x=pos.x+xizes2[state+1], y=pos.y+yizes2[state+1], z=pos.z}, 11)
	if state == 3 then 
		state = -1
		doCombat(cid, combat, {type=2, pos=pos})
	end
	if times < 21 then
		addEvent(shardsWork, 150, cid, state+2, times+1, combat)
	end
end

function promoteEarthAtk(cid, target, combats)
	exhaustion.set(cid, "promoteAtkExh", 8)
	shardsWork(cid, 1, 1, combats[3])
end

-- EARTH OFENSIVE END --

-- WATER OFENSIVE START --

function promoteWaterAtk(cid, target, combats)
	exhaustion.set(cid, "promoteAtkExh", 6)
	doSlow(cid, target, 40, 2000)	
	local targpos = getCreaturePosition(target)
	doSendAnimatedText(targpos, "Slowed!", 130, cid)
	doSendAnimatedText(targpos, "Slowed!", 130, target)
	return doCombat(cid, combats[4], numberToVariant(target))
end
-- WATER OFENSIVE END --

-- AIR OFENSIVE START --

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

local skulls = {1,3,4,5,6}
local function isImune(cid, creature)
    if isMonster(creature) or isMonster(cid) then 
        return false 
    end
	if isPlayer(cid) and isPlayer(creature) and (getPlayerStorageValue(cid, "canAttackable") == 1 or getPlayerStorageValue(creature, "canAttackable") == 1) then 
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

local function searchNewAlvo(cid, targPos, target)
    local creatures = getSpectators(targPos, 4, 4)
    if creatures ~= nil then
		for x = 1, #creatures do
			if creatures[x] ~= cid and creatures[x] ~= target then
				local creaturePos = getThingPos(creatures[x])
				if isMonster(creatures[x]) or (isPlayer(creatures[x]) and getPlayerAccess(creatures[x]) < 5 and not isSameParty(cid, creatures[x]) and not isImune(cid, creatures[x])) then
					if not getTileInfo(creaturePos).protection and isSightClear(targPos, creaturePos, true) then
						return creatures[x]
					end
				end
			end
		end
	end
	return false
end

function promoteAirAtk(cid, target, combats)
	exhaustion.set(cid, "promoteAtkExh", 6)
	doCombat(cid, combats[5], numberToVariant(target))
	local second = searchNewAlvo(cid, getCreaturePosition(cid), target)
	if second and isCreature(second) then
		doCombat(cid, combats[5], numberToVariant(second))
	end
	return true
end
-- AIR OFENSIVE END --

-- 1 fire 2 water 3 air 4 earth
convertedVocsFunc = {tryPromoteAtkFire, promoteWaterAtk, promoteAirAtk, promoteEarthAtk}

function tryPromoteAtk(cid, target, combats)
	local myPos = getCreaturePosition(cid)
	local tgPos = getCreaturePosition(target)
	if not isSightClear(myPos, tgPos, true) or getDistanceBetween(myPos, tgPos) > 4 or exhaustion.check(cid, "promoteAtkExh") then 
		return true
	end
	if math.random(1, 100) > 60 then
		exhaustion.set(cid, "promoteAtkExh", 2)
		return true
	end
	return convertedVocsFunc[getPlayerVocation(cid)](cid, target, combats)
end