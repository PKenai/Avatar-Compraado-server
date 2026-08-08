dofile(getDataDir().."lib/bomberman.lua")

function onStepIn(cid, item, position, fromPosition)
	if not isPlayer(cid) then
		return true
	end

	local id = item and item.itemid or 0

	if id == Bomberman.CONFIG.BOMB_ID then
		-- jogador andou em cima de uma bomba (power-up de chute)
		Bomberman.onStepOnBomb(cid, position, fromPosition)
	elseif id >= Bomberman.CONFIG.FIRE_PU and id <= Bomberman.CONFIG.SLOW_PU then
		-- power-up: fogo (18373), velocidade (18374), bombas (18375), chute (18376), lento (18377)
		Bomberman.onStepOnPowerUp(cid, item)
	end

	return true
end
