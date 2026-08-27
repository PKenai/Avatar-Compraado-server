dofile(getDataDir() .. "lib/custom/hunger_icon_lib.lua")
dofile(getDataDir() .. "lib/custom/nomana_icon_lib.lua")

-- Creature event: Hunger + NoMana Icons
-- Fires every ~5 seconds for each registered player.
-- Checks food status and mana %, broadcasts opcodes when state changes.
function onThink(cid, interval)
    if not isPlayer(cid) then return true end
    HUNGER_ICON.checkAndUpdate(cid)
    NOMANA_ICON.checkAndUpdate(cid)
    return true
end
