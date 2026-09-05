-- NPC Vincente - Forjador
-- Ao dizer "hi", pergunta se quer usar a forja.
-- Ao dizer "yes", envia dados de crafting e abre o modulo no client.
-- Quando o player anda, o modulo fecha (tratado no client).

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local CRAFTING_OPCODE = 106

-- Envia a janela de crafting para o client usando json
local function sendCraftingWindow(cid, profId)
  -- Carrega craftingSystem se necessario
  if type(CraftingSystem) ~= "table" then
    local ok, err = pcall(dofile, getDataDir().."lib/craftingSystem.lua")
    if not ok then
      print("[Vincente] ERRO ao carregar craftingSystem: " .. tostring(err))
      return
    end
  end
  if type(CraftingSystem) == "table" and type(CraftingSystem.sendWindow) == "function" then
    local ok, err = pcall(CraftingSystem.sendWindow, cid, profId or 1)
    if not ok then
      print("[Vincente] ERRO ao enviar janela: " .. tostring(err))
    end
  else
    print("[Vincente] CraftingSystem nao disponivel")
  end
end

-- Callbacks do NPC system
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    selfSay("Hello, " .. getCreatureName(cid) .. "! Sou Vincente, o forjador. Deseja usar minha forja?", cid)
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

    -- Stage 1: Pergunta se quer usar a forja
    if talkState[talkUser] == 1 then
        if msgcontains(msg, "yes") or msgcontains(msg, "yes") or msgcontains(msg, "forja") then
            selfSay("Great! Abrindo a forja agora...", cid)
            talkState[talkUser] = 2
            -- Envia a janela de crafting para o client
            sendCraftingWindow(cid, 1)
        elseif msgcontains(msg, "no") or msgcontains(msg, "no") then
            selfSay("Sem problemas! Volte quando precisar.", cid)
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        else
            selfSay("Deseja usar minha forja? Responda 'sim' ou 'nao'.", cid)
        end

    -- Stage 2: Forja aberta
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "bye") or msgcontains(msg, "tchau") then
            selfSay("Ate logo, " .. getCreatureName(cid) .. "! Volte quando precisar forjar algo.", cid)
            doSendPlayerExtendedOpcode(cid, CRAFTING_OPCODE, "close")
            talkState[talkUser] = 0
            npcHandler:releaseFocus(cid)
        elseif msgcontains(msg, "hi") or msgcontains(msg, "oi") then
            selfSay("A forja ja esta aberta! Use-a para criar seus itens.", cid)
        else
            -- Ignora outras mensagens, mantem a conversa
        end
    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
