-- ==========================================================
-- HUNT WAYPOINT (server side)
-- ----------------------------------------------------------
-- Lê as configurações em data/huntwaypoint/*.lua e responde
-- os pedidos do client via extended opcode.
--
--   client -> server (opcode 169):
--     "list"              -> envia a lista de hunts (nome, looktype, exp, level)
--     "path:<nome>"       -> envia a localização da hunt (X,Y,Z)
--
--   server -> client (opcode 169):
--     "list|nome~looktype~exp~level;nome2~..."
--     "path|nome~x~y~z"   ou   "nopath|nome"
--
-- CONFIGURAÇÃO (um arquivo .lua por hunt em data/huntwaypoint/):
--   O NOME DO ARQUIVO é o nome da criatura (hífens/underscores viram
--   espaços). Ex.: terra_beetle.lua -> "Terra beetle".
--   Name, looktype (apparence) e exp são buscados AUTOMATICAMENTE do
--   monstro no servidor. O único campo obrigatório é a Location.
--   Campos explícitos, se existirem, sobrescrevem o automático.
--
--   Exemplo (terra_beetle.lua):
--     HuntWaypoint.register({
--       ["Location"] = {x = 448, y = 336, z = 7},
--     })
--
-- As localizações NUNCA vão na lista — só chegam ao client que
-- pedir o caminho daquela hunt específica.
-- ==========================================================

HuntWaypoint = {
  opcode = 169,
  configs = {},
}

-- Aceita Location nos formatos:
--   {x = 448, y = 336, z = 7}          (copia do mapa e cola direto)
--   "{x = 448, y = 336, z = 7}"        (mesmo, colado como string)
--   "448,336,7"                        (x,y,z simples)
function HuntWaypoint.parseLocation(loc)
  if type(loc) == "table" then
    return tonumber(loc.x) or 0, tonumber(loc.y) or 0, tonumber(loc.z) or 0
  end
  if type(loc) ~= "string" then
    return 0, 0, 0
  end
  -- "448,336,7"
  local x, y, z = loc:match("([%-%d]+)%s*,%s*([%-%d]+)%s*,%s*([%-%d]+)")
  if x then
    return tonumber(x), tonumber(y), tonumber(z)
  end
  -- "{x = 448, y = 336, z = 7}"
  x, y, z = loc:match("{x%s*=%s*([%-%d]+)%s*,%s*y%s*=%s*([%-%d]+)%s*,%s*z%s*=%s*([%-%d]+)%s*}")
  if x then
    return tonumber(x), tonumber(y), tonumber(z)
  end
  return 0, 0, 0
end

-- Nome da criatura a partir do nome do arquivo do config.
-- Ex.: "terra_beetle.lua" -> "Terra beetle"
function HuntWaypoint.fileMonsterName()
  -- O registro roda no topo de cada arquivo de config; o nome vem do ARQUIVO.
  -- Mas entre o config e esta funcao ha frames do proprio lib (register) e do
  -- pcall — debug.getinfo(2) retorna este lib, nao o config. Entao subimos a
  -- pilha ate o primeiro .lua que nao seja este lib.
  -- Obs.: o match captura o nome SEM a extensao (".lua" fica fora do grupo).
  local libFile = "huntWaypoint"
  for level = 2, 30 do
    local ok, di = pcall(debug.getinfo, level, "S")
    if not ok or not di then
      break
    end
    local src = di.source or ""
    local file = src:match("([^/\\]+)%.lua$") or ""
    if file ~= "" and file ~= libFile then
      return file:gsub("[-_]", " ")
    end
  end
  return ""
end

function HuntWaypoint.register(c)
  -- nome: campo explicito OU nome do arquivo
  local monsterName = c["Creature name"] or c.name or ""
  if monsterName == "" then
    monsterName = HuntWaypoint.fileMonsterName()
  end
  if monsterName == "" then
    monsterName = "?"
  end

  -- dados do monstro (case-insensitive)
  local name = monsterName
  local apparence = tonumber(c["Creature apparence"] or c.apparence) or 0
  local exp = tostring(c["Creature exp"] or c.exp or "")
  local ok, info = pcall(getMonsterInfo, monsterName)
  if ok and type(info) == "table" then
    if info.name and info.name ~= "" then
      name = info.name
    end
    if apparence == 0 and info.outfit then
      apparence = tonumber(info.outfit.lookType) or 0
    end
    if exp == "" and info.experience then
      exp = tostring(info.experience)
    end
  end

  local x, y, z = HuntWaypoint.parseLocation(c["Location"] or c.location)
  table.insert(HuntWaypoint.configs, {
    name = name,
    apparence = apparence,
    exp = exp,
    level = tostring(c["Recomended level"] or c.level or ""),
    x = x,
    y = y,
    z = z,
  })
end

function HuntWaypoint.loadConfigs()
  HuntWaypoint.configs = {}
  local ok, err = pcall(dodirectory, getDataDir() .. "huntwaypoint")
  if not ok then
    print("[HuntWaypoint] erro ao carregar configs: " .. tostring(err))
  end
  -- grade sempre em ordem de level recomendado (menor faixa primeiro)
  table.sort(HuntWaypoint.configs, function(a, b)
    local va = HuntWaypoint.levelValue(a)
    local vb = HuntWaypoint.levelValue(b)
    if va ~= vb then
      return va < vb
    end
    return a.name < b.name
  end)
  print("[HuntWaypoint] " .. #HuntWaypoint.configs .. " hunt(s) carregada(s)")
end

-- Primeiro numero da faixa de level ("25-35" -> 25); sem level vai pro fim.
function HuntWaypoint.levelValue(h)
  local lo = tostring(h.level or ""):match("(%d+)")
  return tonumber(lo) or math.huge
end

function HuntWaypoint.findHunt(name)
  local lower = name:lower()
  for _, h in ipairs(HuntWaypoint.configs) do
    if h.name:lower() == lower then
      return h
    end
  end
  return nil
end

function HuntWaypoint.sendList(cid)
  local parts = {}
  for _, h in ipairs(HuntWaypoint.configs) do
    table.insert(parts, string.format("%s~%d~%s~%s", h.name, h.apparence, h.exp, h.level))
  end
  doSendPlayerExtendedOpcode(cid, HuntWaypoint.opcode, "list|" .. table.concat(parts, ";"))
end

function HuntWaypoint.sendPath(cid, name)
  local h = HuntWaypoint.findHunt(name)
  if not h then
    doSendPlayerExtendedOpcode(cid, HuntWaypoint.opcode, "nopath|" .. name)
    return
  end
  doSendPlayerExtendedOpcode(cid, HuntWaypoint.opcode,
    string.format("path|%s~%d~%d~%d", h.name, h.x, h.y, h.z))
end
