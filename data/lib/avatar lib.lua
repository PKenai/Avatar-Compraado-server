-- ============================================================================
-- BALANCE DE DANO POR ELEMENTO E BEND LEVEL
--
-- MODELO: quem escala o dano e' o LEVEL, multiplicado pela curva de level
-- (SPELL_BALANCE_LEVEL_CURVE, mais abaixo) e pelo BEND LEVEL, que multiplica
-- +4% por ponto (SPELL_BALANCE_BEND_PER_POINT) -- o mesmo para toda magia.
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
-- O QUE O JOGADOR SENTE: as dobras da SPELLBAR das quatro vocacoes batem o
-- mesmo dano no mesmo level (level 1, 5, 8, ..., 250). Sao as quatro listas de
-- sempre (a ordem canonica esta' em 199-ServerToDll.lua, a mesma que o cliente
-- carrega em modules/game_folds/configs.lua), uma por elemento, nos MESMOS
-- leveis -- da' para comparar dobra por dobra:
--
--     perl tools/spell_balance_report.pl --bar     (tabela lado a lado)
--
-- Quem garante essa igualdade hoje e' o atk de cada dobra em
-- data/lib/201-spellsExausted.lua, recalculado para a MEDIA das vocacoes
-- daquele level:
--
--     perl tools/spell_balance_report.pl --bar --emit --apply
--
-- O fator por elemento abaixo virou compensacao: ele entra no fim do dano e o
-- atk de cada dobra ja' o leva em conta. Por isso, MEXER NOS NUMEROS DA TABELA
-- DESALINHA A SPELLBAR -- se mexer, rode o --bar --emit de novo para a tabela
-- de atk voltar a casar.
--
-- O que diferencia as vocacoes passa a ser o KIT, nao o numero: agua cura e
-- controla, terra tanka, ar mexe no campo. Fora da spellbar (ataque de
-- promovido, passivo de set) a tabela continua valendo sozinha.
--
-- Se um dia quiser a hierarquia antiga de volta (fire > air > earth > water),
-- ela era fire 1.00 / air 1.06 / earth 0.81 / water 0.78 -- mas aí a igualdade
-- da spellbar se perde, porque o atk das dobras foi calibrado com os numeros
-- de hoje.
--
-- Para reajustar uma dobra especifica: mude o atk dela em
-- 201-spellsExausted.lua e confira com o relatorio --bar.
--
-- O fator entra no FIM de remakeValue/remakeAirEarth, ou seja, depois de todo
-- o resto do dano (atk da magia em data/lib/201-spellsExausted.lua, talentos,
-- debuff de jump, orbita/cometa, skull vermelha). Assim a hierarquia das
-- vocacoes se ajusta em um lugar so', sem tocar em nenhum dos ~110 scripts de
-- magia. So' vale para players: monstros, summons e dano de arma continuam
-- exatamente como eram.
-- ============================================================================
SPELL_BALANCE = {
	fire  = 0.9827,
	water = 1.0847,
	air   = 1.1915,
	earth = 1.0453
}

-- Correcao por level, por elemento:
--
--   correcao(L) = 1 + b*(L-BASE) + c*(L-BASE)^2      (teto em +-CAP)
--
-- Esta' VAZIA de proposito. Ela existia quando o alvo era igualar a MEDIANA de
-- dano das quatro vocacoes (um numero por vocacao). O alvo hoje e' outro: cada
-- dobra da spellbar bater o mesmo que as outras tres daquele mesmo level, dobra
-- por dobra -- e quem garante isso e' o atk de cada uma em 201-spellsExausted.lua
-- (ver o cabecalho). Uma correcao POR VOCACAO em cima disso so' desalinharia de
-- novo (em level diferente de 100), porque ela empurra a vocacao inteira.
--
-- Se algum dia voltar a querer mediana igual (e nao dobra igual), o caminho e'
-- preencher a tabela: rode perl tools/spell_balance_report.pl em varios --level,
-- veja a mediana por elemento e de' b/c NEGATIVO para quem esta' acima,
-- POSITIVO para quem esta' abaixo. Elemento ausente = sem correcao (1.0x).
-- O teto existe porque fora da faixa medida o quadratico diverge.
SPELL_BALANCE_LEVEL_BASE = 100
SPELL_BALANCE_LEVEL_GROWTH = {
}
SPELL_BALANCE_LEVEL_GROWTH_CAP = 0.25

-- Cada ponto de bend level aumenta o dano das dobras em 4%.
-- Em bend 50 o dano sai 3.0x; em bend 25 sai 2.0x; em bend 0 (personagem
-- novo) sai 1.0x.
SPELL_BALANCE_BEND_PER_POINT = 0.04

