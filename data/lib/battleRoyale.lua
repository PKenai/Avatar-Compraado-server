-- ============================================================================
-- BATTLE ROYALE -- CAJADO DE SONAM (Sonam's Staff)
-- ----------------------------------------------------------------------------
-- Regras (confirmadas):
--   * GM abre a rodada -> portal (air tornado 19204) em {584,350,7} + broadcast
--     em ingles. O cajado (Sonam's Staff 19218) nasce em {461,2017,5}.
--   * O portal fica aberto 10 min. Pisar nele joga o player para um tile
--     andavel aleatorio dentro da arena {321,1892,7} -> {650,2144,7}.
--     A partir da entrada, o player e participante da rodada.
--   * O cajado so pode ser usado apos 5 min da abertura. Ao usar, o item
--     some do chao e o player vira o Avatar da arena (isAvatar + rainbow).
--   * Batata quente: matar o avatar transfere o estado para o matador, com um
--     novo relogio de 10 min de sobrevivencia. O avatar morto e eliminado
--     (sem morte real, teleportado para fora, nao volta nesta rodada).
--   * Se ninguem matar o avatar em 10 min seguidos, a rodada acaba: todos
--     sao teleportados para {572,360,7} e o avatar final mantem o estado por
--     45 min. Morrer ou deslogar nessa janela = perde o estado.
--   * Anti-bug: avatar desloga/morre sem matador player -> rodada abortada e
--     todos saem. Safety cap: se ninguem pegar o cajado ate t+15min, a rodada
--     acaba. O estado nunca sobrevive a relog/crash.
--
-- ARQUITETURA (igual ao bomberman.lua deste fork):
--   Cada sistema de eventos tem o SEU proprio estado Lua, entao NENHUM estado
--   compartilhado pode viver em tabelas Lua "globais". Todo o estado vive em
--   storages globais (getStorage/doSetStorage) e player storages
--   (getPlayerStorageValue/setPlayerStorageValue). Timers (addEvent) releem
--   o estado das storages com guardas e sao seguros de rodar de qualquer
--   estado. Um watchdog (globalevent a cada 5s) garante os prazos.
--
-- ARQUIVOS DO SISTEMA:
--   data/lib/battleRoyale.lua                     <- este arquivo (nucleo)
--   data/globalevents/scripts/battleRoyale.lua    -> onStartup + watchdog
--   data/talkactions/scripts/battleRoyale.lua     -> !battleroyale
--   data/movements/scripts/battleRoyale.lua       -> StepIn do portal
--   data/actions/scripts/battleRoyale.lua         -> uso do cajado
--   data/creaturescripts/scripts/battleRoyale.lua -> login/logout/morte
-- ============================================================================

if not BattleRoyale then
	BattleRoyale = {}
end

BattleRoyale.CONFIG = {
	PORTAL_ID = 19204,          -- air tornado
	PORTAL_AID = 63001,         -- actionid do portal criado em runtime (unico)
	PORTAL_POS = {x = 584, y = 350, z = 7},
	STAFF_ID = 19218,           -- Sonam's Staff
	STAFF_POS = {x = 461, y = 2017, z = 5},  -- z=5 confirmado pelo dono do servidor
	ARENA_MIN = {x = 321, y = 1892, z = 7},
	ARENA_MAX = {x = 650, y = 2144, z = 7},
	EXIT = {x = 572, y = 360, z = 7},
	RAINBOW_SHADER = 113,       -- outfit_rainbow (shaders.xml)

	PORTAL_OPEN_S = 10 * 60,    -- portal fica aberto 10 min
	STAFF_READY_S = 5 * 60,     -- cajado utilizavel apos 5 min
	STAFF_DEADLINE_S = 15 * 60, -- safety cap: sem claim ate aqui, rodada acaba
	SURVIVAL_S = 10 * 60,       -- clock de sobrevivencia do avatar
	HOLD_S = 45 * 60,           -- duracao do estado avatar apos a rodada

	-- storages globais (compartilhados entre TODOS os estados Lua)
	GS = {
		state = "brState",            -- nil = idle | "entry" | "hotpotato"
		roundStart = "brRoundStart",  -- os.time() da abertura do portal
		staffTaken = "brStaffTaken",  -- 1 = cajado ja foi pego
		avatarGuid = "brAvatarGuid",  -- GUID do avatar da arena
		avatarDead = "brAvatarDeadline", -- os.time() do fim da sobrevivencia
	},
	-- player storages (compartilhados, persistidos no DB)
	STORAGE = {
		participant = "brParticipant", -- 1 = participante da rodada
		avatar = "brAvatar",           -- 1 = avatar da arena (batata quente)
		finalHold = "brFinalHold",     -- os.time() ate quando o vencedor mantem o estado
		savedShader = "brSavedShader", -- shader do player antes do rainbow
	},
}

-- ============================================================================
-- HELPERS DE STORAGE (normalizam -1 / "" para nil)
-- ============================================================================

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

local function cfg(k)
	return BattleRoyale.CONFIG[k]
end

local function gsk(k)
	return BattleRoyale.CONFIG.GS[k]
end

local function stk(k)
	return BattleRoyale.CONFIG.STORAGE[k]
end

-- ============================================================================
-- GEOMETRIA
-- ============================================================================

function BattleRoyale.isInArena(pos)
	if not pos then
		return false
	end
	local min = cfg("ARENA_MIN")
	local max = cfg("ARENA_MAX")
	return pos.z == min.z and pos.x >= min.x and pos.x <= max.x
		and pos.y >= min.y and pos.y <= max.y
end

-- Tile andavel aleatorio dentro da arena, sem criatura em cima.
function BattleRoyale.randomArenaPos()
	local min = cfg("ARENA_MIN")
	local max = cfg("ARENA_MAX")
	for i = 1, 300 do
		local pos = {x = math.random(min.x, max.x), y = math.random(min.y, max.y), z = min.z}
		if isWalkable(pos) then
			local top = getTopCreature(pos).uid
			if not top or top == 0 then
				return pos
			end
		end
	end
	return nil
end

function BattleRoyale.isActive()
	return not not gget(gsk("state"))
end

-- Player storage: participante da rodada atual (brParticipant == 1)?
function BattleRoyale.isParticipant(cid)
	if not isPlayer(cid) then
		return false
	end
	return pget(cid, stk("participant")) == 1
end

-- Avatar atual da arena (batata quente), se a rodada estiver no estado
-- "hotpotato" e o dono do estado estiver online. nil fora disso.
function BattleRoyale.getArenaAvatarCid()
	if gget(gsk("state")) ~= "hotpotato" then
		return nil
	end
	local guid = tonumber(gget(gsk("avatarGuid")) or 0)
	if not guid or guid <= 0 then
		return nil
	end
	local cid = getPlayerByGUID(guid)
	if cid and isPlayer(cid) then
		return cid
	end
	return nil
end

-- ============================================================================
-- SHADER / ESTADO AVATAR
-- ============================================================================

function BattleRoyale.applyShader(cid)
	local outfit = getCreatureOutfit(cid)
	if type(outfit) ~= "table" then
		return
	end
	pset(cid, stk("savedShader"), outfit.lookShader or 0)
	outfit.lookShader = cfg("RAINBOW_SHADER")
	doCreatureChangeOutfit(cid, outfit)
end

function BattleRoyale.restoreShader(cid)
	if not isCreature(cid) then
		return
	end
	local outfit = getCreatureOutfit(cid)
	if type(outfit) ~= "table" then
		return
	end
	local saved = pget(cid, stk("savedShader"))
	outfit.lookShader = saved or 0
	doCreatureChangeOutfit(cid, outfit)
	pset(cid, stk("savedShader"), -1)
end

-- Remove completamente o estado avatar de um player (shader + storages).
function BattleRoyale.clearAvatarState(cid)
	if not isCreature(cid) then
		return
	end
	setPlayerStorageValue(cid, "isAvatar", 0)
	pset(cid, stk("avatar"), -1)
	pset(cid, stk("finalHold"), -1)
	BattleRoyale.restoreShader(cid)
end

function BattleRoyale.avatarEffects(cid)
	local pos = getCreaturePosition(cid)
	doSendMagicEffect({x = pos.x + 1, y = pos.y + 1, z = pos.z}, 134)
	doSendMagicEffect({x = pos.x + 1, y = pos.y + 1, z = pos.z}, 135)
	doSendMagicEffect({x = pos.x + 1, y = pos.y + 1, z = pos.z}, 121)
end

-- ============================================================================
-- INICIALIZACAO / RECOVERY (globalevent startup + watchdog 5s)
-- ============================================================================

function BattleRoyale.init()
	-- restart/reload: remove itens que sobraram e zera o estado global.
	-- (player storages de participantes sao limpos no login de cada um.)
	BattleRoyale.removePortal()
	BattleRoyale.removeStaff()
	gclear(gsk("state"))
	gclear(gsk("roundStart"))
	gclear(gsk("staffTaken"))
	gclear(gsk("avatarGuid"))
	gclear(gsk("avatarDead"))
end

function BattleRoyale.watchdog()
	local state = gget(gsk("state"))
	if not state then
		-- backup da expiracao do hold de 45 min (se o addEvent se perdeu)
		for _, cid in ipairs(getPlayersOnline()) do
			local hold = tonumber(pget(cid, stk("finalHold")) or 0)
			if hold > 0 and hold <= os.time() and getPlayerStorageValue(cid, "isAvatar") == 1 then
				BattleRoyale.clearAvatarState(cid)
				doBroadcastMessage("The Avatar's power has faded.", 22)
			end
		end
		return
	end

	local start = tonumber(gget(gsk("roundStart")) or 0)
	local now = os.time()

	-- portal some sozinho apos 10 min (redundante com o timer do start)
	if now >= start + cfg("PORTAL_OPEN_S") then
		BattleRoyale.removePortal()
	end

	-- safety cap: ninguem pegou o cajado ate t+15min
	if tonumber(gget(gsk("staffTaken")) or 0) ~= 1 and now >= start + cfg("STAFF_DEADLINE_S") then
		doBroadcastMessage("No one claimed the Sonam's Staff... The Battle Royale has ended.", 22)
		BattleRoyale.endRound(nil)
		return
	end

	if state == "hotpotato" then
		local guid = tonumber(gget(gsk("avatarGuid")) or 0)
		if guid and guid > 0 then
			local avatarCid = getPlayerByGUID(guid)
			-- avatar sumiu sem evento de logout (crash): aborta (anti-bug)
			if not avatarCid or not isCreature(avatarCid) then
				doBroadcastMessage("The Avatar is no longer online! The Battle Royale has been aborted.", 22)
				BattleRoyale.endRound(nil)
				return
			end
			local deadline = tonumber(gget(gsk("avatarDead")) or 0)
			if deadline > 0 and now >= deadline then
				BattleRoyale.endRound(guid)
			end
		end
	end
end

-- ============================================================================
-- RODADA
-- ============================================================================

function BattleRoyale.startRound()
	if BattleRoyale.isActive() then
		return false, "Ja existe uma rodada do Battle Royale em andamento!"
	end
	-- limpa o vencedor anterior (hold de 45 min) para nunca existirem 2 avatares
	for _, cid in ipairs(getPlayersOnline()) do
		local hold = tonumber(pget(cid, stk("finalHold")) or 0)
		if hold > os.time() and getPlayerStorageValue(cid, "isAvatar") == 1 then
			BattleRoyale.clearAvatarState(cid)
		end
	end

	local portal = doCreateItem(cfg("PORTAL_ID"), 1, cfg("PORTAL_POS"))
	if portal and portal > 0 then
		doSetItemActionId(portal, cfg("PORTAL_AID"))
	end
	doSendMagicEffect(cfg("PORTAL_POS"), 10)

	doCreateItem(cfg("STAFF_ID"), 1, cfg("STAFF_POS"))
	doSendMagicEffect(cfg("STAFF_POS"), 10)

	gset(gsk("state"), "entry")
	gset(gsk("roundStart"), os.time())
	gset(gsk("staffTaken"), 0)

	doBroadcastMessage("A strange tornado east of Ba Sing Se is emanating an immense spiritual power.", 22)

	-- fecha o portal em 10 min
	addEvent(BattleRoyale.closePortal, cfg("PORTAL_OPEN_S") * 1000)
	return true
end

function BattleRoyale.closePortal()
	if not BattleRoyale.isActive() then
		return
	end
	BattleRoyale.removePortal()
	doBroadcastMessage("The tornado has faded... the portal is closed.", 22)
end

function BattleRoyale.removePortal()
	local it = getTileItemById(cfg("PORTAL_POS"), cfg("PORTAL_ID"))
	if it and it.uid and it.uid > 0 then
		doRemoveItem(it.uid)
		doSendMagicEffect(cfg("PORTAL_POS"), 13)
	end
end

function BattleRoyale.removeStaff()
	local it = getTileItemById(cfg("STAFF_POS"), cfg("STAFF_ID"))
	if it and it.uid and it.uid > 0 then
		doRemoveItem(it.uid)
	end
end

-- Encerra a rodada (idempotente). avatarGuid ~= nil = avatar sobreviveu 10 min.
function BattleRoyale.endRound(avatarGuid)
	if not BattleRoyale.isActive() then
		return
	end

	local winner = nil
	if avatarGuid then
		winner = getPlayerByGUID(avatarGuid)
		if winner and not isCreature(winner) then
			winner = nil
		end
	end

	if winner then
		doBroadcastMessage("The Avatar survived 10 minutes! " .. getCreatureName(winner) .. " won the Battle Royale!", 22)
		doBroadcastMessage(getCreatureName(winner) .. " remains the Avatar for the next 45 minutes!", 22)
	else
		doBroadcastMessage("The Battle Royale has ended. All participants were teleported away!", 22)
	end

	-- teleporta para fora: todos os participantes + quem estiver fisicamente na arena
	local list = {}
	for _, cid in ipairs(getPlayersOnline()) do
		if pget(cid, stk("participant")) == 1 or BattleRoyale.isInArena(getCreaturePosition(cid)) then
			list[#list + 1] = cid
			pset(cid, stk("participant"), -1)
			pset(cid, stk("avatar"), -1)
		end
	end
	if #list > 0 then
		addEvent(function()
			for _, cid in ipairs(list) do
				if isCreature(cid) then
					doTeleportThing(cid, cfg("EXIT"), false)
					doSendMagicEffect(cfg("EXIT"), 10)
				end
			end
		end, 50)
	end

	BattleRoyale.removePortal()
	BattleRoyale.removeStaff()

	if winner then
		local holdUntil = os.time() + cfg("HOLD_S")
		pset(winner, stk("finalHold"), holdUntil)
		addEvent(BattleRoyale.expireHold, cfg("HOLD_S") * 1000, getPlayerGUID(winner), holdUntil)
	else
		-- rodada sem vencedor: derruba o avatar da rodada (se houver)
		local guid = tonumber(gget(gsk("avatarGuid")) or 0)
		if guid and guid > 0 then
			local c = getPlayerByGUID(guid)
			if c and isCreature(c) then
				BattleRoyale.clearAvatarState(c)
			end
		end
	end

	gclear(gsk("state"))
	gclear(gsk("roundStart"))
	gclear(gsk("staffTaken"))
	gclear(gsk("avatarGuid"))
	gclear(gsk("avatarDead"))
end

function BattleRoyale.expireHold(guid, holdUntil)
	local cid = getPlayerByGUID(guid)
	if not cid or not isCreature(cid) then
		return
	end
	if tonumber(pget(cid, stk("finalHold")) or 0) ~= holdUntil then
		return -- ja foi limpo por morte/logout
	end
	BattleRoyale.clearAvatarState(cid)
	doBroadcastMessage("The Avatar's power has faded.", 22)
end

-- ============================================================================
-- AVATAR (claim do cajado / transferencia batata-quente)
-- ============================================================================

-- Garante avatar unico: derruba qualquer outro avatar ativo (vencedor em hold,
-- scroll, etc) e marca `cid` como o avatar da arena com relogio de 10 min.
function BattleRoyale.makeAvatar(cid, isClaim)
	for _, other in ipairs(getPlayersOnline()) do
		if other ~= cid and getPlayerStorageValue(other, "isAvatar") == 1 then
			BattleRoyale.clearAvatarState(other)
		end
	end

	pset(cid, stk("participant"), 1)
	pset(cid, stk("avatar"), 1)
	setPlayerStorageValue(cid, "isAvatar", 1)
	BattleRoyale.applyShader(cid)
	BattleRoyale.avatarEffects(cid)

	local guid = getPlayerGUID(cid)
	local deadline = os.time() + cfg("SURVIVAL_S")
	gset(gsk("state"), "hotpotato")
	gset(gsk("avatarGuid"), guid)
	gset(gsk("avatarDead"), deadline)
	addEvent(BattleRoyale.checkAvatarSurvival, cfg("SURVIVAL_S") * 1000, guid, deadline)

	if isClaim then
		doBroadcastMessage(getCreatureName(cid) .. " claimed the Sonam's Staff and became the Avatar of the arena!", 22)
	else
		doBroadcastMessage(getCreatureName(cid) .. " defeated the Avatar and is the new Avatar of the arena!", 22)
	end
	doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "VOCE e o Avatar da arena! Sobreviva por 10 minutos e vença o Battle Royale!")
end

function BattleRoyale.checkAvatarSurvival(guid, deadline)
	if gget(gsk("state")) ~= "hotpotato" then
		return
	end
	if tonumber(gget(gsk("avatarGuid")) or 0) ~= guid then
		return -- avatar mudou (outro matou)
	end
	if tonumber(gget(gsk("avatarDead")) or 0) ~= deadline then
		return -- relogio foi resetado
	end
	BattleRoyale.endRound(guid)
end

-- Elimina um participante: sem morte real, teleporta para fora e tira da rodada.
function BattleRoyale.eliminate(cid)
	pset(cid, stk("participant"), -1)
	pset(cid, stk("avatar"), -1)
	doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voce foi eliminado do Battle Royale!")
	addEvent(function()
		if isCreature(cid) then
			doTeleportThing(cid, cfg("EXIT"), false)
			doSendMagicEffect(cfg("EXIT"), 10)
		end
	end, 50)
end

-- ============================================================================
-- EVENTOS (chamados pelos wrappers dos outros sistemas)
-- ============================================================================

-- Entrada pelo portal.
function BattleRoyale.onPortalStep(cid)
	if not isPlayer(cid) then
		return
	end
	local state = gget(gsk("state"))
	if state ~= "entry" and state ~= "hotpotato" then
		return
	end
	local start = tonumber(gget(gsk("roundStart")) or 0)
	if os.time() >= start + cfg("PORTAL_OPEN_S") then
		return -- portal ja fechou (ou o item sobrou por reload)
	end
	local pos = BattleRoyale.randomArenaPos()
	if not pos then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Nao foi possivel encontrar um local seguro na arena. Tente novamente!")
		return
	end
	doTeleportThing(cid, pos, false)
	doSendMagicEffect(pos, 10)
	pset(cid, stk("participant"), 1)
	doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Voce entrou no Battle Royale! Sobreviva e pegue o Cajado de Sonam para se tornar o Avatar.")
end

-- Uso do Cajado de Sonam.
function BattleRoyale.onClaimStaff(cid)
	if not isPlayer(cid) then
		return
	end
	if not BattleRoyale.isActive() then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "O Battle Royale nao esta ativo no momento.")
		return
	end
	if pget(cid, stk("participant")) ~= 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voce nao e um participante do Battle Royale! Entre pelo tornado ao norte de Ba Sing Se.")
		return
	end
	local start = tonumber(gget(gsk("roundStart")) or 0)
	if os.time() < start + cfg("STAFF_READY_S") then
		local falta = (start + cfg("STAFF_READY_S")) - os.time()
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "O Cajado de Sonam ainda nao despertou. Espere mais " .. math.ceil(falta / 60) .. " minuto(s) apos a abertura do tornado.")
		return
	end
	if tonumber(gget(gsk("staffTaken")) or 0) == 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "O Cajado de Sonam ja foi pego!")
		return
	end

	local it = getTileItemById(cfg("STAFF_POS"), cfg("STAFF_ID"))
	if it and it.uid and it.uid > 0 then
		doRemoveItem(it.uid)
		doSendMagicEffect(cfg("STAFF_POS"), 13)
	end
	gset(gsk("staffTaken"), 1)
	BattleRoyale.makeAvatar(cid, true)
