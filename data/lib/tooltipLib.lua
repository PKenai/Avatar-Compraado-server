-- tooltipLib.lua
-- Server-side tooltip data builder for game_tooltips client module
-- Uses global functions (old TFS 0.3/0.4 style)

local CODE_TOOLTIPS = 105

-- SLOTP constants (from items.h)
local SLOTP_HEAD     = bit.lshift(1, 0)
local SLOTP_NECKLACE = bit.lshift(1, 1)
local SLOTP_BACKPACK = bit.lshift(1, 2)
local SLOTP_ARMOR    = bit.lshift(1, 3)
local SLOTP_RIGHT    = bit.lshift(1, 4)
local SLOTP_LEFT     = bit.lshift(1, 5)
local SLOTP_LEGS     = bit.lshift(1, 6)
local SLOTP_FEET     = bit.lshift(1, 7)
local SLOTP_RING     = bit.lshift(1, 8)
local SLOTP_AMMO     = bit.lshift(1, 9)
local SLOTP_TWO_HAND = bit.lshift(1, 11)

-- STAT constants
local STAT_MAXHEALTH = 0
local STAT_MAXMANA   = 1
local STAT_MAGICLEVEL = 4

-- COMBAT constants
local COMBAT_PHYSICALDAMAGE = 1
local COMBAT_ENERGYDAMAGE   = 2
local COMBAT_FIREDAMAGE     = 8
local COMBAT_LIFEDRAIN      = 32
local COMBAT_MANADRAIN      = 64
local COMBAT_HEALING        = 128
local COMBAT_DROWNDAMAGE    = 256
local COMBAT_ICEDAMAGE      = 512
local COMBAT_HOLYDAMAGE     = 1024
local COMBAT_DEATHDAMAGE    = 2048
local COMBAT_EARTHDAMAGE    = 4096
local COMBAT_NONE           = 0

local combatNames = {
    [COMBAT_PHYSICALDAMAGE] = "Physical",
    [COMBAT_ENERGYDAMAGE]   = "Energy",
    [COMBAT_EARTHDAMAGE]    = "Earth",
    [COMBAT_FIREDAMAGE]     = "Fire",
    [COMBAT_LIFEDRAIN]      = "Lifedrain",
    [COMBAT_MANADRAIN]      = "Manadrain",
    [COMBAT_HEALING]        = "Healing",
    [COMBAT_DROWNDAMAGE]    = "Drown",
    [COMBAT_ICEDAMAGE]      = "Ice",
    [COMBAT_HOLYDAMAGE]     = "Holy",
    [COMBAT_DEATHDAMAGE]    = "Death"
}

local combatTypes = {
    COMBAT_PHYSICALDAMAGE, COMBAT_ENERGYDAMAGE, COMBAT_FIREDAMAGE, COMBAT_EARTHDAMAGE,
    COMBAT_LIFEDRAIN, COMBAT_MANADRAIN, COMBAT_HEALING, COMBAT_DROWNDAMAGE,
    COMBAT_ICEDAMAGE, COMBAT_HOLYDAMAGE, COMBAT_DEATHDAMAGE
}

local SKILL_FIST     = 0
local SKILL_CLUB     = 1
local SKILL_SWORD    = 2
local SKILL_AXE      = 3
local SKILL_DISTANCE = 4
local SKILL_SHIELD   = 5
local SKILL_FISHING  = 6

local skillNames = {
    [SKILL_FIST]     = "Fist",
    [SKILL_AXE]      = "Axe",
    [SKILL_SWORD]    = "Sword",
    [SKILL_CLUB]     = "Club",
    [SKILL_DISTANCE] = "Distance",
    [SKILL_SHIELD]   = "Shielding",
    [SKILL_FISHING]  = "Fishing"
}

TooltipLib = {}

