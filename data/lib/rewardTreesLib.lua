-- ============================================================================
--  ARVORES DE RECOMPENSA  (tronco brilhante)
-- ============================================================================
--  Algumas arvores do mapa viram um tronco brilhante com recompensa dentro.
--
--  Quem entrega as posicoes e' o proprio servidor, que registra as arvores
--  enquanto carrega o mapa (sources/rewardtrees.h + getRewardTreeCandidates()).
--  Vale pro mapa INTEIRO, ja' funciona no primeiro boot e continua certo
--  depois de qualquer edicao no .otbm - sem gerador, sem arquivo gerado.
--
--  TODA a configuracao fica no config.lua (chaves rewardTree...).
--
--  ATENCAO (leia antes de mexer): no servidor cada interface de script tem seu
--  proprio estado Lua, e este arquivo e' carregado em TODAS elas (lib/ e' lida
--  por interface, em luascript.cpp:initState). Ou seja: existe uma copia desta
--  lib no estado das ACTIONS e outra no estado das GLOBALE VENTS. Por isso:
--
--    - o sorteio do boot (seed) e o tick rodam no estado das globalevents e
--      guardam o estoque de troncos nas tabelas locais DAQUELE estado;
--    - o use do player roda no estado das actions e NAO enxerga esse estoque.
--      Ele nao precisa: o id do tronco ja' diz qual e' a recompensa (tabela
--      montada no carregamento da lib). Quem percebe que o tronco sumiu do mapa
--      e' o tick, que devolve a arvore original quando nao tem ninguem perto.
--
--  Cuidado ao adicionar qualquer coisa aqui: estado Lua (tabelas) NAO passa de
--  uma interface pra outra. So' passa o que esta' no C++ (ou no banco). Se
--  precisar que o onUse saiba de algo combinado no boot, guarde essa informacao
--  no C++ (sources/rewardtrees.h) ou em storage - nunca numa tabela Lua local.
-- ============================================================================

rewardTrees = rewardTrees or {}

-- O srand() do servidor semeia o rand() do C, mas o math.random do Lua tem
-- PRNG proprio e comeca sempre do mesmo ponto. Sem isto, todo boot sorteia a
-- mesma sequencia - ou seja, os mesmos troncos nos mesmos lugares.
math.randomseed(os.time())

-- Padroes usados quando a chave correspondente nao existe no config.lua.
local DEFAULTS = {
	chance        = 250,   -- (rewardTreeChance)        1 em cada N arvores vira tronco
	crystalChance = 300,   -- (rewardTreeCrystalChance) 1 em N troncos e' o de crystal coin
	respawnRadius = 12,    -- (rewardTreeRespawnRadius) tiles sem player pra arvore voltar
	minDistance   = 0,     -- (rewardTreeMinDistance)   distancia minima entre troncos (0 = desligado)
	maintain      = true,  -- (rewardTreeMaintain)      repoe troncos com o tempo
	refillSeconds = 600,   -- (rewardTreeRefillSeconds) intervalo da reposicao (segundos)
	reroll        = false, -- (rewardTreeReroll)        a arvore volta original
	effect        = 60,    -- (rewardTreeEffect)        efeito de magia (0 = nenhum)
	sendText      = false, -- (rewardTreeSendText)      mensagem pro player (silencioso)
	verbose       = false, -- (rewardTreeVerbose)       prints no console do server
}

local function configValue(key, default)
	if type(getConfigValue) ~= "function" then
		return default
	end

	local value = getConfigValue(key)
	if value == nil then
		return default
	end
	return value
end

