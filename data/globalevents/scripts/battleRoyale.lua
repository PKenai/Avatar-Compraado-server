dofile(getDataDir().."lib/battleRoyale.lua")

function onStartup()
	BattleRoyale.init()
	return true
end

function onThink(interval)
	BattleRoyale.watchdog()
	return true
end