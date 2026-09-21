-- ============================================================================
-- PLAYER SPEED - dono unico da velocidade (varSpeed) dos players
-- ----------------------------------------------------------------------------
-- Neste fork: Creature::getSpeed() = baseSpeed + varSpeed e
-- Game::changeSpeed(creature, delta) faz varSpeed += delta (ADITIVO).
--
-- Ou seja, TODO mundo escreve no MESMO acumulador: talentos, agilidade,
-- montaria, bomberman, conditions de haste/paralise e slows temporarios de
-- spell. Quem "define" a velocidade em vez de somar apenas o proprio pedaco
-- transforma o delta dos outros em lixo. Casos reais que isso causava:
--
--   * montaria: o codigo forcava varSpeed = vddSpeed (apagava talento e
--     agilidade). Ao desmontar, tirava vddSpeed de novo -> o personagem ficava
--     MAIS LENTO que a base e o servidor cancela a walk (nao anda mais);
--   * haste + rebuild de velocidade: o rebuild zerava o +delta do condition e,
--     quando a haste terminava, o engine subtraia aquele delta de novo ->
--     speed negativa permanente;
--   * doSlow devolvia a velocidade num addEvent: se o restore se perdia, o
--     personagem ficava lento ate' o proximo relog;
--   * bomberman: somava o valor salvo pra "sair" da partida -> speed inflando
--     a cada partida.
--
-- Modelo aqui:
--   setSource(cid, nome, valor)  -> cada fonte com valor conhecido (talento,
--                                   agilidade, montaria, bomberman) guarda o
--                                   SEU valor e o sistema aplica so' a diferenca;
--   tempSlow(cid, valor, tempo)  -> efeito temporario com devolucao garantida
--                                   (addEvent + varredura periodica), idempotente;
--   sweep(cid) / audit(cid)      -> rede de seguranca: roda em onThink, devolve
--                                   slows vencidos e conserta (com log) a speed
--                                   que caiu abaixo do esperado sem paralisia
--                                   nenhuma ativa - que e' corrupcao.
--
-- Invariante que este arquivo garante: a velocidade total NUNCA chega a 0
-- (speed <= 0 faz o servidor cancelar a walk: o personagem para de andar).
-- ============================================================================

PlayerSpeed = {}

-- Ligar/desligar o auto-conserto de velocidade corrompida (liga por default:
-- o conserto e' conservador - so' age quando nenhuma paralisia/haste/slow
-- conhecido justifica estar abaixo da base).
PlayerSpeed.AUDIT_ENABLED = true

local sources = {}  -- [cid] = { [nome da fonte] = valor }
local temps = {}    -- [cid] = { [id] = { amount = n, untilTime = ms, done = bool } }
local tempSeq = 0

local function conditionValue(name)
	local value = rawget(_G, name)
	if type(value) == "number" then
		return value
	end
	return nil
end

local function sumSources(cid)
	local list = sources[cid]
	if not list then
		return 0
	end

	local total = 0
	for _, value in pairs(list) do
		total = total + value
	end
	return total
end

-- Unico ponto do sistema que mexe na velocidade do player.
function PlayerSpeed.apply(cid, delta)
	if not isPlayer(cid) then
		return false
	end

	delta = math.floor(tonumber(delta) or 0)
	if delta == 0 then
		return false
	end

	local current = getCreatureSpeed(cid)
	if current + delta <= 0 then
		-- speed <= 0 faz o servidor cancelar a walk (paralisia real). Piso = 1.
		delta = 1 - current
	end

	if delta == 0 then
		return false
	end

	doChangeSpeed(cid, delta)
	return true
end

-- Fonte com valor proprio. Aplica SO' a diferenca em relacao ao ultimo valor
-- desta fonte - nunca sobrescreve o acumulador. Idempotente.
function PlayerSpeed.setSource(cid, name, value)
	if not isPlayer(cid) or type(name) ~= "string" then
		return false
	end

	value = math.floor(tonumber(value) or 0)
	if value < 0 then
		value = 0
	end

	sources[cid] = sources[cid] or {}
	local previous = sources[cid][name] or 0
	if previous == value then
		return false
	end

	sources[cid][name] = value
	PlayerSpeed.apply(cid, value - previous)
	return true
end

function PlayerSpeed.getSource(cid, name)
	local list = sources[cid]
	return (list and list[name]) or 0
end

-- Soma do que este sistema ja' colocou no varSpeed (usado pelo audit/relatorio).
function PlayerSpeed.getApplied(cid)
	return sumSources(cid)
end

-- Objeto NOVO de player (login de verdade): o varSpeed nasce zerado, entao a
-- contabilidade da sessao anterior nao vale mais. No relogin o objeto e' o
-- MESMO e este reset NAO pode ser chamado.
function PlayerSpeed.resetTracking(cid)
	sources[cid] = nil
	temps[cid] = nil
end

