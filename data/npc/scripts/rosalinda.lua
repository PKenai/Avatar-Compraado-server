-- Rosalinda - Quest: matar 100 Vermes de Cemiterio (quest id 32)
-- Storages: 49320 = status, 49321 = progresso
-- Recompensa: 20.000 exp + item (a definir)
-- Titulo: "Defensora do Cemiterio" (conquista 29)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local STATUS_STORAGE = 49320
local PROGRESS_STORAGE = 49321
local NEEDED = 100
local REWARD_EXP = 20000
local QUEST_NAME = "O Cemiterio da Rosalinda"
local MISSION_NAME = "Limpar o Cemiterio"

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
        payload = payload .. ',\"soundType\":\"' .. soundType .. '\",\"npcName\":\"Rosalinda\"'
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
    selfSay("Oi! Voce parece ser corajoso. Eu sou a {Rosalinda} e preciso de ajuda com um problemazinho no cemiterio.", cid)
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
                selfSay("Voce ja limpou o cemiterio! O brinquedo da vovozinha esta salvo! Obrigada!", cid)
            elseif started then
                if progress >= NEEDED then
                    selfSay("Voce eliminou os 100 vermes! O cemiterio esta limpo! Quer sua recompensa?", cid)
                    talkState[talkUser] = 2
                else
                    selfSay("Ainda faltam " .. (NEEDED - progress) .. " vermes. Eles estao comendo tudo no cemiterio!", cid)
                end
            else
                selfSay("Meu brinquedo favorito da vovozinha caiu no cemiterio e tem vermes comendo tudo! Voce pode me {ajudar} a limpar o cemiterio?", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "cemiterio") or msgcontains(msg, "verme") or msgcontains(msg, "brinquedo") or msgcontains(msg, "ajuda") then
            if started and not completed then
                selfSay("Ainda faltam " .. (NEEDED - progress) .. " vermes. Eles estao comendo tudo no cemiterio!", cid)
            else
                selfSay("Eu sou a {Rosalinda}! Perdi o brinquedo da vovozinha no cemiterio e tem vermes por toda parte! Voce consegue limpar pra mim?", cid)
            end
        else
            selfSay("Nao entendi. Voce quer me {ajudar} com os vermes do cemiterio?", cid)
        end
    elseif talkState[talkUser] == 2 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            doPlayerAddExperience(cid, REWARD_EXP)
            completeQuest(cid)
            selfSay("Aqui esta sua experiencia! Voce salvou o brinquedo da vovozinha! Voce agora e o Guardiao do Cemiterio!", cid)
            talkState[talkUser] = 1
        else
            selfSay("Tudo bem, volte quando quiser receber sua recompensa!", cid)
            talkState[talkUser] = 1
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
