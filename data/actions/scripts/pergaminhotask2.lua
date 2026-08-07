local ITEM_FROM = 18355
local ITEM_TO = 18353
local DURATION = 2500 -- 1.5 segundos (em ms)

local function revertItem(position)
    local tile = Tile(position)
    if not tile then
        return
    end

    local item = tile:getItemById(ITEM_TO)
    if item then
        item:transform(ITEM_FROM)
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if item:getId() ~= ITEM_FROM then
        return true
    end

    item:transform(ITEM_TO)
    addEvent(revertItem, DURATION, item:getPosition())

    return true
end