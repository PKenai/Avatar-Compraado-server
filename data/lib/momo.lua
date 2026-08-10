-- ============================================================================
-- MOMO POUCH (item 18435) — slot real no inventario (slot 12)
-- ----------------------------------------------------------------------------
-- Mesma regra da camera: slot de equipamento dedicado (SLOT_MOMO = 12,
-- compilado na source). So o Momo Pouch equipa nesse slot, e o slot 12 e
-- excluido de TODOS os fluxos de drop de morte — o Momo Pouch JAMAIS e
-- dropado.
-- ============================================================================

MOMO_ITEM_ID = 18435
MOMO_SLOT = 12
MOMO_DEPOT = 1

-- true se o item e um Momo Pouch
function isMomoItemId(itemid)
	return itemid == MOMO_ITEM_ID
end

-- Guarda o Momo Pouch num lugar seguro: primeiro tenta o slot 12 (se estiver
-- vazio), senao vai pro deposito.
function momoAddToSafeSlot(cid)
	local slotItem = getPlayerSlotItem(cid, MOMO_SLOT)
	if not slotItem or slotItem.itemid == 0 then
		local ok = doPlayerAddItem(cid, MOMO_ITEM_ID, 1, false, 1, MOMO_SLOT)
		if ok then
			return true
		end
	end
	return doPlayerAddItemToDepot(cid, MOMO_DEPOT, MOMO_ITEM_ID, 1)
end

-- Move qualquer Momo Pouch solto no inventario do player (slots 1-10 +
-- mochilas) para um lugar seguro. Chamado no onDeath (que roda ANTES do
-- dropLoot neste server) — o slot 12 em si nunca entra no fluxo de drop.
function momoMoveToDepot(cid)
	local moved = false
	for slot = 1, 10 do
		local item = getPlayerSlotItem(cid, slot)
		if item and item.uid and item.uid > 0 then
			if isMomoItemId(item.itemid) then
				doRemoveItem(item.uid, 1)
				momoAddToSafeSlot(cid)
				moved = true
			elseif isContainer(item.uid) then
				if momoScanContainer(cid, item.uid) then
					moved = true
				end
			end
		end
	end
	return moved
end

function momoScanContainer(cid, containerId)
	local moved = false
	local size = getContainerSize(containerId)
	if size < 0 then
		return false
	end
	for i = size - 1, 0, -1 do
		local item = getContainerItem(containerId, i)
		if item and item.uid and item.uid > 0 then
			if isMomoItemId(item.itemid) then
				doRemoveItem(item.uid, 1)
				momoAddToSafeSlot(cid)
				moved = true
			elseif isContainer(item.uid) then
				if momoScanContainer(cid, item.uid) then
					moved = true
				end
			end
		end
	end
	return moved
end

-- true se o player ja tem um Momo Pouch (slot 12, slots 1-10 ou mochilas).
-- Usado pela Store para esconder a oferta de quem ja adquiriu o item.
function playerOwnsMomo(cid)
	local slotItem = getPlayerSlotItem(cid, MOMO_SLOT)
	if slotItem and slotItem.uid and slotItem.uid > 0 and isMomoItemId(slotItem.itemid) then
		return true
	end
	for slot = 1, 10 do
		local item = getPlayerSlotItem(cid, slot)
		if item and item.uid and item.uid > 0 then
			if isMomoItemId(item.itemid) then
				return true
			elseif isContainer(item.uid) then
				if momoContainerHasMomo(cid, item.uid) then
					return true
				end
			end
		end
	end
	return false
end

function momoContainerHasMomo(cid, containerId)
	local size = getContainerSize(containerId)
	if size < 0 then
		return false
	end
	for i = size - 1, 0, -1 do
		local item = getContainerItem(containerId, i)
		if item and item.uid and item.uid > 0 then
			if isMomoItemId(item.itemid) then
				return true
			elseif isContainer(item.uid) then
				if momoContainerHasMomo(cid, item.uid) then
					return true
				end
			end
		end
	end
	return false
end

-- ============================================================================
-- MOMO POUCH — sistema de coleta automatica (versao personalizada do Loot
-- Pouch/autoloot atual)
-- ----------------------------------------------------------------------------
-- * CTRL + botao direito no Momo Pouch (18435) -> janela de config (on/off)
-- * CTRL + botao direito em QUALQUER item -> Add/Remove da lista do pouch
-- * Coleta so loot de criaturas onde o jogador foi o MAIOR causador de dano
--   (frag). Excecao: se o dono do pouch for o lider da party, a regra de frag
--   e ignorada para kills da party.
-- * Itens configurados: "1" = sempre coleta / "0" = nunca coleta. Nao
--   configurado = comportamento padrao do autoloot (coleta tudo, exceto
--   comidas quando o player nao esta com fome).
-- ============================================================================

MOMO_OPCODE = 212
MOMO_STORAGE_ACTIVE = "momoactive"
MOMO_STORAGE_ITEM = "momoitem_"

