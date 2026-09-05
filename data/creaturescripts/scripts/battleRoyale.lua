dofile(getDataDir().."lib/battleRoyale.lua")

function onLogin(cid)
	BattleRoyale.handleLogin(cid)
	return true
end

function onLogout(cid, forceLogout)
	BattleRoyale.handleLogout(cid)
	return true
end

function onPrepareDeath(cid, deathList)
	if not isPlayer(cid) then
		return true
	end
	if BattleRoyale.handleDeath(cid, deathList) then
		return false -- cancela a morte: eliminacao sem morte real
	end
	return true
end