--[[
 * montanhaBarreira - action registrada em data/actions/actions.xml com
 * actionid 50000: ao USAR o item do mapa que tiver esse action id, o item
 * 1290 na posicao {x=640, y=441, z=5} some por 5 minutos e depois
 * reaparece sozinho (mesmo comportamento do onDeath do Defensor da montanha).
]]

local ITEM_BARREIRA = 1290
local BARREIRA_POS = {x = 640, y = 441, z = 5}
local BARREIRA_TIME = 5 * 60 * 1000

local timerAtivo = false

local function respawnBarreira()
    doCreateItem(ITEM_BARREIRA, 1, {x = BARREIRA_POS.x, y = BARREIRA_POS.y, z = BARREIRA_POS.z})
    timerAtivo = false
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if timerAtivo then
        return true
    end

    if removeTileItemById(BARREIRA_POS, ITEM_BARREIRA) then
        timerAtivo = true
        doSendMagicEffect(BARREIRA_POS, CONST_ME_POFF)
        addEvent(respawnBarreira, BARREIRA_TIME)
    end

    return true
end
