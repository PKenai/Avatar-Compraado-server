-- ============================================================================
-- MOMO POUCH — coleta automatica sem abrir o corpo
-- ----------------------------------------------------------------------------
-- Evento de KILL registrado no player (login). Quando o player (ou o summon
-- dele) mata um monstro, agenda a coleta: o loot cai no corpo e, logo depois,
-- os itens vao direto pro Momo Pouch (respeitando frag/party e a lista
-- personalizada). Se o pouch estiver desativado ou o player nao for elegivel,
-- o loot fica no corpo normalmente.
-- ============================================================================

function onKill(cid, target, damage, flags)
	if isPlayer(cid) then
		momoScheduleAutoLoot(cid, target)
	end
	return true
end
