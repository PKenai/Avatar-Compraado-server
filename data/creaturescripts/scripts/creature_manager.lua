-- ═══════════════════════════════════════════════════════════════
-- Agriculture System — adaptado para TFS 0.4 / Avatar
-- Opcode: 135
-- ═══════════════════════════════════════════════════════════════

local FARM_OPCODE   = 135
local QUEST_STORAGE = 45900

-- Client IDs e nomes hardcoded pois ItemType não está disponível
-- nesse ambiente Lua (TFS 0.4 creaturescript).
local AgricultureConfig = {
    waterCooldown = 18000, -- 5 horas por estágio
    plants = {
        ["Fire Seed"] = {
            seedClientId    = 18216,
            harvestItemId   = 18232,
            harvestClientId = 18232,
            harvestName     = "fire fruit",
            harvestCount    = 3,
            price           = 500,
            stages = {
                [1] = {name = "Fire Seedling",   clientId = 18221},
                [2] = {name = "Fire Plant",       clientId = 18223},
                [3] = {name = "Fire Fruit Plant", clientId = 18225}
            }
        },
        ["Water Seed"] = {
            seedClientId    = 18218,
            harvestItemId   = 18231,
            harvestClientId = 18231,
            harvestName     = "water fruit",
            harvestCount    = 3,
            price           = 500,
            stages = {
                [1] = {name = "Water Seedling",   clientId = 18221},
                [2] = {name = "Water Plant",       clientId = 18223},
                [3] = {name = "Water Fruit Plant", clientId = 18226}
            }
        },
        ["Earth Seed"] = {
            seedClientId    = 18217,
            harvestItemId   = 18234,
            harvestClientId = 18234,
            harvestName     = "earth fruit",
            harvestCount    = 3,
            price           = 500,
            stages = {
                [1] = {name = "Earth Seedling",   clientId = 18221},
                [2] = {name = "Earth Plant",       clientId = 18223},
                [3] = {name = "Earth Fruit Plant", clientId = 18227}
            }
        },
        ["Air Seed"] = {
            seedClientId    = 18219,
            harvestItemId   = 18233,
            harvestClientId = 18233,
            harvestName     = "air fruit",
            harvestCount    = 3,
            price           = 500,
            stages = {
                [1] = {name = "Air Seedling",   clientId = 18221},
                [2] = {name = "Air Plant",       clientId = 18223},
                [3] = {name = "Air Fruit Plant", clientId = 18228}
            }
        }
    }
}

-- ─── Serialização ──────────────────────────────────────────────

local function getMyPlantsStr(cid)
    local parts = {}
    local guid  = getPlayerGUID(cid)
    local r = db.getResult(
        "SELECT `id`, `creature_name`, `custom_name`, `stage`, `last_train`" ..
        " FROM `player_creature_manager` WHERE `player_id` = " .. guid
    )
    if r:getID() ~= -1 then
        repeat
            local id        = r:getDataInt("id")
            local baseName  = r:getDataString("creature_name")
            local customName= r:getDataString("custom_name")
            local stage     = r:getDataInt("stage")
            local lastWater = r:getDataInt("last_train")
            local cfg = AgricultureConfig.plants[baseName]
            if cfg then
                local sId = cfg.stages[stage] and cfg.stages[stage].clientId or 18221
                local stageClientId = ItemType(sId):getClientId()
                if stageClientId == 0 then stageClientId = sId end
                -- id~baseName~customName~stage~maxStage~lastWater~cooldown~stageClientId~harvestName
                table.insert(parts,
                    id .."~".. baseName .."~".. customName .."~".. stage
                    .."~".. #cfg.stages .."~".. lastWater .."~".. AgricultureConfig.waterCooldown
                    .."~".. stageClientId .."~".. cfg.harvestName
                )
            end
        until not r:next()
        r:free()
    end
    return table.concat(parts, ";")
end

local function getStorePlantsStr()
    local parts = {}
    for baseName, cfg in pairs(AgricultureConfig.plants) do
        local seedClientId = ItemType(cfg.seedClientId):getClientId()
        if seedClientId == 0 then seedClientId = cfg.seedClientId end
        -- baseName~seedClientId~price~harvestName
        table.insert(parts,
            baseName .."~".. seedClientId .."~".. cfg.price .."~".. cfg.harvestName
        )
    end
    return table.concat(parts, ";")
