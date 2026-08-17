-- Rogerio - Quest: As Fotos de Rogerio (quest id 20)
-- Historia: Rogerio tira fotos das paisagens quando um Mordecasca da terra
-- rouba as fotos. O jogador recupera as fotos (drop condicional das
-- Mordecascas, so quando esta na quest) e devolve ao Rogerio.
-- Storages (data/questSystem/quests.xml):
--   49200 = status da quest (1 = em andamento, 2 = completa)
--   49201 = progresso (quantas fotos o jogador ja possui, 0-3)
--
-- Item: Foto (18877). O drop da foto e condicionado a quest e e feito pelo
-- evento RogerioLoot (data/creaturescripts/scripts/rogerioLoot.lua).
--
-- Rogerio so fala com jogadores de level 115 ou maior.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 115

local STATUS_STORAGE = 49200
local PROGRESS_STORAGE = 49201

local PHOTO_ITEM = 18877
local PHOTOS_NEEDED = 3

-- Recompensa (ajuste como quiser)
local REWARD_ITEM = 2152   -- platinum coin
local REWARD_COUNT = 100
local REWARD_EXP = 1000000

local QUEST_NAME = "As Fotos de Rogerio"
local MISSION_NAME = "Recuperar as fotos roubadas"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function photosCount(cid)
    return getPlayerItemCount(cid, PHOTO_ITEM)
end

local function hasEnoughPhotos(cid)
    return photosCount(cid) >= PHOTOS_NEEDED
end

-- Mantem o progresso do quest log (client: modules/game_quests) sincronizado
-- com as fotos que o jogador carrega no inventario.
local function syncProgress(cid)
    local current = math.min(photosCount(cid), PHOTOS_NEEDED)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, current)
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Rogerio"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    print("[Rogerio] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerRemoveItem(cid, PHOTO_ITEM, PHOTOS_NEEDED)
    doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, PHOTOS_NEEDED)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    print("[Rogerio] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missao concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Ainda nao e a sua hora, aventureiro. Essas paisagens so podem ser registradas por quem tem coragem de level 115 ou mais. Volte quando for mais forte!", cid)
        return true
    end
    talkState[cid] = 1
    syncProgress(cid)

    if questCompleted(cid) then
        selfSay("Ola, " .. getCreatureName(cid) .. "! Obrigado por ter recuperado minhas fotos. Agora consigo registrar as paisagens novamente em paz!", cid)
    elseif hasEnoughPhotos(cid) then
        selfSay("Ola, " .. getCreatureName(cid) .. "! Vejo que voce recuperou minhas fotos! Diga que quer me devolver para receber sua recompensa.", cid)
    elseif questStarted(cid) then
        selfSay("Ola, " .. getCreatureName(cid) .. "! Ainda estou sem minhas fotos... As Mordecascas da terra levaram tudo o que eu tinha registrado. Recupere-as pra mim!", cid)
    else
        selfSay("Ola, " .. getCreatureName(cid) .. "! Eu sou Rogerio, fotografo de paisagens. Eu estava tirando fotos da regiao quando um Mordecasca da terra surgiu e roubou todas as minhas fotos! Voce pode me ajudar a recupera-las?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Ainda nao e a sua hora, aventureiro. Volte quando tiver level 115 ou mais!", cid)
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
                selfSay("Voce ja me devolveu as fotos, " .. getCreatureName(cid) .. "! Obrigado de novo, agora posso voltar a fotografar as paisagens!", cid)
            elseif hasEnoughPhotos(cid) then
                deliverQuest(cid)
                selfSay("Minhas fotos! Que alegria ve-las de volta! Aqui esta sua recompensa: " .. REWARD_COUNT .. " platinum coins e " .. REWARD_EXP .. " de experiencia. Obrigado, " .. getCreatureName(cid) .. "!", cid)
            elseif started then
                selfSay("Ainda estou sem minhas fotos! Faltam " .. (PHOTOS_NEEDED - photosCount(cid)) .. " para completar o album. Vai atras das Mordecascas da terra e recupere-as!", cid)
            else
                selfSay("Otimo! As Mordecascas da terra roubaram minhas fotos quando eu fotografava as paisagens. Cace-as e recupere as " .. PHOTOS_NEEDED .. " fotos que elas levaram!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "foto") or msgcontains(msg, "fotos") or msgcontains(msg, "mordecasca") or msgcontains(msg, "paisagem") or msgcontains(msg, "roub") or msgcontains(msg, "recuperar") or msgcontains(msg, "ajuda") or msgcontains(msg, "album") then
            if hasEnoughPhotos(cid) then
                selfSay("Voce recuperou minhas fotos! Diga que quer me devolver para receber sua recompensa.", cid)
            elseif started then
                selfSay("Eu estava tirando fotos das paisagens quando um Mordecasca da terra apareceu e roubou tudo! Ainda faltam " .. (PHOTOS_NEEDED - photosCount(cid)) .. " fotos pra mim. Cace as Mordecascas da terra!", cid)
            else
                selfSay("Eu estava tirando fotos das paisagens quando um Mordecasca da terra surgiu e roubou todas as minhas fotos! Quer me ajudar a recupera-las?", cid)
            end
        else
            selfSay("Nao entendi. Esta falando das minhas {fotos} que as Mordecascas da terra roubaram?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
