-- ============================================================================
-- MOMO POUCH — protecao contra drop na morte
-- ----------------------------------------------------------------------------
-- O slot 12 (SLOT_MOMO) e excluido do dropLoot na source — o Momo Pouch
-- equipado JAMAIS e dropado. Este script e a rede de seguranca: se o player
-- estiver carregando um Momo Pouch solto no inventario (slots 1-10 /
-- mochilas), ele e movido para o slot 12 (ou deposito) antes do dropLoot rodar.
-- ============================================================================

function onDeath(cid, corpse, deathList)
	if isPlayer(cid) then
		momoMoveToDepot(cid)
	end
	return true
end
