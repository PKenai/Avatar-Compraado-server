-- ============================================================================
--  Arvores de recompensa: sorteio inicial (roda uma vez no boot do server)
-- ============================================================================

function onStartup()
	if rewardTrees then
		rewardTrees.seed()
	end
	return true
end
