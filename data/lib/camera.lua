-- ============================================================================
-- CAMERA (item 18432) — slot real no inventario (slot 11)
-- ----------------------------------------------------------------------------
-- O server agora tem um slot de equipamento dedicado (SLOT_CAMERA = 11),
-- compilado na source. So a camera pode equipar nesse slot, e o slot 11 e
-- excluido de TODOS os fluxos de drop de morte — a camera JAMAIS e dropada.
--
-- Comando do client (opcode 206, JSON {action="camera", data={cmd="toggle"}}):
--   toggle -> liga/desliga a TV (mesma logica do uso do item 18432)
-- ============================================================================

CAMERA_ITEM_ID = 18432   -- camera base (comprada)
CAMERA_ITEM_ON = 18433   -- camera LIGADA (canal on)
CAMERA_ITEM_OFF = 18434  -- camera DESLIGADA (canal off)
CAMERA_OPCODE = 206
CAMERA_SLOT = 11
CAMERA_DEPOT = 1

-- true se o item e qualquer variante da camera (base, on ou off)
function isCameraItemId(itemid)
	return itemid == CAMERA_ITEM_ID or itemid == CAMERA_ITEM_ON or itemid == CAMERA_ITEM_OFF
end

-- Troca a camera no slot 11 para a variante do estado (on/off). O client
-- recebe o UpdateInventoryItem do slot e atualiza o visual sozinho.
function cameraSetStateItem(cid, itemId)
	local slotItem = getPlayerSlotItem(cid, CAMERA_SLOT)
	if slotItem and slotItem.uid and slotItem.uid > 0 and slotItem.itemid ~= itemId then
		doTransformItem(slotItem.uid, itemId)
	end
end

-- Desliga a TV (cast) se estiver transmitindo. Idempotente: se nao estiver
-- transmitindo, nao faz nada (nao reabre canal nem envia mensagem).
function cameraOff(cid)
	local data = getPlayerSpectators(cid)
	if data.broadcast then
		data.mutes = {}
		data.broadcast = false
		doPlayerSetSpectators(cid, data)
		db.executeQuery("UPDATE `players` SET `broadcasting` = 0, `viewers` = 0 WHERE `id` = " .. getPlayerGUID(cid))
		doPlayerClosePrivateChannel(cid) -- fecha a aba do canal no chat (dijuntor)
		cameraSetStateItem(cid, CAMERA_ITEM_OFF) -- camera desligada
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You have disabled your live stream.")
	end
end

-- Liga/desliga a TV (cast) — mesma logica do /cast on|off e do item 18432.
function cameraToggle(cid)
	if isCreature(getCreatureTarget(cid)) and getCreatureName(getCreatureTarget(cid)) == "Target" then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You cannot turn on cast while training.")
		return
	end
	if isPremium(cid) then
		local data = getPlayerSpectators(cid)
		if data.broadcast then
			cameraOff(cid)
		else
			data.broadcast = true
			doPlayerSetSpectators(cid, data)
			doPlayerOpenPrivateChannel(cid)
			db.executeQuery("UPDATE `players` SET `broadcasting` = 1 WHERE `id` = " .. getPlayerGUID(cid))
			cameraSetStateItem(cid, CAMERA_ITEM_ON) -- camera ligada
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You have enabled your live stream.")
		end
	else
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You can only use Cast System if you are Premium Account.")
	end
end

-- Guarda a camera num lugar seguro: primeiro tenta o slot 11 (se estiver
-- vazio), senao vai pro deposito.
function cameraAddToSafeSlot(cid)
	local slotItem = getPlayerSlotItem(cid, CAMERA_SLOT)
	if not slotItem or slotItem.itemid == 0 then
		local ok = doPlayerAddItem(cid, CAMERA_ITEM_ID, 1, false, 1, CAMERA_SLOT)
		if ok then
			return true
		end
	end
	return doPlayerAddItemToDepot(cid, CAMERA_DEPOT, CAMERA_ITEM_ID, 1)
end

-- Move qualquer camera solta no inventario do player (slots 1-10 + mochilas)
-- para um lugar seguro. Chamado no onDeath (que roda ANTES do dropLoot neste
-- server) — o slot 11 em si nunca entra no fluxo de drop.
function cameraMoveToDepot(cid)
	local moved = false
	for slot = 1, 10 do
		local item = getPlayerSlotItem(cid, slot)
		if item and item.uid and item.uid > 0 then
			if isCameraItemId(item.itemid) then
				doRemoveItem(item.uid, 1)
				cameraAddToSafeSlot(cid)
				moved = true
			elseif isContainer(item.uid) then
				if cameraScanContainer(cid, item.uid) then
					moved = true
				end
			end
		end
	end
	return moved
end

function cameraScanContainer(cid, containerId)
	local moved = false
	local size = getContainerSize(containerId)
	if size < 0 then
		return false
	end
	for i = size - 1, 0, -1 do
		local item = getContainerItem(containerId, i)
		if item and item.uid and item.uid > 0 then
			if isCameraItemId(item.itemid) then
				doRemoveItem(item.uid, 1)
				cameraAddToSafeSlot(cid)
				moved = true
			elseif isContainer(item.uid) then
				if cameraScanContainer(cid, item.uid) then
					moved = true
				end
			end
		end
	end
	return moved
end

-- No login o cast sempre comeca desligado: se a camera estiver na variante
-- "On" (18433), volta para "Off" (18434) para o estado bater com a realidade.
function cameraNormalizeOnLogin(cid)
	-- o cast sempre comeca desligado: limpa o flag do banco (se o server caiu,
	-- ele pode ter ficado preso) e volta a camera "On" para "Off".
	db.executeQuery("UPDATE `players` SET `broadcasting` = 0, `viewers` = 0 WHERE `id` = " .. getPlayerGUID(cid))
	local slotItem = getPlayerSlotItem(cid, CAMERA_SLOT)
	if slotItem and slotItem.uid and slotItem.uid > 0 then
		if slotItem.itemid == CAMERA_ITEM_ON then
			cameraSetStateItem(cid, CAMERA_ITEM_OFF)
		end
	end
end

