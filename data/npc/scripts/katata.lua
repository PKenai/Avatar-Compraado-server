-- Katata - Quest: recuperar a Colmeia de barro (quest id 17)
-- Storages (data/questSystem/quests.xml):
--   49170 = status da quest (1 = em andamento, 2 = completa)
--   49171 = progresso (1 = colmeia encontrada no bau; tambem e o storage
--           do "1x so" do bau da colmeia, actionid 49175)
-- Item: Colmeia de barro (18869)
-- Recompensa: 20 platinum coins (2152) + 40.000 de experiencia
--
-- Obs: o NPC nao depende da questSystemLib (o estado Lua dos NPCs e
-- separado do global). Usa apenas storages nativas + notificacao manual.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49170
local PROGRESS_STORAGE = 49171
local COLMEIA_ITEM = 18869
local REWARD_ITEM = 2152
local REWARD_COUNT = 20
local REWARD_EXP = 40000
local QUEST_NAME = "O Mel de Katata"
local MISSION_NAME = "Recuperar a Colmeia de barro"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function hasColmeia(cid)
    return getPlayerItemCount(cid, COLMEIA_ITEM) >= 1
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Katata"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Katata] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Nova missão: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerRemoveItem(cid, COLMEIA_ITEM, 1)
    doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Katata] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missão concluída: " .. MISSION_NAME .. "!", "#00FF00", "end")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. MISSION_NAME)
    end)
end

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end
function onPlayerEndTrade(cid)              npcHandler:onPlayerEndTrade(cid)            end
function onPlayerCloseChannel(cid)          npcHandler:onPlayerCloseChannel(cid)        end

function onGreet(cid)
    talkState[cid] = 1
    selfSay("Zzz... Ah! Você aí! Eu estava dormindo e tive meu mel roubado... Tenho certeza que foram as abelhas de barro! Sem minha colmeia, vou passar fome!", cid)
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

    local started = questStarted(cid)
    local completed = questCompleted(cid)

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            if completed then
                selfSay("Você já me devolveu a colmeia. Obrigado, agora posso voltar a comer mel!", cid)
            elseif hasColmeia(cid) then
                deliverQuest(cid)
                selfSay("Você trouxe minha colmeia de volta! Aqui está sua recompensa: 20 platinum coins e 40.000 de experiência!", cid)
            elseif started then
                selfSay("Ainda estou sem minha colmeia! Vá atrás das abelhas de barro e recupere-a, senão vou passar fome!", cid)
            else
                selfSay("Ótimo! Vá até a toca das abelhas de barro e recupere minha colmeia!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "colmeia") or msgcontains(msg, "mel") or msgcontains(msg, "abelha") or msgcontains(msg, "fome") or msgcontains(msg, "ajuda") then
            if hasColmeia(cid) then
                selfSay("Você recuperou minha colmeia! Diga que quer me devolver para receber sua recompensa.", cid)
            elseif started then
                selfSay("Minha colmeia ainda está com as abelhas de barro... Recupere-a, senão vou passar fome!", cid)
            else
                selfSay("As abelhas de barro roubaram meu mel enquanto eu dormia! Recupere minha colmeia pra mim, senão vou passar fome!", cid)
            end
        else
            selfSay("Não entendi. Está falando da minha {colmeia}?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
