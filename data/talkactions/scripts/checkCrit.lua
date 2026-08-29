function onSay(cid, words, param, channel)
    local critChance = getPlayerCriticalHitChance and getPlayerCriticalHitChance(cid) or 0
    local msg = "=== CRITICAL STATS ===\nTotal Critical Chance: " .. critChance .. "%\n\nEquipped Items:"
    
    local slotNames = {
        [CONST_SLOT_HEAD] = "Head",
        [CONST_SLOT_NECKLACE] = "Necklace",
        [CONST_SLOT_ARMOR] = "Armor",
        [CONST_SLOT_RIGHT] = "Right Hand",
        [CONST_SLOT_LEFT] = "Left Hand",
        [CONST_SLOT_LEGS] = "Legs",
        [CONST_SLOT_FEET] = "Feet",
        [CONST_SLOT_RING] = "Ring",
        [CONST_SLOT_AMMO] = "Ammo"
    }
    
    for slot, name in pairs(slotNames) do
        local item = getPlayerSlotItem(cid, slot)
        if item and item.uid > 0 then
            local itemName = getItemNameById(item.itemid)
            local itemCrit = getItemInfo(item.itemid).criticalHitChance or 0
            local tier = tonumber(getItemAttribute(item.uid, "tier")) or 0
            if tier > 0 and itemCrit > 0 then
                itemCrit = math.floor(itemCrit * (1 + tier * 0.1) + 0.5)
            end
            if itemCrit > 0 or tier > 0 then
                msg = msg .. "\n- " .. name .. ": " .. itemName .. " [Tier " .. tier .. "] (Crit: +" .. itemCrit .. "%)"
            end
        end
    end
    
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, msg)
    return true
end
