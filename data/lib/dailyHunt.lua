--[[
 * dailyHunt.lua -- Task diaria (reescrito do zero)
 *
 * O que mudou em relacao a versao antiga:
 *   - a lista e' sorteada a partir das criaturas OFENSIVAS que possuem boss
 *     (BossConfig.monsters), nunca mais de animais decorativos/de treino
 *   - a meta de kills e' POR CRIATURA, calculada pela forca dela
 *     (50 ate 1000 kills -- ver tools/generate_bosses.py)
 *   - BOTAO DE RE-ROLL: 1x por dia troca ate 3 criaturas da lista
 *   - ao completar uma criatura o jogador ganha o acesso ao boss ALPHA dela
 *     (BossSystem.grantAccess) e pode invoca-lo no tile de portal
 *
 * Protocolo (opcode 166) enviado ao client:
 *   day:<id>|monsters:m1,m2,..|kills:k1,..|required:r1,..|gloves:g1,..
 *   |glovenames:n1;n2;..|outfits:t_h_b_l_f_a_aux;..|claimed:0,1,0,0,1
 *   |rewards:r2,r5|reroll:0|1|bosses:<n>
 *
 * Buffer recebido do client (extendedopcode):
 *   "request"       -> manda a lista
 *   "reroll"        -> usa o re-roll do dia (troca ate 3 criaturas)
 *   "claim:<slot>"  -> entrega o premio (Moeda Avatar) da task concluida
 *                      do slot 1..5 - o slot vem do clique na janela
 *   "claim"         -> premios de marco em % de exp (compatibilidade)
 *
 * Storages usados (por jogador):
 *   DailyHunt_Day          -> id do dia atual da lista
 *   DailyHunt_Monster_<i>  -> nome da criatura do slot i (1..5)
 *   DailyHunt_Kill_<i>     -> kills feitas no slot i
 *   DailyHunt_Task_<i>     -> premio em Moeda Avatar do slot i ja resgatado
 *   DailyHunt_Claimed_2    -> premio de 2/5 ja resgatado
 *   DailyHunt_Claimed_5    -> premio de 5/5 ja resgatado
 *   DailyHunt_Reroll_Day   -> dia em que o re-roll foi usado
 *   Boss_<criatura>        -> dia em que o boss foi liberado (BossSystem)
]]

dofile(getDataDir() .. "lib/bossSystem.lua")

DailyHunt = {
	opcode = 166,
	monstersPerDay = 5,
	rerollAmount = 3,

	-- premio por task concluida, entregue pelo botao "Resgatar" da janela
	taskRewardItem = 18340, -- Moeda Avatar
	taskRewardCount = 1,

	-- premios por quantidade de criaturas concluidas (em % do level atual)
	rewards = {
		{ slots = 2, percent = 0.10, storage = "DailyHunt_Claimed_2" },
		{ slots = 5, percent = 0.50, storage = "DailyHunt_Claimed_5" },
	},
}

-- =========================================================================
-- BOOTSTRAP
-- =========================================================================

function DailyHunt.ensureLoaded()
	return BossSystem.ensureLoaded()
end

-- getItemNameById() explode se o id nao existir no items.xml
-- (getItemInfo devolve false e o .name indexa boolean). Sempre protegido.
local function safeItemName(itemId)
	local id = tonumber(itemId)
	if not id or id <= 0 then
		return "-"
	end
	local ok, name = pcall(getItemNameById, id)
	if ok and type(name) == "string" and name ~= "" then
		return name
	end
	return "-"
end

-- =========================================================================
-- STORAGE
-- =========================================================================

function DailyHunt.getDay(cid)
	return tostring(getPlayerStorageValue(cid, "DailyHunt_Day"))
end

function DailyHunt.setDay(cid, day)
	setPlayerStorageValue(cid, "DailyHunt_Day", day)
end