local CONFIG = {
	chance        = configValue("rewardTreeChance", DEFAULTS.chance),
	crystalChance = configValue("rewardTreeCrystalChance", DEFAULTS.crystalChance),
	respawnRadius = configValue("rewardTreeRespawnRadius", DEFAULTS.respawnRadius),
	minDistance   = configValue("rewardTreeMinDistance", DEFAULTS.minDistance),
	maintain      = configValue("rewardTreeMaintain", DEFAULTS.maintain),
	refillSeconds = configValue("rewardTreeRefillSeconds", DEFAULTS.refillSeconds),
	reroll        = configValue("rewardTreeReroll", DEFAULTS.reroll),
	effect        = configValue("rewardTreeEffect", DEFAULTS.effect),
	sendText      = configValue("rewardTreeSendText", DEFAULTS.sendText),
	verbose       = configValue("rewardTreeVerbose", DEFAULTS.verbose),
}

-- Troncos de recompensa: trunk = id do tronco, item = o que sai de dentro.
-- min/max = quantidade sorteada.
local REWARDS = {
	{trunk = 19251, item = 15014, min = 10, max = 20, label = "10-20 ultimate health potions"},
	{trunk = 19250, item = 2152,  min = 10, max = 15, label = "10-15 platinum coins"},
	{trunk = 19249, item = 7590,  min = 20, max = 30, label = "20-30 great mana potions"},
}

local CRYSTAL = {trunk = 19248, item = 2160, min = 1, max = 1, label = "1 crystal coin"}

-- id do tronco -> recompensa. Montado aqui no carregamento (nao no seed), pra
-- valer tambem no estado do onUse, que nunca roda o seed.
local trunkId = {}
for i = 1, #REWARDS do
	trunkId[REWARDS[i].trunk] = REWARDS[i]
end
trunkId[CRYSTAL.trunk] = CRYSTAL

-- ============================================================================
--  ESTADO DO BOOT/TICK (estado das globalevents - ver o aviso no topo)
-- ============================================================================
local candidates = {} -- arvores do mapa (vem da source, ver seed())
local active = {}     -- [chave] = {pos, originalId, reward}  troncos no mapa
local pending = {}    -- [chave] = {pos, originalId, usedAt}   troncos ja' usados
local targetCount = 0
local lastRefill = 0
local ready = false

local function posKey(pos)
	return pos.x .. ":" .. pos.y .. ":" .. pos.z
end

local function isItemValid(thing)
	return thing and thing.uid and thing.uid > 0
end

local function randomRange(min, max)
	if not max or max <= min then
		return min
	end
	return math.random(min, max)
end

-- quantos players existem no raio configurado
function rewardTrees.playersAround(pos)
	local spectators = getSpectators(pos, CONFIG.respawnRadius, CONFIG.respawnRadius, false)
	if not spectators then
		return 0
	end

	local count = 0
	for i = 1, #spectators do
		if isPlayer(spectators[i]) then
			count = count + 1
		end
	end
	return count
end

-- true se nao tem nenhum tronco ativo dentro do raio minimo configurado.
-- Compara so' o mesmo andar (z) e usa distancia em tiles (nao em quadrado).
function rewardTrees.isFarFromTrunks(pos)
	local minDistance = CONFIG.minDistance
	if not minDistance or minDistance <= 0 then
		return true
	end

	local minSq = minDistance * minDistance
	for _, entry in pairs(active) do
		if entry.pos.z == pos.z then
			local dx = entry.pos.x - pos.x
			local dy = entry.pos.y - pos.y
			if dx * dx + dy * dy < minSq then
				return false
			end
		end
	end
	return true
end

