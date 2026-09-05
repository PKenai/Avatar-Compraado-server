
local function getPriceBless(cid)
    if getPlayerPremiumDays(cid) > 0 then
        return (((getPlayerLevel(cid)*1750)/2)*0.8)
    else
        return ((getPlayerLevel(cid)*1750)/2)
    end
end

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

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)
shopModule:addBuyableItem('Amulet of Loss', 3000, 2173, '')
shopModule:addBuyableItem('Rune Remover I', 50000, 18114, '')

function creatureSayCallback(cid, type, msg)    
    if(not npcHandler:isFocused(cid)) then
        return false
    end    
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid 
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1 
    end
    local msg = msg:lower()

        if talkState[talkUser] == 1 then
            if msgcontains(msg, "bless") or msgcontains(msg, "blessed") or msgcontains(msg, "abençoado") then
                selfSay("With this blessing you will lose 50% less experience when you die (and will not lose any item, unless you're red skulled). The price is {"..getPriceBless(cid).."} gold coins, are you interested?", cid)
                talkState[talkUser] = 2
            end
        elseif talkState[talkUser] == 2 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                if getPlayerLevel(cid) >= 50 then
                    if getPlayerStorageValue(cid, "playerWithBless") ~= 1 then
                        if doPlayerRemoveMoney(cid, getPriceBless(cid)) then
                            setPlayerStorageValue(cid, "playerWithBless", 1)
                            setPlayerStorageValue(cid, "blessExpName", "Sony")
                            selfSay("You will be protected until the next death, thank you.", cid)
                            doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You will be protected until the next death, thank you.")
                        else
                            selfSay("You dont have money for this, I'm sorry.", cid)
                        end
                    else
                        selfSay("Sorry, you are already blessed.", cid)
                    end
                else
                    selfSay("Sorry, only level 50 or higher players can get blessings.", cid)
                end
            else
                selfSay("Ok, I think.", cid) 
            end
            talkState[talkUser] = 1
       end
        return true
end

function onGreet(cid) 
    talkState[cid] = 1      
    selfSay("Hello "..getCreatureName(cid)..", do you want to be {blessed} by me or to {trade} with me?", cid)
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
