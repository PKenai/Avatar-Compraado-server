--[[
 * bossSystem.lua -- Sistema ALPHA de bosses
 *
 * Fluxo:
 *   1. O jogador completa uma task diaria de um monstro (ver data/lib/dailyHunt.lua)
 *   2. O DailyHunt chama BossSystem.grantAccess(cid, monstro)
 *      -> grava o storage "Boss_<monstro>" = <id do dia>
 *   3. O jogador pisa em um tile de portal (itemID 19333/19334 ou qualquer item com
 *      actionID 50030) -> data/movements/scripts/bossPortal.lua
 *   4. O sistema procura monstros proximos que o jogador tenha liberado e
 *      spawna o "ALPHA <monstro>" ao lado dele, UMA unica vez.
 *      Em seguida o storage e' consumido.
 *
 * Tudo e' validado no servidor. O client so' desenha a interface.
 *
 * Arquivos relacionados:
 *   data/lib/bossConfig.lua    (gerado por tools/generate_bosses.py)
 *   data/monster/bosses/       (monstros ALPHA gerados)
 *   data/movements/scripts/bossPortal.lua
 *   data/globalevents/scripts/bossSystem.lua
]]

if type(BossConfig) ~= "table" then
	dofile(getDataDir() .. "lib/bossConfig.lua")
end

BossSystem = {
	PREFIX = "ALPHA ",

	-- tiles que disparam o spawn (duas versoes do mesmo portal)
	TILE_ITEM_IDS = { 19333, 19334 },
	TILE_ACTION_ID = 50030,

	-- quantas casas ao redor do tile o sistema procura o monstro correspondente
	SCAN_RADIUS = 12,

	-- segundos entre duas tentativas do mesmo jogador (anti-spam de tile)
	COOLDOWN = 3,

	-- quantos bosses ALPHA o mesmo jogador pode ter vivo ao mesmo tempo
	MAX_ACTIVE_PER_PLAYER = 1,

	-- tempo maximo de vida de um boss criado por portal (ms)
	LIFETIME = 30 * 60 * 1000,

	-- se o jogador tiver UM unico boss liberado e nao houver nenhuma criatura
	-- dele por perto, ainda assim libera o spawn (util para areas vazias)
	FALLBACK_SINGLE = true,

	-- bloqueia spawn em protection zone / house
	BLOCK_SAFE_ZONES = true,

	-- player_storage.key e' VARCHAR(32)
	MAX_STORAGE_KEY = 32,

	loaded = false,
	active = {},   -- [uid] = { player = nome, monster = "X", boss = "ALPHA X", time = os.time() }
}

-- =========================================================================
-- CONFIG / VALIDACAO
-- =========================================================================

-- Lista "19333, 19334" para mensagens/diagnostico
function BossSystem.tileItemIdsString()
	return table.concat(BossSystem.TILE_ITEM_IDS, ", ")
end