function DailyHunt.getMonsterName(cid, slot)
	local name = getPlayerStorageValue(cid, "DailyHunt_Monster_" .. slot)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return name
end

function DailyHunt.setMonsterName(cid, slot, name)
	setPlayerStorageValue(cid, "DailyHunt_Monster_" .. slot, name)
end

function DailyHunt.getKillCount(cid, slot)
	local kills = tonumber(getPlayerStorageValue(cid, "DailyHunt_Kill_" .. slot)) or 0
	if kills < 0 then
		kills = 0
	end
	return kills
end

function DailyHunt.setKillCount(cid, slot, kills)
	setPlayerStorageValue(cid, "DailyHunt_Kill_" .. slot, math.max(0, kills))
end

function DailyHunt.isClaimed(cid, storage)
	return tonumber(getPlayerStorageValue(cid, storage)) == 1
end

function DailyHunt.setClaimed(cid, storage)
	setPlayerStorageValue(cid, storage, 1)
end

function DailyHunt.requirementFor(name)
	return BossSystem.requirement(name)
end

function DailyHunt.isSlotComplete(cid, slot)
	local name = DailyHunt.getMonsterName(cid, slot)
	if not name then
		return false
	end
	return DailyHunt.getKillCount(cid, slot) >= DailyHunt.requirementFor(name)
end

function DailyHunt.getCompletedCount(cid)
	local completed = 0
	for slot = 1, DailyHunt.monstersPerDay do
		if DailyHunt.isSlotComplete(cid, slot) then
			completed = completed + 1
		end
	end
	return completed
end

function DailyHunt.rerollUsedToday(cid)
	return tostring(getPlayerStorageValue(cid, "DailyHunt_Reroll_Day")) == getDayID()
end

-- Resgate da Moeda Avatar por task concluida (1x por slot por dia)
function DailyHunt.isTaskClaimed(cid, slot)
	return tonumber(getPlayerStorageValue(cid, "DailyHunt_Task_" .. slot)) == 1
end

function DailyHunt.setTaskClaimed(cid, slot)
	setPlayerStorageValue(cid, "DailyHunt_Task_" .. slot, 1)
end

function DailyHunt.resetTaskClaims(cid)
	for slot = 1, DailyHunt.monstersPerDay do
		setPlayerStorageValue(cid, "DailyHunt_Task_" .. slot, 0)
	end
end

-- =========================================================================
-- GERACAO DA LISTA
-- =========================================================================

local function currentNames(cid)
	local names = {}
	for slot = 1, DailyHunt.monstersPerDay do
		local name = DailyHunt.getMonsterName(cid, slot)
		if name then
			names[name:lower()] = slot
		end
	end
	return names
end

