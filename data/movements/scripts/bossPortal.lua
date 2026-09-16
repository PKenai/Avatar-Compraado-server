--[[
 * bossPortal.lua -- Tile de invocacao dos bosses ALPHA
 *
 * Registrado em data/movements/movements.xml para:
 *   itemID   19333 / 19334   (as duas versoes do tile; mesma funcao)
 *   actionID 50030           (alternativa: basta colocar o actionID em qualquer item)
 *
 * O script NAO precisa saber QUAL boss spawnar: ele procura as criaturas
 * ofensivas proximas e cruza com as liberacoes do jogador (task diaria
 * concluida). Assim basta posicionar o item no mapa na area da criatura.
]]

dofile(getDataDir() .. "lib/bossSystem.lua")

function onStepIn(cid, item, position, lastPosition, fromPosition, toPosition, actor)
	if not isPlayer(cid) then
		return true
	end

	BossSystem.onStepPortal(cid, position)
	return true
end
