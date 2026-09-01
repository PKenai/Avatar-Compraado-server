-- Buraco do Passaro do Olavo
-- Quando o jogador pisa no buraco (item 3311 em {x=696, y=323, z=7}),
-- verifica se ele completou a quest do passaro. Se sim, teleporta.
-- Se nao, envia pra posicao segura e avisa.

local QUEST_STATUS_STORAGE = 49410
local QUEST_COMPLETED_VALUE = 2
local HOLE_ITEM = 3311
local HOLE_POS = {x = 696, y = 323, z = 7}

function onStepIn(cid, item, position, lastPosition)
    if item.itemid ~= HOLE_ITEM then
        return false
    end

    -- Verifica se o jogador completou a quest do passaro do olavo
    local status = getPlayerStorageValue(cid, QUEST_STATUS_STORAGE)
    if status >= QUEST_COMPLETED_VALUE then
        -- Completou a quest - teleporta
        doTeleportThing(cid, HOLE_POS)
        doSendMagicEffect(HOLE_POS, CONST_ME_TELEPORT)
    else
        -- Nao completou a quest - envia pra posicao segura e avisa
        doTeleportThing(cid, lastPosition)
        doPlayerSendCancelMessage(cid, "Voce precisa encontrar o passaro do Olavo e descobrir pra onde ele foi primeiro!")
    end
    return true
end
