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
		selfSay(getLangString(cid, "You are already flying!", "Voce ja esta voando!"), cid)
		if appaFlightUnlock then appaFlightUnlock(cid) end
		return
	end
	if doPlayerRemoveMoney(cid, 50) then
		selfSay(getLangString(cid, "We are leaving!", "Estamos saindo!"), cid)
		if not startAppaFlight(cid, destination) then
			doPlayerAddMoney(cid, 50)
			if appaFlightUnlock then appaFlightUnlock(cid) end
			selfSay(getLangString(cid, "Something went wrong with the Appa flight.", "Algo deu errado com o voo do Appa."), cid)
		end
	else
		if appaFlightUnlock then appaFlightUnlock(cid) end
		selfSay(getLangString(cid, "You dont have 50 gold coins.", "Voce nao tem 50 gold coins."), cid)
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
			selfSay(getLangString(cid, "Maybe next time.", "Talvez na proxima."), cid)
		end
		return true
	end

	if talkState[talkUser] == 1 then
		if msgcontains(msg, "routes") or msgcontains(msg, "rotas") or msgcontains(msg, "travel") then
			selfSay(getLangString(cid, "I can take you to: {South Air Temple} or {Ba Sing Se} for 50 gold coins.", "Eu posso levar voce para: {South Air Temple} ou {Ba Sing Se} por 50 gold coins."), cid)
		elseif msgcontains(msg, "temple") then
			pendingDest[cid] = {x = 510, y = 688, z = 4}
			talkState[talkUser] = 2
			selfSay(getLangString(cid, "Travel to South Air Temple for 50 gold? Say {yes} or {no}.", "Viajar para South Air Temple por 50 gold? Digite {yes} ou {no}."), cid)
		elseif msgcontains(msg, "sing") then
			pendingDest[cid] = {x = 552, y = 344, z = 6}
			talkState[talkUser] = 2
			selfSay(getLangString(cid, "Travel to Ba Sing Se for 50 gold? Say {yes} or {no}.", "Viajar para Ba Sing Se por 50 gold? Digite {yes} ou {no}."), cid)
		end
	end
	return true
end

function onGreet(cid)
	talkState[cid] = 1
	pendingDest[cid] = nil
	selfSay(getLangString(cid, "Hello "..getCreatureName(cid)..", do you want to {travel}?", "Ola "..getCreatureName(cid).."! Eu posso lhe transportar para varios lugares, deseja ver minhas {rotas}?"), cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