function TooltipLib.formatItemType(slotPosition, weaponType)
    if weaponType ~= WEAPON_SHIELD then
        local sp = slotPosition - SLOTP_LEFT - SLOTP_RIGHT

        if sp == SLOTP_TWO_HAND and weaponType == WEAPON_SWORD then
            return "Two-Handed Sword"
        elseif sp == SLOTP_TWO_HAND and weaponType == WEAPON_CLUB then
            return "Two-Handed Club"
        elseif sp == SLOTP_TWO_HAND and weaponType == WEAPON_AXE then
            return "Two-Handed Axe"
        elseif weaponType == WEAPON_SWORD then
            return "Sword"
        elseif weaponType == WEAPON_CLUB then
            return "Club"
        elseif weaponType == WEAPON_AXE then
            return "Axe"
        elseif weaponType == WEAPON_DIST then
            return "Distance"
        elseif weaponType == WEAPON_WAND then
            return "Wand"
        elseif bit.band(slotPosition, SLOTP_HEAD) ~= 0 then
            return "Helmet"
        elseif bit.band(slotPosition, SLOTP_NECKLACE) ~= 0 then
            return "Necklace"
        elseif bit.band(slotPosition, SLOTP_ARMOR) ~= 0 then
            return "Armor"
        elseif bit.band(slotPosition, SLOTP_LEGS) ~= 0 then
            return "Legs"
        elseif bit.band(slotPosition, SLOTP_FEET) ~= 0 then
            return "Boots"
        elseif bit.band(slotPosition, SLOTP_RING) ~= 0 then
            return "Ring"
        elseif bit.band(slotPosition, SLOTP_AMMO) ~= 0 then
            return "Ammunition"
        else
            return "Common"
        end
    else
        return "Shield"
    end
    return "Common"
end

-- Helper: format stat with + sign
local function statStr(val, suffix)
    suffix = suffix or ""
    if val == 0 then return nil end
    if val > 0 then
        return "+" .. val .. suffix
    end
    return tostring(val) .. suffix
end

