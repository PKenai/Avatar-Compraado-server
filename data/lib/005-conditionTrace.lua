-- ============================================================================
-- CONDITION TRACE (Lua) - de onde vem a paralisia, no lado dos scripts
-- ----------------------------------------------------------------------------
-- Par do [COND-TRACE] do C++ (config.lua / conditionTrace, ver
-- Creature::traceConditionOrigin em sources/creature.cpp): o C++ diz que veio
-- de Lua (LuaInterface::luaDoAddCondition), este arquivo diz de QUAL SCRIPT.
--
-- ---------------------------------------------------------------------------
-- POR QUE ISSO E' NECESSARIO (o problema de fundo, luascript.cpp)
-- ---------------------------------------------------------------------------
-- Existem DOIS mapas de conditions no Lua e cada um tem seu proprio contador:
--
--   m_conditionMap     -> o que o script cria na CARGA (addConditionObject)
--   m_tempConditionMap -> o que o script cria em TEMPO DE JOGO (addTemp...)
--
-- createConditionObject decide o mapa pelo momento. Mas doAddCondition,
-- setConditionParam e setConditionFormula tem o parametro `loaded` com padrao
-- true, ou seja: procuram SÓ no mapa de CARGA (getConditionObject(id, loaded)).
--
-- Resultado: um script que cria a condition em tempo de jogo (uid 3, digamos)
-- e chama doAddCondition(cid, uid) sem o terceiro argumento NAO acha a propria
-- condition - o motor pega a condition de CARGA de uid 3, que e' outra coisa.
-- Como os dois contadores comecam do zero, isso colide sempre.
--
-- E tem uma vitima pronta no projeto: data/lib/050-function.lua:1566 cria
-- `paralyzeCondition` na carga - CONDITION_PARALYZE, formula [-0.9,0,-0.9,0],
-- que derruba a speed para 10% da base. O doAddCondition dela esta comentado,
-- ninguem aplica de proposito; ela vira paralisia por acidente quando o uid
-- dela e' o que o script passou.
--
-- ---------------------------------------------------------------------------
-- O QUE ESTE ARQUIVO IMPRIME
-- ---------------------------------------------------------------------------
--   [COND-TRACE-LUA] ... doAddCondition resolveu para PARALYZE      -> o dedo
--   [COND-TRACE-LUA] ... COLISAO DE UID: uid N tem 2 conditions     -> a causa
--
-- Nos dois casos sai o traceback (arquivo:linha) de quem chamou. Os wrappers
-- sao pass-through - os argumentos originais vao intactos para a funcao do
-- motor (inclusive a contagem de argumentos, que muda o comportamento).
--
-- DESLIGUE (false) quando terminar o diagnostico.
-- Nome 005-* de proposito: precisa carregar ANTES dos outros arquivos de lib
-- para registrar as conditions que eles criam na carga (ex: 050-function.lua).
-- ============================================================================

COND_TRACE_LUA = true

if COND_TRACE_LUA and type(createConditionObject) == "function" and type(doAddCondition) == "function" then
	local rawCreateConditionObject = createConditionObject
	local rawDoAddCondition = doAddCondition
	local rawSetConditionParam = setConditionParam
	local rawSetConditionFormula = setConditionFormula

	-- [uid] = tipo da PRIMEIRA criacao (a da carga: e' a que o motor acha com
	-- loaded=true) / [uid] = tipo da ULTIMA criacao (a de tempo de jogo).
	local uidLoadType, uidLastType, uidCount = {}, {}, {}

	local function tracebackLine(level)
		if type(debug) == "table" and type(debug.traceback) == "function" then
			return "\n" .. debug.traceback("", level)
		end
		return ""
	end

	local function uidDescription(uid)
		local loadType = uidLoadType[uid]
		local lastType = uidLastType[uid]
		return "uid=" .. tostring(uid) ..
			" criado " .. tostring(uidCount[uid] or 0) .. "x" ..
			" | de carga=" .. tostring(loadType) ..
			" | ultimo=" .. tostring(lastType) ..
			" | vai resolver para=" .. tostring(loadType ~= nil and loadType or lastType)
	end

	function createConditionObject(conditionType, ...)
		local uid = rawCreateConditionObject(conditionType, ...)
		if type(uid) == "number" then
			uidCount[uid] = (uidCount[uid] or 0) + 1
			if uidLoadType[uid] == nil then
				uidLoadType[uid] = conditionType
			end
			uidLastType[uid] = conditionType
		end
		return uid
	end

	function doAddCondition(...)
		local amount = select("#", ...)
		local cid, condition, loaded = ...

		if COND_TRACE_LUA and type(condition) == "number" and isPlayer(cid) then
			-- Com o padrao do motor (loaded=true) ele procura no mapa de CARGA;
			-- so' com o terceiro argumento = false ele olha o de tempo de jogo.
			local useLoadMap = (loaded ~= false)
			local resolved = useLoadMap and uidLoadType[condition] or uidLastType[condition]
			local collision = (uidCount[condition] or 0) > 1
			if resolved == CONDITION_PARALYZE or collision then
				local header
				if resolved == CONDITION_PARALYZE then
					header = "[COND-TRACE-LUA] " .. tostring(getCreatureName(cid)) .. " RECEBEU PARALYZE de doAddCondition"
				else
					header = "[COND-TRACE-LUA] " .. tostring(getCreatureName(cid)) .. " COLISAO DE UID em doAddCondition"
				end

				print(header ..
					"\n    " .. uidDescription(condition) ..
					"\n    mapa usado pelo motor: " .. (useLoadMap and "CARGA (padrao do motor)" or "runtime (temp)") ..
					"\n    tipo pedido pelo script=" .. tostring(uidLastType[condition]) ..
					" | tipo que o motor vai aplicar=" .. tostring(resolved) ..
					"\n    chamado de:" .. tracebackLine(4))
			end
		end

		return rawDoAddCondition(...)
	end

	-- setConditionParam/setConditionFormula sofrem do mesmo padrao `loaded=true`:
	-- um script que configura uma condition criada em tempo de jogo acaba mexendo
	-- na condition de CARGA de mesmo uid (e' assim que a paralyzeCondition de
	-- 050-function.lua fica com ticks=-1, por exemplo).
	local function checkCollision(api, ...)
		local amount = select("#", ...)
		local uid = select(1, ...)
		if amount >= 3 and type(uid) == "number" and (uidCount[uid] or 0) > 1 then
			local loaded = select(amount, ...)
			if loaded ~= false then
				print("[COND-TRACE-LUA] " .. api .. " em uid com COLISAO (vai mexer na condition de CARGA)" ..
					"\n    " .. uidDescription(uid) ..
					"\n    chamado de:" .. tracebackLine(5))
			end
		end
	end

	if type(rawSetConditionParam) == "function" then
		function setConditionParam(...)
			checkCollision("setConditionParam", ...)
			return rawSetConditionParam(...)
		end
	end

	if type(rawSetConditionFormula) == "function" then
		function setConditionFormula(...)
			checkCollision("setConditionFormula", ...)
			return rawSetConditionFormula(...)
		end
	end
end
