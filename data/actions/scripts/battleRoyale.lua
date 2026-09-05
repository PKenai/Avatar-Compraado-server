dofile(getDataDir().."lib/battleRoyale.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
	if isPlayer(cid) then
		BattleRoyale.onClaimStaff(cid)
	end
	return true
end