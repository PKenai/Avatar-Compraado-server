-- ============================================================================
-- BOMBERMAN EVENT -- TFS API ANTIGA (0.4-style, protocolo 8.60)
-- ----------------------------------------------------------------------------
-- Sistema de fila (via !joinbombermanevent), 6 arenas, 1v1.
-- Adaptado do sistema original (TFS novo) para este fork do servidor.
--
-- IMPORTANTE (arquitetura deste fork):
--   Cada sistema de eventos (talkactions, creaturescripts, movements,
--   globalevents) tem o SEU proprio estado Lua. Por isso, NENHUM estado
--   compartilhado pode viver em tabelas Lua "globais" (elas nao sao
--   compartilhadas entre os sistemas).
--
--   O estado compartilhado vive em:
--     * Storages globais  -> getStorage()/doSetStorage() (static StorageMap,
--                            compartilhada entre TODOS os estados Lua).
--       Fila, ocupacao das arenas, bombas ativas, referencia dos blocos.
--     * Player storages   -> getPlayerStorageValue()/setPlayerStorageValue()
--                            (compartilhados entre os estados, persistidos no DB).
--       Estado do jogador na partida, power-ups, outfit original.
--     * O proprio mapa    -> bombas/power-ups/blocos sao itens do mundo,
--                            visiveis por todos os estados.
--
--   Timers (addEvent) ficam no estado que os criou, mas TODAS as funcoes de
--   callback releem o estado das storages (com guardas por planted/start time)
--   e sao seguras para rodar de qualquer estado.
--
-- ARQUIVOS DO SISTEMA:
--   data/lib/bomberman.lua                      <- este arquivo (nucleo)
--   data/globalevents/scripts/bomberman.lua     -> onStartup()
--   data/talkactions/scripts/bomberman.lua      -> !joinbombermanevent / !leavebombermanevent / !bomb
--   data/movements/scripts/bomberman.lua        -> power-ups 18373-18377 + chute 18372
--   data/creaturescripts/scripts/bomberman.lua  -> onLogin / onLogout / onDeath / onExtendedOpcode
-- ============================================================================

if not Bomberman then
	Bomberman = {}
end

Bomberman.CONFIG = {
	-- IDs dos itens do Bomberman
	BOMB_ID = 18372,      -- bomba
	WALL_ID = 18370,      -- bloco indestrutivel
	BLOCK_ID = 18371,     -- bloco destrutivel
	FIRE_PU = 18373,      -- power-up: fogo maior
	SPEED_PU = 18374,     -- power-up: mais velocidade
	BOMBS_PU = 18375,     -- power-up: mais bombas
	KICK_PU = 18376,      -- power-up: chutar a bomba
	SLOW_PU = 18377,      -- power-up: deixar o player lento

	EXPLOSION_EFFECT = 16, -- efeito visual da explosao

	-- outfits da partida: um jogador fica com um, o outro com o outro (nunca iguais na arena)
	MATCH_OUTFITS = {1214, 1215},

	FUSE_MS = 2000,                 -- tempo da bomba ate explodir (ms)
	MATCH_MS = 10 * 60 * 1000,      -- 10 minutos -> empate e libera a arena

	MAX_BOMB_SIZE = 10,  -- maximo de sqm do raio do fogo
	MAX_BOMBS = 10,      -- maximo de bombas simultaneas
	MAX_SPEED = 10,      -- maximo de pontos de velocidade (positivo ou negativo)
	SPEED_PER_POINT = 60,-- velocidade ganha/perdida por ponto

	POWERUP_CHANCE = 25, -- chance (%) de dropar power-up ao destruir bloco

	TEMPLE = {x = 505, y = 342, z = 7},

	-- opcodes usados com o client (OTClient)
	OPCODE_SHOW = 160,   -- servidor -> client: abre/fecha a janelinha BOMB
	OPCODE_CLICK = 161,  -- client -> servidor: botao BOMB foi clicado
	MUSIC_OPCODE = 162,  -- servidor -> client: "play" / "stop" da musica do evento

	-- area da musica do evento (estilo shader): toca enquanto o jogador estiver aqui
	MUSIC_ZONE_MIN = {x = 1459, y = 7,   z = 7},
	MUSIC_ZONE_MAX = {x = 1604, y = 170, z = 7},
	MUSIC_CHECK_MS = 1000,

	-- chaves dos storages globais (compartilhados entre TODOS os estados Lua)
	GS = {
		queue = "bmQueue",             -- "m<guid1>;<guid2>;..."  (fila, FIFO)
		arena = "bmArena",             -- "bmArena<1..6>" = "m<g1>;<g2>;<start>" ou apagado (livre)
		blocks = "bmBlock",            -- "bmBlockCount<arena>" (n) e "bmBlock<arena>_<n>" (pos codificada)
		bombs = "bmBombs",             -- "b<x;y;z;owner;range;planted>|<...>"
		musicLoop = "bmMusicLoop",     -- guarda do loop de musica (1x por boot)
	},

	-- chaves dos player storages (compartilhados entre os estados, DB)
	STORAGE = {
		inMatch = "bombermanInMatch",      -- 1 = em partida
		arena = "bombermanArena",          -- indice da arena (1..6)
		partner = "bombermanPartner",      -- GUID do adversario
		matchStart = "bombermanMatchStart",-- os.time() do inicio da partida
		savedSpeed = "bombermanSavedSpeed",-- delta-de-velocidade que o player tinha antes da partida
		bombSize = "bombermanBombSize",    -- alcance do fogo (sqm)
		maxBombs = "bombermanMaxBombs",    -- maximo de bombas simultaneas
		activeBombs = "bombermanActiveBombs", -- bombas ativas agora
		speed = "bombermanSpeed",          -- pontos de velocidade (1 = normal)
		kick = "bombermanKick",            -- 1 = pode chutar bomba
		inQueue = "bombermanInQueue",      -- 1 = na fila
		outfitType = "bombermanOutfitType",
		outfitEx = "bombermanOutfitEx",
		outfitHead = "bombermanOutfitHead",
		outfitBody = "bombermanOutfitBody",
		outfitLegs = "bombermanOutfitLegs",
		outfitFeet = "bombermanOutfitFeet",
		outfitAddons = "bombermanOutfitAddons",
		outfitMount = "bombermanOutfitMount"
	}
}

