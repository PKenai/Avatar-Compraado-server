-- ============================================================================
-- BALANCE DE DANO POR ELEMENTO E BEND LEVEL
--
-- MODELO v2 (implementado): o dano de UM cast em UM alvo e'
--
--     (20 + 1.55*(level-1)) * CLASSE[cd] * AREA[formato] * bendFactor(bend)
--
-- CLASSE (pelo cooldown REAL, tabelas *Exausted): filler cd<=3 = 0.40 |
-- core cd 4-15 = 1.00 | heavy cd 16-45 = 1.75 | ultimate cd >=60 = 2.75.
-- AREA (pelo spells.xml): needtarget = 1.00 | direction (cone) = 0.95 |
-- area generica = 0.85 | selftarget = 0.75.
-- bendFactor(b) = 1 + 1.2*b/(b+80) (retorno decrescente, ver abaixo).
--
-- CLASSE e AREA vivem no `atk` de cada magia (data/lib/201-spellsExausted.lua),
-- calibrado por:
--     perl tools/spell_balance_report.pl --model --emit --apply
-- LEVEL e BEND continuam sendo aplicados aqui, de uma vez, para toda magia de
-- player. O multiplicador de eco (estagio ELITE) tambem e' daqui.
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
-- O QUE O JOGADOR SENTE: dentro da MESMA vocacao, magia rapida bate pouco e
-- magia lenta bate muito (filler x0.40, core x1.00, heavy x1.75, ultimate
-- x2.75), e o formato desconta (alvo x1.00, cone x0.95, area x0.85, self
-- x0.75). ENTRE vocacoes, quem decide e' o SPELL_BALANCE abaixo:
--
--     fogo 1.10 (DPS)   ar 1.00 (controle)   terra 0.95 (tank)   agua 0.90 (heal)
--
-- A spellbar continua comparavel dobra por dobra -- rode:
--
--     perl tools/spell_balance_report.pl --bar --level 100 --mag 48
--
-- Quem garante a escada DENTRO de cada vocacao e' o atk de cada dobra em
-- data/lib/201-spellsExausted.lua, calibrado em dano BRUTO (CLASSE do cooldown
-- x AREA do formato, SEM o fator de elemento), por:
--
--     perl tools/spell_balance_report.pl --model --emit --apply
--
-- Como a calibracao e' em dano bruto, mexer no SPELL_BALANCE NAO e' cancelado
-- pelo emissor: e' ali que se muda o papel de uma vocacao (e depois basta rodar
-- o --model --emit de novo se quiser refinar o resto).
--
-- O resto da identidade continua no KIT: agua cura e controla, terra tanka,
-- ar mexe no campo. Fora da spellbar (ataque de promovido, passivo de set) a
-- tabela continua valendo sozinha.
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
-- PAPEL DE CADA VOCACAO (modelo v2). Este e' o multiplicador que entra no
-- FIM do dano, so' para player, e e' o UNICO lugar que decide a hierarquia
-- entre as quatro:
--
--     fogo  x1.10  -> DPS puro
--     ar    x1.00  -> controle/suporte (slow, trap, dodge, mobilidade)
--     terra x0.95  -> tank (armor/defense 1.4 na vocations.xml, controle)
--     agua  x0.90  -> healer (heal + regen + revive passivo)
--
-- Ou seja: o fogo bate ~22% mais que a agua, e o resto da identidade fica no
-- kit. A calibracao do `atk` e' feita em dano BRUTO (antes deste fator), entao
-- MEXER AQUI e' o jeito certo de mudar o papel -- basta rodar
--     perl tools/spell_balance_report.pl --model --emit --apply
-- (se a calibracao fosse em dano final, o emissor dividiria por este numero e
-- as quatro vocacoes voltariam a bater igual -- era o que acontecia antes).
--
-- Historico: 1.00 / air 1.06 / earth 0.81 / water 0.78 era a hierarquia antiga
-- (ar acima do fogo); 0.9827 / 1.0847 / 1.1915 / 1.0453 era a compensacao de
-- mix da spellbar, que forcava as quatro a baterem o MESMO dano.
-- Recalibrado pela secao 22: cada numero e' o fator que faz a MEDIANA de
-- dano/cast do elemento bater a media das quatro vocacoes em level 100, 300 e
-- 500 (o resto da curva vem do SPELL_BALANCE_LEVEL_GROWTH abaixo). Os valores
-- antigos (fire 1.10 / air 1.00 / earth 0.95 / water 0.90) descreviam a
-- intencao, mas a mediana real ia de 359 (terra) a 665 (ar): 85% de diferenca.
SPELL_BALANCE = {
	fire  = 1.0422,
	water = 0.8937,
	air   = 0.7974,
	earth = 1.3934
}

