-- ============================================================================
--  Market / Auction System - Startup handler
--  - Ensures the SQL schema exists (persistent across server saves)
--  - Expires offers older than N days
-- ============================================================================

function onStartup()
    -- ------------------------------------------------------------
    -- 1. Schema (MySQL). Harmless if it already exists.
    -- ------------------------------------------------------------
    pcall(function()
        db.executeQuery([[
            CREATE TABLE IF NOT EXISTS `auction_system` (
                `id` int NOT NULL AUTO_INCREMENT,
                `player` int DEFAULT NULL,
                `item_id` int DEFAULT NULL,
                `item_name` varchar(255) DEFAULT NULL,
                `count` int DEFAULT NULL,
                `desc` varchar(255) DEFAULT NULL,
                `cost` bigint DEFAULT NULL,
                `date` int DEFAULT NULL,
                `expired` smallint DEFAULT NULL,
                `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
                `tier` smallint NOT NULL DEFAULT '0',
                PRIMARY KEY (`id`)
            ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
        ]])
    end)

    -- Tier of the item: databases created before the market showed item tiers do
    -- not have this column, and every market query reads it.
    if type(Market) == "table" and type(Market.ensureSchema) == "function" then
        Market.ensureSchema()
    end

    -- Column used to pay sellers (claimed by idle.lua marketCheck).
    -- Only ALTER if the column is missing, so we don't spam the log with
    -- "Duplicate column name" (1060) errors on every startup.
    pcall(function()
        local colCheck = db.getResult("SELECT COUNT(*) AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players' AND COLUMN_NAME = 'auction_balance';")
        if colCheck:getID() == -1 then
            -- Can't inspect the schema (e.g. info_schema unreachable):
            -- try the ALTER directly; pcall swallows a duplicate-column error.
            db.executeQuery("ALTER TABLE `players` ADD COLUMN `auction_balance` bigint NOT NULL DEFAULT 0;")
        else
            local exists = colCheck:getDataInt("c")
            colCheck:free()
            if exists == 0 then
                db.executeQuery("ALTER TABLE `players` ADD COLUMN `auction_balance` bigint NOT NULL DEFAULT 0;")
            end
        end
    end)

    -- Migrate legacy `int` columns to `bigint` (existing installs created
    -- the schema before prices were uncapped). Only ALTERs when needed.
    pcall(function()
        local mig = {
            { tbl = 'auction_system', col = 'cost',            ddl = 'bigint DEFAULT NULL' },
            { tbl = 'players',        col = 'auction_balance', ddl = 'bigint NOT NULL DEFAULT 0' },
        }
        for i, m in ipairs(mig) do
            local chk = db.getResult("SELECT DATA_TYPE AS dt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '" .. m.tbl .. "' AND COLUMN_NAME = '" .. m.col .. "';")
            if chk and chk:getID() ~= -1 then
                local dt = chk:getDataString("dt")
                chk:free()
                if dt and dt ~= "bigint" then
                    db.executeQuery("ALTER TABLE `" .. m.tbl .. "` MODIFY `" .. m.col .. "` " .. m.ddl .. ";")
                end
            end
        end
    end)

    -- ------------------------------------------------------------
    -- 2. Expire offers older than 7 days.
    -- ------------------------------------------------------------
    local days = 7
    local expires = os.time() - (days * 86400)
    local result = db.getResult("SELECT `id` FROM `auction_system` WHERE `date` <= " .. expires .. " AND `expired` = 0 AND `world_id` = " .. getConfigValue('worldId') .. ";")
    if result:getID() ~= -1 then
        local offers_expired = 0
        repeat
            local auctionId = result:getDataInt("id")
            db.executeQuery("UPDATE `auction_system` SET `expired` = 1 WHERE `id` = " .. auctionId .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
            offers_expired = offers_expired + 1
        until not result:next()
        result:free()
        print(">> Auction system: " .. offers_expired .. " offers expired.")
    end
    return true
end
