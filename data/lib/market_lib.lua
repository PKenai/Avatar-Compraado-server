-- ============================================================================
--  Market / Auction System - Server Library
--  Opcode 230  <->  client module "game_market"
--
--  Protocol (server -> client):
--    create>COUNT>{lua table of offers}
--    details>DESCRIPTION
--  Protocol (client -> server):
--    refresh>0
--    getOffer>PAGE>CATEGORY
--    search>TERM>PAGE>CATEGORY
--    details>OFFER_ID
--    resolve>ITEM NAME       -- janela "Adicionar Oferta" (nome digitado)
--    pick>{endereco do item} -- cliente antigo, com mira/crosshair
--
--  A oferta em si NAO entra por aqui: o cliente manda a talkaction
--  "!offer add, NOME, COUNT, PRICE" (data/talkactions/scripts/auctionsystem.lua),
--  que revalida posse/tier/limites e so' entao cobra o item.
-- ============================================================================

-- ----------------------------------------------------------------------------
--  Lua table -> Lua source serializer.
--  Used by the client (loadstring) and by other systems on this server
--  (inspect.lua / loot.lua) - DO NOT REMOVE.
-- ----------------------------------------------------------------------------
function table.val_to_str(v)
  if "string" == type(v) then
    v = string.gsub(v, "\\", "\\\\")
    v = string.gsub(v, "\n", "\\n")
    v = string.gsub(v, "\r", "\\r")
    v = string.gsub(v, '"', '\\"')
    return '"' .. v .. '"'
  end
  return "table" == type(v) and table.tostring(v) or tostring(v)
end

