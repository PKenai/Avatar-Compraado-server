-- ============================================================================
-- BALANCE DE DANO POR ELEMENTO E BEND LEVEL
--
-- MODELO: quem escala o dano e' o LEVEL. O BEND LEVEL e' um bonus plano de
-- +1% por ponto (SPELL_BALANCE_BEND_PER_POINT), o mesmo para toda magia.
--
-- Para isso as formulas das magias nao usam mais o parametro magLevel: ele
-- virou magLevelUnused (segue na assinatura, sem uso) e o termo foi trocado
-- por (level * 0.5), o que deixa o valor IDENTICO no ponto de calibracao
-- (level 100 / bend 50). Quem faz essa troca nas magias:
--     perl tools/apply_level_scaling.pl --dry
--     perl tools/apply_level_scaling.pl --apply
-- (magia nova que use magLevel precisa passar por isso, senao o bend entra
-- duas vezes: uma na formula e outra no bonus abaixo)
--
-- O numero da tabela NAO e' o dano final: e' o fator aplicado em cima da
-- curva de dano. Como cada vocacao tem um mix diferente de magias de alvo
-- unico / cone / area (e a area vale um desconto, porque acerta varios alvos),
-- o fator precisa compensar esse mix. O que importa e' o resultado medido:
--
--   mediana de dano por cast SEM o bend, level 100 (tools/spell_balance_report.pl)
--     fire  429 (1.00x)   -> a que mais bate
--     air   383 (0.89x)   -> quase o fire, ~10% a menos
--     earth 336 (0.78x)   -> tanka e bate: entre o air e o water
--     water 310 (0.72x)   -> o suporte: menos dano de todas, cura/controla bem
--
-- O fator tambem pode escalar com o LEVEL, por elemento (bloco
-- SPELL_BALANCE_LEVEL_GROWTH, logo abaixo da tabela). Hoje so' a agua usa:
-- em level 100 ela batia 0.62x do fire e ia perdendo terreno no fim da
-- jornada, entao subiu para 0.78 no fator (+16% em toda magia de agua) e
-- ganhou +0.05% por level acima de 100, ate' +8%. A hierarquia nao muda:
-- terra segue na frente da agua em level 50, 100, 200, 400 e 1000.
--
-- Para reajustar: mude o numero aqui e rode o relatorio; os atk por magia em
-- 201-spellsExausted.lua foram gerados com
--     perl tools/spell_balance_report.pl --emit
-- (uma passada so': rodar --emit de novo em cima do resultado anterior acumula
-- os limites de ajuste e distorce as magias de varios golpes).
--
-- O fator entra no FIM de remakeValue/remakeAirEarth, ou seja, depois de todo
-- o resto do dano (atk da magia em data/lib/201-spellsExausted.lua, talentos,
-- debuff de jump, orbita/cometa, skull vermelha). Assim a hierarquia das
-- vocacoes se ajusta em um lugar so', sem tocar em nenhum dos ~110 scripts de
-- magia. So' vale para players: monstros, summons e dano de arma continuam
-- exatamente como eram.
-- ============================================================================
SPELL_BALANCE = {
	fire  = 1.00,
	water = 0.78,
	air   = 1.06,
	earth = 0.81
}

-- Escalamento por level, por elemento. O level da curva de dano ja' vem da
-- formula da propria magia; este termo faz o dano crescer um pouco mais rapido
-- a partir do SPELL_BALANCE_LEVEL_BASE. A agua subiu um degrau no fator (0.67 ->
-- 0.78) e ganhou +0,05% de dano por level acima do base, ate' o teto de +8%:
-- e' ela que estava ficando para tras no fim da jornada. Continua a mais fraca
-- das quatro (terra segue na frente em todas as faixas de level).
--
-- Como mexer: crescimento e' por level, nao por bend (o bend ja' tem o seu
-- +1%/ponto). Elemento ausente da tabela = sem escalamento extra (1.0x).
-- O mesmo numero e' lido por tools/spell_balance_report.pl, entao o relatorio
-- acompanha a mudanca sozinho -- nao precisa editar o medidor.
SPELL_BALANCE_LEVEL_BASE = 100
SPELL_BALANCE_LEVEL_GROWTH = {
	water = 0.0005
}
SPELL_BALANCE_LEVEL_GROWTH_CAP = 0.08