function TooltipLib.buildTooltip(uid, itemid, count)
    local info = getItemInfo(itemid)
    if not info then return nil end

    -- Get tier
    local tier = 0
    if uid and uid > 0 then
        tier = getItemAttribute(uid, "tier") or 0
    end
    local tierMult = 1.0 + tier * 0.10

    local cId = 0
    local it = ItemType(itemid)
    if it and it.getClientId then
        cId = it:getClientId()
    end
    if not cId or cId == 0 then
        cId = info.clientId or 0
    end

    local item_data = {
        uid = uid,
        clientId = cId,
        itemName = info.name or "",
        count = count or 0,
        weight = info.weight or 0,
        tier = tier,
        itemType = TooltipLib.formatItemType(info.slotPosition or 0, info.weaponType or 0)
    }

    -- Show tier in name
    if tier > 0 then
        item_data.itemName = info.name .. " [Tier " .. tier .. "]"
    end

    if info.description and info.description:len() > 0 then
        item_data.desc = info.description
    end

    if info.minRequiredLevel and info.minRequiredLevel >= 1 then
        item_data.reqLvl = info.minRequiredLevel
    end

    item_data.stackable = info.stackable or false

    -- ============================================================
    -- Build lookText: comma-separated stat lines (like C++ getDescription)
    -- Each comma = one line in the client tooltip
    -- ============================================================
    local lines = {}

    -- Attack / Defense / Armor
    local type = item_data.itemType
    -- Only show Armor for non-weapon items (C++ skips armor when weaponType != WEAPON_NONE)
    if info.armor and info.armor > 0 and (not info.attack or info.attack <= 0) then
        local arm = info.armor
        if tier > 0 then arm = math.floor(arm * tierMult + 0.5) end
        table.insert(lines, "Armor: " .. arm)
    end

    if info.attack and info.attack > 0 then
        local atk = info.attack
        if tier > 0 then atk = math.floor(atk * tierMult + 0.5) end
        local atkStr = "Atk:" .. atk
        if info.extraAttack and info.extraAttack > 0 then
            local exAtk = info.extraAttack
            if tier > 0 then exAtk = math.floor(exAtk * tierMult + 0.5) end
            atkStr = atkStr .. " " .. statStr(exAtk)
        end
        table.insert(lines, atkStr)
    end

    if info.defense and info.defense > 0 then
        local def = info.defense
        if tier > 0 then def = math.floor(def * tierMult + 0.5) end
        local defStr = "Def:" .. def
        if info.extraDefense and info.extraDefense > 0 then
            local exDef = info.extraDefense
            defStr = defStr .. " " .. statStr(exDef)
        end
        table.insert(lines, defStr)
    end

    if info.hitChance and info.hitChance > 0 then
        table.insert(lines, "Hit%: " .. statStr(info.hitChance, "%"))
    end

    if info.shootRange and info.shootRange > 1 then
        table.insert(lines, "Range: " .. info.shootRange)
    end    -- Critical Chance (check instance attr first, then ItemType field)
    local critChance = 0
    if uid and uid > 0 then
        critChance = getItemAttribute(uid, "criticalhitchance") or 0
    end
    if critChance == 0 then
        critChance = info.criticalHitChance or 0
    end
    if critChance > 0 then
        if tier > 0 then critChance = math.floor(critChance * tierMult + 0.5) end
        table.insert(lines, "Critical Chance:" .. critChance .. "%")
    end

    -- Life Steal (check instance attr first, then ItemType field)
    local lifeSteal = 0
    if uid and uid > 0 then
        lifeSteal = getItemAttribute(uid, "lifesteal") or 0
    end
    if lifeSteal == 0 then
        lifeSteal = info.lifeSteal or 0
    end
    if lifeSteal > 0 then
        if tier > 0 then lifeSteal = math.floor(lifeSteal * tierMult + 0.5) end
        table.insert(lines, "Life Steal: +" .. lifeSteal .. "%")
    end

    -- Abilities: skills, stats, speed, protection, regen
    local abs = info.abilities
    if abs then
        -- Skills (additive tier)
        for skillId, skillName in pairs(skillNames) do
            local val = abs.skills and abs.skills[skillId]
            if val and val >= 1 then
                table.insert(lines, skillName .. " " .. statStr(val + tier))
            end
        end

        -- Magic Level (additive tier like C++: val + tier)
        if abs.stats and abs.stats[STAT_MAGICLEVEL] and abs.stats[STAT_MAGICLEVEL] > 0 then
            table.insert(lines, "bend level " .. statStr(abs.stats[STAT_MAGICLEVEL] + tier))
        end

        -- Max Health (multiplicative tier like C++)
        if abs.stats and abs.stats[STAT_MAXHEALTH] and abs.stats[STAT_MAXHEALTH] > 0 then
            local hp = abs.stats[STAT_MAXHEALTH]
            if tier > 0 then hp = math.floor(hp * tierMult + 0.5) end
            table.insert(lines, "health " .. statStr(hp))
        end

        -- Max Mana (multiplicative tier like C++)
        if abs.stats and abs.stats[STAT_MAXMANA] and abs.stats[STAT_MAXMANA] > 0 then
            local mp = abs.stats[STAT_MAXMANA]
            if tier > 0 then mp = math.floor(mp * tierMult + 0.5) end
            table.insert(lines, "mana " .. statStr(mp))
        end

        -- Protection / Absorb (multiplicative tier)
        -- COMBAT_ALL=0 is not in the getItemInfo absorb table, so check if all individual values are equal
        if abs.absorb then
            -- Collect non-zero absorb values and apply tier
            local absorbVals = {}
            local firstVal = nil
            local allSame = true
            for _, ct in ipairs(combatTypes) do
                local val = abs.absorb[ct] or 0
                if val > 0 then
                    if tier > 0 then val = math.floor(val * tierMult + 0.5) end
                    absorbVals[ct] = val
                    if firstVal == nil then
                        firstVal = val
                    elseif val ~= firstVal then
                        allSame = false
                    end
                end
            end

            if firstVal and allSame then
                -- All protection values are the same -> show as "protection all"
                table.insert(lines, "protection all " .. statStr(firstVal, "%"))
            else
                -- Different protection values -> show individually
                local firstAbsorb = true
                for _, ct in ipairs(combatTypes) do
                    local val = absorbVals[ct]
                    if val and val > 0 then
                        local cname = combatNames[ct] or "Unknown"
                        if firstAbsorb then
                            table.insert(lines, "protection " .. cname .. " " .. statStr(val, "%"))
                            firstAbsorb = false
                        else
                            table.insert(lines, cname .. " " .. statStr(val, "%"))
                        end
                    end
                end
            end
        end

        -- Speed (additive tier)
        if abs.speed and abs.speed > 0 then
            table.insert(lines, "speed " .. statStr(abs.speed + tier))
        end

        -- Regen
        if abs.healthGain and abs.healthGain > 0 then
            local t = (abs.healthTicks and abs.healthTicks > 0) and math.floor(abs.healthTicks / 1000) or 3
            table.insert(lines, "life regeneration " .. abs.healthGain .. " HP/" .. t .. "s")
        end
        if abs.manaGain and abs.manaGain > 0 then
            local t = (abs.manaTicks and abs.manaTicks > 0) and math.floor(abs.manaTicks / 1000) or 3
            table.insert(lines, "mana regeneration " .. abs.manaGain .. " MP/" .. t .. "s")
        end

        -- Mana Shield
        if abs.manaShield then
            table.insert(lines, "mana shield")
        end

        -- Invisibility
        if abs.invisible then
            table.insert(lines, "invisibility")
        end
    end

    -- Unique bonus text from item description attribute (e.g. "[+20% Bend Damage]")
    if uid and uid > 0 then
        local desc = getItemAttribute(uid, "description") or ""
        -- Extract bracketed bonuses like [+20% Bend Damage]
        for bonus in desc:gmatch("%[([^%]]+)%]") do
            table.insert(lines, "[" .. bonus .. "]")
        end
        -- Also check for non-bracket bonus text after the base description
        local baseDesc = info.description or ""
        if desc ~= "" and desc ~= baseDesc then
            local cleanDesc = desc:gsub("%[([^%]]+)%]", ""):gsub(baseDesc, ""):gsub("^%s+", ""):gsub("%s+$", "")
            if cleanDesc ~= "" and cleanDesc ~= "." then
                -- Remove trailing period
                cleanDesc = cleanDesc:gsub("%.$", ""):gsub("^%.", "")
                if cleanDesc ~= "" then
                    table.insert(lines, cleanDesc)
                end
            end
        end
    end

    -- Join all lines with comma separator
    if #lines > 0 then
        item_data.lookText = table.concat(lines, ", ")
    end

    return item_data
