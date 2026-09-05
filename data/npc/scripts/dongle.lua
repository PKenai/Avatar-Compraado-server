local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
local talkState = {}
local runeNames = {}

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) 			end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) 		end
function onCreatureSay(cid, type, msg) 		npcHandler:onCreatureSay(cid, type, msg) 	end
function onThink() 							npcHandler:onThink() 						end
function onPlayerEndTrade(cid)				npcHandler:onPlayerEndTrade(cid)			end
function onPlayerCloseChannel(cid)			npcHandler:onPlayerCloseChannel(cid)		end
npcHandler:setMessage(MESSAGE_GREET, "")

local runesString = "{Air Rune II}, {Air Rune III}, {Earth Rune II}, {Earth Rune III}, {Fire Rune II}, {Fire Rune III}, {Water Rune II}, {Water Rune III}"
local runesTable = {"air rune ii", "air rune iii", "earth rune ii", "earth rune iii", "fire rune ii", "fire rune iii", "water rune ii", "water rune iii"}
local runeToReq = 
{
	["air rune ii"] = {itemId = 18101, count = 60, reward = 18106},
	["air rune iii"] = {itemId = 18106, count = 40, reward = 18111},
	["earth rune ii"] = {itemId = 18102, count = 60, reward = 18107},
	["earth rune iii"] = {itemId = 18107, count = 40, reward = 18112},
	["fire rune ii"] = {itemId = 18099, count = 60, reward = 18104},
	["fire rune iii"] = {itemId = 18104, count = 40, reward = 18109},
	["water rune ii"] = {itemId = 18100, count = 60, reward = 18105},
	["water rune iii"] = {itemId = 18105, count = 40, reward = 18110},
}

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end    
	local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid 
	msg = string.lower(msg)
	if not talkState[talkUser] or talkState[talkUser] <= 0 then
		talkState[talkUser] = 1 
	end
	
	if getPlayerLevel(cid) < 80 then
		selfSay("You are not strong enough to trade with me. Come back when you reach level 80.", cid)
		return false
	end

        if talkState[talkUser] == 1 then
            if msgcontains(msg, "rune") or msgcontains(msg, "runa") or msgcontains(msg, "runas") or msgcontains(msg, "runes") or msgcontains(msg, "yes") or msgcontains(msg, "upgrade") or msgcontains(msg, "canalizar") or msgcontains(msg, "craft") or msgcontains(msg, "yes") then
				selfSay("Wich rune do you want to craft? "..runesString.."?", cid)
				talkState[talkUser] = 2
			else 
				selfSay("I don't get it. Do you want to upgrade your {runes}?", cid)
				talkState[talkUser] = 1
				return false
			end
        elseif talkState[talkUser] == 2 then
			if isInArray(runesTable, msg) then
				runeNames[talkUser] = msg
                selfSay("To this creation i need "..runeToReq[msg].count.."x "..getItemNameById(runeToReq[msg].itemId)..", do you confirm?", cid)
				talkState[talkUser] = 3
            else
                selfSay("I don't get it. Tell me the exactly rune name: "..runesString.."?", cid)
				talkState[talkUser] = 2
            end
		elseif talkState[talkUser] == 3 then 
			if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
				local itemMission = runeNames[talkUser]
				if not itemMission or not runeToReq[itemMission] then 
					selfSay("I didn't find the rune that you want. Choose another!", cid)
					talkState[talkUser] = 2
					return false 
				end 
				if doPlayerRemoveItem(cid, runeToReq[itemMission].itemId, runeToReq[itemMission].count) then 
					doPlayerAddItem(cid, runeToReq[itemMission].reward, 1)
					selfSay("Here you are!", cid)
					talkState[talkUser] = 2
					return false
				else
					selfSay("You don't have all the runes that i need. Come back when you have all!", cid)
					talkState[talkUser] = 2
					return false
				end 
			elseif msgcontains(msg, "no") or msgcontains(msg, "no") or msgcontains(msg, "no") then
					selfSay("Wich rune do you want to craft? "..runesString.."?", cid)
					talkState[talkUser] = 2
					return false 
			else 
					selfSay("What? {Yes} or {no}?", cid)
            end
	   end
        return true
end


function onGreet(cid)
	if getPlayerLevel(cid) < 80 then
		selfSay("You are not strong enough to trade with me. Come back when you reach level 80.", cid)
		return true
	end
	talkState[cid] = 1
	selfSay("Hello "..getCreatureName(cid)..", i can upgrade the elements in a superior {rune}.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
