dofile(getDataDir().."creaturescripts/scripts/loginLogout/loginFuncs.lua")

-- ========================================================================
-- Restore persistent buffs on login
-- Checks storage values and re-adds buff icons for active persistent buffs
-- ========================================================================
local PERSISTENT_BUFFS = {
    -- {storageKey, buffId, description}
    {"hasExpScroll", 11, "Experience Scroll"},
}

-- global de proposito: o relogin (loginLogout/onReLogin.lua) tambem reenvia
-- os buffs persistentes, porque o client recarrega a barra de buffs vazia.
function restorePersistentBuffs(cid)
    local now = os.time()
    for _, entry in ipairs(PERSISTENT_BUFFS) do
        local storageKey, buffId, desc = entry[1], entry[2], entry[3]
        local endTime = tonumber(getPlayerStorageValue(cid, storageKey)) or 0
        if endTime > now then
            local remainingMs = (endTime - now) * 1000
            doCreatureAddBuffWithTime(cid, buffId, remainingMs)
        end
    end

    -- Buff do peixe (data/lib/fishSystem.lua): se o bonus do que o jogador comeu
    -- ainda estiver correndo, o icone volta pra barra de cima. Vai por
    -- FishSystem.restoreBuff (e nao pelo doCreatureAddBuffWithTime daqui de
    -- cima) porque ela manda o MESMO pacote do opcode 100 - assim o icone
    -- aparece mesmo com o servidor sem recompilar.
    if type(FishSystem) ~= "table" then
        pcall(dofile, getDataDir().."lib/fishSystem.lua")
    end
    if type(FishSystem) == "table" and type(FishSystem.restoreBuff) == "function" then
        pcall(FishSystem.restoreBuff, cid)

        -- Redundancia: no relogin este pacote sai na hora, e o client pode
        -- ainda nao ter registrado o opcode 100 (sem handler o pacote e'
        -- descartado). Reenvia 2s depois - o client destroi e recria o MESMO
        -- icone, entao nao duplica nada.
        addEvent(function(cid)
            if isCreature(cid) then
                pcall(FishSystem.restoreBuff, cid)
            end
        end, 2000, cid)
    end
end

local config = {
    loginMessageEN = getConfigValue('loginMessageEN'),
    loginMessagePT = getConfigValue('loginMessagePT'),
    loss = getConfigValue('deathLostPercent'),
	protectMessageEN = "Your items were not lost on your death due to the protection of the adventurers (protection up to level 50).",
	protectMessagePT = "Seus itens n�o foram perdidos em sua morte devido � prote��o dos aventureiros (prote��o at� o n�vel 50)."
}

local noobTutorial = 
{
	posesToArrowComing = 
	{
		[1] = {{x=1252, y=748 ,z=7}, {x=1248, y=747, z=7}, {x=1243, y=744, z=7}, {x=1240, y=740, z=7}, {x=1243, y=736, z=7}, {x=1248, y=733, z=7}, {x=1250, y=737, z=7}, {x=1247, y=741, z=6}},
		[2] = {{x=1457, y=554 ,z=7}, {x=1457, y=557, z=7}, {x=1456, y=562, z=7}, {x=1452, y=567, z=7}, {x=1449, y=568 ,z=8}, {x=1446, y=566, z=8}, {x=1442, y=562, z=8}, {x=1443, y=560, z=8}},
		[3] = {{x=1221, y=671 ,z=7}, {x=1222, y=669 ,z=7}, {x=1222, y=664 ,z=7}, {x=1223, y=659 ,z=7}, {x=1223, y=656 ,z=7}, {x=1220, y=652 ,z=6}},
		[4] = {{x=1115, y=574 ,z=7}, {x=1117, y=572 ,z=7}, {x=1120, y=571 ,z=7}, {x=1123, y=571 ,z=7}, {x=1126, y=567 ,z=7}, {x=1128, y=564 ,z=7}, {x=1129, y=561 ,z=7}, {x=1130, y=559 ,z=7}}
	},
	posesToArrowLeaving = 
	{
		[1] = {{x=1250, y=737 ,z=6}, {x=1249, y=733 ,z=7}, {x=1244, y=735 ,z=7}, {x=1242, y=738 ,z=7}, {x=1240, y=743 ,z=7}, {x=1245, y=745 ,z=7}, {x=1246, y=747 ,z=7}, {x=1250, y=748 ,z=7}, {x=1253, y=748 ,z=7}, {x=1256, y=749 ,z=7}},
		[2] = {{x=1447, y=566 ,z=8}, {x=1452, y=567 ,z=8}, {x=1455, y=561 ,z=7}, {x=1457, y=556 ,z=7}, {x=1456, y=552 ,z=7}, {x=1455, y=550 ,z=7}},
		[3] = {{x=1223, y=656 ,z=6}, {x=1222, y=662 ,z=7}, {x=1221, y=667 ,z=7}, {x=1221, y=672 ,z=7}, {x=1225, y=674 ,z=7}},
		[4] = {{x=1124, y=562 ,z=7}, {x=1121, y=567 ,z=7}, {x=1118, y=572 ,z=7}, {x=1115, y=575 ,z=7}, {x=1112, y=575 ,z=7}, {x=1110, y=576 ,z=7}}
	},
	messageArriveCityEng = "Now you're free to explore the Avatar! The city has some weak underground monsters, explore a little and you'll find them.",
	messageArriveCityBr = "Agora voc� est� livre para explorar o mundo de Avatar! A cidade possui alguns monstros com for�a iniciante em seu subsolo, explore um pouco e voc� os achar�.",
	messageTargetEng = "When you find a monster, click with the right button and select the option 'attack'. After killing it, you can open the corpse by clicking and selecting the option 'open'. Have a nice game!",
	messageTargetBr = "Quando encontrar um monstro, clique com o bot�o direito e selecione a op��o 'atacar'. Ap�s mat�-lo, voc� poder� abrir o corpo com o bot�o direito, selecionando a op��o 'abrir', e depois arrastar os itens para a sua backpack. Tenha um bom jogo!",
	messageTalkNpcEng = "Type 'hi' close from an NPC to start a conversation.",
	messageTalkNpcBr = "Envie 'oi' pr�ximo a um NPC para iniciar uma conversa.",
	messageStartBoatBr = 
	{
		[1] = "Chegamos. Siga o percurso para encontrar a senhora do fogo Izumi, mostre-a que merece fazer parte da na��o do fogo! Seja r�pido, n�o temos muito tempo, a lava j� est� cobrindo a nossa sa�da..",
		[2] = "Chegamos. Siga ao sul para encontrar a chefe Eska, mostre-a que merece fazer parte da tribo da �gua!",
		[3] = "Chegamos. Siga ao norte para encontrar o mestre Tenzin, mostre-o que merece ser um n�made do ar!",
		[4] = "Chegamos. Siga o percurso para encontrar a comandante Kuvira, mostre-a que merece fazer parte do reino da terra!"
	},
	messageStartBoatEng = 
	{
		[1] = "We arrived. Follow the path to find the fire lord Izumi, show that you deserve to be part of the fire nation! Be quick, we don't have much time, the lava is closing our way out..",
		[2] = "We arrived. Follow the south path to find the chief Eska, show that you deserve to be part of the water tribe!",
		[3] = "We arrived. Follow the north path to find the master Tenzin, show that you deserve to be a air nomad!",
		[4] = "We arrived. Follow the path to find the commander Kuvira, show that you deserve to be part of the earth kingdom!"
	},
	startBoatPos = 
	{
		[1] = {x=1256, y=749, z=7},
		[2] = {x=1455, y=550, z=7},
		[3] = {x=1225, y=674, z=7},
		[4] = {x=1110, y=576, z=7},
	}
}