function table.key_to_str(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  end
  return "[" .. table.val_to_str(k) .. "]"
end

function table.tostring(tbl)
  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, table.val_to_str(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
    end
  end
  return "{" .. table.concat(result, ",") .. "}"
end

-- ----------------------------------------------------------------------------
--  Market library
-- ----------------------------------------------------------------------------
Market = {
  opcodes  = 230,
  limitPag = 15, -- must match the client (market.lua updateControlsPagination)
}

-- ----------------------------------------------------------------------------
--  Schema: the `tier` column.
--  Older databases were created before the market knew about item tiers, so the
--  column may be missing. Every read/write of the market needs it, so we make
--  sure it exists once per server run (same pattern used for the players'
--  `auction_balance` column).
-- ----------------------------------------------------------------------------
local schemaChecked = false

function Market.ensureSchema()
  if schemaChecked then
    return true
  end
  schemaChecked = true

  pcall(function()
    local colCheck = db.getResult("SELECT COUNT(*) AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'auction_system' AND COLUMN_NAME = 'tier';")
    if colCheck and colCheck:getID() ~= -1 then
      local exists = colCheck:getDataInt("c")
      colCheck:free()
      if exists == 0 then
        db.executeQuery("ALTER TABLE `auction_system` ADD COLUMN `tier` smallint NOT NULL DEFAULT 0;")
      end
    else
      -- Can't inspect the schema: try the ALTER directly, the pcall swallows
      -- the "duplicate column name" (1060) error when it already exists.
      db.executeQuery("ALTER TABLE `auction_system` ADD COLUMN `tier` smallint NOT NULL DEFAULT 0;")
    end
  end)

  return true
end

-- cache: serverItemId -> clientId (sprite id)
local clientIdCache = {}

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

-- cache: serverItemId -> category
local categoryCache = {}

-- Item category used by the client filter dropdown.
-- Slots (creature.h): 1=capacete 2=amuleto 4=armadura 7=calça 8=bota 9=anel.
-- Weapons: WEAPON_SHIELD=5 -> escudo, any other weaponType>0 -> arma.
local function getItemCategory(serverItemId)
  local cached = categoryCache[serverItemId]
  if cached ~= nil then
    return cached
  end

  local cat = "misc"
  local info = getItemInfo(serverItemId)
  if type(info) == "table" then
    local wt = tonumber(info.weaponType) or 0
    local wp = tonumber(info.wieldPosition) or 0
    if wt == 5 or wp == 6 then
      cat = "shield"
    elseif wt > 0 then
      cat = "weapon"
    elseif wp == 1 then
      cat = "helmet"
    elseif wp == 2 then
      cat = "amulet"
    elseif wp == 4 then
      cat = "armor"
    elseif wp == 7 then
      cat = "legs"
    elseif wp == 8 then
      cat = "boots"
    elseif wp == 9 then
      cat = "ring"
    end
  end

  categoryCache[serverItemId] = cat
  return cat
end

-- "look real" text sent to the client hover tooltip
local slotNames = {
  [1] = "Capacete", [2] = "Amuleto", [4] = "Armadura",
  [7] = "Calça", [8] = "Bota", [9] = "Anel"
}

local weaponTypeNames = {
  [1] = "Espada", [2] = "Maça", [3] = "Machado", [4] = "Distância",
  [5] = "Escudo", [6] = "Punho", [7] = "Varinha", [8] = "Munição"
}

-- Lua 5.1 string.format("%.2f") is locale-dependent (pt-BR prints "42,00").
-- Force a dot decimal separator for the weight line.
local function formatWeight(w)
  return string.format("%.2f", w):gsub(",", ".")
end

local function buildItemLook(serverItemId, storedDesc, tier)
  local info = getItemInfo(serverItemId)
  if type(info) ~= "table" then
    return storedDesc or ""
  end

  local lines = {}
  table.insert(lines, info.name or "")

  -- tier do item, na linha de baixo do nome (a lista do market mostra em amarelo)
  tier = tonumber(tier) or 0
  if tier > 0 then
    table.insert(lines, "Tier: " .. tier)
  end

  local wt = tonumber(info.weaponType) or 0
  local wp = tonumber(info.wieldPosition) or 0
  local typeName
  if wt == 5 or wp == 6 then
    typeName = "Escudo"
  elseif wt > 0 then
    typeName = weaponTypeNames[wt] or "Arma"
  else
    typeName = slotNames[wp]
  end
  if typeName then
    table.insert(lines, "Tipo: " .. typeName)
  end

  local atk = tonumber(info.attack) or 0
  if atk > 0 then
    local extra = tonumber(info.extraAttack) or 0
    if extra > 0 then
      table.insert(lines, "Ataque: " .. atk .. "+" .. extra)
    else
      table.insert(lines, "Ataque: " .. atk)
    end
  end

  local def = tonumber(info.defense) or 0
  if def > 0 then
    local extra = tonumber(info.extraDefense) or 0
    if extra > 0 then
      table.insert(lines, "Defesa: " .. def .. "+" .. extra)
    else
      table.insert(lines, "Defesa: " .. def)
    end
  end

  local arm = tonumber(info.armor) or 0
  if arm > 0 then
    table.insert(lines, "Armadura: " .. arm)
  end

  local w = tonumber(info.weight) or 0
  if w > 0 then
    table.insert(lines, "Peso: " .. formatWeight(w) .. " oz.")
  end

  local desc = storedDesc or ""
  if desc == "" then
    desc = info.description or ""
  end
  if desc ~= "" then
    table.insert(lines, "")
    table.insert(lines, desc)
  end

  return table.concat(lines, "\n")
end

local function escapeSql(str)
  return tostring(str or ""):gsub("'", "''")
end

local function escapeLike(str)
  local s = escapeSql(str)
  s = s:gsub("([%%_])", "%%%1")
  return s
end

local function buildWhere(search)
  local where = "expired = 0 AND world_id = " .. getConfigValue('worldId')
  if search and search ~= "" then
    where = where .. " AND LOWER(item_name) LIKE LOWER('%" .. escapeLike(search) .. "%')"
  end
  return where
end

-- Build the SELECT prefix shared by the paginated and filtered queries.
local function selectColumns()
  return "SELECT id, item_id, item_name, player, " ..
         "(SELECT name FROM players WHERE `id` = player) AS player_name, cost, count, `desc`, tier " ..
         "FROM auction_system"
end

-- Fetch a single page with SQL LIMIT/OFFSET (fast path, category "all").
local function fetchPage(search, offset)
  local rows = db.getResult(
    selectColumns() ..
    " WHERE " .. buildWhere(search) ..
    " ORDER BY id DESC LIMIT " .. Market.limitPag .. " OFFSET " .. offset
  )

  local offers = {}
  if rows and rows:getID() ~= -1 then
    repeat
      table.insert(offers, {
        id         = rows:getDataInt("id"),
        itemId     = rows:getDataInt("item_id"),
        itemName   = rows:getDataString("item_name") or "",
        player     = rows:getDataInt("player"),
        playerName = rows:getDataString("player_name") or "",
        cost       = rows:getDataLong("cost"),
        count      = rows:getDataInt("count"),
        desc       = rows:getDataString("desc") or "",
        tier       = tonumber(rows:getDataInt("tier")) or 0
      })
    until not rows:next()
    rows:free()
  end
  return offers
end

-- Fetch ALL matching rows and filter by category/tier in Lua (slow path, only
-- used when a specific category or tier filter is active).
local function fetchAllFiltered(search, category, tier)
  local rows = db.getResult(
    selectColumns() ..
    " WHERE " .. buildWhere(search) ..
    " ORDER BY id DESC"
  )

  local offers = {}
  if rows and rows:getID() ~= -1 then
    repeat
      local itemId = rows:getDataInt("item_id")
      local rowTier = tonumber(rows:getDataInt("tier")) or 0
      local categoryOk = (not category) or category == "all" or getItemCategory(itemId) == category
      local tierOk = (not tier) or tier <= 0 or rowTier == tier
      if categoryOk and tierOk then
        table.insert(offers, {
          id         = rows:getDataInt("id"),
          itemId     = itemId,
          itemName   = rows:getDataString("item_name") or "",
          player     = rows:getDataInt("player"),
          playerName = rows:getDataString("player_name") or "",
          cost       = rows:getDataLong("cost"),
          count      = rows:getDataInt("count"),
          desc       = rows:getDataString("desc") or "",
          tier       = rowTier
        })
      end
    until not rows:next()
    rows:free()
  end
  return offers
end

local function sqlCount(search)
  local row = db.getResult("SELECT COUNT(*) AS count FROM auction_system WHERE " .. buildWhere(search) .. ";")
  local count = 0
  if row and row:getID() ~= -1 then
    count = tonumber(row:getDataInt("count")) or 0
    row:free()
  end
  return count
end

function Market.getOfferDescription(offerId)
  local row = db.getResult("SELECT `desc` FROM `auction_system` WHERE `id` = " .. tostring(offerId) .. " AND `world_id` = " .. getConfigValue('worldId'))
  local desc = ""
  if row and row:getID() ~= -1 then
    desc = row:getDataString("desc") or ""
    row:free()
  end
  return desc
end

-- Returns (offers, total). "all"/nil uses SQL COUNT + LIMIT/OFFSET; any other
-- category (or an active tier filter) fetches all matching rows and filters in
-- Lua (markets are small).
function Market.getOffers(cid, pag, search, category, tier)
  Market.ensureSchema()

  tier = tonumber(tier) or 0
  if tier < 1 or tier > 10 then
    tier = 0
  end

  local pageRows
  local total

  if (not category or category == "all") and tier == 0 then
    total = sqlCount(search)
    local numPag = math.max(1, math.ceil(total / Market.limitPag))
    pag = (not pag or pag <= 0 or pag > numPag) and 1 or pag
    pageRows = fetchPage(search, Market.limitPag * (pag - 1))
  else
    local filtered = fetchAllFiltered(search, category, tier)
    total = #filtered
    local numPag = math.max(1, math.ceil(total / Market.limitPag))
    pag = (not pag or pag <= 0 or pag > numPag) and 1 or pag
    pageRows = {}
    local first = (pag - 1) * Market.limitPag + 1
    local last  = math.min(first + Market.limitPag - 1, total)
    for i = first, last do
      pageRows[#pageRows + 1] = filtered[i]
    end
  end

  local offers = {}
  for _, row in ipairs(pageRows) do
    table.insert(offers, {
      id       = row.id,
      itemId   = getClientId(row.itemId),
      itemName = row.itemName,
      type     = row.player == getPlayerGUID(cid) and 1 or 0,
      player   = row.playerName,
      price    = row.cost,
      count    = row.count,
      tier     = tonumber(row.tier) or 0,
      look     = buildItemLook(row.itemId, row.desc, row.tier)
    })
  end

  return offers, total
end

-- open = true manda o payload com o prefixo "open>", que e' a UNICA coisa que
-- faz o cliente abrir a janela do market. Sem o prefixo o payload e' so' dado
-- de lista (o cliente atualiza o conteudo se a janela ja' estiver aberta e nao
-- abre nada). Antes de existir essa distincao, QUALQUER resposta do servidor
-- abria a janela - e como o cliente pedia a lista sozinho ao entrar no jogo, o
-- market aparecia de graca no login (e no relog sem deslogar, caso em que o
-- guard de 5s do opcode 230 nao pega, porque o "timeLogin" continua sendo o do
-- login original).
function Market.sendOfferOtclient(cid, pag, search, category, tier, open)
  local offers, total = Market.getOffers(cid, pag, search, category, tier)
  local payload = "create>" .. total .. ">" .. table.tostring(offers)
  if open then
    payload = "open>" .. payload
  end
  doSendPlayerExtendedOpcode(cid, Market.opcodes, payload)
end

function Market.sendSearchOtclient(cid, term, pag, category, tier)
  Market.sendOfferOtclient(cid, pag or 1, term or "", category or "all", tier or 0)
end

-- Abre o market no cliente (usado pela action 50005 e por quem mais precisar
-- dar "use" no balcao). Primeira pagina, sem filtro.
function Market.sendOpenOtclient(cid)
  if not isPlayer(cid) then return false end
  Market.sendOfferOtclient(cid, 1, "", "all", 0, true)
  return true
end

-- ----------------------------------------------------------------------------
--  Item pick (crosshair da janela "Adicionar Oferta") - CLIENTE ANTIGO
--
--  O cliente atual do market nao usa mais isto: ele resolve por NOME
--  (Market.resolveName, mais abaixo). O bloco ficou porque o servidor e' um so'
--  para todo mundo e um cliente que ainda manda pick> continua funcionando.
--
--  The client sends the address of the item the player clicked (the same
--  encoding the tooltip module uses):
--    pick>{"slot":N}                  -- equipment slot / inventory slot N
--    pick>{"container":C,"slot":S}    -- open container C, slot S (backpack, depot,
--                                      --   bag inside a backpack, ...)
--    pick>{"pos":[x,y,z,stackpos]}     -- item on the map -> refused
--
--  The server answers with pickok>{...} (name, counts, tier) or pickerr>MESSAGE.
--  Nothing is removed here: this only TELLS the client which item is being sold,
--  and only when the item really belongs to the player (his inventory or one of
--  his depots). The offer itself is validated again - and only then charged -
--  by data/talkactions/scripts/auctionsystem.lua.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--  Quais itens podem ser vendidos no market.
--
--  Mesma regra usada pelo talkaction !offer (data/talkactions/scripts/
--  auctionsystem.lua) - que agora chama esta funcao -, so' que aqui ela roda no
--  momento do clique do crosshair: assim o jogador e' avisado na hora que o item
--  nao pode ser vendido, em vez de escolher preco/quantidade pra receber o erro.
--  Containers (mochilas, baus...) nunca passam: o item iria com o conteudo.
-- ----------------------------------------------------------------------------
Market.blockedItems = {} -- itens que nunca podem ser vendidos
Market.acceptedItems = {11259, 13041, 12686, 12687, 12688, 12689} -- moedas, scrolls e stones

function Market.isSellableItem(itemid)
  itemid = tonumber(itemid) or 0
  local info = getItemInfo(itemid)
  if type(info) ~= "table" then
    return false
  end

  if isInArray(Market.blockedItems, itemid) then
    return false
  end
  if isInArray(Market.acceptedItems, itemid) then
    return true
  end

  -- mochila / bau / qualquer coisa que caiba item dentro: nao
  if (tonumber(info.maxItems) or 0) > 0 then
    return false
  end
  -- itens stackaveis so' passam pela lista de aceitos acima
  if info.stackable then
    return false
  end

  -- capacete, amuleto, armadura, calca, bota, anel
  local wp = tonumber(info.wieldPosition) or 0
  if wp == 1 or wp == 2 or wp == 4 or wp == 7 or wp == 8 or wp == 9 then
    return true
  end

  return (tonumber(info.weaponType) or 0) > 0
end

-- How many of `itemid` the player has inside his depots (all lockers + reward
-- mailbox, nested containers included).
function Market.depotItemCount(cid, itemid)
  if type(getPlayerDepotContent) ~= "function" then
    return 0
  end

  local ok, content = pcall(getPlayerDepotContent, cid)
  if not ok or type(content) ~= "table" then
    return 0
  end

  for _, entry in ipairs(content) do
    if tonumber(entry.itemid) == itemid then
      return tonumber(entry.count) or 0
    end
  end
  return 0
end

-- An item that is not on the map (no tile) is inside a player inventory or a
-- player depot: Thing::getPosition() returns the tile position, and those
-- containers have no tile at all, so the position comes back as 0,0,0.
local function isOffMap(uid)
  local pos = getThingPosition(uid)
  if type(pos) ~= "table" then
    return false
  end
  return pos.x == 0 and pos.y == 0 and pos.z == 0
end

local function pickError(message)
  return { ok = false, error = message }
end

function Market.resolvePick(cid, payload)
  local decodedOk, data = pcall(function() return json.decode(payload) end)
  if not decodedOk or type(data) ~= "table" then
    return pickError("Nao foi possivel identificar o item selecionado.")
  end

  local thing

  if data.pos and type(data.pos) == "table" then
    -- clicking the map is always refused: only backpack/depot items are sellable
    return pickError("Voce so pode vender itens da sua mochila ou do seu deposito.")
  elseif data.container ~= nil then
    local containerIndex = tonumber(data.container)
    local slot = tonumber(data.slot)
    if not containerIndex or not slot then
      return pickError("Nao foi possivel identificar o item selecionado.")
    end

    local ok, container = pcall(getPlayerContainer, cid, containerIndex)
    if not ok or type(container) ~= "table" or not container.uid or container.uid <= 0 then
      return pickError("Abra a mochila (ou o deposito) que tem o item e tente de novo.")
    end

    local itemOk, item = pcall(getContainerItem, container.uid, slot)
    if not itemOk or type(item) ~= "table" then
      return pickError("Nao foi possivel ler o item selecionado.")
    end
    thing = item
  elseif data.slot ~= nil then
    local slot = tonumber(data.slot)
    if not slot then
      return pickError("Nao foi possivel identificar o item selecionado.")
    end

    local ok, item = pcall(getPlayerSlotItem, cid, slot)
    if not ok or type(item) ~= "table" then
      return pickError("Nao foi possivel ler o item selecionado.")
    end
    thing = item
  else
    return pickError("Nao foi possivel identificar o item selecionado.")
  end

  if not thing or not thing.uid or thing.uid <= 0 or not thing.itemid or thing.itemid <= 0 then
    return pickError("Nao ha nenhum item nesse lugar.")
  end

  local uid = thing.uid
  local itemid = thing.itemid

  -- 1st check: the item can not be on the map (ground, chest on the floor, ...)
  if not isOffMap(uid) then
    return pickError("Voce so pode vender itens da sua mochila ou do seu deposito.")
  end

  -- 2nd check: cross the item against the player's own inventory. Anything that
  -- is not found there must exist inside one of his depots.
  local source = "inventory"
  local owned = getPlayerItemById(cid, true, itemid)
  if not (owned and owned.uid == uid) then
    source = "depot"
    if Market.depotItemCount(cid, itemid) <= 0 then
      return pickError("Voce so pode vender itens da sua mochila ou do seu deposito.")
    end
  end

  local info = getItemInfo(itemid)

  -- 3rd check: item que o market nao aceita nem chega a abrir a janela
  if not Market.isSellableItem(itemid) then
    return pickError("Este item nao pode ser vendido no market.")
  end

  local tier = tonumber(getItemAttribute(uid, "tier")) or 0
  if tier < 0 or tier > 10 then
    tier = 0
  end

  local count = thing.type
  if type(count) ~= "number" or count <= 0 then
    count = 1
  end

  return {
    ok        = true,
    uid       = uid,
    itemId    = itemid,
    itemName  = (type(info) == "table" and info.name) or getItemNameById(itemid),
    count     = count,
    tier      = tier,
    source    = source,
    clientId  = getClientId(itemid),
    -- item unico (nao-stackavel) so' pode ser anunciado com quantidade 1: o
    -- cliente usa isso pra travar o campo de quantidade
    stackable = (type(info) == "table" and info.stackable == true) or false
  }
end

function Market.sendPickResult(cid, payload)
  local result = Market.resolvePick(cid, payload)
  if result.ok then
    result.ok = nil
    doSendPlayerExtendedOpcode(cid, Market.opcodes, "pickok>" .. json.encode(result))
  else
    doSendPlayerExtendedOpcode(cid, Market.opcodes, "pickerr>" .. tostring(result.error or "Item invalido."))
  end
end

-- ----------------------------------------------------------------------------
--  Resolve por NOME (janela "Adicionar Oferta" do cliente atual)
--
--  O cliente do market NAO tem tabela de nomes de item: o DAT/SPR dele carrega
--  so' o binario (modules/game_things/things.lua) e o engine nao chama
--  loadXml, entao "magic sword" nao existe do lado do cliente. Quem traduz o
--  que o jogador digitou para item e' o servidor:
--
--    resolve>NOME DIGITADO
--      -> itemok>{...}   itemName, clientId (sprite), count, stackable, source
--      -> itemerr>MOTIVO
--
--  Mesma resposta do pick (inclusive o campo `requested`, que o cliente usa
--  para descartar resposta de um nome que ele ja' trocou). O bloco do pick
--  continua aqui de proposito: cliente antigo que ainda manda pick> segue
--  funcionando.
--
--  Nada e' removido aqui - isto so' DIZ ao cliente qual item e' esse. A oferta
--  e' validada (e o item cobrado) em
--  data/talkactions/scripts/auctionsystem.lua, via "!offer add, NOME, COUNT, PRICE".
-- ----------------------------------------------------------------------------

-- getItemIdByName() do engine chama errorEx("Item not found") quando o nome nao
-- existe, o que imprime um bloco [Error - ...] no console a cada erro de
-- digitacao do jogador. O desvio e' o mesmo usado em
-- data/talkactions/scripts/createitem.lua: desligar o report de erro so' durante
-- a chamada e restaurar o valor anterior depois.
-- Devolve (itemId, erro). Nome com espaco sobrando ("magic sword , 1, 2000") e'
-- aparado aqui.
function Market.getItemIdByName(name)
  name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then
    return nil, "Digite o nome do item."
  end

  local previous = errors(false)
  local itemId = getItemIdByName(name)
  errors(previous)

  if not itemId or itemId <= 0 then
    return nil, "Nao existe item com este nome."
  end
  return itemId
end

function Market.resolveName(cid, name)
  if not isPlayer(cid) then
    return { ok = false, error = "Personagem invalido." }
  end

  local itemId, err = Market.getItemIdByName(name)
  if not itemId then
    return { ok = false, error = err }
  end

  -- mesma regra do crosshair e do !offer: item que o market nao vende nem
  -- chega a mostrar sprite
  if not Market.isSellableItem(itemId) then
    return { ok = false, error = "Este item nao pode ser vendido no market." }
  end

  local info = getItemInfo(itemId)

  -- Quantidades separadas: a mochila e' getPlayerItemCount, o deposito e' o
  -- mesmo helper do !offer (Market.depotItemCount). O jogador pode anunciar
  -- somando as duas, porque o talkaction puxa o que falta do deposito.
  local inBackpack = tonumber(getPlayerItemCount(cid, itemId)) or 0
  local inDepot = Market.depotItemCount(cid, itemId)
  if (inBackpack + inDepot) <= 0 then
    return { ok = false, error = "Voce nao tem esse item na mochila nem no deposito." }
  end

  return {
    ok         = true,
    -- eco do texto digitado: o cliente descarta a resposta se o campo ja' mudou
    requested  = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", ""),
    itemId     = itemId,
    itemName   = (type(info) == "table" and info.name) or getItemNameById(itemId),
    clientId   = getClientId(itemId),
    count      = inBackpack + inDepot,
    inBackpack = inBackpack,
    inDepot    = inDepot,
    source     = inBackpack > 0 and "inventory" or "depot",
    -- o tier e' do item (uid), nao do nome: quem le' e' o !offer, no item que
    -- ele realmente for remover. Por isso nao vai tier aqui.
    stackable  = (type(info) == "table" and info.stackable == true) or false
  }
end

function Market.sendNameResult(cid, name)
  local result = Market.resolveName(cid, name)
  if result.ok then
    result.ok = nil
    doSendPlayerExtendedOpcode(cid, Market.opcodes, "itemok>" .. json.encode(result))
  else
    doSendPlayerExtendedOpcode(cid, Market.opcodes, "itemerr>" .. tostring(result.error or "Item invalido."))
  end
end
