-- ============================================================================
-- DANO DAS DOBRAS - modelo do servidor de referencia (raava ot wind)
--
-- A hierarquia de dano NAO e' decidida aqui: cada magia carrega a propria
-- formula e o proprio `atk` (data/lib/201-spellsExausted.lua), exatamente como
-- no servidor de referencia. Estas duas funcoes so' aplicam os modificadores de
-- PERSONAGEM em cima do dano que a magia ja' calculou:
--
--   * reset 750+      : +15%
--   * debuff de jump  : reduz o dano pelo valor do debuff (exhaustion)
--   * orbita/cometa   : fogo (1) +20% / agua (2) +20% / eclipse (3) -20%
--   * item 90526i1    : +5%
--   * skull vermelha  : dano /4
--   * talento Bend    : +talentBendDmgBonus % (arvore de talentos do servidor
--                       atual; e' a UNICA diferenca proposital em relacao ao
--                       referencia, ver AUDITORIA_BALANCEAMENTO.md secao 18)
--
-- O modelo antigo (SPELL_BALANCE por elemento, curva de level, bend com
-- retorno decrescente, SPELL_BALANCE_GLOBAL_MULT e o eco do estagio ELITE) foi
-- REMOVIDO. Nao reintroduza um fator global aqui: o alvo e' o numero do
-- servidor de referencia.
-- ============================================================================

-- Ar e terra compartilham esta funcao
function remakeAirEarth(cid, value)
	if cid and isCreature(cid) and getPlayerResets(cid) >= 750 then
		value = value * 1.15
	end
	if cid and isCreature(cid) then
		local talentBonus = getPlayerStorageValue(cid, "talentBendDmgBonus")
		if type(talentBonus) == "number" and talentBonus > 0 then
			value = value * (1 + (talentBonus / 100))
		end
	end
	return value
end

function remakeValue(vocation, value, cid)
	if cid and isCreature(cid) and getPlayerResets(cid) >= 750 then
		value = value * 1.15
	end
	if cid and isCreature(cid) and type(getPlayerStorageValue(cid, "jumpdebuff")) == "number" and exhaustion.check(cid, "jumpdebuff") and type(getPlayerStorageValue(cid, "debuffValue")) == "number" and getPlayerStorageValue(cid, "debuffValue") > 0 then
		value = value*((100-getPlayerStorageValue(cid, "debuffValue"))*0.01)
	end
	if cid and isCreature(cid) then
		local talentBonus = getPlayerStorageValue(cid, "talentBendDmgBonus")
		if type(talentBonus) == "number" and talentBonus > 0 then
			value = value * (1 + (talentBonus / 100))
		end
	end
	local orbita = getStorage(57302)
	if orbita == 1 and vocation == 1 then
		value = value * 1.2
	elseif orbita == 2 and vocation == 2 then
		value = value * 1.2
	elseif orbita == 3 then
		value = value * 0.8
	end
	if getPlayerStorageValue(cid, "90526i1") == 1 then
		value = value * 1.05
	end
	if (getCreatureSkullType(cid) == SKULL_RED) then
		value = value/4
	end
	return value
end

function tryEclipse()
	-- aqui se encerra o passado e nao rola um novo no caso
	if getStorage(57302) > 0 then
		local ultimo = getStorage(57302)
		doSetStorage(57302, 0)
		if ultimo == 1 then
			doBroadcastMessage("O Cometa de Sozin não está mais afetando o mundo Avatar, os dobradores de Fogo não estão mais fortificados.", 22)
		elseif ultimo == 2 then
			doBroadcastMessage("A Lua Cheia se despede do mundo Avatar, os dobradores de Água não estão mais fortificados.", 22)
		else
			doBroadcastMessage("O Eclipse Lunar terminou, os dobradores de Água e Fogo não estão mais enfraquecidos.", 22)
		end
		return false
	end
	
	-- aqui antes fica o test de 10 porcento
	if getStorage(56304) ~= 1 and math.random(1, 100) <= 75 then
		return false
	end
	doSetStorage(56304, 0)

	local proximo = getStorage(57301)
	if proximo < 2 then
		proximo = 2
	end
	proximo = proximo + 1
	doSetStorage(57301, proximo)
	if proximo % 3 == 2 then
		-- eclipse
		doBroadcastMessage("O mundo Avatar está sob Eclipse Lunar, todos os dobradores de Água e Fogo estão enfraquecidos com 20% menos de dano em suas dobras nas próximas 4 horas.", 22)
		doSetStorage(57302, 3)
	elseif proximo % 3 == 1 then
		-- lua
		doBroadcastMessage("A Lua Cheia chegou no mundo Avatar, todos os dobradores de Água estão fortificados com 20% de dano extra em suas dobras nas próximas 4 horas.", 22)
		doSetStorage(57302, 2)
	else
		-- cometa
		doBroadcastMessage("O Cometa de Sozin está passando próximo ao mundo Avatar, os dobradores de Fogo estão fortificados com 20% de dano extra em suas dobras nas próximas 4 horas.", 22)
		doSetStorage(57302, 1)
	end
end
