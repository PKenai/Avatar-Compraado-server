function onStartup()
    local days = 7
    local expires = os.time() - (days * 86400)
    local result = db.getResult("SELECT `id` FROM `auction_system` WHERE `date` <= " .. expires .. " AND `expired` = 0 AND `world_id` = " .. getConfigValue('worldId') .. ";")
    if result:getID() ~= -1 then
        local offers_expired = 0
        repeat
            local auctionId = result:getDataInt("id")
            db.executeQuery("UPDATE `auction_system` SET `expired` = 1 WHERE `id` = " .. auctionId .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
            offers_expired = offers_expired + 1
        until not result.next(result)
        result.free(result)
        print(">> Auction system: ".. offers_expired .." offers deleted.")
    end
    return true
end