end

local function getOpenContainerFallback(cid, containerIndex)
    local containers = {}
    local function collect(itemUid)
        if not itemUid or itemUid <= 0 or not isContainer(itemUid) then return end
        table.insert(containers, itemUid)
        local size = getContainerSize(itemUid)
        for i = 0, size - 1 do
            local sub = getContainerItem(itemUid, i)
            if sub and sub.uid > 0 and isContainer(sub.uid) then
                collect(sub.uid)
            end
        end
    end

    -- Priority 1: Backpack slot (slot 3)
    local bp = getPlayerSlotItem(cid, 3)
    if bp and bp.uid > 0 and isContainer(bp.uid) then
        collect(bp.uid)
    end
    -- Priority 2: Other slots
    for slot = 1, 10 do
        if slot ~= 3 then
            local item = getPlayerSlotItem(cid, slot)
            if item and item.uid > 0 and isContainer(item.uid) then
                collect(item.uid)
            end
        end
    end

    local targetUid = containers[containerIndex + 1]
    if targetUid then
        return {uid = targetUid}
    end
    if #containers > 0 then
        return {uid = containers[1]}
    end
    return nil
end

local function resolvePlayerContainer(cid, containerIndex)
    if getPlayerContainer then
        local ok, c = pcall(getPlayerContainer, cid, containerIndex)
        if ok and c and (type(c) == "table" and c.uid and c.uid > 0) then
            return c
        elseif ok and type(c) == "number" and c > 0 then
            return {uid = c}
        end
    end
    return getOpenContainerFallback(cid, containerIndex)
