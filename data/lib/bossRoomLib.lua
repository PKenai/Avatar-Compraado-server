--[[
 * BossRoomLib - Shared functions and state for the Boss Room system
 * Loaded globally via data/lib/, accessible from all script types.
 *
 * Used by:
 *   data/actions/scripts/bossRoom.lua (lever action)
 *   data/creaturescripts/scripts/bossRoomPantano.lua (boss death event)
]]

-- ============================================================
-- Global state (persists across calls)
-- ============================================================
bossRoomState = bossRoomState or {
    active = false,
    bossId = nil,
    healTimerId = nil,
    tentacleTimerId = nil,
}

-- ============================================================
-- Constants
-- ============================================================
BOSS_ROOM_FROM = BOSS_ROOM_FROM or {x = 120, y = 1924, z = 7}
BOSS_ROOM_TO   = BOSS_ROOM_TO   or {x = 177, y = 1968, z = 7}
ROOM_CENTER    = ROOM_CENTER    or {x = 149, y = 1946, z = 7}
ROOM_RANGEX    = ROOM_RANGEX    or 30
ROOM_RANGEY    = ROOM_RANGEY    or 23

BOSS_NAME      = BOSS_NAME      or "Monstro do pantano"
BOSS_SPAWN     = BOSS_SPAWN     or {x = 147, y = 1940, z = 7}

TENTACLE_NAME     = TENTACLE_NAME     or "Tentaculos do pantano"
TENTACLE_MIN_DIST = TENTACLE_MIN_DIST or 3

LEVER_ON  = LEVER_ON  or 1946
LEVER_OFF = LEVER_OFF or 1945

ENTRY_TILES = ENTRY_TILES or {
    {x = 807, y = 517, z = 5},
    {x = 807, y = 518, z = 5},
    {x = 807, y = 519, z = 5},
    {x = 807, y = 520, z = 5},
    {x = 807, y = 521, z = 5},
}

EXIT_POS = EXIT_POS or {x = 799, y = 519, z = 6}

-- ============================================================
-- Shared functions
-- ============================================================

-- Remove all tentacles from the boss room
function bossRoomRemoveTentacles()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) and getCreatureName(specs[i]) == TENTACLE_NAME then
                doRemoveCreature(specs[i])
            end
        end
    end
end

-- Stop all timers and clean up state
function bossRoomStopTimers()
    bossRoomState.active = false
    if bossRoomState.healTimerId then
        stopEvent(bossRoomState.healTimerId)
        bossRoomState.healTimerId = nil
    end
    if bossRoomState.tentacleTimerId then
        stopEvent(bossRoomState.tentacleTimerId)
        bossRoomState.tentacleTimerId = nil
    end
    bossRoomRemoveTentacles()
    bossRoomState.bossId = nil
end
