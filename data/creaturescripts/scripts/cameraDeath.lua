-- ============================================================================
-- CAMERA — protecao contra drop na morte
-- ----------------------------------------------------------------------------
-- O slot 11 (SLOT_CAMERA) e excluido do dropLoot na source — a camera
-- equipada JAMAIS e dropada. Este script e a rede de seguranca: se o player
-- estiver carregando uma camera solta no inventario (slots 1-10 / mochilas),
-- ela e movida para o slot 11 (ou deposito) antes do dropLoot rodar.
-- ============================================================================

function onDeath(cid, corpse, deathList)
	if isPlayer(cid) then
		cameraOff(cid) -- morreu: encerra a transmissao e a camera mostra OFF
		cameraMoveToDepot(cid)
	end
	return true
end