-- Sorteia uma criatura que ainda nao esta na lista
function DailyHunt.pickMonster(pool, excluded)
	local available = {}
	for _, name in ipairs(pool) do
		if not excluded[name:lower()] then
			table.insert(available, name)
		end
	end
	if #available == 0 then
		return nil
	end
	return available[math.random(1, #available)]
end

function DailyHunt.generate(cid)
	if not BossSystem.ensureLoaded() then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Daily Hunt temporariamente indisponivel. Tente novamente em instantes.")
		return false
	end

	local pool = BossSystem.getDailyPool()
	if #pool == 0 then
		print("[DailyHunt] ERRO: BossConfig sem criaturas validas para a task diaria.")
		return false
	end

	local taken = {}
	local day = getDayID()

	DailyHunt.setDay(cid, day)
	for slot = 1, DailyHunt.monstersPerDay do
		local name = DailyHunt.pickMonster(pool, taken)
		if not name then
			name = pool[math.random(1, #pool)]
		end
		taken[name:lower()] = true
		DailyHunt.setMonsterName(cid, slot, name)
		DailyHunt.setKillCount(cid, slot, 0)
	end

	for _, reward in ipairs(DailyHunt.rewards) do
		setPlayerStorageValue(cid, reward.storage, 0)
	end
	DailyHunt.resetTaskClaims(cid)
	setPlayerStorageValue(cid, "DailyHunt_Reroll_Day", 0)

	return true
end

-- Garante que a lista existe e e' do dia atual
function DailyHunt.ensureToday(cid)
	if DailyHunt.getDay(cid) ~= getDayID() or not DailyHunt.getMonsterName(cid, 1) then
		DailyHunt.generate(cid)
		return true
	end
	return false
end

-- =========================================================================
-- RE-ROLL (1x por dia, troca ate 3 criaturas)
-- =========================================================================

function DailyHunt.reroll(cid)
	if not isPlayer(cid) then
		return
	end
	DailyHunt.ensureLoaded()
	DailyHunt.ensureToday(cid)

	if DailyHunt.rerollUsedToday(cid) then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Você já usou o re-roll de hoje. Ele volta a ficar disponível amanhã.")
		DailyHunt.sendDataToClient(cid)
		return
	end

	local pool = BossSystem.getDailyPool()
	if #pool == 0 then
		return
	end

	local taken = currentNames(cid)

	-- so' troca slots que ainda nao foram concluidos (nao punir quem ja cumpriu)
	local candidates = {}
	for slot = 1, DailyHunt.monstersPerDay do
		if not DailyHunt.isSlotComplete(cid, slot) then
			table.insert(candidates, slot)
		end
	end

	if #candidates == 0 then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Todas as criaturas da sua lista já foram concluídas. Nada para trocar!")
		return
	end

	-- 1) escolhe quais slots serao trocados
	local slots = {}
	for _ = 1, math.min(DailyHunt.rerollAmount, #candidates) do
		local idx = math.random(1, #candidates)
		table.insert(slots, table.remove(candidates, idx))
	end

	-- 2) libera os nomes antigos para poderem ser sorteados em outro slot
	for _, slot in ipairs(slots) do
		local old = DailyHunt.getMonsterName(cid, slot)
		if old then
			taken[old:lower()] = nil
		end
	end

	-- 3) sorteia as criaturas novas (sem repetir dentro da lista)
	local changed = 0
	for _, slot in ipairs(slots) do
		local name = DailyHunt.pickMonster(pool, taken)
		if not name then
			break
		end
		taken[name:lower()] = true
		DailyHunt.setMonsterName(cid, slot, name)
		DailyHunt.setKillCount(cid, slot, 0)
		changed = changed + 1
	end

	if changed == 0 then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Não há criaturas novas disponíveis para trocar agora.")
		return
	end

	setPlayerStorageValue(cid, "DailyHunt_Reroll_Day", getDayID())
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
		"Re-roll usado! " .. changed .. " criatura(s) da sua task diária foram trocadas.")
	doSendMagicEffect(getThingPos(cid), 30)
	DailyHunt.sendDataToClient(cid)
end

-- =========================================================================
-- PREMIOS
-- =========================================================================

local function grantReward(cid, reward)
	local level = getPlayerLevel(cid)
	local expReward = (getExperienceForLevel(level + 1) - getExperienceForLevel(level)) * reward.percent
	doPlayerAddExperience(cid, math.ceil(expReward))
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
		"Daily Hunt: " .. reward.slots .. "/" .. DailyHunt.monstersPerDay .. " concluídas - você ganhou " ..
		math.floor(reward.percent * 100) .. "% do seu level de experiência!")
	doSendMagicEffect(getThingPos(cid), reward.slots >= 5 and 30 or 28)
end

-- Concede os premios de marco ainda nao resgatados
function DailyHunt.checkMilestones(cid)
	local completed = DailyHunt.getCompletedCount(cid)
	for _, reward in ipairs(DailyHunt.rewards) do
		if completed >= reward.slots and not DailyHunt.isClaimed(cid, reward.storage) then
			DailyHunt.setClaimed(cid, reward.storage)
			grantReward(cid, reward)
		end
	end
end

-- Botao "Resgatar" da janela (rede de seguranca: se o jogador perdeu o
-- momento automatico, ele ainda pode resgatar o premio)
function DailyHunt.claim(cid)
	if not isPlayer(cid) then
		return
	end
	DailyHunt.ensureLoaded()
	DailyHunt.ensureToday(cid)

	local completed = DailyHunt.getCompletedCount(cid)
	if completed < DailyHunt.rewards[1].slots then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Você precisa concluir pelo menos " .. DailyHunt.rewards[1].slots ..
			" criaturas para resgatar o prêmio. Atual: " .. completed .. "/" .. DailyHunt.monstersPerDay)
		return
	end

	local granted = 0
	for _, reward in ipairs(DailyHunt.rewards) do
		if completed >= reward.slots and not DailyHunt.isClaimed(cid, reward.storage) then
			DailyHunt.setClaimed(cid, reward.storage)
			grantReward(cid, reward)
			granted = granted + 1
		end
	end

	if granted == 0 then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Você já resgatou todos os prêmios disponíveis hoje.")
	end

	DailyHunt.sendDataToClient(cid)
