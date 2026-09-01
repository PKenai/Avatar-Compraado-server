-- Alavanca do Passaro do Olavo
-- Ao usar a alavanca (actionid 50002), coloca o item 3311 no buraco
-- ({x=696, y=323, z=7}) por 5 minutos e manda um yell na posicao.
-- Somente quem completou a quest do passaro pode entrar no buraco.

local HOLE_ITEM = 3311
local HOLE_POS = {x = 696, y = 323, z = 7}
local HOLE_DURATION = 5 * 60 * 1000  -- 5 minutos em milissegundos

local holeAtivo = false

local function removerBuraco()
    local tile = getTileItemById(HOLE_POS, HOLE_ITEM)
    if tile and tile.uid and tile.uid > 0 then
        doRemoveItem(tile.uid)
    end
    holeAtivo = false
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if holeAtivo then
        doPlayerSendCancel(cid, "A alavanca ja foi usada recentemente. Aguarde...")
        return true
    end

    -- Cria o item do buraco na posicao
    local hole = doCreateItem(HOLE_ITEM, 1, HOLE_POS)
    if not hole then
        doPlayerSendCancel(cid, "Algo deu errado...")
        return true
    end

    holeAtivo = true

    -- Envia yell na posicao do buraco
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "Parece que algo aconteceu a oeste daqui!")

    -- Efeito magico na posicao do buraco
    doSendMagicEffect(HOLE_POS, CONST_ME_MEEH)

    -- Agenda a remocao do buraco apos 5 minutos
    addEvent(removerBuraco, HOLE_DURATION)

    return true
end
