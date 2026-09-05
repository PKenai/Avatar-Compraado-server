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
    local msg = msg:lower()	
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid 
	msg = string.lower(msg)
	if not talkState[talkUser] or talkState[talkUser] <= 0 then
		talkState[talkUser] = 1 
	end
        if talkState[talkUser] == 1 then
    		if msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "viajar") or msgcontains(msg, "travel") then
				if getPlayerStorageValue(cid, "tutorialback") ~= 1 then
					selfSay("You didn't spoke with the chief Eska yet. Follow the south path, you'll find her.", cid)
					talkState[talkUser] = 1         
				else
					selfSay("I see that you are already fit to {travel}. It will be a long trip, are you ready?", cid)
					talkState[talkUser] = 2
            	end
			end
		elseif talkState[talkUser] == 2 then
    		if msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "viajar") or msgcontains(msg, "travel") then
				selfSay("Alright then, get ready, we are leaving!", cid)
				doTeleportThing(cid, {x = 336, y = 214, z = 7})
				doSendMagicEffect(getCreaturePosition(cid), CONST_ME_TELEPORT)
			  --sendInitialItens(cid)
				doPlayerSetTown(cid, 4)
				setPlayerStorageValue(cid, "finishedTutorial", 1)
			end
		end
        return true
end

function onGreet(cid) 
	if getPlayerStorageValue(cid, "tutorialback") ~= 1 then
		selfSay("You didn't spoke with the chief Eska yet. Follow the south path, you'll find her.", cid)
		talkState[cid] = 1         
	else
		selfSay("I see that you are already fit to {travel}. It will be a long trip, are you ready?", cid)
		talkState[cid] = 2
    end
   return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