function BossSystem.ensureLoaded()
	if BossSystem.loaded then
		return true
	end
	if type(BossConfig) ~= "table" or type(BossConfig.monsters) ~= "table" then
		print("[BossSystem] ERRO: bossConfig.lua nao carregou (rode tools/generate_bosses.py)")
		return false
	end

	local missingBoss, missingItem, longKey = {}, {}, {}
	for name, cfg in pairs(BossConfig.monsters) do
		if cfg.boss and not getMonsterInfo(cfg.boss) then
			table.insert(missingBoss, cfg.boss)
		end
		if cfg.glove and not getItemInfo(cfg.glove) then
			table.insert(missingItem, tostring(cfg.glove))
		end
		if #BossSystem.storageKey(name) > BossSystem.MAX_STORAGE_KEY then
			table.insert(longKey, name)
		end
	end

	if #missingBoss > 0 then
		print("[BossSystem] ERRO: monstros ALPHA nao encontrados: " .. table.concat(missingBoss, ", "))
	end
	if #missingItem > 0 then
		print("[BossSystem] AVISO: luvas inexistentes no items.xml: " .. table.concat(missingItem, ", "))
	end
	if #longKey > 0 then
		print("[BossSystem] ERRO: nome de monstro gera storage > " .. BossSystem.MAX_STORAGE_KEY ..
			" chars: " .. table.concat(longKey, ", "))
	end

	BossSystem.loaded = true
	print("[BossSystem] pronto: " .. tostring(#BossSystem.getDailyPool()) ..
		" criaturas na task diaria, " .. tostring(BossSystem.countMonsters()) .. " bosses ALPHA.")
	return true
end

function BossSystem.countMonsters()
	local total = 0
	for _ in pairs(BossConfig.monsters) do
		total = total + 1
	end
	return total
end

function BossSystem.getConfig(monsterName)
	if not monsterName then
		return nil
	end
	return BossConfig.monsters[monsterName]
end

function BossSystem.bossFor(monsterName)
	local cfg = BossSystem.getConfig(monsterName)
	return cfg and cfg.boss or nil
end

function BossSystem.gloveFor(monsterName)
	local cfg = BossSystem.getConfig(monsterName)
	return cfg and cfg.glove or nil
end

function BossSystem.requirement(monsterName)
	local cfg = BossSystem.getConfig(monsterName)
	return cfg and cfg.kills or 250
end

-- Lista de criaturas que podem cair no sorteio da task diaria
function BossSystem.getDailyPool()
	local pool = {}
	if type(BossConfig) ~= "table" or type(BossConfig.monsters) ~= "table" then
		return pool
	end
	for name, cfg in pairs(BossConfig.monsters) do
		local excluded = BossConfig.dailyExcluded and BossConfig.dailyExcluded[name]
		if not excluded and (cfg.experience or 0) > 0 then
			table.insert(pool, name)
		end
	end
	table.sort(pool)
	return pool
end

function BossSystem.isBossName(name)
	return type(name) == "string" and name:upper():sub(1, #BossSystem.PREFIX) == BossSystem.PREFIX
end

-- "ALPHA Cockroach" -> "Cockroach"
function BossSystem.baseName(name)
	if not BossSystem.isBossName(name) then
		return nil
	end
	return name:sub(#BossSystem.PREFIX + 1)
end

-- =========================================================================
-- STORAGE (por jogador, some no fim do dia)
-- =========================================================================

local function sanitize(name)
	return (name:gsub("[^%w]", "_"))
end

function BossSystem.storageKey(monsterName)
	return "Boss_" .. sanitize(monsterName or "?")
end

function BossSystem.grantAccess(cid, monsterName)
	if not isPlayer(cid) or not BossSystem.getConfig(monsterName) then
		return false
	end
	setPlayerStorageValue(cid, BossSystem.storageKey(monsterName), getDayID())
	return true
end

function BossSystem.revokeAccess(cid, monsterName)
	if not isPlayer(cid) then
		return false
	end
	setPlayerStorageValue(cid, BossSystem.storageKey(monsterName), 0)
	return true
end

function BossSystem.hasAccess(cid, monsterName)
	if not isPlayer(cid) or not BossSystem.getConfig(monsterName) then
		return false
	end
	return tostring(getPlayerStorageValue(cid, BossSystem.storageKey(monsterName))) == getDayID()
end

-- Retorna a lista de monstros que o jogador liberou no dia de hoje
function BossSystem.getAccessList(cid)
	local list = {}
	if not isPlayer(cid) or type(BossConfig) ~= "table" then
		return list
	end
	local today = getDayID()
	for name in pairs(BossConfig.monsters) do
		if tostring(getPlayerStorageValue(cid, BossSystem.storageKey(name))) == today then
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

-- =========================================================================
-- SPAWN
-- =========================================================================

-- Procura criaturas proximas que o jogador tenha liberado.
-- Retorna (monstroMaisProximo, quantidadeEncontrada)
function BossSystem.findNearbyTarget(position, allowed)
	local best, bestDist, found = nil, nil, 0
	local spectators = getSpectators(position, BossSystem.SCAN_RADIUS, BossSystem.SCAN_RADIUS, false)
	if not spectators then
		return nil, 0
	end

	for _, uid in ipairs(spectators) do
		if isMonster(uid) and not isSummon(uid) and isCreature(uid) then
			local name = getCreatureName(uid)
			if name and not BossSystem.isBossName(name) and allowed[name] then
				found = found + 1
				local pos = getThingPos(uid)
				local dist = math.max(math.abs(pos.x - position.x), math.abs(pos.y - position.y))
				if not bestDist or dist < bestDist then
					best, bestDist = name, dist
				end
			end
		end
	end
	return best, found
end

function BossSystem.canSpawnAt(cid, position)
	if BossSystem.BLOCK_SAFE_ZONES then
		local info = getTileInfo(position)
		if type(info) ~= "table" then
			return false, "Você não pode invocar o boss aqui."
		end
		if info.protection then
			return false, "Não é possível invocar bosses em protection zone."
		end
		if info.house then
			return false, "Não é possível invocar bosses dentro de casas."
		end
	end

	local mine = 0
	for uid, entry in pairs(BossSystem.active) do
		if not isCreature(uid) then
			BossSystem.active[uid] = nil
		elseif entry.player == getCreatureName(cid) then
			mine = mine + 1
		end
	end

	if mine >= BossSystem.MAX_ACTIVE_PER_PLAYER then
		return false, "Você já tem um boss ALPHA ativo. Mate-o (ou espere ele desaparecer) antes de invocar outro."
	end

	return true
end

-- Cria o boss ao lado do jogador. Retorna uid ou nil + motivo.
function BossSystem.spawnFor(cid, monsterName, position)
	if not isPlayer(cid) then
		return nil, "não é jogador"
	end

	local cfg = BossSystem.getConfig(monsterName)
	if not cfg or not cfg.boss then
		return nil, "monstro sem boss configurado"
	end
	if not BossSystem.hasAccess(cid, monsterName) then
		return nil, "sem liberação para " .. monsterName
	end

	local ok, reason = BossSystem.canSpawnAt(cid, position)
	if not ok then
		return nil, reason
	end

	if not getMonsterInfo(cfg.boss) then
		print("[BossSystem] ERRO: monstro " .. cfg.boss .. " nao esta registrado em monsters.xml")
		return nil, "boss indisponível (avise a administração)"
	end

	-- extend = true -> o engine procura uma casa livre ao lado do jogador
	local uid = doCreateMonster(cfg.boss, position, true, false)
	if not uid or uid == false then
		return nil, "não havia espaço livre ao lado"
	end

	setPlayerStorageValue(cid, "Boss_Cooldown", os.time())
	BossSystem.revokeAccess(cid, monsterName)
	BossSystem.active[uid] = {
		player = getCreatureName(cid),
		monster = monsterName,
		boss = cfg.boss,
		time = os.time() * 1000,
	}

	doSendMagicEffect(position, 77)
	doSendMagicEffect(position, 30)
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
		cfg.boss .. " apareceu! Derrote-o para tentar a luva (4%).")
	print("[BossSystem] " .. getCreatureName(cid) .. " invocou " .. cfg.boss .. " em " .. tostring(position.x) .. "," .. tostring(position.y) .. "," .. tostring(position.z))
	return uid
end

-- =========================================================================
-- TILE DE PORTAL
-- =========================================================================

function BossSystem.onStepPortal(cid, position)
	if not isPlayer(cid) then
		return
	end
	if not BossSystem.ensureLoaded() then
		return
	end

	-- anti-spam: o jogador pode pisar no tile varias vezes por segundo
	local now = os.time()
	local last = tonumber(getPlayerStorageValue(cid, "Boss_Cooldown")) or 0
	if last > 0 and (now - last) < BossSystem.COOLDOWN then
		return
	end
	setPlayerStorageValue(cid, "Boss_Cooldown", now)

	local list = BossSystem.getAccessList(cid)
	if #list == 0 then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Você não tem nenhum boss liberado. Complete uma task diária para liberar o portal.")
		return
	end

	-- mapa nome -> true para a busca pelos espectadores
	local allowed = {}
	for _, name in ipairs(list) do
		allowed[name] = true
	end

	local target, found = BossSystem.findNearbyTarget(position, allowed)
	if not target and BossSystem.FALLBACK_SINGLE and #list == 1 then
		target = list[1]
		found = 0
	end

	if not target then
		if #list == 1 then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
				"Não há " .. list[1] .. " por perto. Vá até a área da criatura e pise neste tile.")
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
				"Você tem " .. #list .. " bosses liberados, mas nenhuma dessas criaturas está por perto.")
		end
		return
	end

	local uid, reason = BossSystem.spawnFor(cid, target, position)
	if not uid then
		if reason then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, reason)
		end
		return
	end
