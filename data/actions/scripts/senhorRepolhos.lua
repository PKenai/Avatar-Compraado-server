-- senhorRepolhos.lua - Acao para clicar nos repolhos (item 18929) no chao
-- Quando o player clica em um repolho no chao, o repolho NAO e coletado
-- (permanece no chao para outras pessoas). Apenas o contador do player
-- e incrementado, desde que ele tenha a quest ativa e nao tenha coletado
-- aquele repolho especifico antes.
--
-- Os repolhos devem ter action IDs unicos no mapa (recomendado: 49263-49312,
-- correspondendo aos 50 repolhos). O script usa a action ID do item para
-- identificar qual repolho foi coletado.
--
-- Se o repolho nao tiver action ID, o script usa a posicao (x,y,z) como
-- identificador unico.

local CABBAGE_ITEM = 18929

local STATUS_STORAGE = 49260   -- 1 = quest ativa, 2 = completa
local COUNT_STORAGE  = 49261   -- total de repolhos recuperados

local TOTAL_CABBAGES = 50

-- Gera uma storage key unica para cada repolho
local function getCabbageStorageKey(actionId, pos)
    if actionId and actionId > 0 then
        return "cabbage_" .. actionId
    end
    -- Fallback: usa a posicao como identificador
    return "cabbage_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
end

-- Incrementa o contador de repolhos do player
local function incrementCount(cid)
    local current = getPlayerStorageValue(cid, COUNT_STORAGE)
    if type(current) ~= "number" or current < 0 then
        current = 0
    end
    setPlayerStorageValue(cid, COUNT_STORAGE, current + 1)
    return current + 1
end

-- Envia notificacao visual ao player
local function sendCollectEffect(cid, pos)
    doSendMagicEffect(pos, CONST_ME_MAGIC_GREEN)
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "Voce coletou um repolho!")
    end)
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- So funciona com o item de repolho
    if item.itemid ~= CABBAGE_ITEM then
        return true
    end

    -- Verificar se o player tem a quest ativa
    local questStatus = getPlayerStorageValue(cid, STATUS_STORAGE)
    if questStatus ~= 1 then
        pcall(function()
            doPlayerSendCancel(cid, "Voce precisa falar com o Senhor dos repolhos primeiro!")
        end)
        return true
    end

    -- Verificar se ja atingiu o maximo
    local currentCount = getPlayerStorageValue(cid, COUNT_STORAGE)
    if type(currentCount) ~= "number" or currentCount < 0 then
        currentCount = 0
    end
    if currentCount >= TOTAL_CABBAGES then
        pcall(function()
            doPlayerSendCancel(cid, "Voce ja recuperou todos os repolhos! Volte ao Senhor dos repolhos!")
        end)
        return true
    end

    -- Identificar o repolho (actionID ou posicao)
    local actionId = item.actionid
    local pos = toPosition
    local storageKey = getCabbageStorageKey(actionId, pos)

    -- Verificar se ja coletou este repolho especifico
    local alreadyCollected = getPlayerStorageValue(cid, storageKey)
    if alreadyCollected == 1 then
        pcall(function()
            doPlayerSendCancel(cid, "Voce ja coletou este repolho antes!")
        end)
        return true
    end

    -- Marcar este repolho como coletado
    setPlayerStorageValue(cid, storageKey, 1)

    -- Incrementar o contador
    local newCount = incrementCount(cid)

    -- Efeito visual
    sendCollectEffect(cid, pos)

    -- Notificar a contagem
    pcall(function()
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
            "Repolhos recuperados: " .. newCount .. "/" .. TOTAL_CABBAGES)
    end)

    -- NAO remover o item (repolho fica no chao para outras pessoas)
    -- return true = acao tratada, item NAO e coletado
    return true
end
