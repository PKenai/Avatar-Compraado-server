dofile(getDataDir().."lib/battleRoyale.lua")

function onStepIn(cid, item, position, fromPosition)
	if isPlayer(cid) then
		BattleRoyale.onPortalStep(cid)
	end
	return true
end