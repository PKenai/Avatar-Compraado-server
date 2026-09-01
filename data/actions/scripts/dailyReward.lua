-- ============================================================================
-- Coletor de Recompensas (item 19009)
-- ----------------------------------------------------------------------------
-- Ao usar o item, abre a janela de recompensas diarias.
-- A logica real fica em dailyRewardLib.lua, aqui so dispara o opcode.
-- ============================================================================

dofile(getDataDir() .. "lib/dailyRewardLib.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    registerCreatureEvent(cid, "DailyRewardOpcode")
    dailyRewardSendToClient(cid)
    return true
end
