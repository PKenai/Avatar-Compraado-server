-- Dr. Ferreira - Quest: matar 100 Homens de Barro (quest id 34)
-- Storages: 49340 = status, 49341 = progresso
-- Recompensa: 20 platinum coins (2152) + 40.000 exp
-- Titulo: "Mao de Obra" (conquista 31)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49340
local PROGRESS_STORAGE = 49341
local NEEDED = 100
local REWARD_ITEM = 2152
local REWARD_COUNT = 20
local REWARD_EXP = 40000
local QUEST_NAME = "A Experiencia do Dr. Ferreira"
local MISSION_NAME = "Coletar Argila"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Dr. Ferreira\"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    setPlayerStorageValue(cid, PROGRESS_STORAGE, 0)
    sendNotification(cid, QUEST_NAME, "Nova missao: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function completeQuest(cid)
    setPlayerStorageValue(cid, STATUS_STORAGE, 2)
    sendNotification(cid, QUEST_NAME, "Missao concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. QUEST_NAME)
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
    selfSay("Ah, voce parece ser um assistente de laboratorio em potencial! Sou o {Dr. Ferreira} e preciso de um material muito especifico.", cid)
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
                selfSay("Voce ja me trouxe toda a argila que eu precisava! Obrigado, meu {assistente}!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Perfeito! Voce coletou a argila de 100 homens de barro! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " homens de barro. Preciso de argila fresca pra minha experiencia!", cid)
                end
            else
                selfSay("Estou fazendo uma experiencia muito importante no laboratorio e preciso de argila dos {homens de barro}. Voce pode me ajudar a coletar?", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "argila") or msgcontains(msg, "homem") or msgcontains(msg, "barro") or msgcontains(msg, "experiencia") or msgcontains(msg, "ajuda") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " homens de barro. Preciso de argila fresca pra minha experiencia!", cid)
            else
                selfSay("Eu sou o {Dr. Ferreira}! Estou fazendo uma experiencia no laboratorio da vila e preciso de argila especial dos homens de barro. Quer ser meu assistente?", cid)
            end
        else
            selfSay("Nao entendi. Voce quer ser meu {assistente}?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddItem(cid, REWARD_ITEM, REWARD_COUNT)
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui estao seus 20 platinum coins e 40 mil de experiencia. Voce e um otimo assistente de laboratorio!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Tudo bem, volte quando quiser receber sua recompensa.", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
