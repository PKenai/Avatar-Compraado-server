-- ============================================================================
--  Depot Search - busca de itens no depósito do jogador (a "lupa")
--  Opcode 233  <->  client (busca nativa na janela do container)
--
--  Protocolo (client -> server): search>TERMO
--                                take>ITEMID>COUNT  (pega item do depósito)
--  Protocolo (server -> client): search>TOTAL>{tabela de resultados}
--    cada resultado: { id=spriteId, name=nome, count=total, itemid=serverId }
--
--  A busca roda no servidor (não no client) porque o pacote de abertura do
--  container só envia até 255 itens ao client - com o baú de 2000 slots,
--  filtrar localmente não acharia nada além dos 255 primeiros.
-- ============================================================================

DepotSearch = {
	opcodes = 233,
	limit   = 200, -- máx. de resultados enviados por busca
}

local clientIdCache = {}
local nameCache = {}

local function getItemDisplayName(serverItemId)
	local cached = nameCache[serverItemId]
	if cached ~= nil then
		return cached
	end

	local name = ""
	local info = getItemInfo(serverItemId)
	if type(info) == "table" and info.name then
		name = info.name
	end

	nameCache[serverItemId] = name
	return name
end

local function getClientId(serverItemId)
	local cached = clientIdCache[serverItemId]
	if cached ~= nil then
		return cached
	end

	local cid = 0
	local info = getItemInfo(serverItemId)
	if type(info) == "table" then
		cid = tonumber(info.clientId) or 0
	end

	clientIdCache[serverItemId] = cid
	return cid
end

function DepotSearch.search(cid, term)
	term = tostring(term or "")
	term = term:gsub("^%s+", ""):gsub("%s+$", "")
	local needle = string.lower(term)

	print("[DepotSearch] search cid=" .. tostring(cid) .. " term='" .. tostring(term) .. "' needle='" .. needle .. "'")

	local entries = getPlayerDepotContent(cid)
	if type(entries) ~= "table" then
		print("[DepotSearch] getPlayerDepotContent returned nil or not table")
		doSendPlayerExtendedOpcode(cid, DepotSearch.opcodes, "search>0>{}")
		return
	end

	print("[DepotSearch] entries count: " .. #entries)
	if #entries > 0 then
		-- Log primeiros 5 itens pra debug
		local debugCount = math.min(5, #entries)
		for i = 1, debugCount do
			local e = entries[i]
			print("[DepotSearch] entry[" .. i .. "] itemid=" .. tostring(e.itemid) .. " count=" .. tostring(e.count))
		end
	end

	local results = {}
	local total = 0
	for _, e in ipairs(entries) do
		local itemid = tonumber(e.itemid)
		if itemid then
			local name = getItemDisplayName(itemid)
			if needle == "" or string.find(string.lower(name), needle, 1, true) then
				total = total + 1
				if total <= DepotSearch.limit then
					table.insert(results, {
						id     = getClientId(itemid),
						name   = name,
						count  = tonumber(e.count) or 1,
						itemid = itemid,
					})
				end
			end
		end
	end

	print("[DepotSearch] results: total=" .. total .. " showing=" .. #results)
	local response = "search>" .. total .. ">" .. table.tostring(results)
	print("[DepotSearch] response length: " .. #response)
	doSendPlayerExtendedOpcode(cid, DepotSearch.opcodes, response)
end

function DepotSearch.take(cid, itemid, count)
	itemid = tonumber(itemid) or 0
	count = tonumber(count) or 0
	if itemid <= 0 then
		return
	end

	print("[DepotSearch] take cid=" .. tostring(cid) .. " itemid=" .. itemid .. " count=" .. count)
	local moved = takePlayerDepotItem(cid, itemid, count)
	if moved and moved > 0 then
		print("[DepotSearch] take SUCCESS moved=" .. moved)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Você pegou " .. moved .. "x " .. getItemNameById(itemid) .. " do depósito (enviado para a mochila).")
	else
		print("[DepotSearch] take FAILED")
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
			"Não foi possível pegar " .. getItemNameById(itemid) .. " do depósito.")
	end
end