end

function TooltipLib.onTooltipRequest(cid, buffer)
    local status, data = pcall(function() return json.decode(buffer) end)
    if not status or not data then
        return
    end
    if type(data) == "table" then
        if #data == 4 and data[1] == -1 then
            -- Inventory slot hover: {-1, slotNumber, 0, 0}
            local slot = data[2]
            local thing = getPlayerSlotItem(cid, slot)
            if thing and thing.uid and thing.uid > 0 and thing.itemid and thing.itemid > 0 then
                local tooltipData = TooltipLib.buildTooltip(thing.uid, thing.itemid, thing.type)
                if tooltipData then
                    doSendPlayerExtendedOpcode(cid, CODE_TOOLTIPS, json.encode({action = "new", data = tooltipData}))
                end
            end
        elseif #data == 2 and data[1] == -1 then
            -- Inventory slot hover: {-1, slotNumber}
            local slot = data[2]
            local thing = getPlayerSlotItem(cid, slot)
            if thing and thing.uid and thing.uid > 0 and thing.itemid and thing.itemid > 0 then
                local tooltipData = TooltipLib.buildTooltip(thing.uid, thing.itemid, thing.type)
                if tooltipData then
                    doSendPlayerExtendedOpcode(cid, CODE_TOOLTIPS, json.encode({action = "new", data = tooltipData}))
                end
            end
        elseif #data == 4 and data[1] == 65535 then
            -- Container item hover: {65535, containerIndex + 64, slotIndex, 0}
            local containerIndex = data[2] - 64
            local slotIndex = data[3]
            local container = resolvePlayerContainer(cid, containerIndex)
            if container then
                local contUid = container.uid or container
                local thing = getContainerItem(contUid, slotIndex)
                if thing and thing.uid and thing.uid > 0 and thing.itemid and thing.itemid > 0 then
                    local tooltipData = TooltipLib.buildTooltip(thing.uid, thing.itemid, thing.type)
                    if tooltipData then
                        doSendPlayerExtendedOpcode(cid, CODE_TOOLTIPS, json.encode({action = "new", data = tooltipData}))
                    end
                end
            end
        elseif #data == 4 then
            -- Position hover: {x, y, z, stackpos}
            local pos = {x = data[1], y = data[2], z = data[3], stackpos = data[4]}
            local thing = getThingFromPosition(pos)
            if thing and thing.uid and thing.uid > 0 and thing.itemid and thing.itemid > 0 then
                local tooltipData = TooltipLib.buildTooltip(thing.uid, thing.itemid, thing.type)
                if tooltipData then
                    doSendPlayerExtendedOpcode(cid, CODE_TOOLTIPS, json.encode({action = "new", data = tooltipData}))
                end
            end
        elseif #data == 1 then
            -- UID hover: {uid}
            local realUid = data[1]
            local thing = getThing(realUid)
            if thing and thing.itemid and thing.itemid > 0 then
                local tooltipData = TooltipLib.buildTooltip(thing.uid or realUid, thing.itemid, thing.type)
                if tooltipData then
                    doSendPlayerExtendedOpcode(cid, CODE_TOOLTIPS, json.encode({action = "new", data = tooltipData}))
                end
            end
        end
    end
end
