-- Carlos - Quest: matar 200 Centopeias Carapaca de Aco (quest id 27)
-- Storages: 49270 = status, 49271 = progresso
-- Recompensa: 50 platinum coins (2152)
-- Titulo: "Forjador de Aco" (conquista 24)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49270
local PROGRESS_STORAGE = 49271
local NEEDED = 200
local REWARD_ITEM = 2152
local REWARD_COUNT = 50
local QUEST_NAME = "A Carapaca de Carlos"
local MISSION_NAME = "Recolher Carapacas de Aco"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 1
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) >= 2
end

local function questProgress(cid)
    local p = getPlayerStorageValue(cid, PROGRESS_STORAGE)
    if p < 0 then p = 0 end
    return math.min(p, NEEDED)
end

local function sendNotification(cid, title, message, color, soundType)
    local payload = '{\"title\":\"' .. title .. '\",\"message\":\"' .. message ..
        '\",\"color\":\"' .. color .. '\",\"duration\":5000'
    if soundType then
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Carlos\"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    local pos = getCreaturePosition(cid)
    if pos then
        doSendMagicEffect(pos, 199)
    end
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
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
    talkState[cid] = 1
    selfSay("E ai, voce parece ser um cara de fibra. Preciso de ajuda com umas {centopeias} que estao atrapalhando meu trabalho.", cid)
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
    local progress = questProgress(cid)

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            if completed then
                selfSay("Voce ja me ajudou com as centopeias. Valeu, parceiro!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Boa! Voce derrotou as 200 centopeias! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " centopeias. Vai la e me traz essas carapacas!", cid)
                end
            else
                selfSay("Beleza! Vai la e me traz 200 carapacas de aco dessas centopeias. Tô precisando pra forjar umas armaduras.", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "centopeia") or msgcontains(msg, "carapaca") or msgcontains(msg, "ajuda") or msgcontains(msg, "desafio") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " centopeias. Vai la e me traz essas carapacas!", cid)
            else
                selfSay("Preciso de carapacas de aco das centopeias pra minha forja. Quer me {ajudar}?", cid)
            end
        else
            selfSay("Nao entendi. Voce quer me {ajudar} com as centopeias?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            completeQuest(cid)
            selfSay("Aqui estao seus 50 platinum coins. Voce e um verdadeiro forjador de aco!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Tudo bem, volte quando quiser pegar sua recompensa.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
