dofile(getDataDir().."lib/appaFlight.lua")

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
local talkState = {}
local pendingDest = {}

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) 			end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) 		end
function onCreatureSay(cid, type, msg) 		npcHandler:onCreatureSay(cid, type, msg) 	end
function onThink() 							npcHandler:onThink() 						end
function onPlayerEndTrade(cid)				npcHandler:onPlayerEndTrade(cid)			end
function onPlayerCloseChannel(cid)			npcHandler:onPlayerCloseChannel(cid)		end
npcHandler:setMessage(MESSAGE_GREET, "")
npcHandler:setMessage(MESSAGE_WALKAWAY, "")

local function tryTravel(cid, destination)
	if isAppaFlying and isAppaFlying(cid) then
		selfSay("You are already flying!", cid)
		if appaFlightUnlock then appaFlightUnlock(cid) end
		return
	end
	if doPlayerRemoveMoney(cid, 50) then
		selfSay("We are leaving!", cid)
		if not startAppaFlight(cid, destination) then
			doPlayerAddMoney(cid, 50)
			if appaFlightUnlock then appaFlightUnlock(cid) end
			selfSay("Something went wrong with the Appa flight.", cid)
		end
	else
		if appaFlightUnlock then appaFlightUnlock(cid) end
		selfSay("You dont have 50 gold coins.", cid)
	end
end

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end
	if isPlayerPzLocked(cid) then
		return true
	end
	local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
	msg = string.lower(msg)
	if not talkState[talkUser] or talkState[talkUser] <= 0 then
		talkState[talkUser] = 1
	end

	if talkState[talkUser] == 2 then
		if msgcontains(msg, "yes") then
			local dest = pendingDest[cid]
			pendingDest[cid] = nil
			talkState[talkUser] = 1
			if dest then
				doCreatureSetNoMove(cid, true)
				tryTravel(cid, dest)
			end
		elseif msgcontains(msg, "no") then
			pendingDest[cid] = nil
			talkState[talkUser] = 1
			selfSay("Maybe next time.", cid)
		end
		return true
	end

	if talkState[talkUser] == 1 then
		if msgcontains(msg, "routes") or msgcontains(msg, "rotas") or msgcontains(msg, "travel") then
			selfSay("I can take you to: {Ba Sing Se} or {West Field} for 50 gold coins.", cid)
		elseif msgcontains(msg, "sing") then
			pendingDest[cid] = {x = 552, y = 344, z = 6}
			talkState[talkUser] = 2
			selfSay("Travel to Ba Sing Se for 50 gold? Say {yes} or {no}.", cid)
		elseif msgcontains(msg, "west") then
			pendingDest[cid] = {x = 716, y = 529, z = 5}
			talkState[talkUser] = 2
			selfSay("Travel to West Field for 50 gold? Say {yes} or {no}.", cid)
		end
	end
	return true
end

function onGreet(cid)
	talkState[cid] = 1
	pendingDest[cid] = nil
	selfSay("Hello "..getCreatureName(cid)..", do you want to {travel}?", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