end

-- Morte: retorna true = cancela a morte (sem morte real, eliminacao do evento).
function BattleRoyale.handleDeath(cid, deathList)
	if not isPlayer(cid) then
		return false
	end

	-- vencedor em hold (45 min apos a rodada): morrer = perde o estado, morte normal
	local hold = tonumber(pget(cid, stk("finalHold")) or 0)
	if hold > os.time() and getPlayerStorageValue(cid, "isAvatar") == 1 then
		BattleRoyale.clearAvatarState(cid)
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voce morreu e perdeu o estado Avatar!")
		return false
	end

	if pget(cid, stk("participant")) ~= 1 then
		return false -- nao e da rodada: morte normal
	end

	if not BattleRoyale.isActive() then
		-- participante de rodada ja encerrada (stale): so limpa os flags
		pset(cid, stk("participant"), -1)
		pset(cid, stk("avatar"), -1)
		return false
	end

	local isAvatar = pget(cid, stk("avatar")) == 1

	-- descobre o matador (lastHit gravado pelo imuneable.lua; deathList de backup)
	local killer = nil
	local lh = pget(cid, "lastHit")
	if lh and isPlayer(lh) and lh ~= cid then
		killer = lh
	end
	if not killer and type(deathList) == "table" then
		for _, k in ipairs(deathList) do
			if isPlayer(k) and k ~= cid then
				killer = k
				break
			end
		end
	end

	if isAvatar then
		if killer then
			-- batata quente: o matador vira o novo avatar
			BattleRoyale.makeAvatar(killer, false)
			BattleRoyale.eliminate(cid)
		else
			-- morreu para campo/monstro/suicidio: aborta a rodada (anti-bug)
			doBroadcastMessage("The Avatar has fallen without a worthy killer... The Battle Royale is over.", 22)
			BattleRoyale.endRound(nil)
		end
		return true -- cancela a morte
	end

	BattleRoyale.eliminate(cid)
	return true -- cancela a morte