-- Arenas: o par de jogadores SEMPRE cai na mesma arena.
-- spawn1 = extremidade minima, spawn2 = extremidade maxima.
Bomberman.ARENAS = {
	[1] = {min = {x=1479, y=27,  z=7}, max = {x=1506, y=51,  z=7}, spawn1 = {x=1479, y=27,  z=7}, spawn2 = {x=1506, y=51,  z=7}},
	[2] = {min = {x=1548, y=28,  z=7}, max = {x=1575, y=52,  z=7}, spawn1 = {x=1548, y=28,  z=7}, spawn2 = {x=1575, y=52,  z=7}},
	[3] = {min = {x=1481, y=82,  z=7}, max = {x=1508, y=106, z=7}, spawn1 = {x=1481, y=82,  z=7}, spawn2 = {x=1508, y=106, z=7}},
	[4] = {min = {x=1547, y=83,  z=7}, max = {x=1574, y=107, z=7}, spawn1 = {x=1547, y=83,  z=7}, spawn2 = {x=1574, y=107, z=7}},
	[5] = {min = {x=1482, y=137, z=7}, max = {x=1509, y=161, z=7}, spawn1 = {x=1482, y=137, z=7}, spawn2 = {x=1509, y=161, z=7}},
	[6] = {min = {x=1548, y=138, z=7}, max = {x=1575, y=162, z=7}, spawn1 = {x=1548, y=138, z=7}, spawn2 = {x=1575, y=162, z=7}},
}

local DIRS = { {0, -1}, {0, 1}, {-1, 0}, {1, 0} }

local function cfg(k)
	return Bomberman.CONFIG[k]
end

local function gs(k)
	return Bomberman.CONFIG.GS[k]
end

local function st(k)
	return Bomberman.CONFIG.STORAGE[k]
end

-- ============================================================================
-- HELPERS DE STORAGE
-- ============================================================================

-- getStorage retorna -1 quando a chave nao existe.
-- Normaliza: retorna nil para ausente/"" e o valor (number ou string) caso exista.
local function gget(key)
	local v = getStorage(key)
	if v == nil or v == -1 or v == "" then
		return nil
	end
	return v
end

local function gset(key, value)
	doSetStorage(key, value)
end

local function gclear(key)
	doSetStorage(key, nil)
end

-- getPlayerStorageValue retorna -1 para chave nao setada.
local function pget(cid, key)
	local v = getPlayerStorageValue(cid, key)
	if v == nil or v == -1 then
		return nil
	end
	return v
end

local function pset(cid, key, value)
	setPlayerStorageValue(cid, key, value)
end