-- Fontes que vivem em storage: agilidade (points*) e montaria (bonusMount).
-- Seguro chamar em qualquer momento (idempotente).
function PlayerSpeed.refreshFromStorages(cid)
	if not isPlayer(cid) then
		return
	end

	-- tonumber: storage com chave string volta como string depois do relog. Sem
	-- a conversao o teste "type(agi) ~= number" descartava o valor e a agilidade
	-- (e o bonus de montaria) sumiam da velocidade a cada login.
	local agi = tonumber(getPlayerStorageValue(cid, "getPointsInDodge")) or 0
	if agi < 0 then
		agi = 0
	end
	PlayerSpeed.setSource(cid, "agi", agi * 6)

	local mount = 0
	if getPlayerStorageValue(cid, "inMount") == 1 then
		local bonus = tonumber(getPlayerStorageValue(cid, "bonusMount")) or 0
		if bonus > 0 then
			mount = bonus
		end
	end
	PlayerSpeed.setSource(cid, "mount", mount)
end

-- ============================================================================
-- EFEITOS TEMPORARIOS (slows) - devolucao garantida
-- ============================================================================

function PlayerSpeed.tempSlow(cid, amount, timeMs)
	if not isPlayer(cid) then
		return false
	end

	amount = math.floor(tonumber(amount) or 0)
	timeMs = math.floor(tonumber(timeMs) or 0)
	if amount <= 0 or timeMs <= 0 then
		return false
	end

	local current = getCreatureSpeed(cid)
	if current - amount < 1 then
		amount = current - 1
	end
	if amount <= 0 then
		return false
	end

	tempSeq = tempSeq + 1
	local id = tempSeq

	temps[cid] = temps[cid] or {}
	temps[cid][id] = { amount = amount, untilTime = os.mtime() + timeMs, done = false }

	PlayerSpeed.apply(cid, -amount)

	-- Caminho normal: devolve no prazo. A varredura (sweep) existe pra caso
	-- este evento se perca (exception, reload de script, etc).
	addEvent(function() PlayerSpeed.releaseTemp(cid, id) end, timeMs)
	return true
end

function PlayerSpeed.releaseTemp(cid, id)
	local list = temps[cid]
	local entry = list and list[id]
	if not entry or entry.done then
		return false
	end

	entry.done = true
	list[id] = nil
	if next(list) == nil then
		temps[cid] = nil
	end

	PlayerSpeed.apply(cid, entry.amount)
	return true
end

-- Devolve todo slow temporario que passou do prazo (rede de seguranca).
-- Cada entrada sai da tabela no proprio release, entao a lista nao cresce: uma
-- entrada vive no maximo a duracao do slow + ate' a proxima varredura.
function PlayerSpeed.sweep()
	local now = os.mtime()

	for cid, list in pairs(temps) do
		for id, entry in pairs(list) do
			if entry.untilTime <= now then
				-- apply() checa isPlayer: dono offline nao recebe nada (o varSpeed
				-- dele morreu com o objeto) e a entrada e' descartada.
				PlayerSpeed.releaseTemp(cid, id)
			end
		end
	end
end

-- ============================================================================
-- AUDITORIA (auto-conserto)
-- ----------------------------------------------------------------------------
-- Sem paralisia (CONDITION_PARALYZE), sem haste (CONDITION_HASTE - o fork usa
-- esse tipo tambem pra slows, ex: imuneable/drown) e sem slow temporario
-- pendente, o player NAO pode estar abaixo de base + o que este sistema
-- aplicou. Se estiver, alguem escreveu no acumulador e perdeu a devolucao.
-- ============================================================================

function PlayerSpeed.audit(cid)
	if not PlayerSpeed.AUDIT_ENABLED or not isPlayer(cid) then
		return false
	end

	local paralyze = conditionValue("CONDITION_PARALYZE")
	if paralyze and getCreatureCondition(cid, paralyze) then
		return false
	end

	local haste = conditionValue("CONDITION_HASTE")
	if haste and getCreatureCondition(cid, haste) then
		return false
	end

	if temps[cid] and next(temps[cid]) ~= nil then
		return false
	end

	local expected = getCreatureBaseSpeed(cid) + sumSources(cid)
	local current = getCreatureSpeed(cid)
	if current >= expected then
		return false
	end

	local lost = expected - current
	print(string.format(
		"[PlayerSpeed] %s estava %d abaixo do esperado (speed %d, esperado %d). Corrigindo.",
		tostring(getCreatureName(cid)), lost, current, expected))

	PlayerSpeed.apply(cid, lost)
	return true
end

-- Relatorio pra debug/console: de onde vem a velocidade do player agora.
function PlayerSpeed.report(cid)
	if not isPlayer(cid) then
		return nil
	end

	local parts = {}
	local list = sources[cid]
	if list then
		for name, value in pairs(list) do
			parts[#parts + 1] = name .. "=" .. tostring(value)
		end
	end

	return string.format("speed=%d base=%d fontes={%s} aplicado=%d",
		getCreatureSpeed(cid), getCreatureBaseSpeed(cid),
		(#parts > 0 and table.concat(parts, ", ") or "nenhuma"), sumSources(cid))
end