end

-- Botao "Resgatar" da janela: entrega o premio (Moeda Avatar, item 18340) da
-- task CONCLUIDA que o jogador selecionou clicando na linha dela.
-- O client so' manda o numero do slot: toda a validacao e' feita aqui.
function DailyHunt.claimTask(cid, slot)
	if not isPlayer(cid) then
		return
	end

	slot = tonumber(slot)
	if not slot or slot < 1 or slot > DailyHunt.monstersPerDay then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Task inválida. Abra a janela da Daily Hunt e clique na task que você concluiu.")
		return
	end

	DailyHunt.ensureLoaded()
	DailyHunt.ensureToday(cid)

	local name = DailyHunt.getMonsterName(cid, slot)
	if not name then
		DailyHunt.sendDataToClient(cid)
		return
	end

	if not DailyHunt.isSlotComplete(cid, slot) then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Essa task ainda não foi concluída: " .. name .. " (" ..
			DailyHunt.getKillCount(cid, slot) .. "/" .. DailyHunt.requirementFor(name) .. ").")
		DailyHunt.sendDataToClient(cid)
		return
	end

	if DailyHunt.isTaskClaimed(cid, slot) then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Você já resgatou o prêmio da task " .. name .. " hoje.")
		DailyHunt.sendDataToClient(cid)
		return
	end

	local item = doPlayerAddItem(cid, DailyHunt.taskRewardItem, DailyHunt.taskRewardCount)
	if not item then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Não deu para entregar o prêmio. Libere espaço na mochila e tente de novo.")
		return
	end

	DailyHunt.setTaskClaimed(cid, slot)
	doSendMagicEffect(getThingPos(cid), 30)
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
		"Daily Hunt: prêmio resgatado (" .. name .. ") - você recebeu " ..
		DailyHunt.taskRewardCount .. "x " .. safeItemName(DailyHunt.taskRewardItem) .. ".")

	DailyHunt.sendDataToClient(cid)
end

-- =========================================================================
-- CONTAGEM DE KILLS
-- =========================================================================