-- Cada ponto de bend level aumenta o dano das dobras em 1%.
-- Em bend 50 o dano sai 1.5x; em bend 0 (personagem novo) sai 1.0x.
SPELL_BALANCE_BEND_PER_POINT = 0.01

-- vocacao (1-8, promovidas incluidas) -> elemento
SPELL_BALANCE_VOCATION = {
	[1] = "fire",  [2] = "water", [3] = "air",   [4] = "earth",
	[5] = "fire",  [6] = "water", [7] = "air",   [8] = "earth"
}

-- id usado pelos scripts (remakeValue(1, dano, cid) = fogo) -> elemento
SPELL_BALANCE_ELEMENT = {
	[1] = "fire", [2] = "water", [3] = "air", [4] = "earth"
}

function getSpellBalanceElement(cid, elementId)
	if elementId and SPELL_BALANCE_ELEMENT[elementId] then
		return SPELL_BALANCE_ELEMENT[elementId]
	end
	if cid and isPlayer(cid) then
		return SPELL_BALANCE_VOCATION[getPlayerVocation(cid)]
	end
	return nil
end

function getBendDamageBonus(cid)
	if not (cid and isPlayer(cid)) then
		return 1
	end
	local bend = getPlayerMagLevel(cid)
	if type(bend) ~= "number" or bend < 0 then
		bend = 0
	end
	return 1 + (bend * SPELL_BALANCE_BEND_PER_POINT)
end

function getElementLevelScaling(cid, element)
	local growth = SPELL_BALANCE_LEVEL_GROWTH[element]
	if not growth then
		return 1
	end
	local level = isPlayer(cid) and getPlayerLevel(cid)
	if type(level) ~= "number" or level <= SPELL_BALANCE_LEVEL_BASE then
		return 1
	end
	local bonus = (level - SPELL_BALANCE_LEVEL_BASE) * growth
	if bonus > SPELL_BALANCE_LEVEL_GROWTH_CAP then
		bonus = SPELL_BALANCE_LEVEL_GROWTH_CAP
	end
	return 1 + bonus
end

function applySpellBalance(cid, value, element)
	if not value or not element then
		return value
	end
	if not (cid and isPlayer(cid)) then
		return value
	end
	local factor = SPELL_BALANCE[element]
	if not factor then
		return value
	end
	factor = factor * getElementLevelScaling(cid, element)
	-- o bend multiplica depois do fator por elemento (multiplicacao, a ordem
	-- nao muda o resultado), mas so' chega aqui quem e' player
	return value * factor * getBendDamageBonus(cid)
end

function remakeAirEarth(cid, value)
	if cid and isCreature(cid) then
		local talentBonus = getPlayerStorageValue(cid, "talentBendDmgBonus")
		if type(talentBonus) == "number" and talentBonus > 0 then
			value = value * (1 + (talentBonus / 100))
		end
	end
	-- ar e terra dividem esta funcao: quem decide o elemento e' a vocacao
	return applySpellBalance(cid, value, getSpellBalanceElement(cid))
end

function remakeValue(vocation, value, cid)
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
	-- ultimo passo: a hierarquia de dano das vocacoes (fire > air > earth > water)
	return applySpellBalance(cid, value, getSpellBalanceElement(cid, vocation))
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
		doBroadcastMessage("O Cometa de Sozin está passando próximo ao mundo Avatar, todos os dobradores de Fogo estão fortificados com 20% de dano extra em suas dobras nas próximas 4 horas.", 22)
		doSetStorage(57302, 1)
	end
end