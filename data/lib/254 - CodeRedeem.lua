CodeRedeem = CodeRedeem or {}

CodeRedeem.cfg = CodeRedeem.cfg or {
  opcodeShow = 44,
  opcodeAction = 45,

  text = {
    invalid = "Codigo invalido.",
    already = "Voce ja resgatou esse codigo.",
    expired = "Codigo expirado.",
    limit = "Codigo esgotado (limite de %d usos).",
    ok = "Codigo resgatado com sucesso.",
    receivedPrefix = "Voce recebeu:"
  },

  -- Os codigos ficam em data/lib/codes_data.lua (gerados pelo
  -- gerador_codigos.bat). O servidor relê esse arquivo do disco a
  -- CADA resgate, entao codigos novos entram sem reiniciar o servidor.
  codesFile = "lib/codes_data.lua",
  usedFile = "lib/codes_used.lua",
  codes = {}
}

local function trim(s)
  s = tostring(s or "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

-- Dobra acentos (aceita ç, é, ã, õ, ~ etc. em latin1 OU utf-8) para a
-- letra base. Assim digitar PROMOCAO / PROMOCÃO / promoção dá no mesmo.
local function foldAccents(s)
  -- utf-8: 2 bytes por acento
  local utf8Map = {
    ["\195\128"] = "A", ["\195\129"] = "A", ["\195\130"] = "A",
    ["\195\131"] = "A", ["\195\132"] = "A", ["\195\133"] = "A",
    ["\195\160"] = "A", ["\195\161"] = "A", ["\195\162"] = "A",
    ["\195\163"] = "A", ["\195\164"] = "A", ["\195\165"] = "A",
    ["\195\136"] = "E", ["\195\137"] = "E", ["\195\138"] = "E",
    ["\195\139"] = "E", ["\195\168"] = "E", ["\195\169"] = "E",
    ["\195\170"] = "E", ["\195\171"] = "E",
    ["\195\140"] = "I", ["\195\141"] = "I", ["\195\142"] = "I",
    ["\195\143"] = "I", ["\195\172"] = "I", ["\195\173"] = "I",
    ["\195\174"] = "I", ["\195\175"] = "I",
    ["\195\146"] = "O", ["\195\147"] = "O", ["\195\148"] = "O",
    ["\195\149"] = "O", ["\195\150"] = "O", ["\195\152"] = "O",
    ["\195\178"] = "O", ["\195\179"] = "O", ["\195\180"] = "O",
    ["\195\181"] = "O", ["\195\182"] = "O", ["\195\184"] = "O",
    ["\195\153"] = "U", ["\195\154"] = "U", ["\195\155"] = "U",
    ["\195\156"] = "U", ["\195\185"] = "U", ["\195\186"] = "U",
    ["\195\187"] = "U", ["\195\188"] = "U",
    ["\195\157"] = "Y", ["\195\189"] = "Y", ["\195\159"] = "Y",
    ["\195\191"] = "Y", ["\195\145"] = "N", ["\195\177"] = "N",
    ["\195\135"] = "C", ["\195\167"] = "C"
  }
  -- latin1: 1 byte por acento
  local latinMap = {
    ["\192"] = "A", ["\193"] = "A", ["\194"] = "A", ["\195"] = "A",
    ["\196"] = "A", ["\197"] = "A", ["\224"] = "A", ["\225"] = "A",
    ["\226"] = "A", ["\227"] = "A", ["\228"] = "A", ["\229"] = "A",
    ["\200"] = "E", ["\201"] = "E", ["\202"] = "E", ["\203"] = "E",
    ["\232"] = "E", ["\233"] = "E", ["\234"] = "E", ["\235"] = "E",
    ["\204"] = "I", ["\205"] = "I", ["\206"] = "I", ["\207"] = "I",
    ["\236"] = "I", ["\237"] = "I", ["\238"] = "I", ["\239"] = "I",
    ["\210"] = "O", ["\211"] = "O", ["\212"] = "O", ["\213"] = "O",
    ["\214"] = "O", ["\216"] = "O", ["\242"] = "O", ["\243"] = "O",
    ["\244"] = "O", ["\245"] = "O", ["\246"] = "O", ["\248"] = "O",
    ["\217"] = "U", ["\218"] = "U", ["\219"] = "U", ["\220"] = "U",
    ["\249"] = "U", ["\250"] = "U", ["\251"] = "U", ["\252"] = "U",
    ["\221"] = "Y", ["\253"] = "Y", ["\255"] = "Y",
    ["\209"] = "N", ["\241"] = "N", ["\199"] = "C", ["\231"] = "C"
  }
  for k, v in pairs(utf8Map) do
    s = s:gsub(k, v)
  end
  for k, v in pairs(latinMap) do
    s = s:gsub(k, v)
  end
  return s
end

local function normalizeCode(s)
  s = trim(s)
  s = s:gsub("%s+", "")
  s = foldAccents(s)
  s = s:upper()
  return s
end

-- ---------------------------------------------------------------------------
-- Relê os codigos do disco (data/lib/codes_data.lua).
-- Chamado no startup e a cada resgate, para codigos gerados pelo
-- gerador_codigos.bat entrarem imediatamente, sem reiniciar.
-- ---------------------------------------------------------------------------
function CodeRedeem.loadCodes()
  local ok, err = pcall(dofile, getDataDir() .. CodeRedeem.cfg.codesFile)
  if not ok then
    print("[CodeRedeem] Erro ao ler codes_data.lua: " .. tostring(err))
    return false
  end
  if type(CodeRedeemData) == "table" then
    -- Reconstroi as chaves dobrando acentos, para aceitar codigos
    -- escritos com acento no arquivo tambem.
    local folded = {}
    for k, v in pairs(CodeRedeemData) do
      folded[normalizeCode(k)] = v
    end
    CodeRedeem.cfg.codes = folded
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Contador de usos por codigo (limite de resgates).
-- Persistente em data/lib/codes_used.lua, que o gerador_codigos.bat tambem
-- le para mostrar "usos X de Y" e zera quando o codigo e deletado.
-- ---------------------------------------------------------------------------
function CodeRedeem.getUsedCount()
  local path = getDataDir() .. CodeRedeem.cfg.usedFile
  CodeRedeemUsed = nil
  local ok = pcall(dofile, path)
  if ok and type(CodeRedeemUsed) == "table" then
    return CodeRedeemUsed
  end
  return {}
end

function CodeRedeem.saveUsedCount(tbl)
  local path = getDataDir() .. CodeRedeem.cfg.usedFile
  local keys = {}
  for k in pairs(tbl) do
    keys[#keys + 1] = k
  end
  table.sort(keys)

  local lines = { "CodeRedeemUsed = {" }
  for i = 1, #keys do
    lines[#lines + 1] = string.format('  ["%s"] = %d,', keys[i], tonumber(tbl[keys[i]]) or 0)
  end
  lines[#lines + 1] = "}"

  -- Grava em arquivo temporario e renomeia: se o servidor cair no meio
  -- da escrita, o arquivo antigo continua intacto (nunca fica truncado).
  local tmp = path .. ".tmp"
  local f = io.open(tmp, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
    os.remove(path)
    os.rename(tmp, path)
  end
end

local function cr_getClientItemId(serverItemId)
  serverItemId = tonumber(serverItemId) or 0
  if serverItemId <= 0 then return 0 end
  local info = getItemInfo(serverItemId)
  if type(info) == "table" and info.clientId and info.clientId > 0 then
    return info.clientId
  end
  return serverItemId
end

local function getItemNameSafe(itemId)
  itemId = tonumber(itemId) or 0
  if itemId <= 0 then return "Item" end
  local name = getItemNameById(itemId)
  if type(name) ~= "string" or name == "" then return "Item" end
  return name
end

local function buildAutoMessage(items)
  if type(items) ~= "table" or #items == 0 then
    return CodeRedeem.cfg.text.ok
  end

  local parts = {}
  for i = 1, #items do
    local it = items[i]
    local id = tonumber(it[1]) or 0
    local count = tonumber(it[2]) or 1
    if id > 0 and count > 0 then
      local name = getItemNameSafe(id)
      parts[#parts + 1] = string.format("%dx %s", count, name)
    end
  end

  if #parts == 0 then
    return CodeRedeem.cfg.text.ok
  end

  return CodeRedeem.cfg.text.receivedPrefix .. " " .. table.concat(parts, ", ") .. "."
end

function CodeRedeem.sendResult(cid, ok, msg, code, items)
  local status = ok and "ok" or "err"
  local out = "result@" .. status .. "@" .. tostring(msg or "")

  if ok then
    out = out .. "@" .. tostring(code or "")
    if items then
      for i = 1, #items do
        local it = items[i]
        local sid = tonumber(it[1]) or 0
        local clientId = cr_getClientItemId(sid)
        local count = tonumber(it[2]) or 1
        local name = getItemNameSafe(sid)

        if clientId > 0 then
          out = out .. "@" .. clientId .. "@" .. count .. "@" .. name
        end
      end
    end
  end

  doSendPlayerExtendedOpcode(cid, CodeRedeem.cfg.opcodeShow, out)
end

function CodeRedeem.open(cid)
  doSendPlayerExtendedOpcode(cid, CodeRedeem.cfg.opcodeShow, "show")
end

function CodeRedeem.redeem(cid, code)
  -- Relê os codigos do disco: codigo novo gerado pelo .bat ja vale agora.
  CodeRedeem.loadCodes()

  code = normalizeCode(code)
  if code == "" then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.invalid)
    return true
  end

  local entry = CodeRedeem.cfg.codes[code]
  if not entry then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.invalid)
    return true
  end

  -- Expiração (timestamp unix absoluto; 0/ausente = não expira)
  local expire = tonumber(entry.expire) or 0
  if expire > 0 and os.time() >= expire then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.expired)
    return true
  end

  local st = tonumber(entry.storage) or 0
  if st <= 0 then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.invalid)
    return true
  end

  if getPlayerStorageValue(cid, st) == 1 then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.already)
    return true
  end

  -- Limite de uso: so X pessoas podem resgatar (0 ou ausente = sem limite)
  local maxUses = tonumber(entry.maxUses) or 0
  if maxUses > 0 then
    local usedTbl = CodeRedeem.getUsedCount()
    local used = tonumber(usedTbl[code]) or 0
    if used >= maxUses then
      CodeRedeem.sendResult(cid, false, string.format(CodeRedeem.cfg.text.limit, maxUses))
      return true
    end
  end

  local items = entry.items or {}
  for i = 1, #items do
    local it = items[i]
    local id = tonumber(it[1]) or 0
    local count = tonumber(it[2]) or 1
    if id > 0 and count > 0 then
      doPlayerAddItem(cid, id, count)
    end
  end

  setPlayerStorageValue(cid, st, 1)

  -- Contabiliza o uso (persistente em codes_used.lua)
  if maxUses > 0 then
    local usedTbl = CodeRedeem.getUsedCount()
    usedTbl[code] = (tonumber(usedTbl[code]) or 0) + 1
    CodeRedeem.saveUsedCount(usedTbl)
  end

  local msg = entry.message
  if type(msg) ~= "string" or msg == "" then
    msg = buildAutoMessage(items)
  end

  CodeRedeem.sendResult(cid, true, msg, code, items)
  return true
end

function CodeRedeem.onExtendedOpcode(cid, opcode, buffer)
  if opcode ~= CodeRedeem.cfg.opcodeAction then
    return false
  end

  buffer = tostring(buffer or "")
  if buffer == "" then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.invalid)
    return true
  end

  local p = buffer:explode("@")
  if p[1] ~= "redeem" then
    CodeRedeem.sendResult(cid, false, CodeRedeem.cfg.text.invalid)
    return true
  end

  local code = p[2] or ""
  return CodeRedeem.redeem(cid, code)
end

-- Carrega os codigos iniciais no startup (os exemplos ERICK/CODE
-- estao em codes_data.lua agora).
CodeRedeem.loadCodes()