-- Mesma lista de comidas do autoloot.lua (comportamento padrao: comida so e
-- coletada quando o player esta com fome).
local momoFoods = {2328, 2787, 2362, 2666, 2667, 2668, 2669, 2670, 2671, 2672, 2673, 2674, 2675, 2676, 2677, 2678, 2679, 2680, 2681, 2682, 2683, 2684, 2685, 2686, 2687, 2688, 2689, 2690, 2691, 2692, 2693, 2694, 2695, 2696, 5097, 5678, 6125, 6278, 2679, 6393, 6394, 6501, 6541, 6542, 6543, 6544, 6545, 6569, 6574, 7158, 7159, 7245, 7372, 7373, 7374, 7375, 7376, 7377, 7909, 7963, 8838, 8839, 8840, 8841, 8842, 8843, 8844, 8845, 8847, 9005, 9114, 10454, 11246, 11429, 12415, 12416, 12417, 12418, 12637, 12639}

-- Converte moedas para o maior denominador (mesma logica do autoloot atual).
function momoTransformGolds(cid)
	local gold = getPlayerMoney(cid)
	if doPlayerRemoveMoney(cid, gold) then
		doPlayerAddMoney(cid, gold)
	end
end

-- status do pouch: "1" ativado / "0" desativado (padrao: ativado)
function momoGetStatus(cid)
	local v = getPlayerStorageValue(cid, MOMO_STORAGE_ACTIVE)
	if v == -1 or v == nil then return "1" end
	return tostring(v)
end

function momoSetStatus(cid, status)
	if status == "1" or status == "0" then
		setPlayerStorageValue(cid, MOMO_STORAGE_ACTIVE, status)
	end
end

-- ativo = player possui o Momo Pouch equipado E o sistema esta ativado
function momoIsActive(cid)
	return playerOwnsMomo(cid) and momoGetStatus(cid) == "1"
end

-- status configurado de um item: "1" coleta / "0" bloqueia / nil = nao configurado
function momoItemStatus(cid, itemId)
	local v = getPlayerStorageValue(cid, MOMO_STORAGE_ITEM .. itemId)
	if v == -1 or v == nil then return nil end
	return tostring(v)
end

function momoSetItem(cid, itemId, status)
	if status == "1" or status == "0" then
		setPlayerStorageValue(cid, MOMO_STORAGE_ITEM .. itemId, status)
	end
end

-- lista completa dos itens configurados: { {id=..., status="1"|"0"}, ... }
function momoGetItemList(cid)
	local list = {}
	local keys = getCreatureStorageList(cid)
	if type(keys) == "table" then
		local prefixLen = #MOMO_STORAGE_ITEM
		for _, key in ipairs(keys) do
			if type(key) == "string" and key:sub(1, prefixLen) == MOMO_STORAGE_ITEM then
				local id = tonumber(key:sub(prefixLen + 1))
				local status = getPlayerStorageValue(cid, key)
				if id and status ~= -1 and status ~= nil then
					table.insert(list, {id = id, status = tostring(status)})
				end
			end
		end
	end
	return list
end

-- Elegibilidade da coleta:
--   * fora de party (ou membro nao-lider): so o MAIOR causador de dano
--     (corpseowner = guid do maior dano, gravado na source na morte)
--   * lider da party com Momo Pouch: ignora a regra de frag (kills da party)
function momoIsEligible(cid, corpseUid)
	local corpseOwner = getItemAttribute(corpseUid, "corpseowner")
	if not corpseOwner then return false end
	local ownerGuid = tonumber(corpseOwner)
	if not ownerGuid or ownerGuid == 0 then return false end

	if ownerGuid == getPlayerGUID(cid) then
		return true
	end

	-- excecao: lider da party + dono do pouch
	local leader = getPlayerParty(cid)
	if leader and leader == cid and playerOwnsMomo(cid) then
		return true
	end
	return false
end

