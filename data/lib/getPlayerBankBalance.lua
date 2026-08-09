-- ============================================================================
-- getPlayerBankBalance(cid)
-- ----------------------------------------------------------------------------
-- Retorna o saldo em gold que o player tem no banco.
-- Usada pelo game_shop (modulo do client) para exibir o saldo bancario.
--
-- Retorna 0 se:
--   * o player nao for valido
--   * o sistema de banco estiver desativado no config.lua (bankSystem = false)
-- ============================================================================

function getPlayerBankBalance(cid)
  if not isPlayer(cid) then
    return 0
  end

  if not getBooleanFromString(getConfigValue('bankSystem')) then
    return 0
  end

  local balance = getPlayerBalance(cid)
  return tonumber(balance) or 0
end
