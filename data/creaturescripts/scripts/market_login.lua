-- ============================================================================
--  Market / Auction System - Login handler
--  Returns expired offers back to the player via mail.
-- ============================================================================

local function returnLoot(uid, itemid, count)
    local chest = doCreateItemEx(1988)
    doAddContainerItem(chest, itemid, count)
    doPlayerSendMailByName(getPlayerName(uid), chest, 1)
    doPlayerSendTextMessage(uid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você recebeu no depot de Ba Sing Se " .. count .. " " .. getItemNameById(itemid) .. " por sua oferta no market ter expirado.")
end

function onLogin(cid)
    local result = db.getResult("SELECT `id`, `item_id`, `count` FROM `auction_system` WHERE `player` = " .. getPlayerGUID(cid) .. " AND `world_id` = " .. getConfigValue('worldId') .. " AND `expired` = 1;")
    if result:getID() ~= -1 then
        repeat
            local auctionId = result:getDataInt("id")
            local itemId = result:getDataInt("item_id")
            local itemCount = result:getDataInt("count")
            db.executeQuery("DELETE FROM `auction_system` WHERE `id` = " .. auctionId .. ";")
            returnLoot(cid, itemId, itemCount)
        until not result:next()
        result:free()
    end
    return true
end
