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
    if getPlayerStorageValue(cid, "tutorialback") ~= 1 then
        if not msgcontains(msg, "yes") and not msgcontains(msg, "yes") and not msgcontains(msg, "interested") and not msgcontains(msg, "interessado") and not msgcontains(msg, "join") and not msgcontains(msg, "juntar") then
			selfSay("Oh, are not you {interested}? Well, if you change your mind, talk to me again.", cid)		
			return true
		end
		setPlayerStorageValue(cid, "jadissesim", 1)
		selfSay("Show me what you can do.", cid) 		
		doPlayerSendTextMessage(cid, 22, "Show to Eska the bend Water Whip. You can use it by clicking on the bending list, or by saying the word 'Water Whip', that can be automatically sent with a shortcut using the hotkey system (CTRL+K).")
	else
		selfSay("What are you waiting for?! Go back and talk with Hilde, she'll travel with you to the North Water Tribe.", cid)
		--selfSay("I see that you already know how to bend the water. We'll prepare you and teach how to control it with the bests benders, be welcome to the tribe! Go back and talk with Hilde, she'll travel with you to North Water Tribe. Good luck, "..getCreatureName(cid).."!", cid)	
	end

    return true
end

function ensinarYes(cid)
	if isCreature(cid) and getPlayerStorageValue(cid, "jadissesim") ~= 1 then
		doPlayerSendTextMessage(cid, 22, "For simple questions like that, you can just type 'yes' in the NPCs tab.")
	end
end

function onGreet(cid) 
	talkState[cid] = 1 	
	if getPlayerStorageValue(cid, "tutorialback") ~= 1 then
		selfSay("Finally someone interesting! Command an entire nation is a boring thing, know? But, meet the best fighters.. its something different. So, seeing that you look strong, i want you in our tribe. What do you say, {interested}?", cid)
		setPlayerStorageValue(cid, "jadissesim", 0)
		addEvent(ensinarYes, 3000, cid)
	else
		selfSay("What are you waiting for?! Go back and talk with Hilde, she'll travel with you to the North Water Tribe.", cid)
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
