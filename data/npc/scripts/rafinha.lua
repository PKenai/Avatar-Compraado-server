-- Rafinha - Quest: O Anel do Rafinha (quest id 25)
-- Historia: Rafinha perdeu o anel do pai dentro do lago onde eles costumam
-- pescar e pede ajuda pra recupera-lo antes do pai voltar. O jogador usa a
-- vara de pescar (2580) no ponto do lago com actionid 49252 (5% de chance
-- de pescar o Anel de tubarao, 18880 - integrado no tools/fishing.lua) e
-- volta ate o Rafinha, que deixa o anel com o jogador.
-- Storages (data/questSystem/quests.xml):
--   49250 = status (1 = em andamento, 2 = anel pescado, 3 = completa)
--   49251 = progresso (1 = anel pescado; setado pelo fishing.lua)
-- Item: Anel de tubarao (18880) - fica com o jogador
-- Recompensa: 100.000 de experiencia + titulo "Pescador nato"
-- (conquista id 22, achievementsLib.lua)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
npcHandler:setMessage(MESSAGE_GREET, "")
local talkState = {}

local LEVEL_REQUIRED = 50
local STATUS_STORAGE = 49250
local PROGRESS_STORAGE = 49251
local FISHING_ROD = 2580
local REWARD_EXP = 100000
local QUEST_NAME = "O Anel do Rafinha"
local MISSION_NAME = "Pegar o anel no lago"

local function questStarted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) == 1
end

local function ringCaught(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) == 2
end

local function questCompleted(cid)
    return getPlayerStorageValue(cid, STATUS_STORAGE) == 3
end

local function sendNotification(cid, title, message, color, soundType)
    -- JSON manual (opcode 201, client: modules/game_notification).
    -- O json nao existe no estado Lua do NPC, entao montamos na mao.
    local payload = '{"title":"' .. title .. '","message":"' .. message ..
        '","color":"' .. color .. '","duration":5000'
    if soundType then
        payload = payload .. ',"soundType":"' .. soundType .. '","npcName":"Rafinha"'
    end
    payload = payload .. '}'
    pcall(function()
        doSendPlayerExtendedOpcode(cid, 201, payload)
    end)
end

local function startQuest(cid)
    if getPlayerItemCount(cid, FISHING_ROD) < 1 then
        doPlayerAddItem(cid, FISHING_ROD, 1)
    end
    setPlayerStorageValue(cid, STATUS_STORAGE, 1)
    print("[Rafinha] startQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Nova missão: " .. MISSION_NAME .. "!", "#FFA500", "start")
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. QUEST_NAME)
    end)
end

local function deliverQuest(cid)
    doPlayerAddExperience(cid, REWARD_EXP)
    setPlayerStorageValue(cid, STATUS_STORAGE, 3)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    -- Titulo "Pescador nato": conquista id 22 (achievementsLib.lua), mesmo
    -- padrao manual do "Amigo dos animais" (desbloqueio via NPC).
    setPlayerStorageValue(cid, "achCreatureKill_22", 1)
    local ok = pcall(function()
        Achievements.check(cid, 22)
    end)
    if not ok then
        setPlayerStorageValue(cid, "achUnlocked_22", 1)
        pcall(function()
            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Conquista desbloqueada: Pescou o anel do Rafinha! Titulo: Pescador nato (abra Conquistas na topbar para equipar).")
        end)
    end

    print("[Rafinha] completeQuest cid=" .. cid)
    sendNotification(cid, QUEST_NAME, "Missão concluida: " .. MISSION_NAME .. "!", "#00FF00", "end")
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
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Olá, acho que vou precisar de ajuda logo logo antes do meu pai chegar!", cid)
        return true
    end
    talkState[cid] = 1
    local name = getCreatureName(cid)

    if questCompleted(cid) then
        selfSay("Olá, " .. name .. "! Obrigado de novo por me ajudar com o anel! Meu pai adorou a história que eu contei pra ele!", cid)
    elseif ringCaught(cid) then
        deliverQuest(cid)
        selfSay("Nossa, esse anel era meu há muito tempo atrás, não e o do meu pai, mas, obrigado mesmo assim, eu vou contar pro meu pai o que aconteceu, mas pode ficar com meu anel de tubarão pra você, ele costumava ser meu favorito, obrigado pela ajuda!", cid)
    elseif questStarted(cid) then
        selfSay("Olá, " .. name .. "! Você já achou o anel do meu pai no lago? Ele vai voltar logo e eu não posso chegar em casa sem o anel...", cid)
    else
        selfSay("Olá, " .. name .. "! Meu pai e eu costumamos pescar no lago aqui perto, mas hoje eu perdi o anel dele dentro da água! Ele vai voltar logo e eu não posso chegar em casa sem o anel... Você pode me ajudar a pegar o anel de novo antes que meu pai volte?", cid)
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    if getPlayerLevel(cid) < LEVEL_REQUIRED then
        selfSay("Você ainda e muito novinho pra essa aventura. Volte com level 50 ou mais!", cid)
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    msg = string.lower(msg)
    if not talkState[talkUser] or talkState[talkUser] <= 0 then
        talkState[talkUser] = 1
    end

    local name = getCreatureName(cid)
    local completed = questCompleted(cid)
    local caught = ringCaught(cid)

    if talkState[talkUser] == 1 then
        if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
            if completed then
                selfSay("Você já me ajudou, " .. name .. "! Obrigado por tudo!", cid)
            elseif caught then
                deliverQuest(cid)
                selfSay("Nossa, esse anel era meu há muito tempo atrás, não e o do meu pai, mas, obrigado mesmo assim, eu vou contar pro meu pai o que aconteceu, mas pode ficar com meu anel de tubarão pra você, ele costumava ser meu favorito, obrigado pela ajuda!", cid)
            elseif questStarted(cid) then
                selfSay("Você já aceitou! Use a vara de pescar no lago e tente achar o anel. Eu fico te esperando aqui!", cid)
            else
                selfSay("Muito obrigado, " .. name .. "! Use esta vara de pescar no lago e tente achar o anel! Eu fico te esperando aqui!", cid)
                startQuest(cid)
            end
        elseif msgcontains(msg, "anel") or msgcontains(msg, "lago") or msgcontains(msg, "pai")
            or msgcontains(msg, "pescar") or msgcontains(msg, "ajuda") or msgcontains(msg, "vara") then
            if completed then
                selfSay("Obrigado por ter recuperado o anel, " .. name .. "! Foi uma grande aventura!", cid)
            elseif caught then
                selfSay("Você pescou o anel! Volte aqui pra me entregar!", cid)
            elseif questStarted(cid) then
                selfSay("Use a vara de pescar no lago e tente achar o anel do meu pai antes que ele volte!", cid)
            else
                selfSay("Meu pai e eu costumamos pescar no lago aqui perto, e eu perdi o anel dele dentro da água! Você pode me ajudar a pegar o anel de novo antes que meu pai volte?", cid)
            end
        else
            selfSay("Não entendi. Está falando do {anel} do meu pai no lago?", cid)
        end
    end
    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