end

local function sendFarmUpdate(cid)
    local unlocked = (getPlayerStorageValue(cid, QUEST_STORAGE) >= 1) and "1" or "0"
    local buf = "update_all"
        .."|unlocked:".. unlocked
        .."|serverTime:".. os.time()
        .."|myPlants:".. getMyPlantsStr(cid)
        .."|storePlants:".. getStorePlantsStr()
    doSendPlayerExtendedOpcode(cid, FARM_OPCODE, buf)
end

-- ─── Handler principal (chamado pelo opcode.lua) ───────────────

function handleFarmOpcode(cid, buffer)
    local ok, err = pcall(function()
        if not buffer or buffer == "" then return end

        local sep    = buffer:find("|")
        local action = sep and buffer:sub(1, sep - 1) or buffer
        local param  = sep and buffer:sub(sep + 1) or ""
        local guid   = getPlayerGUID(cid)

        -- ── FETCH ────────────────────────────────────────────────
        if action == "fetch" then
            sendFarmUpdate(cid)

        -- ── WATER (rega gratuita - diminui 5-15 min, 1x por estágio) ─
        elseif action == "water" then
            if getPlayerStorageValue(cid, QUEST_STORAGE) < 1 then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "You must buy your farm from the Farmer first!")
                return
            end
            local farmId = tonumber(param)
            if not farmId then return end

            local r = db.getResult(
                "SELECT `creature_name`, `custom_name`, `stage`, `last_train`, `watered_stage` FROM `player_creature_manager`" ..
                " WHERE `id` = " .. farmId .. " AND `player_id` = " .. guid
            )
            if r:getID() ~= -1 then
                local baseName     = r:getDataString("creature_name")
                local customName   = r:getDataString("custom_name")
                local stage        = r:getDataInt("stage")
                local lastWater    = r:getDataInt("last_train")
                local wateredStage = r:getDataInt("watered_stage")
                r:free()
                local cfg = AgricultureConfig.plants[baseName]
                if cfg then
                    if stage >= #cfg.stages then
                        doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                            "This plant is fully grown. Harvest it!")
                    elseif wateredStage >= stage then
                        doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                            "You have already watered this plant in its current stage!")
                    else
                        local minutes = math.random(5, 15)
                        local reduceSeconds = minutes * 60
                        local newLastTrain = lastWater - reduceSeconds
                        db.query(string.format(
                            "UPDATE `player_creature_manager` SET `last_train` = %d, `watered_stage` = %d WHERE `id` = %d",
                            newLastTrain, stage, farmId
                        ))
                        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_WATERSPLASH)
                        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                            string.format("You watered your %s! Growth time reduced by %d minutes.", customName, minutes))
                        sendFarmUpdate(cid)
                    end
                end
            end

        -- ── GROW (avança estágio) ────────────────────────────────
        elseif action == "grow" then
            if getPlayerStorageValue(cid, QUEST_STORAGE) < 1 then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "You must buy your farm from the Farmer first!")
                return
            end
            local farmId = tonumber(param)
            if not farmId then return end

            local r = db.getResult(
                "SELECT `creature_name`, `custom_name`, `stage`, `last_train` FROM `player_creature_manager`" ..
                " WHERE `id` = " .. farmId .. " AND `player_id` = " .. guid
            )
            if r:getID() ~= -1 then
                local baseName   = r:getDataString("creature_name")
                local customName = r:getDataString("custom_name")
                local stage      = r:getDataInt("stage")
                local lastWater  = r:getDataInt("last_train")
                r:free()
                local cfg = AgricultureConfig.plants[baseName]
                if cfg then
                    local now = os.time()
                    if now >= (lastWater + AgricultureConfig.waterCooldown) then
                        local nextStage = stage + 1
                        if nextStage <= #cfg.stages then
                            local newName = cfg.stages[nextStage].name
                            db.query(string.format(
                                "UPDATE `player_creature_manager` SET `stage` = %d, `custom_name` = %s, `last_train` = %d WHERE `id` = %d",
                                nextStage, db.escapeString(newName), now, farmId
                            ))
                            doSendMagicEffect(getCreaturePosition(cid), CONST_ME_PLANTATTACK)
                            doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                                "Your " .. customName .. " grew into a " .. newName .. "!")
                            sendFarmUpdate(cid)
                        else
                            doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                                "This plant is already at its final stage. Harvest it!")
                        end
                    else
                        local remaining = (lastWater + AgricultureConfig.waterCooldown) - os.time()
                        local hours = math.floor(remaining / 3600)
                        local mins  = math.floor((remaining % 3600) / 60)
                        doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                            string.format("Wait %dh %dm before this plant is ready to grow.", hours, mins))
                    end
                end
            end

        -- ── HARVEST ──────────────────────────────────────────────
        elseif action == "harvest" then
            if getPlayerStorageValue(cid, QUEST_STORAGE) < 1 then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "You must buy your farm from the Farmer first!")
                return
            end
            local farmId = tonumber(param)
            if not farmId then return end

            local r = db.getResult(
                "SELECT `creature_name`, `custom_name`, `stage`, `last_train` FROM `player_creature_manager`" ..
                " WHERE `id` = " .. farmId .. " AND `player_id` = " .. guid
            )
            if r:getID() ~= -1 then
                local baseName   = r:getDataString("creature_name")
                local customName = r:getDataString("custom_name")
                local stage      = r:getDataInt("stage")
                local lastWater  = r:getDataInt("last_train")
                r:free()
                local cfg = AgricultureConfig.plants[baseName]
                if cfg then
                    local now = os.time()
                    if stage == #cfg.stages and now >= (lastWater + AgricultureConfig.waterCooldown) then
                        db.query("DELETE FROM `player_creature_manager` WHERE `id` = " .. farmId)
                        doPlayerAddItem(cid, cfg.harvestItemId, cfg.harvestCount)
                        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_GREEN)
                        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                            "You harvested your " .. customName .. " and received "
                            .. cfg.harvestCount .. "x " .. cfg.harvestName .. "!")
                        sendFarmUpdate(cid)
                    else
                        doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                            "This plant is not ready for harvest yet.")
                    end
                end
            end

        -- ── RELEASE ──────────────────────────────────────────────
        elseif action == "release" then
            if getPlayerStorageValue(cid, QUEST_STORAGE) < 1 then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "You must buy your farm from the Farmer first!")
                return
            end
            local farmId = tonumber(param)
            if not farmId then return end

            local r = db.getResult(
                "SELECT `custom_name` FROM `player_creature_manager`" ..
                " WHERE `id` = " .. farmId .. " AND `player_id` = " .. guid
            )
            if r:getID() ~= -1 then
                local customName = r:getDataString("custom_name")
                r:free()
                db.query("DELETE FROM `player_creature_manager` WHERE `id` = " .. farmId)
                doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
                doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                    "You removed your " .. customName .. " from the farm.")
                sendFarmUpdate(cid)
            end

        -- ── BUY ──────────────────────────────────────────────────
        elseif action == "buy" then
            if getPlayerStorageValue(cid, QUEST_STORAGE) < 1 then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "You must buy your farm from the Farmer first!")
                return
            end

            local rCount = db.getResult(
                "SELECT COUNT(*) AS `count` FROM `player_creature_manager` WHERE `player_id` = " .. guid
            )
            local count = 0
            if rCount:getID() ~= -1 then
                count = rCount:getDataInt("count")
                rCount:free()
            end
            if count >= 9 then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                    "Your farm is full! You can only have 9 plants at a time.")
                return
            end

            local baseName = param
            if not baseName or baseName == "" then return end

            local cfg = AgricultureConfig.plants[baseName]
            if cfg then
                if doPlayerRemoveMoney(cid, cfg.price) then
                    local firstName = cfg.stages[1].name
                    db.query(string.format(
                        "INSERT INTO `player_creature_manager` (`player_id`, `creature_name`, `custom_name`, `stage`, `last_train`) VALUES (%d, %s, %s, 1, %d)",
                        guid, db.escapeString(baseName), db.escapeString(firstName), os.time()
                    ))
                    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
                    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE,
                        "You planted a " .. baseName .. "! Water it and let it grow.")
                    sendFarmUpdate(cid)
                else
                    doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL,
                        "You do not have enough money to buy this seed.")
                end
            end
        end
    end)

    if not ok then
        print("[AgricultureSystem] Error in handleFarmOpcode: " .. tostring(err))
    end
end