end

function BattleRoyale.handleLogout(cid)
	if not isPlayer(cid) then
		return
	end
	local state = gget(gsk("state"))
	if pget(cid, stk("avatar")) == 1 and (state == "entry" or state == "hotpotato") then
		-- avatar deslogou no meio da rodada: aborta (anti-bug)
		doBroadcastMessage("The Avatar logged out! The Battle Royale has been aborted.", 22)
		BattleRoyale.endRound(nil)
		return
	end
	if pget(cid, stk("participant")) == 1 then
		pset(cid, stk("participant"), -1)
		pset(cid, stk("avatar"), -1)
	end
	-- vencedor em hold deslogou: perde o estado
	local hold = tonumber(pget(cid, stk("finalHold")) or 0)
	if hold > os.time() and getPlayerStorageValue(cid, "isAvatar") == 1 then
		BattleRoyale.clearAvatarState(cid)
	end
end

function BattleRoyale.handleLogin(cid)
	if not isPlayer(cid) then
		return
	end
	local state = gget(gsk("state"))
	if pget(cid, stk("participant")) == 1 then
		-- crash/relog no meio da rodada: saiu do evento
		if pget(cid, stk("avatar")) == 1 and (state == "entry" or state == "hotpotato") then
			doBroadcastMessage("The Avatar disconnected! The Battle Royale has been aborted.", 22)
			BattleRoyale.endRound(nil)
		end
		pset(cid, stk("participant"), -1)
		pset(cid, stk("avatar"), -1)
	end
	-- estado avatar nunca sobrevive a relog (morte/deslogar = perde)
	if getPlayerStorageValue(cid, "isAvatar") == 1 then
		BattleRoyale.clearAvatarState(cid)
	elseif pget(cid, stk("savedShader")) then
		-- crash durante hold/rodada: o login.lua ja zerou isAvatar, mas o
		-- shader rainbow ficou aplicado no outfit -> devolve o shader original
		pset(cid, stk("avatar"), -1)
		pset(cid, stk("finalHold"), -1)
		BattleRoyale.restoreShader(cid)
	end
end

-- ============================================================================
-- STATUS (para o GM)
-- ============================================================================

function BattleRoyale.status()
	if not BattleRoyale.isActive() then
		return "O Battle Royale esta inativo."
	end
	local state = gget(gsk("state"))
	local start = tonumber(gget(gsk("roundStart")) or 0)
	local count = 0
	for _, cid in ipairs(getPlayersOnline()) do
		if pget(cid, stk("participant")) == 1 then
			count = count + 1
		end
	end
	local s = "Estado: " .. state .. " | Participantes: " .. count
	if state == "hotpotato" then
		local guid = tonumber(gget(gsk("avatarGuid")) or 0)
		local cid = getPlayerByGUID(guid)
		local name = "desconhecido"
		if cid and isCreature(cid) then
			name = getCreatureName(cid)
		end
		local deadline = tonumber(gget(gsk("avatarDead")) or 0)
		s = s .. " | Avatar: " .. name .. " | Sobrevivencia restante: " .. math.max(0, deadline - os.time()) .. "s"
	end
	return s
end