-- ============================================================================
-- CURVA DE LEVEL - MEDIA DE DANO GERAL DO SERVIDOR
--
-- Meta de media de dano por level (uma aplicacao de magia, SEM bend):
--
--     level   1 ...... 20 ~~ 30
--     level   5 ...... 30 ~~ 50
--     level  10 ...... 50 ~~ 80
--     level  50 ...... 100 ~~ 150
--     level 100 ...... 200 ~~ 250
--     level 150 ...... 300 ~~ 400
--
-- A tabela abaixo e' a CORRECAO aplicada para a media medida bater essa meta.
-- E' medicao real, nao chute:
--
--     correcao = meta do level / mediana medida naquele level
--
-- Meta  = a meta acima interpolada em linha reta entre as faixas (o valor da
--         faixa no proprio level, ex: level 100 = 225 = meio de 200 ~~ 250).
-- Hoje  = mediana medida das 71 magias de dano, SEM bend, no level:
--         perl tools/spell_balance_report.pl --level N --mag 0
--
--     level    meta hoje      hoje medido    correcao
--     ---------------------------------------------------
--         1      25     (20-30)      27.0       1.00  <- ja' batia
--         5      40     (30-50)      43.4       1.00  <- ja' batia
--        10      65     (50-80)      67.0       1.00  <- ja' batia
--        25      87.5                132.1       0.66
--        50     125    (100-150)     237.8       0.53
--        75     175                  342.0       0.51
--       100     225    (200-250)     452.1       0.50
--       150     350    (300-400)     655.4       0.53
--       200     475                  873.4       0.54
--       400     975                 1709.1       0.57
--
-- Ou seja: ate' o level 10 a curva de hoje JA' e' a meta (a formula da propria
-- magia entrega o valor, correcao 1.00); do 25 pra cima o servidor vinha
-- entregando ~2x a meta, e e' isso que a correcao corta. Os pontos do 25, 75,
-- 200 e 400 existem para a reta entre um ponto e outro nao fugir da meta (entre
-- o 10 e o 50 a meta andava 1.5 por level e a curva de hoje 4.2). Entre dois
-- pontos interpola em linha reta e depois do ultimo continua no passo do ultimo
-- trecho (hoje +0.0005 por level: o corte fica estavel no fim da jornada).
--
-- Se a meta mudar, remeca a mediana e refaca a conta: mexer aqui mexe na media
-- do servidor inteiro. Magia isolada continua se ajustando pelo atk em
-- 201-spellsExausted.lua.
-- ============================================================================
SPELL_BALANCE_LEVEL_CURVE = {
	[1]   = 1.00,
	[5]   = 1.00,
	[10]  = 1.00,
	[25]  = 0.66,
	[50]  = 0.53,
	[75]  = 0.51,
	[100] = 0.50,
	[150] = 0.53,
	[200] = 0.54,
	[400] = 0.57,
}

-- Chaves da tabela em ordem: pairs() nao garante ordem em Lua, e a leitura
-- abaixo anda pelos passos do menor para o maior.
local SPELL_BALANCE_LEVEL_CURVE_STEPS = {}
for spellCurveStep in pairs(SPELL_BALANCE_LEVEL_CURVE) do
	SPELL_BALANCE_LEVEL_CURVE_STEPS[#SPELL_BALANCE_LEVEL_CURVE_STEPS + 1] = spellCurveStep
end
table.sort(SPELL_BALANCE_LEVEL_CURVE_STEPS)

-- Le a correcao da curva em qualquer level: entre dois pontos interpola em linha
-- reta, antes do primeiro devolve o primeiro e depois do ultimo continua no
-- passo do ultimo trecho (a curva nao termina no 150).
function getSpellLevelCurve(level)
	local tabela = SPELL_BALANCE_LEVEL_CURVE
	local passos = SPELL_BALANCE_LEVEL_CURVE_STEPS
	if type(level) ~= "number" or level <= passos[1] then
		return tabela[passos[1]]
	end
	for i = 2, #passos do
		local levelDepois = passos[i]
		if level <= levelDepois then
			local levelAntes = passos[i - 1]
			local antes, depois = tabela[levelAntes], tabela[levelDepois]
			return antes + ((depois - antes) * (level - levelAntes) / (levelDepois - levelAntes))
		end
	end
	local ultimo, penultimo = passos[#passos], passos[#passos - 1]
	local passo = (tabela[ultimo] - tabela[penultimo]) / (ultimo - penultimo)
	return tabela[ultimo] + ((level - ultimo) * passo)
end

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
	local curve = SPELL_BALANCE_LEVEL_GROWTH[element]
	if not curve then
		return 1
	end
	local level = isPlayer(cid) and getPlayerLevel(cid)
	if type(level) ~= "number" then
		return 1
	end
	-- o descolamento entre as vocacoes cresce com o level (cada mix de magias
	-- tem um coeficiente de level proprio), entao a correcao e' quadratica.
	local x = level - SPELL_BALANCE_LEVEL_BASE
	local bonus = ((curve.b or 0) * x) + ((curve.c or 0) * x * x)
	if bonus > SPELL_BALANCE_LEVEL_GROWTH_CAP then
		bonus = SPELL_BALANCE_LEVEL_GROWTH_CAP
	elseif bonus < -SPELL_BALANCE_LEVEL_GROWTH_CAP then
		bonus = -SPELL_BALANCE_LEVEL_GROWTH_CAP
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
	-- correcao da curva de level: e' ela que faz a MEDIA de dano do servidor
	-- seguir a meta por level (SPELL_BALANCE_LEVEL_CURVE, no comeco do arquivo)
	factor = factor * getSpellLevelCurve(getPlayerLevel(cid))
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