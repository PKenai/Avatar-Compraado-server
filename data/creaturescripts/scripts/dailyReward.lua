-- ============================================================================
-- Daily Reward - Opcode Handler
-- ----------------------------------------------------------------------------
-- Recebe Extended Opcode 170 do client e despacha para dailyRewardLib.
-- Registrado em creaturescripts.xml como type="extendedopcode".
-- ============================================================================

dofile(getDataDir() .. "lib/dailyRewardLib.lua")

function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= DAILY_REWARD_OPCODE then
        return true
    end

    dailyRewardHandleOpcode(cid, opcode, buffer)
    return true
end