local function tutorialCity(cid)
	if not isCreature(cid) then
		return false
	end
	doPlayerSendTextMessage(cid, 22, getLangString(cid, noobTutorial.messageArriveCityEng, noobTutorial.messageArriveCityBr))
	setPlayerStorageValue(cid, "finishedTutorial", 2)
	addEvent(function(cid)
		if isCreature(cid) then
			doPlayerSendTextMessage(cid, 22, getLangString(cid, noobTutorial.messageTargetEng, noobTutorial.messageTargetBr))
		end
	end, 8000, cid)
end

local function tryHiTip(cid)
	if getPlayerStorageValue(cid, "alreadyhitip") ~= 1 then
		doPlayerSendTextMessage(cid, 22, getLangString(cid, noobTutorial.messageTalkNpcEng, noobTutorial.messageTalkNpcBr))
		setPlayerStorageValue(cid, "alreadyhitip", 1)
	end
	return false
end

local function tutorialIsland(cid)
	if not isCreature(cid) then
		return false
	end
	if getPlayerStorageValue(cid, "finishedTutorial") == 1 then -- already leave island
		tutorialCity(cid)
		return false
	end
	if getPlayerStorageValue(cid, "tutorialback") ~= 1 then -- coming
		local comingTable = noobTutorial.posesToArrowComing[getPlayerVocation(cid)]
		if not comingTable then
			return false
		end
		local myPos = getCreaturePosition(cid)
		for i = 0, #comingTable-1 do
			local posAlvo = comingTable[#comingTable-i]
			if getDistanceBetween(myPos, posAlvo) <= 5 then
				if i == 0 then
					if getDistanceBetween(myPos, posAlvo) > 2 then
						doSendMagicEffect({x=posAlvo.x-1, y=posAlvo.y-1, z=posAlvo.z}, 55, cid)
					end
					tryHiTip(cid)
				else
					doSendMagicEffect(posAlvo, 56, cid)
					doSendMagicEffect(posAlvo, 55, cid)
				end
				break
			end
		end
	else -- leaving
		local leavingTable = noobTutorial.posesToArrowLeaving[getPlayerVocation(cid)]
		if not leavingTable then
			return false
		end
		local myPos = getCreaturePosition(cid)
		for i = 0, #leavingTable-1 do
			local posAlvo = leavingTable[#leavingTable-i]
			if getDistanceBetween(myPos, posAlvo) <= 5 then
				if i == 0 then
					if getDistanceBetween(myPos, posAlvo) > 2 then
						doSendMagicEffect({x=posAlvo.x-1, y=posAlvo.y-1, z=posAlvo.z}, 55, cid)
					end
				else
					doSendMagicEffect(posAlvo, 56, cid)
					doSendMagicEffect(posAlvo, 55, cid)
				end
				break
			end
		end
	end
	addEvent(tutorialIsland, 3000, cid)
end

local function boartStartTalk(cid, npc)
	if not isCreature(cid) then return false end
	local vocId = getPlayerVocation(cid)
	local mensagem = getLangString(cid, noobTutorial.messageStartBoatEng[vocId], noobTutorial.messageStartBoatBr[vocId])
	doCreatureSay(npc, mensagem, 5, false, cid)
end
 
local function normalizeNumberStorage(cid)
    if getPlayerStorageValue(cid, "addedPointsMore2") == -1 then
        setPlayerStorageValue(cid, "getPointsInStones", -1)
 
        local guid = tonumber(getPlayerGUID(cid)) or 0
        local result = db.getResult('SELECT * FROM `web_ats_shop_historico` WHERE `status` = "entregue" AND `produto_type` = "pontos" AND `to_player` = "'..guid..'"')
        local pointsMore = 0
 
        if result:getID() ~= -1 then
            pointsMore = result:getDataInt("produto_quantidade")
        end
 
        addPointsInSkill(cid, "stones", pointsMore)
 
        setPlayerStorageValue(cid, "addedPointsMore2", 1)
    end
end
 
local function checkArchangel(cid)

	return true
end 
 
local conditionE = createConditionObject(CONDITION_INFIGHT)
setConditionParam(conditionE, CONDITION_PARAM_TICKS, 6000)

-- 1 fire, 2 water, 3 air, 4 earth
local vocOuts = 
{
	{ -- MALE
		{388, 718, 732},
		{368, 720, 721, 723},
		{457, 715, 730, 735},
		{371, 716, 722}
	},
	{ -- FEMALE
		{383, 717, 725, 728},
		{387, 719, 727, 731},
		{456, 714, 726, 734},
		{384, 713, 724}
	}
}

local function calculateSetRegen(cid)
	local totalRegen = 0
	local slots = {1, 4, 7, 8}
	for i = 1, #slots do
		local equip = getPlayerSlotItem(cid, slots[i]).uid
		if equip ~= 0 then
			local runeType = getItemAttribute(equip, 'elementalrunetype')
			local runeLevel = getItemAttribute(equip, 'elementalrunelevel')
			if runeType == 2 and runeLevel > 0 and runeLevel < 5 then
				local percentByLevel = {0.008, 0.012, 0.016, 0.020}
				totalRegen = totalRegen + (getCreatureMaxHealth(cid)*percentByLevel[runeLevel])
			end
		end
	end
	return totalRegen
end

local function runeRegen(cid, sequenceCount, lastRegenCount)
	if not isCreature(cid) then
		return true
	end
	local newRegenCount = calculateSetRegen(cid)
	if sequenceCount == 5 and lastRegenCount and newRegenCount == lastRegenCount and newRegenCount > 0 then
		sequenceCount = 0
		doCreatureAddHealth(cid, newRegenCount, 1)
	end
	if (not lastRegenCount and newRegenCount > 0) or (lastRegenCount == newRegenCount) then
		sequenceCount = sequenceCount+1
	else
		sequenceCount = 1
	end
	
	if newRegenCount < 1 then
		sequenceCount = 1
	end
	addEvent(runeRegen, 1000, cid, sequenceCount, newRegenCount)
end

-- ============================================================================
-- ESTADO NO LOGIN: limpeza defensiva + diagnostico
-- ----------------------------------------------------------------------------
-- Veneno, fogo, energia, sangramento, paralisia, freezing, dazzled, cursed,
-- drunk e drown sao estado de SESSAO.  Se algum sobrar (client fechado no meio
-- do efeito, efeito que ninguem removeu, restauracao por addEvent que se
-- perdeu) o jogador entra no jogo "envenenado/paralisado" em QUALQUER lugar,
-- inclusive numa protection zone - onde nada pode ter aplicado aquilo.
-- O flag de "nao pode andar" (setNoMove) e' a mesma coisa: e' um campo do
-- objeto do player, nao um timer, entao atravessa fechar/abrir o client.
-- ============================================================================

-- global de proposito: onReLogin.lua (relogin) tambem consulta esta flag
LOGIN_STATE_DEBUG = false -- true liga o relatorio [LOGIN-STATE] no console

-- As constantes CONDITION_* vem de data/lib e podem nao existir no instante
-- em que este arquivo e' lido, entao a lista guarda so os NOMES e o valor e'
-- resolvido na hora do login.
local LOGIN_DEBUFFS = {
	"CONDITION_POISON", "CONDITION_FIRE", "CONDITION_ENERGY",
	"CONDITION_BLEEDING", "CONDITION_PARALYZE", "CONDITION_FREEZING",
	"CONDITION_DAZZLED", "CONDITION_CURSED", "CONDITION_DRUNK",
	"CONDITION_DROWN",
}

local function conditionValue(name)
	local value = rawget(_G, name)
	if type(value) == "number" then
		return value
	end
	return nil
end

-- Tira do personagem os estados de combate da sessao anterior e destrava o
-- movimento. Retorna a lista do que foi encontrado.
function clearLoginSessionStates(cid)
	if not isPlayer(cid) then return {} end

	local cleared = {}
	for _, name in ipairs(LOGIN_DEBUFFS) do
		local conditionType = conditionValue(name)
		if conditionType and getCreatureCondition(cid, conditionType) then
			doRemoveCondition(cid, conditionType)
			cleared[#cleared + 1] = string.lower(string.gsub(name, "CONDITION_", ""))
		end
	end

	if getCreatureNoMove(cid) then
		doCreatureSetNoMove(cid, false)
		cleared[#cleared + 1] = "noMove"
	end

	if #cleared > 0 and LOGIN_STATE_DEBUG then
		print("[LOGIN-STATE] limpou estado pendurado de " .. getCreatureName(cid) .. ": " .. table.concat(cleared, ", "))
	end
	return cleared
end

-- Diagnostico: mostra o bitfield de icones que o servidor esta mandando pro
-- client (mesma conta de Player::sendIcons) e cada condicao ativa.
local CLIENT_ICON_NAMES = {
	{1,     "poisoned"},
	{2,     "burning"},
	{4,     "electrified"},
	{8,     "drunk"},
	{16,    "magic shield"},
	{32,    "PARALYSED"},
	{64,    "hasted"},
	{128,   "logout block"},
	{256,   "drowning"},
	{512,   "freezing"},
	{1024,  "dazzled"},
	{2048,  "cursed"},
	{4096,  "strengthened/buff"},
	{8192,  "pz block"},
	{16384, "inside a protection zone"},
	{32768, "bleeding"},
}

local DIAG_CONDITIONS = {
	{"poison",     "CONDITION_POISON"},
	{"fire",       "CONDITION_FIRE"},
	{"energy",     "CONDITION_ENERGY"},
	{"bleeding",   "CONDITION_BLEEDING"},
	{"haste",      "CONDITION_HASTE"},
	{"paralyze",   "CONDITION_PARALYZE"},
	{"outfit",     "CONDITION_OUTFIT"},
	{"invisible",  "CONDITION_INVISIBLE"},
	{"light",      "CONDITION_LIGHT"},
	{"manashield", "CONDITION_MANASHIELD"},
	{"infight",    "CONDITION_INFIGHT"},
	{"drunk",      "CONDITION_DRUNK"},
	{"exhaust",    "CONDITION_EXHAUST"},
	{"food/regen", "CONDITION_FOOD"},
	{"soul",       "CONDITION_SOUL"},
	{"drown",      "CONDITION_DROWN"},
	{"attributes", "CONDITION_ATTRIBUTES"},
	{"freezing",   "CONDITION_FREEZING"},
	{"dazzled",    "CONDITION_DAZZLED"},
	{"cursed",     "CONDITION_CURSED"},
}

function loginStateReport(cid, tag)
	if not LOGIN_STATE_DEBUG or not isPlayer(cid) then return end

	local active, bits = {}, {}
	for _, entry in ipairs(DIAG_CONDITIONS) do
		local conditionType = conditionValue(entry[2])
		local info = conditionType and getCreatureConditionInfo(cid, conditionType) or nil
		if info then
			local text = entry[1] .. "(ticks=" .. tostring(info.ticks) .. ")"
			local iconValue = tonumber(info.icons) or 0
			if iconValue > 0 then
				text = text .. "[icon=" .. iconValue .. "]"
				for _, icon in ipairs(CLIENT_ICON_NAMES) do
					if math.floor(iconValue / icon[1]) % 2 == 1 then
						bits[icon[1]] = true
					end
				end
			end
			active[#active + 1] = text
		end
	end

	local tileInfo = getTileInfo(getThingPos(cid))
	if tileInfo and tileInfo.protection then
		bits[16384] = true
	end

	local iconList, iconSum = {}, 0
	for _, icon in ipairs(CLIENT_ICON_NAMES) do
		if bits[icon[1]] then
			iconSum = iconSum + icon[1]
			iconList[#iconList + 1] = icon[2]
		end
	end

	local msg = string.format(
		"[LOGIN-STATE %s] noMove=%s moveImmune=%s speed=%s/base=%s food=%s | conds: %s | icons=%d (%s)",
		tag,
		tostring(getCreatureNoMove(cid)),
		tostring(getCreatureMoveImmuneTime(cid)),
		tostring(getCreatureSpeed(cid)),
		tostring(getCreatureBaseSpeed(cid)),
		tostring(getPlayerFood(cid)),
		(#active > 0 and table.concat(active, ", ") or "nenhuma"),
		iconSum,
		(#iconList > 0 and table.concat(iconList, " + ") or "nenhum")
	)

	if type(PlayerSpeed) == "table" and PlayerSpeed.report then
		local speedInfo = PlayerSpeed.report(cid)
		if speedInfo then
			msg = msg .. " | " .. speedInfo
		end
	end

	print(msg)
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, msg)
end

function onLogin(cid)
	-- Estado de combate da sessao anterior nao atravessa login nenhum.
	clearLoginSessionStates(cid)

	-- Objeto NOVO de player: o varSpeed nasce zerado, entao a contabilidade de
	-- velocidade da sessao anterior (PlayerSpeed) nao vale mais. O RELOGIN nao
	-- passa por aqui de proposito (o objeto e' o mesmo e o varSpeed tambem).
	if type(PlayerSpeed) == "table" and PlayerSpeed.resetTracking then
		PlayerSpeed.resetTracking(cid)
	end

	-- MONTARIA DESATIVADA (data/creaturescripts/scripts/onMount.lua): ninguem
	-- entra no jogo montado. O estado "mounted" + lookMount fica salvo no banco
	-- (iologindata), entao quem montou antes disso precisa sair do modo montado
	-- aqui - senao continuaria com o outfit de montaria e o speed dela.
	if type(dismountPlayer) == "function" and getPlayerStorageValue(cid, "inMount") == 1 then
		pcall(dismountPlayer, cid)         -- montaria do Lua (bonusMount + speed)
	end
	pcall(doPlayerSetMounted, cid, false)  -- montaria do engine (mounted/outfit/speed)

	-- Diagnostico: no login, 1.5s e 5s depois (efeitos aplicados por onThink,
	-- talentos e buffs aparecem depois do login). Desligado por padrao em
	-- LOGIN_STATE_DEBUG - quando falso nem agenda os eventos.
	if LOGIN_STATE_DEBUG then
		loginStateReport(cid, "+0s")
		addEvent(function(cid) loginStateReport(cid, "+1.5s") end, 1500, cid)
		addEvent(function(cid) loginStateReport(cid, "+5s") end, 5000, cid)
	end

	-- Never keep Appa item look after death/logout/crash mid-flight
	if restoreAppaOutfit then
		local wasFlying = getPlayerStorageValue(cid, "appaFlying") == 1
		local dest = {
			x = getPlayerStorageValue(cid, "appaDestX"),
			y = getPlayerStorageValue(cid, "appaDestY"),
			z = getPlayerStorageValue(cid, "appaDestZ")
		}
		restoreAppaOutfit(cid)
		if wasFlying and dest.x > 0 and dest.y > 0 and dest.z >= 0 then
			doTeleportThing(cid, dest)
		end
	end

	if getPlayerVocation(cid) == 0 or getPlayerVocation(cid) > 4 then
		if (tonumber(getPlayerStorageValue(cid, "exaustedfirewhip")) or 0) > 1000 then
			doPlayerSetVocation(cid, 1)
		elseif (tonumber(getPlayerStorageValue(cid, "exaustedwaterwhip")) or 0) > 1000 then
			doPlayerSetVocation(cid, 2)
		elseif (tonumber(getPlayerStorageValue(cid, "exaustedairball")) or 0) > 1000 then
			doPlayerSetVocation(cid, 3)
		elseif (tonumber(getPlayerStorageValue(cid, "exaustedearthcrush")) or 0) > 1000 then
			doPlayerSetVocation(cid, 4)
		end
	end
	
	
--	if getPlayerGroupId(cid) <= 3 then
--		doCreatureSetGuildEmblem(cid, getPlayerVocation(cid))
--	else
--		doCreatureSetGuildEmblem(cid, 0)
--	end
	if getPlayerStorageValue(cid, "canAttackable") == 1 then
		setPlayerStorageValue(cid, "canAttackable", 0)
		setPlayerStorageValue(cid, "Archangel", 0)
	end
	-- Avatar state never survives a login: it is lost on logout/death.
	-- (The Battle Royale / Sonam's Staff system manages isAvatar itself.)
	setPlayerStorageValue(cid, "isAvatar", 0)
	if getCreatureMaxHealth(cid, true) > getRealMaxHp(cid) then 
		local old = getCreatureMaxHealth(cid, true)
		local new = getRealMaxHp(cid)
		setCreatureMaxHealth(cid, new)
		doCreatureAddHealth(cid, old-new, 1)
		--doPlayerSendTextMessage(cid, 22, "Seus pontos de vida estava acima do valor correto e foi ajustado.")
	elseif getCreatureMaxHealth(cid, true) < getRealMaxHp(cid) then
		local old = getCreatureMaxHealth(cid, true)
		local new = getRealMaxHp(cid)
		setCreatureMaxHealth(cid, new)
	end

	if getCreatureMaxMana(cid, true) ~= getRealMaxMana(cid) then
		local old = getCreatureMaxMana(cid, true)
		local new = getRealMaxMana(cid)
		setCreatureMaxMana(cid, new)
	end  
	if getCreatureHealth(cid) > getCreatureMaxHealth(cid) then
		doCreatureAddHealth(cid, - (getCreatureHealth(cid) - getCreatureMaxHealth(cid)))
	end
	if getCreatureMana(cid) > getCreatureMaxMana(cid) then
		doCreatureAddMana(cid, - (getCreatureMana(cid) - getCreatureMaxMana(cid)))
	end

	-- New characters: start with 50 mana (creation often leaves mana at 0)
	if getPlayerStorageValue(cid, "startedWithMana") ~= 1 then
		setPlayerStorageValue(cid, "startedWithMana", 1)
		if getCreatureMaxMana(cid) < 50 then
			setCreatureMaxMana(cid, 50)
		end
		local needMana = 50 - getCreatureMana(cid)
		if needMana > 0 then
			doCreatureAddMana(cid, needMana)
		end
	end
	local vocId, sexId = getPlayerVocation(cid), getPlayerSex(cid)
	local outList = vocOuts[2-sexId][vocId]
--	for i = 1, #outList do
--		if not canPlayerWearOutfit(cid, outList[i], 0) then 
--			doPlayerAddOutfit(cid, outList[i], 0)
--		end
--	end
--	if (vocId ~= 3 and canPlayerWearOutfit(cid, 457, 0)) or getCreatureOutfit(cid).lookType == 75 then 	
--		local outfit = getCreatureOutfit(cid)
--		outfit.lookType = outList[2]
--		doCreatureChangeOutfit(cid, outfit)	
--		doPlayerRemoveOutfit(cid, 457)	
--	end 
--	if (vocId ~= 3 and canPlayerWearOutfit(cid, 456, 0))then 	
--		local outfit = getCreatureOutfit(cid)
--		outfit.lookType = outList[2]
--		doCreatureChangeOutfit(cid, outfit)	
--		doPlayerRemoveOutfit(cid, 456)	
--	end 

    local lastLogin = getPlayerLastLoginSaved(cid)
       if getPlayerItemCount(cid, 9775) ~= 0 then 
			doPlayerRemoveItem(cid, 9775, 1)
	   end 
	if getPlayerStorageValue(cid, "morreuD") == 1 then 
		setPlayerStorageValue(cid, "morreuD", -1)            
		doPlayerSendTextMessage(cid, 22, getLangString(cid, config.protectMessageEN, config.protectMessagePT))
	end 
	--if getPlayerStorageValue(cid, "ddoskick") == 1 then 
	--	setPlayerStorageValue(cid, "ddoskick", 0)
	--	doPlayerSendTextMessage(cid, 22, "Voc� foi desconectado como preven��o devido � instabilidade do servidor. Pedimos que evite ca�ar por um tempo at� normalizar sua conex�o!")
	--	doTeleportThing(cid, getTownTemplePosition(getPlayerTown(cid)), false)
	--end 
	--doAddCondition(cid, conditionE)
	exhaustion.set(cid, "npodedeslogar", 6)
	   	doPlayerSetLossPercent(cid, PLAYERLOSS_ITEMS, 0)
		doPlayerSetLossPercent(cid, PLAYERLOSS_CONTAINERS, 100)
		    doCreatureAddHealth(cid, getCreatureMaxHealth(cid) - getCreatureHealth(cid), 1)
   -- doCreatureAddMana(cid, getCreatureMaxMana(cid) - getCreatureMana(cid))
		addEvent(runeRegen, 1000, cid, 1)
		if getPlayerStorageValue(cid, "getPointsInDodge") == -1 then 
			setPlayerStorageValue(cid, "getPointsInDodge", 0)
		end 
		-- Attribute points to distribute: start with 1 (never leave as -1)
		local pendentes = getPlayerStorageValue(cid, "pendentes")
		if type(pendentes) ~= "number" or pendentes < 0 then
			setPlayerStorageValue(cid, "firstPendentes", 1)
			setPlayerStorageValue(cid, "pendentes", 1)
			pendentes = 1
		end
		-- Track last level that already awarded points (avoids retroactive dump)
		local lastAwarded = getPlayerStorageValue(cid, 188100)
		if type(lastAwarded) ~= "number" or lastAwarded < 0 then
			setPlayerStorageValue(cid, 188100, getPlayerLevel(cid))
		end
		doSendPlayerExtendedOpcode(cid, 41, tostring(pendentes))
		if getAtributosString then
			doSendPlayerExtendedOpcode(cid, 40, getAtributosString(cid))
		end
		-- Agilidade e montaria sao FONTES de velocidade (cada uma com seu valor
		-- em PlayerSpeed). O jeito antigo somava agi*6 direto no acumulador: o
		-- rebuild de velocidade somava de novo e a montaria apagava o valor.
		if type(PlayerSpeed) == "table" and PlayerSpeed.refreshFromStorages then
			PlayerSpeed.refreshFromStorages(cid)
		else
			local agi = tonumber(getPlayerStorageValue(cid, "getPointsInDodge")) or 0
			if agi < 0 then agi = 0 end
			doChangeSpeed(cid, agi*6)
		end
       
    if getPlayerAccess(cid) >= 5 then
		vocId = vocId +1
		if vocId > 4 then
			vocId = 1
		end
        doPlayerSetVocation(cid, vocId)
        doCreatureSetVocationEmblem(cid, vocId)
    else
            local posicao = getThingPos(cid)
    		doSendMagicEffect({x=posicao.x+1, y=posicao.y+1, z=posicao.z}, 119)
    end
   
    if(config.loss ~= nil) then
        doPlayerSetLossPercent(cid, PLAYERLOSS_EXPERIENCE, config.loss * 10)
    end
 
    if(getPlayerAccountManager(cid) == MANAGER_NONE) then
        if(lastLogin > 0) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, getLangString(cid, "Your last visit was on "..os.date("%a %b %d %X %Y", lastLogin) ..".", "Sua última visita foi em "..os.date("%a %b %d %X %Y", lastLogin).."."))
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, getLangString(cid, config.loginMessageEN, config.loginMessagePT))
        end

        if (getPlayerStorageValue(cid, "tutorialback") ~= 1) and (getPlayerVocation(cid) == 1) then
        	-- personagem novo ganha apenas o outfit Apprentice; os demais sao comprados/quest
        	doPlayerAddOutfitId(cid, 1, 3)
			doCreatureChangeOutfit(cid, {lookType=({1020, 1025})[getPlayerSex(cid)+1], lookHead = 115, lookBody = 114, lookFeet = 0, lookLegs = 68})
        end

        if (getPlayerStorageValue(cid, "tutorialback") ~= 1) and (getPlayerVocation(cid) == 2) then
        	-- personagem novo ganha apenas o outfit Apprentice; os demais sao comprados/quest
        	doPlayerAddOutfitId(cid, 6, 3)
			doCreatureChangeOutfit(cid, {lookType=({1040, 1045})[getPlayerSex(cid)+1], lookHead = 115, lookBody = 114, lookFeet = 0, lookLegs = 68})
        end

        if (getPlayerStorageValue(cid, "tutorialback") ~= 1) and (getPlayerVocation(cid) == 3) then
        	-- personagem novo ganha apenas o outfit Apprentice; os demais sao comprados/quest
        	doPlayerAddOutfitId(cid, 11, 3)
			doCreatureChangeOutfit(cid, {lookType=({1060, 1065})[getPlayerSex(cid)+1], lookHead = 115, lookBody = 114, lookFeet = 0, lookLegs = 68})
        end

        if (getPlayerStorageValue(cid, "tutorialback") ~= 1) and (getPlayerVocation(cid) == 4) then
        	-- personagem novo ganha apenas o outfit Apprentice; os demais sao comprados/quest
        	doPlayerAddOutfitId(cid, 16, 3)
			doCreatureChangeOutfit(cid, {lookType=({1080, 1085})[getPlayerSex(cid)+1], lookHead = 115, lookBody = 114, lookFeet = 0, lookLegs = 68})
        end
 
        sendAllCheckFunctions(cid)
		if getPlayerStorageValue(cid, "tutorialback") ~= 1 and getDistanceBetween(getCreaturePosition(cid), noobTutorial.startBoatPos[vocId]) <= 4  then
			local posNpc = noobTutorial.startBoatPos[vocId]
			if isNpc(getTopCreature(posNpc).uid) then
				addEvent(boartStartTalk, 2000, cid, getTopCreature(posNpc).uid)
			end
		end
    end

    -- outfits de premium (29/33/35/40) nao sao mais concedidos gratis; devem ser comprados/quest

    if getPlayerPremiumDays(cid) == 0 then
    	doPlayerRemoveOutfitId(cid, 29)
    	doPlayerRemoveOutfitId(cid, 33)
    	doPlayerRemoveOutfitId(cid, 35)
    	doPlayerRemoveOutfitId(cid, 40)
    end
 
	if getPlayerStorageValue(cid, "finishedTutorial") ~= 2 then
		if getPlayerStorageValue(cid, "finishedTutorial") ~= 1 then
			tutorialIsland(cid)
		else
			tutorialCity(cid)
		end
	end
 
	
	local orbita = getStorage(57302)
	if type(orbita) == "number" then
		if orbita == 1 then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "O Cometa de Sozin est� afetando o mundo Avatar, os dobradores de Fogo est�o fortificados com 20% de dano extra em suas dobras.")
		elseif orbita == 2 then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "A Lua Cheia est� presente no mundo Avatar, os dobradores de �gua est�o fortificados com 20% de dano extra em suas dobras.")
		elseif orbita == 3 then
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "O Eclipse Lunar est� acontecendo, os dobradores de �gua e Fogo est�o enfraquecidos com 20% de dano reduzido em suas dobras.")
		end
	end
    --addPremiumOutfit(cid)                                   --Adiciona outfit premium;
    --sendOutfitToNormal(cid)                                 --Flag para arrumar outfit;
    registerEvents(cid)                                     --Registra todos eventos;
    sendBlessIfActive(cid)                                  --Manda bless exp, se ativa;
    setPlayerStorageValue(cid, "playerCanMoveDirection", 0) --Tira bloqueio de movimento para os lados;
    setPlayerStorageValue(cid, "timeLogin", os.time())      --Registra data ultimo login;
    registerCreatureEvent(cid, "Inquisition")
    registerCreatureEvent(cid, "mobsKill")
    registerCreatureEvent(cid, "MomoKill")
    registerCreatureEvent(cid, "DailyHunt")
    registerCreatureEvent(cid, "DailyHuntOpcode")
    registerCreatureEvent(cid, "HuntWaypointOpcode")
    registerCreatureEvent(cid, "KnockoutLog")
    registerCreatureEvent(cid, "KnockoutLogPrep")
    registerCreatureEvent(cid, "KnockoutCombat")
    registerCreatureEvent(cid, "HungerIcon")
    registerCreatureEvent(cid, "BombermanDeath")
    registerCreatureEvent(cid, "BombermanOpcode")
    registerCreatureEvent(cid, "Store")
    registerCreatureEvent(cid, "GameStoreExtended") -- loja nova (opcode 102)
    registerCreatureEvent(cid, "HighscoreExtended") -- janela de highscores (opcode 73)
    registerCreatureEvent(cid, "GamePixExtended") -- doacao via Pix (opcode 103)
    registerCreatureEvent(cid, "StatueDonationOpcode") -- estatua das nacoes (opcode 121)
    registerCreatureEvent(cid, "StatueDonationCombat") -- +5% de dano da nacao (PvE)
    registerCreatureEvent(cid, "QuestKill")
    registerCreatureEvent(cid, "QuestsOpcode")
    registerCreatureEvent(cid, "AchievementsKill")
    registerCreatureEvent(cid, "AchievementsAdvance")
    registerCreatureEvent(cid, "AchievementsOpcode")

    cameraNormalizeOnLogin(cid)
    sendOpCode(cid, 19, tostring(getPlayerVocation(cid)))
 
    if getPlayerStorageValue(cid, "hasActiveInQuest") == 1 then
        doTeleportThing(cid, getPosInStorage(cid, "genericQuestPos"))    
        setPlayerStorageValue(cid, "hasActiveInQuest", -1)
    end
	local bcExhaust = getStorage(52341)
	local onlineCount = #getPlayersOnline()
	if onlineCount >= 400 then
		if onlineCount == 400 and type(bcExhaust) == "number" and bcExhaust <= os.time() then
			doSetStorage(52341, os.time()+1800)
			doBroadcastMessage("O servidor atingiu a incr�vel meta de 500 jogadores online e agora os jogadores est�o com +50% de experi�ncia b�nus!", MESSAGE_STATUS_CONSOLE_BLUE)
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, "There are 500 players online and all players received +50% exp bonus to celebrate!", "O servidor atingiu a incr�vel meta de 500 jogadores online e agora os jogadores est�o com +50% de experi�ncia b�nus!"))
		end
	elseif onlineCount >= 300 then
		if onlineCount == 300 and type(bcExhaust) == "number" and bcExhaust <= os.time() then
			doSetStorage(52341, os.time()+1800)
			doBroadcastMessage("A meta de 400 jogadores online foi atingida e agora os jogadores est�o com +40% de experi�ncia b�nus!", MESSAGE_STATUS_CONSOLE_BLUE)
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, "There are 400 players online and all players received +40% exp bonus to celebrate!", "A meta de 400 jogadores online foi atingida e agora os jogadores est�o com +40% de experi�ncia b�nus!"))
		end
	elseif onlineCount >= 200 then
		if onlineCount == 200 and type(bcExhaust) == "number" and bcExhaust <= os.time() then
			doSetStorage(52341, os.time()+1800)
			doBroadcastMessage("A meta de 300 jogadores online foi atingida e agora os jogadores est�o com +30% de experi�ncia b�nus!", MESSAGE_STATUS_CONSOLE_BLUE)
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, "There are 300 players online and all players received +20% exp bonus to celebrate!", "A meta de 300 jogadores online foi atingida e agora os jogadores est�o com +30% de experi�ncia b�nus!"))
		end
	elseif onlineCount >= 100 then
		if onlineCount == 100 and type(bcExhaust) == "number" and bcExhaust <= os.time() then
			doSetStorage(52341, os.time()+1800)
			doBroadcastMessage("A meta de 200 jogadores online foi atingida e agora os jogadores est�o com +20% de experi�ncia b�nus!", MESSAGE_STATUS_CONSOLE_BLUE)
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, "There are 200 players online and all players received +20% exp bonus to celebrate!", "A meta de 200 jogadores online foi atingida e agora os jogadores est�o com +20% de experi�ncia b�nus!"))
		end
	elseif onlineCount >= 40 then
		if onlineCount == 40 and type(bcExhaust) == "number" and bcExhaust <= os.time() then
			doSetStorage(52341, os.time()+1800)
			doBroadcastMessage("A meta de 100 jogadores online foi atingida e agora os jogadores est�o com +10% de experi�ncia b�nus!", MESSAGE_STATUS_CONSOLE_BLUE)
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, "There are 100 players online and all players received +10% exp bonus to celebrate!", "A meta de 100 jogadores online foi atingida e agora os jogadores est�o com +10% de experi�ncia b�nus!"))
		end
	end
    -- Sistema ALPHA / Daily Hunt: valida a config e manda a lista do dia
    addEvent(function(cid)
        if isCreature(cid) then
            if BossSystem and BossSystem.ensureLoaded then
                pcall(BossSystem.ensureLoaded)
            end
            DailyHunt.sendDataToClient(cid)
        end
    end, 1000, cid)

    -- Send Achievements data shortly after login
    addEvent(function(cid)
        if isCreature(cid) then
            Achievements.onLogin(cid)
        end
    end, 1500, cid)

    -- Send Hunt Waypoint list shortly after login
    addEvent(function(cid)
        if isCreature(cid) then
            HuntWaypoint.loadConfigs()
            HuntWaypoint.sendList(cid)
        end
    end, 1000, cid)

    -- Restore persistent buffs on login (delay to ensure client opcode is registered)
    addEvent(function(cid)
        if isCreature(cid) then
            restorePersistentBuffs(cid)
        end
    end, 2000, cid)

    -- Statue Donation: se a nacao do player (ou as abas globais) estiver com o
    -- bonus ativo, ele entra no jogo JA' com o icone do buff na barra de cima.
    addEvent(function(cid)
        if isCreature(cid) and type(StatueDonation) == "table" then
            StatueDonation.onLogin(cid)
        end
    end, 2500, cid)

    -- Sincroniza os tiers de todos os itens do player no inventario/backpack
    addEvent(function(cid)
        if isCreature(cid) then
            syncPlayerItemTiers(cid)
        end
    end, 1200, cid)

    -- Talent Tree: reaplica os efeitos dos talentos aprendidos e envia dados ao client
    addEvent(function(cid)
        if isCreature(cid) then
            if type(TalentTree) ~= "table" then
                dofile(getDataDir().."lib/talentTree.lua")
            end
            if type(TalentTree) == "table" then
                TalentTree.reapplyAll(cid)
                TalentTree.sendData(cid)
            end
        end
    end, 2500, cid)

    return true
end