-- Bau da Colmeia de barro (actionid 49175)
-- Dá a Colmeia de barro (18869) ao player apenas 1 vez (storage 49171,
-- o mesmo storage de progresso da quest 17 "O Mel de Katata").

local COLMEIA_ITEM = 18869
local CHEST_STORAGE = 49171

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if getPlayerStorageValue(cid, CHEST_STORAGE) == 1 then
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "O bau esta vazio... A colmeia ja foi levada.")
        return true
    end

    doPlayerAddItem(cid, COLMEIA_ITEM, 1)
    setPlayerStorageValue(cid, CHEST_STORAGE, 1)
    doSendMagicEffect(getThingPos(cid), 29)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Você encontrou a Colmeia de barro! Leve de volta ao Katata.")
    return true
end
