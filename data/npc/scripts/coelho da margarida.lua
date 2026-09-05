-- Coelho da Margarida - Quest: O Coelho da Margarida (quest id 23)
-- O coelho fugiu de medo e entrou na toca das aranhas cospe pedra.
-- O jogador (que ja falou com a Dona Margarida) diz {resgatar} e o
-- coelho se acalma e vai pra casa. O resgate libera a reward na
-- Dona Margarida.
-- Storages (data/questSystem/quests.xml):
--   49230 = status da quest (1 = em andamento, 2 = coelho resgatado,
--           3 = completa / reward entregue)
--   49231 = progresso (1 = coelho resgatado)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49230
local PROGRESS_STORAGE = 49231

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function rabbitRescued(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 3
end

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    if questCompleted(cid) or rabbitRescued(cid) then
        selfSay("*The rabbit happily hops around you, ready to go back to Mrs. Margarida's house!*", cid)
    elseif questStarted(cid) then
        selfSay("*The rabbit is trembling with fear, hiding in a corner of the stone-spitting spiders' den...*", cid)
    else
        selfSay("*The scared little rabbit cowers when it sees you. It doesn't seem to trust you...*", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "rescue") or msgcontains(msg, "rescue") or msgcontains(msg, "return") or msgcontains(msg, "home") or msgcontains(msg, "margarida") then
            if questCompleted(cid) then
                selfSay("*The rabbit is happy and safe at home with Mrs. Margarida!*", cid)
            elseif rabbitRescued(cid) then
                selfSay("*The rabbit snuggles in your arms, ready to go home! Take it back to Mrs. Margarida!*", cid)
            elseif questStarted(cid) then
                setPlayerStorageValue(cid, STATUS_STORAGE, 2)
                setPlayerStorageValue(cid, PROGRESS_STORAGE, 1)
                doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
                print("[Coelho da Margarida] resgatado cid=" .. cid)
                selfSay("*The rabbit calms down when it hears you came from Mrs. Margarida! It snuggles in your arms, safe! Take it back to her!*", cid)
            else
                selfSay("*The rabbit cowers, scared... It only trusts whoever Mrs. Margarida sent. Talk to her first!*", cid)
            end
        else
            selfSay("*The little rabbit looks at you with wide eyes full of fear...*", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
