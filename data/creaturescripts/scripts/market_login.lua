-- ============================================================================
--  Market / Auction System - Login handler
--  Returns expired offers back to the player via mail.
-- ============================================================================

local function returnLoot(uid, itemid, count, tier)
    local chest = doCreateItemEx(1988)
    local itemUid = doAddContainerItem(chest, itemid, count)

    -- devolve o tier: o atributo tem que estar no item antes de o baú ser
    -- aberto pelo jogador, senão o sprite volta sem o shader do tier
    tier = tonumber(tier) or 0
    if tier > 0 and itemUid and itemUid > 0 and type(doItemSetAttribute) == "function" then
        pcall(doItemSetAttribute, itemUid, "tier", tier)
    end

    doPlayerSendMailByName(getPlayerName(uid), chest, 1)
    doPlayerSendTextMessage(uid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você recebeu no depot de Ba Sing Se " .. count .. " " .. getItemNameById(itemid) .. " por sua oferta no market ter expirado.")
end

function onLogin(cid)
    local result = db.getResult("SELECT `id`, `item_id`, `count`, `tier` FROM `auction_system` WHERE `player` = " .. getPlayerGUID(cid) .. " AND `world_id` = " .. getConfigValue('worldId') .. " AND `expired` = 1;")
    if result:getID() ~= -1 then
        repeat
            local auctionId = result:getDataInt("id")
            local itemId = result:getDataInt("item_id")
            local itemCount = result:getDataInt("count")
            local itemTier = tonumber(result:getDataInt("tier")) or 0
            db.executeQuery("DELETE FROM `auction_system` WHERE `id` = " .. auctionId .. ";")
            returnLoot(cid, itemId, itemCount, itemTier)
        until not result:next()
        result:free()
    end
    return true
end