-- ============================================================================
-- MULTIPLICADOR GLOBAL DE DANO (ajuste de servidor)
--
-- 1.00 = modelo v2 puro (o que o emissor calibra). 2.00 = +100% em TODA magia
-- de dano de player.
--
-- Entra no FIM de applySpellBalance, depois do fator de elemento, do bend e do
-- eco do estagio ELITE -- ou seja, nao muda a hierarquia entre vocacoes nem o
-- que o --model --emit enxerga (ele mede em dano BRUTO, antes deste numero).
-- E' aqui que se sobe/desce o teto geral sem tocar em nenhum `atk`: mexer neste
-- numero preserva a calibracao e NAO e' desfeito por um novo
-- `perl tools/spell_balance_report.pl --model --emit --apply`.
--
-- Vale so' para magia de dano de player (remakeValue/remakeAirEarth). Nao pega
-- heal (water heal / earth ingrain calculam cura por fora), monstro, summon nem
-- dano de arma.
-- ============================================================================
SPELL_BALANCE_GLOBAL_MULT = 2.00

-- Correcao por level, por elemento:
--
--   correcao(L) = 1 + b*(L-BASE) + c*(L-BASE)^2      (teto em +-CAP)
--
-- PREENCHIDA (secao 22). Ela segura a igualdade das medianas DEPOIS do ponto
-- de calibracao: o `atk` de cada magia e' uma constante, entao a mediana de cada
-- elemento cresce com um coeficiente proprio e as quatro se descolam com o
-- level (medido: ate +4,4% do terra para o fogo entre o level 100 e o 500).
--
-- Como os coeficientes foram achados: rode
--     perl tools/spell_balance_report.pl --level 100 --mag 48 --json
--     perl tools/spell_balance_report.pl --level 300 --mag 71 --json
--     perl tools/spell_balance_report.pl --level 500 --mag 85 --json
-- tire a mediana de dano/cast por elemento, e resolva b/c para
-- `mediana(elemento) * correcao(L) = media das quatro` nos tres pontos (b e c
-- tem solucao exata: sao duas equacoes, dois niveis). O fator constante de
-- cada elemento fica no SPELL_BALANCE acima.
--
-- Se mexer no `atk` de varias magias, as duas tabelas ficam velhas: refaca a
-- conta. O teto existe porque fora da faixa medida o quadratico diverge.
SPELL_BALANCE_LEVEL_BASE = 100
SPELL_BALANCE_LEVEL_GROWTH = {
	fire  = {b = 1.937376e-04, c = -2.972547e-07},
	water = {b = -8.157671e-05, c = 1.146718e-07},
	air   = {b = 1.112759e-04, c = -1.372479e-07},
	earth = {b = -3.009164e-04, c = 4.397701e-07}
}
SPELL_BALANCE_LEVEL_GROWTH_CAP = 0.25

-- BEND: retorno decrescente (modelo v2).
--
--     bendFactor(b) = 1 + GAIN * b / (b + HALF)
--
--     bend   0 -> x1.00     bend  25 -> x1.29     bend 100 -> x1.67
--     bend  10 -> x1.13     bend  48 -> x1.45
--     bend  20 -> x1.24     bend  62 -> x1.52
--
-- O modelo antigo era linear (+4% por ponto: x3.00 em bend 50 e x5.00 em bend
-- 100), o que fazia 25 pontos de bend valerem mais que 75 levels. O bend
-- continua valendo (+67% no teto), mas nao engole mais o level -- que agora
-- carrega a curva (1.55 por level) e a classe/area da magia.
-- SPELL_BALANCE_BEND_PER_POINT e' o numero do modelo antigo, mantido so' para
-- quem leia o valor por fora (o relatorio usa GAIN/HALF).
SPELL_BALANCE_BEND_PER_POINT = 0.04
SPELL_BALANCE_BEND_GAIN = 1.2
SPELL_BALANCE_BEND_HALF = 80

