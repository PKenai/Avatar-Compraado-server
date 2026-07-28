local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
local talkState = {}

function onCreatureAppear(cid)    npcHandler:onCreatureAppear(cid)    end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local STORAGE   = 45900
local PRICE     = 10000
local OPCODE    = 135
local MIN_LEVEL = 100

function greetCallback(cid)
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    talkState[talkUser] = 0

    if getPlayerStorageValue(cid, STORAGE) >= 1 then
        npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|. Welcome back to your creature {farm}!")
    else
        npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|. Are you interested in having your own creature {farm}?")
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    if not talkState[talkUser] then talkState[talkUser] = 0 end

    local unlocked = (getPlayerStorageValue(cid, STORAGE) >= 1)

    if msgcontains(msg, "farm") or msgcontains(msg, "fazenda") then
        if not unlocked then
            if getPlayerLevel(cid) < MIN_LEVEL then
                selfSay("You don't even know how to take care of yourself, let alone a farm. Go acquire more experience...", cid)
                talkState[talkUser] = 0
            else
                selfSay("Would you like to establish your own creature farm? It will cost you 10,000 gold coins. Do you wish to pay and unlock it now?", cid)
                talkState[talkUser] = 1
            end
        else
            selfSay("Opening your creature farm manager...", cid)
            doSendPlayerExtendedOpcode(cid, OPCODE, 'open')
            talkState[talkUser] = 0
        end

    elseif msgcontains(msg, "yes") and talkState[talkUser] == 1 then
        if doPlayerRemoveMoney(cid, PRICE) then
            setPlayerStorageValue(cid, STORAGE, 1)
            selfSay("Wonderful! Your creature farm is now fully operational. Whenever you talk to me about your {farm}, I will open the manager for you!", cid)
            doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
            doSendPlayerExtendedOpcode(cid, OPCODE, 'open')
        else
            selfSay("I'm sorry, but you don't have 10,000 gold coins. Come back when you have the money.", cid)
        end
        talkState[talkUser] = 0

    elseif msgcontains(msg, "no") and talkState[talkUser] == 1 then
        selfSay("Alright, let me know if you change your mind.", cid)
        talkState[talkUser] = 0
    end
    return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
