-- Passaro do Olavo - Item clicavel no mapa
-- Ao clicar no item, marca que o jogador encontrou o passaro.
-- Depois ele volta ao Olavo e diz "oeste" pra completar a quest.

local STATUS_STORAGE = 49410
local BIRD_FOUND_STORAGE = 49411

function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- Verifica se a quest foi iniciada
    local status = getPlayerStorageValue(cid, STATUS_STORAGE)
    if status < 1 then
        doPlayerSendCancel(cid, "Voce ve um passaro fofo, mas ele parece pertencer a alguem...")
        return true
    end

    -- Verifica se ja encontrou
    local found = getPlayerStorageValue(cid, BIRD_FOUND_STORAGE)
    if found >= 1 then
        doPlayerSendCancel(cid, "Voce ja encontrou o passaro! Volte ao Olavo e conte que ele foi pro oeste!")
        return true
    end

    -- Marca que encontrou o passaro
    setPlayerStorageValue(cid, BIRD_FOUND_STORAGE, 1)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Voce encontrou o passaro do Olavo! Ele apontou pro OESTE e fez 'piu piu'! Volte ao Olavo e conte pra ele!")
    print("[Passaro do Olavo] birdFound cid=" .. cid)
    return true
end