end

-- =========================================================================
-- MANUTENCAO
-- =========================================================================

function BossSystem.onBossKilled(uid)
	local entry = BossSystem.active[uid]
	if entry then
		BossSystem.active[uid] = nil
		return entry
	end
	return nil
end

-- Chamado pelo globalevent (data/globalevents/scripts/bossSystem.lua)
function BossSystem.onThink(interval)
	for uid, entry in pairs(BossSystem.active) do
		local dead = not isCreature(uid)
		if not dead then
			-- protecao contra uid reciclado: o nome precisa continuar batendo
			local name = getCreatureName(uid)
			if not BossSystem.isBossName(name or "") then
				dead = true
			end
		end

		if dead then
			BossSystem.active[uid] = nil
		else
			local owner = getCreatureByName(entry.player)
			local expired = entry.time and (os.time() * 1000 - entry.time) > BossSystem.LIFETIME
			if not owner or not isPlayer(owner) then
				doRemoveCreature(uid)
				BossSystem.active[uid] = nil
			elseif expired then
				doRemoveCreature(uid)
				doPlayerSendTextMessage(owner, MESSAGE_STATUS_CONSOLE_BLUE,
					entry.boss .. " desapareceu (tempo esgotado).")
				BossSystem.active[uid] = nil
			end
		end
	end
	return true
end