function DailyHunt.onMonsterKill(cid, monsterName)
	if not isPlayer(cid) or type(monsterName) ~= "string" then
		return
	end
	if BossSystem.isBossName(monsterName) then
		return -- matar o proprio boss ALPHA nao conta para a task
	end

	if not BossSystem.ensureLoaded() then
		return
	end

	if DailyHunt.getDay(cid) ~= getDayID() then
		DailyHunt.generate(cid)
		return
	end

	local lower = monsterName:lower()
	for slot = 1, DailyHunt.monstersPerDay do
		local target = DailyHunt.getMonsterName(cid, slot)
		if target and target:lower() == lower then
			local required = DailyHunt.requirementFor(target)
			local kills = DailyHunt.getKillCount(cid, slot)
			if kills >= required then
				return -- slot ja concluido, nao conta mais
			end

			kills = kills + 1
			DailyHunt.setKillCount(cid, slot, kills)

			if kills >= required then
				-- BOSS LIBERADO
				BossSystem.grantAccess(cid, target)
				doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
					"Task diária concluída: " .. target .. "! Você liberou " ..
					(BossSystem.bossFor(target) or ("ALPHA " .. target)) ..
					". Pise no portal (item 19333/19334 / actionID 50030) na área da criatura para invocá-lo.")
				doSendMagicEffect(getThingPos(cid), 30)
			end

			DailyHunt.checkMilestones(cid)
			DailyHunt.sendDataToClient(cid)
			return
		end
	end
end

-- =========================================================================
-- PROTOCOLO COM O CLIENT
-- =========================================================================

function DailyHunt.sendDataToClient(cid)
	if not isPlayer(cid) then
		return
	end
	if not BossSystem.ensureLoaded() then
		return
	end

	DailyHunt.ensureToday(cid)

	local day = getDayID()
	local names, kills, required, outfits, gloves, gloveNames = {}, {}, {}, {}, {}, {}

	for slot = 1, DailyHunt.monstersPerDay do
		local name = DailyHunt.getMonsterName(cid, slot) or "Unknown"
		local need = DailyHunt.requirementFor(name)
		local done = DailyHunt.getKillCount(cid, slot)

		table.insert(names, name)
		table.insert(kills, tostring(done))
		table.insert(required, tostring(need))
		local gloveId = BossSystem.gloveFor(name) or 0
		table.insert(gloves, tostring(gloveId))
		table.insert(gloveNames, safeItemName(gloveId))

		local lookType, lookHead, lookBody, lookLegs, lookFeet, lookAddons = 0, 0, 0, 0, 0, 0
		local live = getCreatureByName(name)
		local outfit = live and getCreatureOutfit(live) or nil
		if not outfit then
			local info = getMonsterInfo(name)
			outfit = info and info.outfit or nil
		end
		if outfit then
			lookType = outfit.lookType or 0
			lookHead = outfit.lookHead or 0
			lookBody = outfit.lookBody or 0
			lookLegs = outfit.lookLegs or 0
			lookFeet = outfit.lookFeet or 0
			lookAddons = outfit.lookAddons or 0
		end

		table.insert(outfits, string.format("%d_%d_%d_%d_%d_%d_0",
			lookType, lookHead, lookBody, lookLegs, lookFeet, lookAddons))
	end

	local claimed = {}
	for slot = 1, DailyHunt.monstersPerDay do
		table.insert(claimed, DailyHunt.isTaskClaimed(cid, slot) and "1" or "0")
	end

	local reward2 = DailyHunt.isClaimed(cid, DailyHunt.rewards[1].storage) and 1 or 0
	local reward5 = DailyHunt.isClaimed(cid, DailyHunt.rewards[2].storage) and 1 or 0
	local reroll = DailyHunt.rerollUsedToday(cid) and 0 or 1
	local pendingBosses = #BossSystem.getAccessList(cid)

	local data = "day:" .. day
		.. "|monsters:" .. table.concat(names, ",")
		.. "|kills:" .. table.concat(kills, ",")
		.. "|required:" .. table.concat(required, ",")
		.. "|gloves:" .. table.concat(gloves, ",")
		.. "|glovenames:" .. table.concat(gloveNames, ";")
		.. "|outfits:" .. table.concat(outfits, ";")
		.. "|claimed:" .. table.concat(claimed, ",")
		.. "|rewards:" .. reward2 .. "," .. reward5
		.. "|reroll:" .. reroll
		.. "|bosses:" .. tostring(pendingBosses)

	doSendPlayerExtendedOpcode(cid, DailyHunt.opcode, data)
end