-- Coleta os itens do corpo DENTRO do Momo Pouch (container com slots
-- infinitos). Respeita a config personalizada de itens.
-- Retorna (coletou_algum, falhou_algum): falhou_algum = true quando algum
-- item nao coube (ex.: capacidade do char estourada) e ficou no corpo.
function momoAutoLootContainer(cid, container)
	local pouch = getPlayerSlotItem(cid, MOMO_SLOT)
	if not pouch or not pouch.uid or pouch.uid <= 0 then
		return false, false
	end
	if not isContainer(pouch.uid) then
		return false, false
	end

	local looted = false
	local failed = false
	local toRemove = {}
	local sendLootScreen = {}
	for x = 0, (getContainerSize(container.uid) - 1) do
		local candidato = getContainerItem(container.uid, x)
		if candidato.itemid == 1987 then
			local okSub, failSub = momoAutoLootContainer(cid, candidato)
			if okSub then looted = true end
			if failSub then failed = true end
		else
			local collect = true
			-- O client configura os itens pelo CLIENT id (o id que ele ve no OTB),
			-- mas o candidato.itemid e o SERVER id (ex.: gold 3031 -> client 4212).
			-- Converte antes de consultar a lista configurada.
			local lookupId = ItemType(candidato.itemid):getClientId()
			if not lookupId or lookupId <= 0 then lookupId = candidato.itemid end
			local status = momoItemStatus(cid, lookupId)
			if status == "0" then
				collect = false -- removido/bloqueado: nunca coleta
			elseif status == nil then
				-- nao configurado: comportamento padrao (igual autoloot atual)
				if isInArray(momoFoods, candidato.itemid) and getPlayerFood(cid) > 0 then
					collect = false
				end
			end
			if collect and candidato.itemid > 0 then
				-- ATENCAO: doAddContainerItem usa FLAG_NOLIMIT e IGNORA a capacidade
				-- do char (Player::__queryAdd -> childOwner + skipLimit). O pouch
				-- precisa se comportar como mochila normal: so coleta se o player
				-- tem cap para receber o item (mesma regra do hasCapacity C++:
				-- cabe se peso < cap livre).
				local info = getItemInfo(candidato.itemid)
				local fits = true
				if info then
					local weight = info.weight or 0
					if info.stackable then
						weight = weight * (candidato.type or 1)
					end
					if getPlayerFreeCap(cid) <= weight then
						fits = false -- sem cap: item fica no corpo
					end
				end
				if fits then
					if doAddContainerItem(pouch.uid, candidato.itemid, candidato.type) then
						table.insert(toRemove, candidato.uid)
						sendLootScreen[getItemInfo(candidato.itemid).name] = {
							itemId = getItemInfo(candidato.itemid).clientId,
							count  = candidato.type
						}
						looted = true
					else
						failed = true -- nao coube mesmo assim (caso raro): fica no corpo
					end
				else
					failed = true
				end
			end
		end
	end
	if #toRemove > 0 then
		for i = 1, #toRemove do
			doRemoveItem(toRemove[i])
		end
	end
	if looted then
		doSendPlayerExtendedOpcode(cid, 158, table.serialize(sendLootScreen))
	end
	return looted, failed
end

-- Envia o estado completo (ativado + lista de itens) para o client.
function momoSendState(cid)
	doSendPlayerExtendedOpcode(cid, MOMO_OPCODE, json.encode({
		action = "state",
		data = {
			enabled = momoGetStatus(cid),
			items = momoGetItemList(cid)
		}
	}))
end

-- Handler do opcode 212 (client -> server): get / toggle / setitem
function momoHandleOpcode(cid, buffer)
	if type(buffer) ~= "string" or buffer == "" then return true end
	local ok, json_data = pcall(function() return json.decode(buffer) end)
	if not ok or type(json_data) ~= "table" then return true end

	local action = json_data["action"]
	if action == "get" then
		momoSendState(cid)
	elseif action == "toggle" then
		if momoGetStatus(cid) == "1" then
			momoSetStatus(cid, "0")
		else
			momoSetStatus(cid, "1")
		end
		momoSendState(cid)
	elseif action == "setitem" then
		local data = json_data["data"] or {}
		local itemId = tonumber(data["item"])
		local status = tostring(data["status"])
		if itemId and itemId > 0 then
			momoSetItem(cid, itemId, status)
		end
		momoSendState(cid)
	end
	return true
end


-- ============================================================================
-- Coleta AUTOMATICA sem abrir o corpo
-- ----------------------------------------------------------------------------
-- Evento onKill (registrado no login): o player matou um monstro. Agendamos
-- uma checagem para logo depois do loot cair (dropLoot roda apos o evento de
-- morte). O corpo e encontrado na tile (container com actionid 49631) e os
-- itens vao direto pro pouch, respeitando frag/party e a lista configurada.
-- Se o player nao for elegivel, o loot fica no corpo normalmente.
-- ============================================================================

-- agenda a coleta quando o player (ou o summon dele) mata um monstro
function momoScheduleAutoLoot(cid, target)
	if not momoIsActive(cid) then return true end
	if not isMonster(target) then return true end
	local pos = getThingPos(target)
	addEvent(momoAutoLootAtPos, 100, cid, pos)
	return true
end

-- roda depois do loot cair: encontra o corpo na tile e coleta pro pouch
function momoAutoLootAtPos(cid, pos)
	if not momoIsActive(cid) then return end

	local count = getTileThingByPos({x = pos.x, y = pos.y, z = pos.z, stackpos = -1})
	if not count or count <= 0 then return end

	local corpse = nil
	for sp = 0, count - 1 do
		local t = getTileThingByPos({x = pos.x, y = pos.y, z = pos.z, stackpos = sp})
		if t and t.uid and t.uid > 0 and isContainer(t.uid) and t.actionid == 49631 then
			corpse = t
			break
		end
	end
	if not corpse then return end

	-- regra de frag/party: so coleta se o player for elegivel
	if not momoIsEligible(cid, corpse.uid) then return end

	local looted, failed = momoAutoLootContainer(cid, corpse)
	if looted then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, getLangString(cid, "You looted some items.", "Voce coletou alguns itens."))
	end
	if failed then
		-- aviso VERMELHO no centro da tela (client: MESSAGE_STATUS_WARNING -> MessageWarning -> centerRed)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, getLangString(cid, "Your capacity has been exceeded. Some items were left on the corpse.", "Sua capacidade se excedeu! Alguns itens ficaram no corpo."))
	end
end
