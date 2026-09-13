-- ============================================================================
--  Arvores de recompensa: tick (devolve as arvores usadas quando ninguem
--  esta por perto e repoe o estoque de troncos com o tempo)
-- ============================================================================

function onThink(interval)
	if rewardTrees then
		rewardTrees.tick()
	end
	return true
end
