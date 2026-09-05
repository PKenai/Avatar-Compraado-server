local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
local talkState = {}

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) 			end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) 		end
function onCreatureSay(cid, type, msg) 		npcHandler:onCreatureSay(cid, type, msg) 	end
function onThink() 							npcHandler:onThink() 						end
function onPlayerEndTrade(cid)				npcHandler:onPlayerEndTrade(cid)			end
function onPlayerCloseChannel(cid)			npcHandler:onPlayerCloseChannel(cid)		end
npcHandler:setMessage(MESSAGE_GREET, "")
npcHandler:setMessage(MESSAGE_WALKAWAY, "")

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end    
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid 
	if not talkState[talkUser] or talkState[talkUser] <= 0 then
		talkState[talkUser] = 1 
	end
    local msg = msg:lower()
    if msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "return") or msgcontains(msg, "back") then
		selfSay("Alright then, get ready, we are leaving!", cid)
		doTeleportThing(cid, {x = 1008, y = 267, z = 7})
		doSendMagicEffect(getCreaturePosition(cid), CONST_ME_TELEPORT)
	end
	return true
end

function onGreet(cid) 
	talkState[cid] = 1
	selfSay("I need to get out of here, "..getCreatureName(cid)..". This place is too dangerous, we are crossing the line. I can take you with me, this time for free. Do you want to go {back}?", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