local function split(s, sep)
	local out = {}
	if type(s) ~= "string" or s == "" then
		return out
	end
	for part in string.gmatch(s, "[^" .. sep .. "]+") do
		out[#out + 1] = part
	end
	return out
end

local function encodePos(x, y, z)
	return x * 10000 + y * 10 + z
end

local function decodePos(v)
	return {x = math.floor(v / 10000), y = math.floor((v % 10000) / 10), z = v % 10}
end

-- ============================================================================
-- HELPERS DE GEOMETRIA
-- ============================================================================

function Bomberman.samePos(a, b)
	return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

function Bomberman.insideArena(arenaIdx, pos)
	local arena = Bomberman.ARENAS[arenaIdx]
	if not arena or not pos then
		return false
	end
	return pos.x >= arena.min.x and pos.x <= arena.max.x
		and pos.y >= arena.min.y and pos.y <= arena.max.y
		and pos.z == arena.min.z
end

function Bomberman.findArenaByPos(pos)
	for i = 1, 6 do
		if Bomberman.insideArena(i, pos) then
			return i
		end
	end
	return nil
end

-- ============================================================================
-- INICIALIZACAO (globalevent startup -> roda no estado do GLOBALEVENT)
-- ============================================================================

function Bomberman.init()
	-- Os storages globais nascem vazios no boot (StorageMap estatica).
	-- Escaneia os blocos destrutiveis das arenas (referencia p/ reconstrucao)
	-- com um pequeno atraso: garante que o mapa ja esta 100% carregado.
	addEvent(Bomberman.scanBlocks, 3000)

	-- loop de musica (estado do globalevent; apenas ele usa essa tabela)
	Bomberman.musicOn = Bomberman.musicOn or {}
	Bomberman.startMusicLoop()
end

function Bomberman.scanBlocks()
	Bomberman.blockScanAttempts = (Bomberman.blockScanAttempts or 0) + 1
	local total = 0
	local ok = pcall(function()
		for arenaIdx = 1, 6 do
			local arena = Bomberman.ARENAS[arenaIdx]
			local count = 0
			for x = arena.min.x, arena.max.x do
				for y = arena.min.y, arena.max.y do
					local it = getTileItemById({x = x, y = y, z = arena.min.z}, cfg("BLOCK_ID"))
					if it and it.uid and it.uid > 0 then
						count = count + 1
						gset(gs("blocks") .. arenaIdx .. "_" .. count, encodePos(x, y, arena.min.z))
					end
				end
			end
			gset(gs("blocks") .. "Count" .. arenaIdx, count)
			total = total + count
		end
	end)
	if not ok then
		total = 0 -- scan falhou: forca o retry silencioso
	end
	if total == 0 and Bomberman.blockScanAttempts < 5 then
		addEvent(Bomberman.scanBlocks, 5000)
	end
end

-- Reconstrói os blocos destruidos de uma arena (fim de partida).
function Bomberman.rebuildBlocks(arenaIdx)
	local count = gget(gs("blocks") .. "Count" .. arenaIdx)
	if not count or count < 1 then
		return
	end
	for n = 1, count do
		local v = gget(gs("blocks") .. arenaIdx .. "_" .. n)
		if type(v) == "number" and v > 0 then
			local pos = decodePos(v)
			local it = getTileItemById(pos, cfg("BLOCK_ID"))
			if (not it or not it.uid or it.uid == 0) then
				doCreateItem(cfg("BLOCK_ID"), 1, pos)
			end
		end
	end
end

-- Remove bombas e power-ups que sobraram na arena (fim de partida).
function Bomberman.clearArenaItems(arenaIdx)
	local arena = Bomberman.ARENAS[arenaIdx]
	local ids = {cfg("BOMB_ID"), cfg("FIRE_PU"), cfg("SPEED_PU"), cfg("BOMBS_PU"), cfg("KICK_PU"), cfg("SLOW_PU")}
	for x = arena.min.x, arena.max.x do
		for y = arena.min.y, arena.max.y do
			local p = {x = x, y = y, z = arena.min.z}
			for _, id in ipairs(ids) do
				local it = getTileItemById(p, id)
				if it and it.uid and it.uid > 0 then
					doRemoveItem(it.uid)
				end
			end
		end
	end
end

-- ============================================================================
-- MUSICA DA AREA DO EVENTO (estilo shader: entra na area -> toca, sai -> para)
-- Roda APENAS no estado do globalevent (iniciada pelo init).
-- ============================================================================

function Bomberman.startMusicLoop()
	-- guarda em storage global (compartilhado entre estados): sobrevive a
	-- re-dofile da lib (ex.: /reload) e impede loop duplicado.
	if gget(gs("musicLoop")) then
		return
	end
	gset(gs("musicLoop"), os.time())
	addEvent(Bomberman.checkMusicZone, cfg("MUSIC_CHECK_MS"))
end

function Bomberman.checkMusicZone()
	pcall(function()
		local minP = cfg("MUSIC_ZONE_MIN")
		local maxP = cfg("MUSIC_ZONE_MAX")
		local inside = {}

		for _, cid in ipairs(getPlayersOnline()) do
			local pos = getThingPosition(cid)
			if pos.x >= minP.x and pos.x <= maxP.x
				and pos.y >= minP.y and pos.y <= maxP.y
				and pos.z == minP.z then
				inside[cid] = true
				if not Bomberman.musicOn[cid] then
					Bomberman.musicOn[cid] = true
					doSendPlayerExtendedOpcode(cid, cfg("MUSIC_OPCODE"), "play")
				end
			end
		end

		-- para a musica de quem saiu da area / deslogou
		for cid in pairs(Bomberman.musicOn) do
			if not inside[cid] then
				Bomberman.musicOn[cid] = nil
				if isCreature(cid) then
					doSendPlayerExtendedOpcode(cid, cfg("MUSIC_OPCODE"), "stop")
				end
			end
		end

		-- rede de seguranca do pareamento: se houver fila e arena livre, pareia.
		Bomberman.tryStartNextMatch()
	end)
	addEvent(Bomberman.checkMusicZone, cfg("MUSIC_CHECK_MS"))
end

-- ============================================================================
-- FILA (storage global "bmQueue")
-- ============================================================================

function Bomberman.readQueue()
	local out = {}
	local data = gget(gs("queue"))
	if not data then
		return out
	end
	local s = tostring(data)
	if s:sub(1, 1) == "m" then
		s = s:sub(2)
	end
	if s == "" then
		return out
	end
	for part in string.gmatch(s, "[^;]+") do
		local g = tonumber(part)
		if g then
			out[#out + 1] = g
		end
	end
	return out
end

function Bomberman.writeQueue(list)
	if #list == 0 then
		gclear(gs("queue"))
		return
	end
	local parts = {}
	for _, g in ipairs(list) do
		parts[#parts + 1] = tostring(g)
	end
	gset(gs("queue"), "m" .. table.concat(parts, ";"))
end

function Bomberman.removeFromQueue(cid)
	local guid = getPlayerGUID(cid)
	local list = Bomberman.readQueue()
	local changed = false
	for i = #list, 1, -1 do
		if list[i] == guid then
			table.remove(list, i)
			changed = true
		end
	end
	if changed then
		Bomberman.writeQueue(list)
	end
	pset(cid, st("inQueue"), -1)
end

function Bomberman.joinQueue(cid)
	if not isPlayer(cid) then
		return false
	end
	if pget(cid, st("inMatch")) == 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já está em uma partida de Bomberman!")
		return false
	end
	if pget(cid, st("inQueue")) == 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já está na fila do Bomberman, aguardando um adversario...")
		return false
	end

	local guid = getPlayerGUID(cid)
	local list = Bomberman.readQueue()
	for _, g in ipairs(list) do
		if g == guid then
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já está na fila do Bomberman, aguardando um adversario...")
			return false
		end
	end

	table.insert(list, guid)
	Bomberman.writeQueue(list)
	pset(cid, st("inQueue"), 1)
	doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Você entrou na fila do Bomberman! Aguardando um adversario... (fila: " .. #list .. "/2)")

	Bomberman.tryStartNextMatch()
	return true
end

function Bomberman.leaveQueue(cid)
	if pget(cid, st("inQueue")) ~= 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você não está na fila do Bomberman.")
		return false
	end
	Bomberman.removeFromQueue(cid)
	doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você saiu da fila do Bomberman.")
	return true
end

function Bomberman.findFreeArena()
	for i = 1, 6 do
		if not gget(gs("arena") .. i) then
			return i
		end
	end
	return nil
end

-- Tenta parear 2 jogadores da fila. Chamado de QUALQUER estado:
--   * apos entrar/sair da fila (talkaction)
--   * apos liberar arena (endMatch)
--   * a cada 1s (rede de seguranca, do loop de musica no globalevent)
function Bomberman.tryStartNextMatch()
	local list = Bomberman.readQueue()

	-- remove da fila quem deslogou / ja esta em partida
	local clean = {}
	local changed = false
	for _, g in ipairs(list) do
		local cid = getPlayerByGUID(g)
		if cid and cid ~= 0 and isPlayer(cid) and pget(cid, st("inMatch")) ~= 1 then
			clean[#clean + 1] = g
		else
			changed = true
			if cid and cid ~= 0 then
				pset(cid, st("inQueue"), -1)
			end
		end
	end
	if changed then
		Bomberman.writeQueue(clean)
	end

	if #clean < 2 then
		return
	end

	local arenaIdx = Bomberman.findFreeArena()
	if not arenaIdx then
		return
	end

	local g1 = table.remove(clean, 1)
	local g2 = table.remove(clean, 1)
	Bomberman.writeQueue(clean)
	Bomberman.startMatch(arenaIdx, g1, g2)
end

-- ============================================================================
-- PARTIDA (storage global "bmArena<idx>" = "m<g1>;<g2>;<start>")
-- ============================================================================

function Bomberman.startMatch(arenaIdx, g1, g2)
	local c1 = getPlayerByGUID(g1)
	local c2 = getPlayerByGUID(g2)
	if not c1 or c1 == 0 or not c2 or c2 == 0 or not isCreature(c1) or not isCreature(c2) then
		-- alguem deslogou no meio do pareamento: devolve para a fila
		local list = Bomberman.readQueue()
		table.insert(list, 1, g1)
		if g2 ~= g1 then
			table.insert(list, 1, g2)
		end
		Bomberman.writeQueue(list)
		return
	end

	-- guarda dupla: arena deve estar livre
	local arenaKey = gs("arena") .. arenaIdx
	if gget(arenaKey) then
		local list = Bomberman.readQueue()
		table.insert(list, 1, g1)
		if g2 ~= g1 then
			table.insert(list, 1, g2)
		end
		Bomberman.writeQueue(list)
		return
	end

	local matchStart = os.time()
	gset(arenaKey, "m" .. g1 .. ";" .. g2 .. ";" .. matchStart)

	for _, pair in ipairs({{c1, g1, g2}, {c2, g2, g1}}) do
		local cid, partnerGuid = pair[1], pair[3]
		local savedSpeed = getCreatureSpeed(cid) - getCreatureBaseSpeed(cid)
		pset(cid, st("inMatch"), 1)
		pset(cid, st("arena"), arenaIdx)
		pset(cid, st("partner"), partnerGuid)
		pset(cid, st("matchStart"), matchStart)
		pset(cid, st("savedSpeed"), savedSpeed)
		pset(cid, st("bombSize"), 1)
		pset(cid, st("maxBombs"), 1)
		pset(cid, st("activeBombs"), 0)
		pset(cid, st("speed"), 1)
		pset(cid, st("kick"), 0)
		pset(cid, st("inQueue"), -1)
	end

	doTeleportThing(c1, Bomberman.ARENAS[arenaIdx].spawn1, false)
	doTeleportThing(c2, Bomberman.ARENAS[arenaIdx].spawn2, false)
	doSendMagicEffect(Bomberman.ARENAS[arenaIdx].spawn1, 10)
	doSendMagicEffect(Bomberman.ARENAS[arenaIdx].spawn2, 10)

	-- outfits da partida: cada jogador com um outfit diferente (1214 e 1215)
	Bomberman.applyMatchOutfit(c1, cfg("MATCH_OUTFITS")[1])
	Bomberman.applyMatchOutfit(c2, cfg("MATCH_OUTFITS")[2])

	-- abre a janelinha BOMB no client
	doSendPlayerExtendedOpcode(c1, cfg("OPCODE_SHOW"), "open")
	doSendPlayerExtendedOpcode(c2, cfg("OPCODE_SHOW"), "open")

	local name1 = getCreatureName(c1)
	local name2 = getCreatureName(c2)
	doPlayerSendTextMessage(c1, MESSAGE_EVENT_ADVANCE, "PARTIDA DE BOMBERMAN (Arena " .. arenaIdx .. ")! Seu adversario: " .. name2 .. ". Solte bombas com o botao BOMB na tela ou digite !bomb.")
	doPlayerSendTextMessage(c2, MESSAGE_EVENT_ADVANCE, "PARTIDA DE BOMBERMAN (Arena " .. arenaIdx .. ")! Seu adversario: " .. name1 .. ". Solte bombas com o botao BOMB na tela ou digite !bomb.")
	doBroadcastMessage("Bomberman: " .. name1 .. " vs " .. name2 .. " na Arena " .. arenaIdx .. "!", MESSAGE_EVENT_ADVANCE)

	addEvent(Bomberman.matchTimeout, cfg("MATCH_MS"), arenaIdx, matchStart)
end

-- Empate (10 min): so encerra se a partida ainda for a mesma (mesmo start).
function Bomberman.matchTimeout(arenaIdx, matchStart)
	local parts = Bomberman.readArenaData(arenaIdx)
	if not parts then
		return
	end
	if tonumber(parts[3]) ~= matchStart then
		return
	end
	Bomberman.endMatch(arenaIdx, nil)
end

-- Le o conteudo de "bmArena<idx>" ja sem o prefixo "m".
function Bomberman.readArenaData(arenaIdx)
	local data = gget(gs("arena") .. arenaIdx)
	if not data then
		return nil
	end
	local s = tostring(data)
	if s:sub(1, 1) == "m" then
		s = s:sub(2)
	end
	return split(s, ";")
end

-- Encerra a partida, libera a arena e devolve os jogadores ao templo.
-- Pode ser chamado de QUALQUER estado (morte, logout, empate, crash).
function Bomberman.endMatch(arenaIdx, winnerGuid)
	local arenaKey = gs("arena") .. arenaIdx
	local parts = Bomberman.readArenaData(arenaIdx)
	if not parts then
		return -- idempotente: arena ja livre
	end
	gclear(arenaKey)

	local g1 = tonumber(parts[1])
	local g2 = tonumber(parts[2])

	-- remove bombas/power-ups que sobraram e zera o rastreio de bombas da arena
	Bomberman.clearArenaItems(arenaIdx)
	Bomberman.clearBombEntriesForArena(arenaIdx)

	local winnerName = nil
	if winnerGuid then
		local wcid = getPlayerByGUID(winnerGuid)
		if wcid and wcid ~= 0 and isCreature(wcid) then
			winnerName = getCreatureName(wcid)
		end
	end

	local msg
	if winnerName then
		msg = "Fim de partida! " .. winnerName .. " venceu o Bomberman!"
		doBroadcastMessage(msg, MESSAGE_EVENT_ADVANCE)
	else
		msg = "A partida de Bomberman terminou em empate! A arena foi liberada."
		doBroadcastMessage(msg, MESSAGE_EVENT_ADVANCE)
	end

	-- devolve os 2 jogadores (quem estiver online) ao templo + limpa tudo.
	-- (offline: storages ficam para a limpeza do login)
	for _, guid in ipairs({g1, g2}) do
		local cid = getPlayerByGUID(guid)
		if cid and cid ~= 0 and isCreature(cid) then
			if winnerGuid and guid == winnerGuid then
				doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "VOCÊ VENCEU a partida de Bomberman! Parabens!")
			else
				doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, msg)
			end
			Bomberman.resetPlayer(cid, true)
		end
	end

	-- reconstrói os blocos para a proxima partida
	Bomberman.rebuildBlocks(arenaIdx)

	-- a arena foi liberada: tenta parear os proximos da fila
	Bomberman.tryStartNextMatch()
end

-- Limpa storages/buffs de um jogador e (opcional) teleporta para o templo.
function Bomberman.resetPlayer(cid, teleport)
	if not isCreature(cid) then
		return
	end

	-- restaura a velocidade que o player tinha antes da partida
	local savedSpeed = pget(cid, st("savedSpeed"))
	if type(savedSpeed) ~= "number" or savedSpeed < 0 then
		savedSpeed = 0
	end
	doChangeSpeed(cid, savedSpeed)

	pset(cid, st("inMatch"), -1)
	pset(cid, st("arena"), -1)
	pset(cid, st("partner"), -1)
	pset(cid, st("matchStart"), -1)
	pset(cid, st("savedSpeed"), 0)
	pset(cid, st("bombSize"), 1)
	pset(cid, st("maxBombs"), 1)
	pset(cid, st("activeBombs"), 0)
	pset(cid, st("speed"), 1)
	pset(cid, st("kick"), 0)
	pset(cid, st("inQueue"), -1)

	-- restaura o outfit original salvo no storage
	Bomberman.restorePlayerOutfit(cid)

	-- fecha a janelinha BOMB no client
	doSendPlayerExtendedOpcode(cid, cfg("OPCODE_SHOW"), "close")

	if teleport then
		doTeleportThing(cid, cfg("TEMPLE"), false)
		doSendMagicEffect(cfg("TEMPLE"), 10)
	end
end

-- ============================================================================
-- OUTFIT DA PARTIDA
-- ============================================================================

-- Aplica o outfit da partida (1214/1215) e salva o outfit original no storage.
function Bomberman.applyMatchOutfit(cid, lookType)
	if not isCreature(cid) then
		return
	end
	local outfit = getCreatureOutfit(cid)
	if type(outfit) ~= "table" then
		return
	end

	pset(cid, st("outfitType"), outfit.lookType or 0)
	pset(cid, st("outfitEx"), outfit.lookTypeEx or 0)
	pset(cid, st("outfitHead"), outfit.lookHead or 0)
	pset(cid, st("outfitBody"), outfit.lookBody or 0)
	pset(cid, st("outfitLegs"), outfit.lookLegs or 0)
	pset(cid, st("outfitFeet"), outfit.lookFeet or 0)
	pset(cid, st("outfitAddons"), outfit.lookAddons or 0)
	pset(cid, st("outfitMount"), outfit.lookMount or 0)

	doCreatureChangeOutfit(cid, {
		lookType = lookType,
		lookTypeEx = outfit.lookTypeEx or 0,
		lookHead = outfit.lookHead or 0,
		lookBody = outfit.lookBody or 0,
		lookLegs = outfit.lookLegs or 0,
		lookFeet = outfit.lookFeet or 0,
		lookAddons = outfit.lookAddons or 0,
		lookMount = outfit.lookMount or 0
	})
end

-- Restaura o outfit original salvo no storage (fim de partida, logout, crash).
function Bomberman.restorePlayerOutfit(cid)
	if not isCreature(cid) then
		return
	end
	local lookType = pget(cid, st("outfitType"))
	if not lookType or lookType <= 0 then
		-- nada salvo (lookType 0 pode ser item-look; nesse caso restaura o ex)
		local lookTypeEx = pget(cid, st("outfitEx"))
		if not lookTypeEx or lookTypeEx <= 0 then
			Bomberman.clearOutfitStorages(cid)
			return
		end
		doCreatureChangeOutfit(cid, {
			lookType = 0,
			lookTypeEx = lookTypeEx,
			lookHead = pget(cid, st("outfitHead")) or 0,
			lookBody = pget(cid, st("outfitBody")) or 0,
			lookLegs = pget(cid, st("outfitLegs")) or 0,
			lookFeet = pget(cid, st("outfitFeet")) or 0,
			lookAddons = pget(cid, st("outfitAddons")) or 0,
			lookMount = pget(cid, st("outfitMount")) or 0
		})
		Bomberman.clearOutfitStorages(cid)
		return
	end

	doCreatureChangeOutfit(cid, {
		lookType = lookType,
		lookTypeEx = pget(cid, st("outfitEx")) or 0,
		lookHead = pget(cid, st("outfitHead")) or 0,
		lookBody = pget(cid, st("outfitBody")) or 0,
		lookLegs = pget(cid, st("outfitLegs")) or 0,
		lookFeet = pget(cid, st("outfitFeet")) or 0,
		lookAddons = pget(cid, st("outfitAddons")) or 0,
		lookMount = pget(cid, st("outfitMount")) or 0
	})
	Bomberman.clearOutfitStorages(cid)
end

function Bomberman.clearOutfitStorages(cid)
	pset(cid, st("outfitType"), 0)
	pset(cid, st("outfitEx"), 0)
	pset(cid, st("outfitHead"), 0)
	pset(cid, st("outfitBody"), 0)
	pset(cid, st("outfitLegs"), 0)
	pset(cid, st("outfitFeet"), 0)
	pset(cid, st("outfitAddons"), 0)
	pset(cid, st("outfitMount"), 0)
end

-- ============================================================================
-- BOMBAS (rastreadas no storage global "bmBombs"; guardas por planted)
-- ============================================================================

function Bomberman.readBombs()
	local out = {}
	local data = gget(gs("bombs"))
	if not data then
		return out
	end
	local s = tostring(data)
	if s:sub(1, 1) == "b" then
		s = s:sub(2)
	end
	if s == "" then
		return out
	end
	for entry in string.gmatch(s, "[^|]+") do
		local p = split(entry, ";")
		local e = {
			x = tonumber(p[1]),
			y = tonumber(p[2]),
			z = tonumber(p[3]),
			owner = tonumber(p[4]),
			range = tonumber(p[5]),
			planted = tonumber(p[6])
		}
		if e.x and e.y and e.z and e.owner then
			out[#out + 1] = e
		end
	end
	return out
end

function Bomberman.writeBombs(list)
	if #list == 0 then
		gclear(gs("bombs"))
		return
	end
	local parts = {}
	for _, e in ipairs(list) do
		parts[#parts + 1] = e.x .. ";" .. e.y .. ";" .. e.z .. ";" .. e.owner .. ";" .. e.range .. ";" .. e.planted
	end
	gset(gs("bombs"), "b" .. table.concat(parts, "|"))
end

function Bomberman.findBombEntryAt(pos)
	local list = Bomberman.readBombs()
	for _, e in ipairs(list) do
		if e.x == pos.x and e.y == pos.y and e.z == pos.z then
			return e
		end
	end
	return nil
end

function Bomberman.removeBombEntryAt(pos)
	local list = Bomberman.readBombs()
	local keep = {}
	for _, e in ipairs(list) do
		if not (e.x == pos.x and e.y == pos.y and e.z == pos.z) then
			keep[#keep + 1] = e
		end
	end
	Bomberman.writeBombs(keep)
end

function Bomberman.updateBombEntryAt(pos, newEntry)
	local list = Bomberman.readBombs()
	local out = {}
	for _, e in ipairs(list) do
		if e.x == pos.x and e.y == pos.y and e.z == pos.z then
			out[#out + 1] = newEntry
		else
			out[#out + 1] = e
		end
	end
	Bomberman.writeBombs(out)
end

-- Remove do rastreio todas as bombas de uma arena (fim de partida).
function Bomberman.clearBombEntriesForArena(arenaIdx)
	local list = Bomberman.readBombs()
	local keep = {}
	for _, e in ipairs(list) do
		if Bomberman.findArenaByPos({x = e.x, y = e.y, z = e.z}) ~= arenaIdx then
			keep[#keep + 1] = e
		end
	end
	Bomberman.writeBombs(keep)
end

function Bomberman.dropBomb(cid)
	if not isPlayer(cid) then
		return
	end
	if pget(cid, st("inMatch")) ~= 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você só pode soltar bombas dentro de uma partida de Bomberman!")
		return
	end

	local arenaIdx = pget(cid, st("arena"))
	if not arenaIdx or not gget(gs("arena") .. arenaIdx) then
		return
	end

	local maxBombs = pget(cid, st("maxBombs")) or 1
	if maxBombs < 1 then
		maxBombs = 1
	end
	local active = pget(cid, st("activeBombs")) or 0
	if active < 0 then
		active = 0
	end
	if active >= maxBombs then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já soltou o número máximo de bombas!")
		return
	end

	local pos = getThingPosition(cid)
	if not Bomberman.insideArena(arenaIdx, pos) then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você só pode soltar bombas dentro da arena!")
		return
	end
	if getTileItemById(pos, cfg("BOMB_ID")).uid > 0
		or getTileItemById(pos, cfg("WALL_ID")).uid > 0
		or getTileItemById(pos, cfg("BLOCK_ID")).uid > 0 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Não da para soltar a bomba neste tile!")
		return
	end
	local top = getTopCreature(pos).uid
	if top > 0 and top ~= cid then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Não da para soltar a bomba neste tile!")
		return
	end

	doCreateItem(cfg("BOMB_ID"), 1, pos)
	if getTileItemById(pos, cfg("BOMB_ID")).uid == 0 then
		-- nao conseguiu criar a bomba (item nao configurado?) -> nao gasta o slot
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Não foi possível criar a bomba!")
		return
	end

	pset(cid, st("activeBombs"), active + 1)

	local range = pget(cid, st("bombSize")) or 1
	if range < 1 then
		range = 1
	end

	local guid = getPlayerGUID(cid)
	local planted = os.time()
	Bomberman.writeBombs(Bomberman.appendBomb({
		x = pos.x, y = pos.y, z = pos.z, owner = guid, range = range, planted = planted
	}))

	addEvent(Bomberman.bombFuse, cfg("FUSE_MS"), pos.x, pos.y, pos.z, range, guid, planted)
end

function Bomberman.appendBomb(entry)
	local list = Bomberman.readBombs()
	list[#list + 1] = entry
	return list
end

-- Fuse da bomba. Guardas:
--   * owner fora de partida / arena livre      -> partida acabou, ignora
--   * bomba nao esta mais na posicao           -> foi chutada, ignora
--   * planted != planted registrado            -> bomba foi chutada/re-agendada, ignora
--   * planted == -1                            -> disparada em cadeia por outra explosao
function Bomberman.bombFuse(px, py, pz, range, ownerGuid, planted)
	local pos = {x = px, y = py, z = pz}

	local ownerCid = getPlayerByGUID(ownerGuid)
	if not ownerCid or ownerCid == 0 or not isCreature(ownerCid) then
		return
	end
	if pget(ownerCid, st("inMatch")) ~= 1 then
		return
	end
	local arenaIdx = pget(ownerCid, st("arena"))
	if not arenaIdx or arenaIdx < 1 or arenaIdx > 6 then
		return
	end
	if not gget(gs("arena") .. arenaIdx) then
		return
	end

	local entry = Bomberman.findBombEntryAt(pos)
	if not entry or entry.planted ~= planted then
		return
	end

	-- explodiu de verdade: remove a bomba e gasta o slot do dono
	local it = getTileItemById(pos, cfg("BOMB_ID"))
	if it and it.uid and it.uid > 0 then
		doRemoveItem(it.uid)
	end
	Bomberman.removeBombEntryAt(pos)
	local active = pget(ownerCid, st("activeBombs")) or 0
	if active and active > 0 then
		pset(ownerCid, st("activeBombs"), active - 1)
	end

	Bomberman.spread(arenaIdx, pos, entry.range or 1)
end

-- Explosao em cadeia: outra bomba atingida pelo fogo explode logo em seguida.
-- Marca a bomba com planted = -1 para o fuse original dela nao explodir de novo.
function Bomberman.chainBomb(arenaIdx, pos)
	local entry = Bomberman.findBombEntryAt(pos)
	if not entry then
		return
	end
	entry.planted = -1
	Bomberman.updateBombEntryAt(pos, entry)
	addEvent(Bomberman.bombFuse, 50, pos.x, pos.y, pos.z, entry.range or 1, entry.owner, -1)
end

-- Espalha o fogo (cruz) a partir de `center` ate o alcance.
function Bomberman.spread(arenaIdx, center, range)
	if not gget(gs("arena") .. arenaIdx) then
		return
	end

	local hitTiles = {center}

	for d = 1, 4 do
		local dir = DIRS[d]
		local blocked = false
		for i = 1, range do
			if blocked then
				break
			end
			if not gget(gs("arena") .. arenaIdx) then
				return -- partida encerrou no meio da explosao
			end
			local p = {x = center.x + (dir[1] * i), y = center.y + (dir[2] * i), z = center.z}

			if not Bomberman.insideArena(arenaIdx, p) then
				blocked = true
				break
			end

			if getTileItemById(p, cfg("WALL_ID")).uid > 0 then
				blocked = true -- parede indestrutivel: o fogo para
			elseif getTileItemById(p, cfg("BLOCK_ID")).uid > 0 then
				table.insert(hitTiles, p)
				Bomberman.destroyBlock(arenaIdx, p)
				blocked = true -- bloco destrutivel: explode e para
			elseif getTileItemById(p, cfg("BOMB_ID")).uid > 0 then
				table.insert(hitTiles, p)
				Bomberman.chainBomb(arenaIdx, p)
				blocked = true -- outra bomba: explode em cadeia e o fogo para nela
			else
				table.insert(hitTiles, p)
			end
		end
	end

	for _, p in ipairs(hitTiles) do
		if not gget(gs("arena") .. arenaIdx) then
			return
		end
		doSendMagicEffect(p, cfg("EXPLOSION_EFFECT"))
		local top = getTopCreature(p).uid
		if top > 0 and isPlayer(top) then
			Bomberman.hitPlayer(arenaIdx, top)
		end
	end
end

-- Jogador atingido: 1o hit perde os power-ups, 2o hit sai da partida.
function Bomberman.hitPlayer(arenaIdx, victim)
	if pget(victim, st("inMatch")) ~= 1 then
		return
	end
	if pget(victim, st("arena")) ~= arenaIdx then
		return
	end

	local hasPowers =
		(pget(victim, st("bombSize")) or 1) > 1
		or (pget(victim, st("maxBombs")) or 1) > 1
		or (pget(victim, st("speed")) or 1) ~= 1
		or (pget(victim, st("kick")) or 0) == 1

	if hasPowers then
		Bomberman.resetPowerUps(victim)
		doSendMagicEffect(getThingPosition(victim), cfg("EXPLOSION_EFFECT"))
		doPlayerSendTextMessage(victim, MESSAGE_INFO_DESCR, "Você foi atingido pela explosao e perdeu suas habilidades!")
	else
		local winner = pget(victim, st("partner"))
		Bomberman.endMatch(arenaIdx, winner)
	end
end

function Bomberman.resetPowerUps(cid)
	pset(cid, st("bombSize"), 1)
	pset(cid, st("maxBombs"), 1)
	pset(cid, st("speed"), 1)
	pset(cid, st("kick"), 0)
	Bomberman.applySpeed(cid)
end

-- Aplica a velocidade do bomberman respeitando a velocidade que o player
-- tinha antes da partida (doChangeSpeed deste fork define o delta absoluto
-- da velocidade base: nova = atual - base + valor).
function Bomberman.applySpeed(cid)
	local savedSpeed = pget(cid, st("savedSpeed"))
	if type(savedSpeed) ~= "number" or savedSpeed < 0 then
		savedSpeed = 0
	end
	local cur = pget(cid, st("speed")) or 1
	doChangeSpeed(cid, savedSpeed + (cur - 1) * cfg("SPEED_PER_POINT"))
end

-- ============================================================================
-- BLOCOS E POWER-UPS
-- ============================================================================

function Bomberman.destroyBlock(arenaIdx, pos)
	local it = getTileItemById(pos, cfg("BLOCK_ID"))
	if it and it.uid and it.uid > 0 then
		doRemoveItem(it.uid)
	end
	if math.random(1, 100) <= cfg("POWERUP_CHANCE") then
		Bomberman.dropPowerUp(arenaIdx, pos)
	end
end

function Bomberman.dropPowerUp(arenaIdx, pos)
	local roll = math.random(1, 100)
	local id
	if roll <= 25 then
		id = cfg("FIRE_PU")     -- fogo maior
	elseif roll <= 45 then
		id = cfg("BOMBS_PU")    -- mais bombas
	elseif roll <= 65 then
		id = cfg("SPEED_PU")    -- mais velocidade
	elseif roll <= 85 then
		id = cfg("KICK_PU")     -- chutar a bomba
	else
		id = cfg("SLOW_PU")     -- fica lento
	end
	doCreateItem(id, 1, pos)
end

-- Aplica o power-up ao jogador (chamado pelo movement).
function Bomberman.onStepOnPowerUp(cid, item)
	if pget(cid, st("inMatch")) ~= 1 then
		return
	end
	local arenaIdx = pget(cid, st("arena"))
	if not Bomberman.insideArena(arenaIdx, getThingPosition(cid)) then
		return
	end

	local id = item.itemid

	if id == cfg("FIRE_PU") then
		local cur = pget(cid, st("bombSize")) or 1
		if cur >= cfg("MAX_BOMB_SIZE") then
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Sua bomba já atinge o máximo de " .. cfg("MAX_BOMB_SIZE") .. " sqm.")
		else
			pset(cid, st("bombSize"), cur + 1)
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Agora sua bomba atinge até " .. (cur + 1) .. " sqm!")
		end
	elseif id == cfg("BOMBS_PU") then
		local cur = pget(cid, st("maxBombs")) or 1
		if cur >= cfg("MAX_BOMBS") then
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já pode soltar o máximo de " .. cfg("MAX_BOMBS") .. " bombas.")
		else
			pset(cid, st("maxBombs"), cur + 1)
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Agora você pode soltar até " .. (cur + 1) .. " bombas!")
		end
	elseif id == cfg("SPEED_PU") then
		local cur = pget(cid, st("speed")) or 1
		if cur >= cfg("MAX_SPEED") then
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já está com a velocidade máxima (" .. cfg("MAX_SPEED") .. ").")
		else
			pset(cid, st("speed"), cur + 1)
			Bomberman.applySpeed(cid)
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Sua velocidade aumentou!")
		end
	elseif id == cfg("KICK_PU") then
		pset(cid, st("kick"), 1)
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Agora você pode chutar as bombas! Ande em cima delas para move-las.")
	elseif id == cfg("SLOW_PU") then
		local cur = pget(cid, st("speed")) or 1
		if cur <= -cfg("MAX_SPEED") then
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você já está bem lento...")
		else
			pset(cid, st("speed"), cur - 1)
			Bomberman.applySpeed(cid)
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você ficou lento!")
		end
	end

	doRemoveItem(item.uid)
end

-- Chute: com o power-up de chute, andar em cima da bomba a empurra.
function Bomberman.onStepOnBomb(cid, position, fromPosition)
	if pget(cid, st("inMatch")) ~= 1 then
		return
	end
	if pget(cid, st("kick")) ~= 1 then
		return
	end

	local arenaIdx = pget(cid, st("arena"))
	if not Bomberman.insideArena(arenaIdx, position) then
		return
	end

	local dx = position.x - fromPosition.x
	local dy = position.y - fromPosition.y
	if dx == 0 and dy == 0 then
		return
	end

	local target = {x = position.x + dx, y = position.y + dy, z = position.z}
	if not Bomberman.insideArena(arenaIdx, target) then
		return
	end

	-- nao pode empurrar para parede, bloco, outra bomba ou criatura
	if getTileItemById(target, cfg("WALL_ID")).uid > 0
		or getTileItemById(target, cfg("BLOCK_ID")).uid > 0
		or getTileItemById(target, cfg("BOMB_ID")).uid > 0 then
		return
	end
	local top = getTopCreature(target).uid
	if top > 0 then
		return
	end

	local uid = getTileItemById(position, cfg("BOMB_ID")).uid
	if uid == 0 then
		return
	end

	local entry = Bomberman.findBombEntryAt(position)
	if not entry then
		return
	end

	doRemoveItem(uid)
	doCreateItem(cfg("BOMB_ID"), 1, target)
	doSendMagicEffect(target, 10)

	-- atualiza o rastreio da bomba (nova posicao + novo planted) e re-agenda o fuse
	local newPlanted = os.time()
	entry.x = target.x
	entry.y = target.y
	entry.z = target.z
	entry.planted = newPlanted
	Bomberman.updateBombEntryAt(position, entry)
	addEvent(Bomberman.bombFuse, cfg("FUSE_MS"), target.x, target.y, target.z, entry.range or 1, entry.owner, newPlanted)
end

-- ============================================================================
-- EVENTOS DE CRIATURA (login / logout / morte / opcode)
-- ============================================================================

function Bomberman.handleLogin(cid)
	-- limpa qualquer resto de fila
	Bomberman.removeFromQueue(cid)

	if pget(cid, st("inMatch")) == 1 then
		-- estado antigo (crash/restart): limpa tudo do evento
		local arenaIdx = pget(cid, st("arena"))
		local pos = getThingPosition(cid)
		local inArena = arenaIdx and Bomberman.ARENAS[arenaIdx]
			and Bomberman.insideArena(arenaIdx, pos)
		Bomberman.resetPlayer(cid, inArena)
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Uma partida de Bomberman que estava em andamento foi encerrada.")
	end
end

function Bomberman.handleLogout(cid)
	Bomberman.removeFromQueue(cid)

	if pget(cid, st("inMatch")) == 1 then
		local arenaIdx = pget(cid, st("arena"))
		local winner = pget(cid, st("partner"))
		Bomberman.endMatch(arenaIdx, winner)
	end
end

function Bomberman.handleDeath(cid)
	if pget(cid, st("inMatch")) ~= 1 then
		return
	end
	local arenaIdx = pget(cid, st("arena"))
	local winner = pget(cid, st("partner"))
	Bomberman.endMatch(arenaIdx, winner)
end

function Bomberman.handleOpcode(cid, opcode, buffer)
	if opcode == cfg("OPCODE_CLICK") and buffer == "bomb" then
		Bomberman.dropBomb(cid)
	end
end
