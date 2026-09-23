--[[
 * spellPowerHotReload.lua -- recarrega as magias quando o `atk` muda no disco
 *
 * Registrado em data/globalevents/globalevents.xml (interval 500).
 *
 * Serve para tools/spell_power_tool.py, mas nao depende dele: qualquer gravacao
 * em data/lib/201-spellsExausted.lua (inclusive salvar no editor) dispara o
 * reload.
 *
 * Por que isso funciona (conferido no codigo do motor, sources/spells.cpp):
 *   /reload spells -> Spells::reload() -> clear() -> m_interface.reInitState()
 *   -> closeState() + initState(), e o initState e' quem le' data/lib/** de
 *   novo (LuaInterface::loadDirectory). Depois o loadFromXml() re-executa os
 *   scripts de magia, que leem o `atk` atualizado da tabela.
 *
 * ATENCAO (efeito colateral real): recarregar a interface de magias apaga o que
 * os scripts guardam em memoria, porque cada interface tem o seu proprio Lua
 * state (sources/spells.h: `LuaInterface m_interface`). Isso inclui as tabelas
 * MyLocal.* (os tornados do air stormcall, canais como o water heal, bufs em
 * andamento). Nao ajuste magia com gente canalizando/PvP.
 *
 * O motor tambem recarrega os monstros junto com as magias
 * (Game::reloadInfo -> g_monsters.reload()), que re-le data/monster/**. E' o
 * comportamento do proprio /reload spells, mas custa alguns segundos.
]]

-- getDataDir()/getLogsDir() ja' vem com o separador no fim, mas normalizo por
-- seguranca: se faltar, o nome do arquivo sairia colado na pasta.
local function withSlash(path)
	if path == "" or path:sub(-1) == "/" or path:sub(-1) == "\\" then
		return path
	end

	return path .. "/"
end

local FILE = withSlash(getDataDir()) .. "lib/201-spellsExausted.lua"
local LOG  = withSlash(getLogsDir()) .. "spellPowerReload.log"

local lastContent = nil
local candidate   = nil
local hits        = 0
local reloads     = 0

local function readAll(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end

	local content = f:read("*a")
	f:close()
	return content
end

local function logReload()
	local f = io.open(LOG, "a")
	if f then
		f:write(os.date("%Y-%m-%d %H:%M:%S") .. "  reload #" .. reloads .. " disparado\n")
		f:close()
	end
end

function onThink(interval, lastExecution)
	local content = readAll(FILE)
	if not content then
		return true
	end

	-- primeiro tique: so' guarda a referencia, nao recarrega no boot
	if lastContent == nil then
		lastContent = content
		return true
	end

	if content == lastContent then
		candidate, hits = nil, 0
		return true
	end

	-- exige dois tiques com o MESMO conteudo novo: se o arquivo estiver sendo
	-- gravado em pedacos (editor), nao recarrega no meio da gravacao
	if content == candidate then
		hits = hits + 1
	else
		candidate, hits = content, 1
	end

	if hits >= 2 then
		lastContent, candidate, hits = content, nil, 0
		reloads = reloads + 1

		print("[spellPower] 201-spellsExausted.lua mudou - recarregando as magias (reload #" .. reloads .. ")")
		doReloadInfo(RELOAD_SPELLS, 0)
		logReload()
	end

	return true
end
