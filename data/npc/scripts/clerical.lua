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

local items = {
    [6500] = 25,
	[11322] = 3,
	[11334] = 5,
	[12409] = 20,
	[11325] = 2
}

local function checkItems(cid)
	for i,v in pairs (items) do
		if not (getPlayerItemCount(cid, i) >= v) then
			return false
		end
	end
	return true
end

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
            if msgcontains(msg, "help") or msgcontains(msg, "help") then
				if getPlayerStorageValue(cid, Huahua) >= 1 then
					selfSay("You've helped me enough.", cid)
					talkState[talkUser] = 1         
				elseif (getPlayerLevel(cid) >= 120) then
					selfSay("Would you like to help me?", cid)
					talkState[talkUser] = 2
				else
					selfSay("You need Level 120+  to help me.", cid)
					talkState[talkUser] = 1
				end
			end
		elseif talkState[talkUser] == 2 then
			if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
				it = "The church entrusted the huge and responsible task of fighting heresy and black magic to the profaned. If you wish to enlist as a member, it is your duty to fight evil and always stay alert, because evil can appear in the most diverse disguises. If you want to enlist, I need you to gather some things for me: 25 demonic essence, 3 metal bracelets, 5 legionnaire's flags, 20 broken elmo and 2 spiked iron balls"
				it = it .. ". Have you collected all of them?"
				selfSay("The church entrusted the huge and responsible task of combating heresy and black magic to the profaned. If you wish to enroll as a member, it is your duty to fight against evil and always keep on alert because evil can appear in the most diverse disguises. If you want to enlist, I need you to gather some things for me: 25 demonic essence, 3 metal bracelets, 5 legionnaire's flags, 20 broken elmo and 2 spiked iron balls. Have you collected all of them?", cid)
				talkState[talkUser] = 3			
			end
			
		elseif talkState[talkUser] == 3 then
			if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
				if checkItems(cid) then
					for i,v in pairs(items) do
						doPlayerRemoveItem(cid, i, v)
					end
					selfSay("Thanks for helping me, you're listed! Go to the Tunico guard, he needs the help of warriors like you.", cid)
					setPlayerStorageValue(cid, Huahua, 1)
					talkState[talkUser] = 1
				else
					selfSay("You did not collect anything yet.", cid)
					talkState[talkUser] = 1
				end
			end
		end
        return true
end

function onGreet(cid) 
	talkState[cid] = 1 	
	selfSay("Hello "..getCreatureName(cid)..", this new plague has affected us! At this moment i'm a little busy blessing this poor corpse, but i'm accepting any kind of {help}!", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