-- ============================================================================
-- CURVA DE LEVEL - DESATIVADA NO MODELO v2
--
-- No modelo v2 o alvo de dano por level e' a formula linear
--
--     base(level) = 20 + 1.55 * (level - 1)      (base = magia CLASSE core)
--
-- e quem entrega essa reta e' o `atk` de cada magia em 201-spellsExausted.lua,
-- calibrado contra ela. Nao existe mais correcao por level aqui: a tabela
-- abaixo fica toda em 1.00 e o getSpellLevelCurve segue funcionando (devolve
-- 1.0). O corte antigo (0.66 @25 ... 0.50 @100) foi o que invertia a curva:
-- o trecho 1->25 rendia 5x e o 25->100 rendia 2.9x.
--
-- Se algum dia precisar de volta de um ajuste fino por level, mexa nos valores
-- da tabela (o getSpellLevelCurve interpola em linha reta entre os pontos).
-- ============================================================================
SPELL_BALANCE_LEVEL_CURVE = {
	-- MODELO v2: TODOS os pontos em 1.00 de proposito.
	--
	-- A inclinacao do dano por level agora esta' dentro do `atk` de cada magia
	-- (CLASSE * AREA * 100), calibrado contra o alvo (20 + 1.55*(level-1)).
	-- O corte de ~2x que existia daqui para cima (0.66 @25, 0.50 @100) foi
	-- removido: era ele que fazia o trecho 25->100 render 2.9x enquanto o
	-- trecho 1->25 rendia 5x. Sem o corte a curva de dano fica monotonica.
	[1]   = 1.00,
	[5]   = 1.00,
	[10]  = 1.00,
	[25]  = 1.00,
	[50]  = 1.00,
	[75]  = 1.00,
	[100] = 1.00,
	[150] = 1.00,
	[200] = 1.00,
	[400] = 1.00,
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
	-- retorno decrescente (modelo v2): x1.45 em bend 48, x1.67 no teto
	return 1 + (SPELL_BALANCE_BEND_GAIN * bend / (bend + SPELL_BALANCE_BEND_HALF))
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

-- Estagio ELITE (nivel 100+): a magia de alvo unico e' reaplicada 300 ms
-- depois do golpe base. Quem liga SPELL_ECHO_ACTIVE e' spellStages.lua, e SO'
-- em volta do doCombat do eco (chamada sincrona). Com 0.5, a reaplicacao vale
-- metade da aplicacao base -- ou seja, o cast inteiro fica em 1.5x a base e
-- cabe no orcamento da classe (base = 2/3, eco = 1/3).
-- E' isto que torna o eco NEUTRO entre vocacoes: quem tem eco na magia fica
-- com `atk` calibrado 2/3 do de quem nao tem, entao o total do cast e' o mesmo.
SPELL_ECHO_FACTOR = 0.5
SPELL_ECHO_ACTIVE = nil

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
	-- reaplicacao do eco do estagio ELITE (base 2/3 + eco 1/3 do orcamento)
	if SPELL_ECHO_ACTIVE and SPELL_ECHO_ACTIVE == cid then
		factor = factor * SPELL_ECHO_FACTOR
	end
	-- o bend multiplica depois do fator por elemento (multiplicacao, a ordem
	-- nao muda o resultado), mas so' chega aqui quem e' player
	-- SPELL_BALANCE_GLOBAL_MULT: ajuste geral de servidor (1.00 = modelo v2)
	return value * factor * getBendDamageBonus(cid) * SPELL_BALANCE_GLOBAL_MULT
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