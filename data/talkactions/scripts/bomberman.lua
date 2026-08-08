dofile(getDataDir().."lib/bomberman.lua")

function onSay(cid, words, param, channel)
	if not isPlayer(cid) then
		return false
	end

	if words == "!joinbombermanevent" then
		Bomberman.joinQueue(cid)
	elseif words == "!leavebombermanevent" then
		Bomberman.leaveQueue(cid)
	elseif words == "!bomb" then
		Bomberman.dropBomb(cid)
	end

	return false
end
