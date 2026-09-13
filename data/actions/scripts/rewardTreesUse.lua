-- ============================================================================
--  Arvore de recompensa: ao dar USE no tronco brilhante o player recebe o
--  premio e o tronco some. A arvore original volta quando ninguem estiver no
--  raio configurado (ver data/lib/rewardTreesLib.lua).
-- ============================================================================

function onUse(cid, item, fromPosition, itemEx, toPosition)
	if not rewardTrees then
		return false
	end

	-- so reage aos troncos do sistema (a action esta registrada para eles)
	if not rewardTrees.isRewardTrunk(item.itemid) then
		return false
	end

	return rewardTrees.use(cid, item, fromPosition)
end
