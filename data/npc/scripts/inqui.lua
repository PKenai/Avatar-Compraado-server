local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
local talkState = {}

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

npcHandler:setMessage(MESSAGE_GREET, "")

local items = {
    [2177] = 5
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
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "entrar") or msgcontains(msg, "join") then
                if getPlayerStorageValue(cid, Huahua) < 1 then
                    selfSay("You need to talk to the old man Clerical Jorge before coming to me.", cid)
                    talkState[talkUser] = 1         
                elseif getPlayerStorageValue(cid, Ahu) >= 2 then
                    selfSay("You are already free to go.", cid)
                    talkState[talkUser] = 1
                elseif getPlayerLevel(cid) >= 120 then
                    selfSay("Ok, I see you're already listed, however, I need you to help me with one more thing. Are you willing?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("You are not strong enough to help me.", cid)
                    talkState[talkUser] = 1
                end
            end
        elseif talkState[talkUser] == 2 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                it = "Preciso que me traga 5 life crystal"
                it = it .. ". You already coletou todos?"
                selfSay("I need you to bring me 5 life crystal. You've collected all?", cid)
                talkState[talkUser] = 3         
            end
            
        elseif talkState[talkUser] == 3 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                if checkItems(cid) then
                    for i,v in pairs(items) do
                        doPlayerRemoveItem(cid, i, v)
                    end
                    selfSay("Thanks for your help, you're free to go. Be careful!", cid)
                    setPlayerStorageValue(cid, Ahu, 2)
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
	selfSay("Hello, "..getCreatureName(cid)..". Would you like to {join} the Profaned Quest?", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
