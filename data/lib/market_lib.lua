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

local function buildItemLook(serverItemId, storedDesc)
  local info = getItemInfo(serverItemId)
  if type(info) ~= "table" then
    return storedDesc or ""
  end

  local lines = {}
  table.insert(lines, info.name or "")

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
         "(SELECT name FROM players WHERE `id` = player) AS player_name, cost, count, `desc` " ..
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
        desc       = rows:getDataString("desc") or ""
      })
    until not rows:next()
    rows:free()
  end
  return offers
end

-- Fetch ALL matching rows and filter by category in Lua (slow path, only used
-- when a specific category filter is active).
local function fetchAllFiltered(search, category)
  local rows = db.getResult(
    selectColumns() ..
    " WHERE " .. buildWhere(search) ..
    " ORDER BY id DESC"
  )

  local offers = {}
  if rows and rows:getID() ~= -1 then
    repeat
      local itemId = rows:getDataInt("item_id")
      if getItemCategory(itemId) == category then
        table.insert(offers, {
          id         = rows:getDataInt("id"),
          itemId     = itemId,
          itemName   = rows:getDataString("item_name") or "",
          player     = rows:getDataInt("player"),
          playerName = rows:getDataString("player_name") or "",
          cost       = rows:getDataLong("cost"),
          count      = rows:getDataInt("count"),
          desc       = rows:getDataString("desc") or ""
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
-- category fetches all matching rows and filters in Lua (markets are small).
function Market.getOffers(cid, pag, search, category)
  local pageRows
  local total

  if not category or category == "all" then
    total = sqlCount(search)
    local numPag = math.max(1, math.ceil(total / Market.limitPag))
    pag = (not pag or pag <= 0 or pag > numPag) and 1 or pag
    pageRows = fetchPage(search, Market.limitPag * (pag - 1))
  else
    local filtered = fetchAllFiltered(search, category)
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
      look     = buildItemLook(row.itemId, row.desc)
    })
  end

  return offers, total
end

function Market.sendOfferOtclient(cid, pag, search, category)
  local offers, total = Market.getOffers(cid, pag, search, category)
  local payload = "create>" .. total .. ">" .. table.tostring(offers)
  doSendPlayerExtendedOpcode(cid, Market.opcodes, payload)
end

function Market.sendSearchOtclient(cid, term, pag, category)
  Market.sendOfferOtclient(cid, pag or 1, term or "", category or "all")
end
