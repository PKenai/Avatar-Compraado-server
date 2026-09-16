--[[
 * bossSystem.lua -- Manutencao periodica do sistema ALPHA
 *
 * Registrado em data/globalevents/globalevents.xml (interval 15000).
 * Faz tres coisas:
 *   - limpa da tabela de bosses ativos os que morreram / sumiram
 *   - remove bosses cujo dono deslogou (evita acumular monstro sem dono)
 *   - remove bosses que passaram do tempo maximo de vida
]]

dofile(getDataDir() .. "lib/bossSystem.lua")

function onThink(interval, lastExecution)
	-- primeira execucao (~15s depois do boot): valida monsters.xml/items.xml
	-- e imprime um resumo no console do servidor
	local loaded, err = pcall(BossSystem.ensureLoaded)
	if not loaded then
		print("[BossSystem] falha ao carregar: " .. tostring(err))
	end

	local ok, err = pcall(BossSystem.onThink, interval)
	if not ok then
		print("[BossSystem] erro no onThink: " .. tostring(err))
	end
	return true
end