-- escolhe o tipo de recompensa (a de crystal coin e' a rara)
function rewardTrees.pickReward()
	if CONFIG.crystalChance > 0 and math.random(CONFIG.crystalChance) == 1 then
		return CRYSTAL
	end
	return REWARDS[math.random(#REWARDS)]
end

-- transforma a arvore que esta em pos no tronco da recompensa
local function makeRewardTree(pos, originalId, reward)
	local tree = getTileItemById(pos, originalId)
	if not isItemValid(tree) then
		return false
	end

	if not doTransformItem(tree.uid, reward.trunk) then
		return false
	end

	-- confere se o tronco ficou mesmo no tile antes de registrar: um tronco que
	-- nao esta' la' seria invisivel pro player e nunca voltaria a ser arvore
	if not isItemValid(getTileItemById(pos, reward.trunk)) then
		doTransformItem(tree.uid, originalId)
		return false
	end

	active[posKey(pos)] = {pos = {x = pos.x, y = pos.y, z = pos.z}, originalId = originalId, reward = reward}
	if CONFIG.effect ~= 0 then
		doSendMagicEffect(pos, CONFIG.effect)
	end
	return true
end

-- ============================================================================
--  1) BOOT: sorteia o mapa inteiro (posicoes vindas da propria source)
-- ============================================================================
function rewardTrees.seed()
	if type(getRewardTreeCandidates) ~= "function" then
		print("[RewardTrees] ERRO: getRewardTreeCandidates() nao existe nesta source.")
		print("[RewardTrees] Compile o server com sources/rewardtrees.h + luascript atualizado.")
		return
	end

	candidates = getRewardTreeCandidates() or {}
	if #candidates == 0 then
		print("[RewardTrees] AVISO: nenhuma arvore de recompensa encontrada no mapa.")
		return
	end

	active = {}
	pending = {}

	-- 1) quais candidatas ainda sao arvore de verdade no mapa (item dentro de
	-- container, arvore trocada pelo mapper e casos do tipo ficam fora)
	local valid = {}
	for i = 1, #candidates do
		local entry = candidates[i]
		if isItemValid(getTileItemById({x = entry.x, y = entry.y, z = entry.z}, entry.id)) then
			valid[#valid + 1] = entry
		end
	end

	local found = #valid
	if found == 0 then
		print("[RewardTrees] AVISO: nenhuma arvore candidata valida no mapa.")
		return
	end

	-- meta: 1 em cada CONFIG.chance arvores. Com distancia minima ligada pode
	-- ser que o mapa nao comporte a meta; a linha do boot mostra meta x criados.
	targetCount = math.max(1, math.floor(found / CONFIG.chance))

	-- 2) embaralha: sem isso a ordem do mapa (area por area, de cima pra baixo)
	-- decide quais arvores viram tronco e eles ficariam todos no comeco do mapa
	for i = #valid, 2, -1 do
		local j = math.random(i)
		valid[i], valid[j] = valid[j], valid[i]
	end

	-- 3) escolhe ate' a meta, respeitando a distancia minima entre troncos
	local created, crystals = 0, 0
	for i = 1, #valid do
		if created >= targetCount then
			break
		end

		local entry = valid[i]
		local pos = {x = entry.x, y = entry.y, z = entry.z}
		if rewardTrees.isFarFromTrunks(pos) then
			local reward = rewardTrees.pickReward()
			if makeRewardTree(pos, entry.id, reward) then
				created = created + 1
				if reward == CRYSTAL then
					crystals = crystals + 1
				end
			end
		end
	end

	lastRefill = os.time()
	ready = true

	print(string.format("[RewardTrees] mapa: %d arvores candidatas | %d confirmadas | %d troncos criados (%d crystal) | meta: %d | distancia minima: %d",
		#candidates, found, created, crystals, targetCount, CONFIG.minDistance))
end

-- ============================================================================
--  2) USE: entrega a recompensa e some com o tronco
-- ============================================================================
--  Roda no estado das ACTIONS (onUse), que nao tem o estoque do boot. Por isso
--  aqui nao se usa active/pending: a recompensa sai do proprio id do tronco
--  (tabela montada no carregamento da lib, em todos os estados). A volta da
--  arvore original fica com o tick, que ve o tronco sumir do mapa.
function rewardTrees.use(cid, item, fromPosition)
	local reward = trunkId[item.itemid]
	if not reward then
		return false
	end

	local count = randomRange(reward.min, reward.max)

	-- recompensa primeiro: se algo falhar aqui a arvore continua no mapa.
	-- doPlayerAddItem cai no chao sozinho se a mochila estiver cheia.
	doPlayerAddItem(cid, reward.item, count)

	if CONFIG.effect ~= 0 then
		doSendMagicEffect(fromPosition, CONFIG.effect)
	end
	if CONFIG.sendText then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Voce encontrou " .. reward.label .. " dentro do tronco!")
	end

	doRemoveItem(item.uid)
	return true
end

-- ============================================================================
--  3) TICK: ve os troncos usados, devolve a arvore original e repoe o estoque
-- ============================================================================
function rewardTrees.tick()
	if not ready then
		return
	end

	-- tronco que sumiu do mapa = player abriu. O use roda em outro estado Lua,
	-- entao o proprio tick detecta a ausencia e agenda a volta da arvore.
	for key, entry in pairs(active) do
		if not isItemValid(getTileItemById(entry.pos, entry.reward.trunk)) then
			active[key] = nil
			pending[key] = {
				pos = {x = entry.pos.x, y = entry.pos.y, z = entry.pos.z},
				originalId = entry.originalId,
				usedAt = os.time(),
			}
		end
	end

	-- devolve as arvores usadas quando ninguem esta' por perto
	for key, entry in pairs(pending) do
		if (entry.retryAt or 0) <= os.time() and rewardTrees.playersAround(entry.pos) == 0 then
			local created = doCreateItem(entry.originalId, 1, entry.pos)
			if created then
				pending[key] = nil

				if CONFIG.effect ~= 0 then
					doSendMagicEffect(entry.pos, CONFIG.effect)
				end

				-- desligado por padrao: a arvore volta como esta' no mapa original
				if CONFIG.reroll and math.random(CONFIG.chance) == 1 then
					makeRewardTree(entry.pos, entry.originalId, rewardTrees.pickReward())
				end
			else
				-- tile ocupado/bloqueado: antes o pendente era apagado do mesmo
				-- jeito, entao aquela arvore sumia do mapa pra sempre. Agora fica
				-- tentando de novo, com espera crescente.
				entry.fails = (entry.fails or 0) + 1
				local wait = math.min(120, 5 * entry.fails)
				entry.retryAt = os.time() + wait

				if CONFIG.verbose then
					print(string.format("[RewardTrees] nao deu pra devolver a arvore em %d,%d,%d (tentativa %d), nova tentativa em %ds",
						entry.pos.x, entry.pos.y, entry.pos.z, entry.fails, wait))
				end
			end
		end
	end

	-- repoe o estoque: sem isso o sistema morre depois que o mapa for explorado
	if CONFIG.maintain and os.time() - lastRefill >= CONFIG.refillSeconds then
		lastRefill = os.time()
		local count = 0
		for _ in pairs(active) do
			count = count + 1
		end

		if count < targetCount and #candidates > 0 then
			-- tenta algumas posicoes ate' achar uma arvore livre E sem player perto
			-- (a reposta nao pode aparecer na cara de quem esta' olhando o tile)
			for _ = 1, 60 do
				local entry = candidates[math.random(#candidates)]
				local pos = {x = entry.x, y = entry.y, z = entry.z}
				local key = posKey(pos)

				if not active[key] and not pending[key] and rewardTrees.playersAround(pos) == 0
					and rewardTrees.isFarFromTrunks(pos) then
					-- so usa se ainda for uma arvore normal no mapa
					if isItemValid(getTileItemById(pos, entry.id)) then
						local reward = rewardTrees.pickReward()
						if makeRewardTree(pos, entry.id, reward) then
							if CONFIG.verbose then
								print(string.format("[RewardTrees] reposta uma arvore de recompensa em %d,%d,%d (%s)",
									pos.x, pos.y, pos.z, reward.label))
							end
						end
						break
					end
				end
			end
		end
	end
end

-- usado pelo script da action/futuras ferramentas
function rewardTrees.isRewardTrunk(itemId)
	return trunkId[itemId] ~= nil
end

function rewardTrees.getConfig()
	return CONFIG
end
