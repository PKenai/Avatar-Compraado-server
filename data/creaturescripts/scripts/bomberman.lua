dofile(getDataDir().."lib/bomberman.lua")

function onLogin(cid)
	Bomberman.handleLogin(cid)
	return true
end

function onLogout(cid, forceLogout)
	Bomberman.handleLogout(cid)
	return true
end

function onDeath(cid, corpse, deathList)
	if isPlayer(cid) then
		Bomberman.handleDeath(cid)
	end
	return true
end

function onExtendedOpcode(cid, opcode, buffer)
	Bomberman.handleOpcode(cid, opcode, buffer)
	return true
end
