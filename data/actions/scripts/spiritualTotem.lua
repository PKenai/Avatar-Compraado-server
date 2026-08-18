-- Spiritual Totems: +1 attribute point each, once per character per totem location.
-- Several of each type can exist on the map; each one grants 1 point when used.
-- 18193 Earth, 18194 Fire, 18195 Air, 18196 Water
-- Vocations: 1 fire, 2 water, 3 air, 4 earth (5-8 = promoted same elements)

local TOTEMS = {
	[18193] = {voc = 4, name = "Spiritual Earth Totem", element = "terra"},
	[18194] = {voc = 1, name = "Spiritual Fire Totem", element = "fogo"},
	[18195] = {voc = 3, name = "Spiritual Air Totem", element = "ar"},
	[18196] = {voc = 2, name = "Spiritual Water Totem", element = "água"}
}

local function getBaseVocation(cid)
	local voc = getPlayerVocation(cid)
	if voc >= 5 and voc <= 8 then
		return voc - 4
	end
	return voc
end

local function getTotemStorageKey(item, fromPosition)
	-- Each totem on the map is identified by itemid + tile position,
	-- so several of the same type can each grant 1 point once.
	-- Items used from inventory/backpack use their runtime uid instead.
	local pos = fromPosition
	if not pos or not pos.x or pos.x >= 0xFF00 then
		return "spiritualTotem_uid_" .. item.uid
	end
	return string.format("spiritualTotem_%d_%d_%d_%d", item.itemid, pos.x, pos.y, pos.z)
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
	local totem = TOTEMS[item.itemid]
	if not totem then
		return false
	end

	local storageKey = getTotemStorageKey(item, fromPosition)
	if getPlayerStorageValue(cid, storageKey) == 1 then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Você já usou este totem neste personagem.")
		return true
	end

	if getBaseVocation(cid) ~= totem.voc then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Apenas dobradores de " .. totem.element .. " podem usar o " .. totem.name .. ".")
		return true
	end

	local pendentes = getPlayerStorageValue(cid, "pendentes")
	if type(pendentes) ~= "number" or pendentes < 0 then
		pendentes = 0
	end
	pendentes = pendentes + 1

	setPlayerStorageValue(cid, "pendentes", pendentes)
	setPlayerStorageValue(cid, storageKey, 1)
	doSendPlayerExtendedOpcode(cid, 41, tostring(pendentes))
	if getAtributosString then
		doSendPlayerExtendedOpcode(cid, 40, getAtributosString(cid))
	end

	doSendMagicEffect(getCreaturePosition(cid), 28)
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Seu espirito ficou mais forte, você acaba de ganhar 1 attribute point.")
	return true
end
