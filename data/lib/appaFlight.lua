-- Appa flight (Toxic NPC):
-- fade out 2s -> staging {24,11,6} + cloudy -> cloudy then cloudy+fade out -> final teleport when dark
-- Teleports are driven by client fade-done opcodes (6).

local APPA_STAGE = {x = 24, y = 11, z = 6}
local FADE_OUT_MS = 2000
local CLOUD_MS = 15000
local FADE_FALLBACK_SLACK_MS = 500
local MAP_SHADER_OPCODE = 6

local PHASE_FADE_OUT = 1
local PHASE_CLOUD = 2
local PHASE_EXIT_FADE = 3

local APPA_ITEM_BY_VOC = {
	[1] = 18205, -- fire
	[2] = 18206, -- water
	[3] = 18208, -- air
	[4] = 18207  -- earth
}

local function getBaseVocation(cid)
	local voc = getPlayerVocation(cid)
	if voc >= 5 and voc <= 8 then
		return voc - 4
	end
	return voc
end

local function getAppaItemId(cid)
	return APPA_ITEM_BY_VOC[getBaseVocation(cid)]
end

local function getPhase(cid)
	return getPlayerStorageValue(cid, "appaPhase")
end

local function setPhase(cid, phase)
	setPlayerStorageValue(cid, "appaPhase", phase)
end

local function lockMovement(cid)
	doCreatureSetNoMove(cid, true)
end

local function unlockMovement(cid)
	doCreatureSetNoMove(cid, false)
end

local function saveAppaOutfit(cid)
	local outfit = getCreatureOutfit(cid)
	setPlayerStorageValue(cid, "appaSaved", 1)
	setPlayerStorageValue(cid, "appaLookType", outfit.lookType or 0)
	setPlayerStorageValue(cid, "appaLookHead", outfit.lookHead or 0)
	setPlayerStorageValue(cid, "appaLookBody", outfit.lookBody or 0)
	setPlayerStorageValue(cid, "appaLookLegs", outfit.lookLegs or 0)
	setPlayerStorageValue(cid, "appaLookFeet", outfit.lookFeet or 0)
	setPlayerStorageValue(cid, "appaLookAddons", outfit.lookAddons or 0)
	setPlayerStorageValue(cid, "appaLookTypeEx", outfit.lookTypeEx or 0)
end

local function clearAppaFlight(cid)
	setPlayerStorageValue(cid, "appaFlying", -1)
	setPlayerStorageValue(cid, "appaSaved", -1)
	setPlayerStorageValue(cid, "appaDestX", -1)
	setPlayerStorageValue(cid, "appaDestY", -1)
	setPlayerStorageValue(cid, "appaDestZ", -1)
	setPhase(cid, -1)
end

function restoreAppaOutfit(cid)
	if not isPlayer(cid) then
		return false
	end
	if getPlayerStorageValue(cid, "appaSaved") ~= 1 and getPlayerStorageValue(cid, "appaFlying") ~= 1 then
		return false
	end

	doRemoveCondition(cid, CONDITION_OUTFIT)
	unlockMovement(cid)

	if getPlayerStorageValue(cid, "appaSaved") == 1 then
		local lookType = getPlayerStorageValue(cid, "appaLookType")
		if lookType < 0 then
			lookType = 0
		end
		doCreatureChangeOutfit(cid, {
			lookType = lookType,
			lookHead = math.max(0, getPlayerStorageValue(cid, "appaLookHead")),
			lookBody = math.max(0, getPlayerStorageValue(cid, "appaLookBody")),
			lookLegs = math.max(0, getPlayerStorageValue(cid, "appaLookLegs")),
			lookFeet = math.max(0, getPlayerStorageValue(cid, "appaLookFeet")),
			lookAddons = math.max(0, getPlayerStorageValue(cid, "appaLookAddons")),
			lookTypeEx = math.max(0, getPlayerStorageValue(cid, "appaLookTypeEx"))
		})
	end

	clearAppaFlight(cid)
	return true
end

