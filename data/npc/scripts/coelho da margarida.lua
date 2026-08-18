-- Coelho da Margarida - Quest: O Coelho da Margarida (quest id 23)
-- O coelho fugiu de medo e entrou na toca das aranhas cospe pedra.
-- O jogador (que ja falou com a Dona Margarida) diz {resgatar} e o
-- coelho se acalma e vai pra casa. O resgate libera a recompensa na
-- Dona Margarida.
-- Storages (data/questSystem/quests.xml):
--   49230 = status da quest (1 = em andamento, 2 = coelho resgatado,
--           3 = completa / recompensa entregue)
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
        selfSay("*O coelho pula feliz ao seu redor, pronto pra voltar pra casa da Dona Margarida!*", cid)
    elseif questStarted(cid) then
        selfSay("*O coelho está tremendo de medo, escondido num canto da toca das aranhas cospe pedra...*", cid)
    else
        selfSay("*Um coelhinho assustado se encolhe ao te ver. Ele parece não confiar em você...*", cid)
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
        if msgcontains(msg, "resgatar") or msgcontains(msg, "resgata") or msgcontains(msg, "voltar") or msgcontains(msg, "casa") or msgcontains(msg, "margarida") then
            if questCompleted(cid) then
                selfSay("*O coelho está feliz e seguro em casa com a Dona Margarida!*", cid)
            elseif rabbitRescued(cid) then
                selfSay("*O coelho se aconchega nos seus braços, pronto pra voltar pra casa! Leve ele de volta pra Dona Margarida!*", cid)
            elseif questStarted(cid) then
                setPlayerStorageValue(cid, STATUS_STORAGE, 2)
                setPlayerStorageValue(cid, PROGRESS_STORAGE, 1)
                doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
                print("[Coelho da Margarida] resgatado cid=" .. cid)
                selfSay("*O coelho se acalma ao ouvir que você veio da Dona Margarida! Ele se aconchega nos seus braços, salvo! Leve ele de volta pra ela!*", cid)
            else
                selfSay("*O coelho se encolhe, assustado... Ele só confia em quem a Dona Margarida enviou. Fale com ela primeiro!*", cid)
            end
        else
            selfSay("*O coelhinho te olha com os olhos arregalados de medo...*", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
