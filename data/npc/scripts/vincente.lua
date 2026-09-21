-- NPC Vincente - Blacksmith
-- On saying "hi", asks if the player wants to use the forge.
-- On saying "yes", sends crafting data and opens the module on the client.
-- When the player walks, the module closes (handled on the client).

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local CRAFTING_OPCODE = 106

-- Sends the crafting window to the client using json
local function sendCraftingWindow(cid, profId)
  -- Loads craftingSystem if necessary
  if type(CraftingSystem) ~= "table" then
    local ok, err = pcall(dofile, getDataDir().."lib/craftingSystem.lua")
    if not ok then
      print("[Vincente] ERROR loading craftingSystem: " .. tostring(err))
      return
    end
  end
  if type(CraftingSystem) == "table" and type(CraftingSystem.sendWindow) == "function" then
    local ok, err = pcall(CraftingSystem.sendWindow, cid, profId or 1)
    if not ok then
      print("[Vincente] ERROR sending window: " .. tostring(err))
    end
  else
    print("[Vincente] CraftingSystem not available")
  end
end

-- NPC system callbacks
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    selfSay("Hello, " .. getCreatureName(cid) .. "! I am Vincente, the blacksmith. Would you like to use my forge?", cid)
    return true
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)

    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    -- Stage 1: Asks if the player wants to use the forge
    if talkState[talkUser] == 1 then
        if msgcontains(msg, "yes") or msgcontains(msg, "forge") then
            selfSay("Great! Opening the forge now...", cid)
            talkState[talkUser] = 2
            -- Sends the crafting window to the client
            sendCraftingWindow(cid, 1)
        elseif msgcontains(msg, "no") then
            selfSay("No problem! Come back whenever you need.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        else
            selfSay("Would you like to use my forge? Answer 'yes' or 'no'.", cid)
        end

    -- Stage 2: Forge open
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "bye") then
            selfSay("See you soon, " .. getCreatureName(cid) .. "! Come back whenever you need to forge something.", cid)
            doSendPlayerExtendedOpcode(cid, CRAFTING_OPCODE, "close")
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        elseif msgcontains(msg, "hi") then
            selfSay("The forge is already open! Use it to create your items.", cid)
        else
            -- Ignores other messages, keeps the conversation going
        end
    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