local function finishAppaFlight(cid)
	if not isPlayer(cid) then
		return
	end
	if getPlayerStorageValue(cid, "appaFlying") ~= 1 then
		return
	end
	if getPhase(cid) ~= PHASE_EXIT_FADE then
		return
	end

	local dest = {
		x = getPlayerStorageValue(cid, "appaDestX"),
		y = getPlayerStorageValue(cid, "appaDestY"),
		z = getPlayerStorageValue(cid, "appaDestZ")
	}

	restoreAppaOutfit(cid)
	doSendPlayerExtendedOpcode(cid, MAP_SHADER_OPCODE, "")

	if dest.x > 0 and dest.y > 0 and dest.z >= 0 then
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
		doTeleportThing(cid, dest)
		doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
	end
end

local function beginExitFade(cid)
	if not isPlayer(cid) or getPlayerStorageValue(cid, "appaFlying") ~= 1 then
		return
	end
	if getPhase(cid) ~= PHASE_CLOUD then
		return
	end

	setPhase(cid, PHASE_EXIT_FADE)
	-- Clouds keep playing while the screen darkens.
	doSendPlayerExtendedOpcode(cid, MAP_SHADER_OPCODE, "cloudy_fade_out")
	addEvent(function(pid)
		if isPlayer(pid) and getPhase(pid) == PHASE_EXIT_FADE then
			finishAppaFlight(pid)
		end
	end, math.floor(FADE_OUT_MS * 0.9) + FADE_FALLBACK_SLACK_MS, cid)
end

local function arriveAtStage(cid)
	if not isPlayer(cid) or getPlayerStorageValue(cid, "appaFlying") ~= 1 then
		return
	end
	if getPhase(cid) ~= PHASE_FADE_OUT then
		return
	end

	setPhase(cid, PHASE_CLOUD)

	local itemId = getAppaItemId(cid)
	doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)
	doTeleportThing(cid, APPA_STAGE)
	doSendMagicEffect(getThingPos(cid), CONST_ME_TELEPORT)

	if itemId then
		doSetCreatureOutfit(cid, {
			lookType = 0,
			lookTypeEx = itemId,
			lookHead = 0,
			lookBody = 0,
			lookLegs = 0,
			lookFeet = 0,
			lookAddons = 0
		}, CLOUD_MS + 1000)
	end

	doSendPlayerExtendedOpcode(cid, MAP_SHADER_OPCODE, "map_cloudy")
	-- Start exit fade during the last 2s of cloud time (overlap).
	addEvent(beginExitFade, math.max(0, CLOUD_MS - FADE_OUT_MS), cid)
end

function startAppaFlight(cid, destination)
	if not isPlayer(cid) or not destination then
		return false
	end
	if getPlayerStorageValue(cid, "appaFlying") == 1 then
		return false
	end
	if not getAppaItemId(cid) then
		return false
	end

	saveAppaOutfit(cid)
	setPlayerStorageValue(cid, "appaFlying", 1)
	setPlayerStorageValue(cid, "appaDestX", destination.x)
	setPlayerStorageValue(cid, "appaDestY", destination.y)
	setPlayerStorageValue(cid, "appaDestZ", destination.z)
	setPhase(cid, PHASE_FADE_OUT)

	lockMovement(cid)
	doSendPlayerExtendedOpcode(cid, MAP_SHADER_OPCODE, "fade_out")
	addEvent(function(pid)
		if isPlayer(pid) and getPhase(pid) == PHASE_FADE_OUT then
			arriveAtStage(pid)
		end
	end, FADE_OUT_MS + FADE_FALLBACK_SLACK_MS, cid)
	return true
end

function isAppaFlying(cid)
	return isPlayer(cid) and getPlayerStorageValue(cid, "appaFlying") == 1
end

function appaFlightOnFadeDone(cid, which)
	if not isPlayer(cid) or getPlayerStorageValue(cid, "appaFlying") ~= 1 then
		return
	end
	if which == "fade_out_done" then
		arriveAtStage(cid)
	elseif which == "exit_fade_done" or which == "fade_in_done" then
		finishAppaFlight(cid)
	end
end

function appaFlightUnlock(cid)
	if isPlayer(cid) then
		unlockMovement(cid)
	end
end
