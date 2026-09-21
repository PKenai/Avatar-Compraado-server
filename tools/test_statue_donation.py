#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================================
 TESTE DO STATUE DONATION (data/lib/statueDonation.lua)
============================================================================
 Roda a lib DE VERDADE (o proprio arquivo do datapack) dentro de um
 interpretador Lua, com stubs da API do engine, e confere as regras de
 dinheiro/bonus:

   * mapeamento vocacao -> elemento (inclusive as promovidas 5..8)
   * doacao parcial / meta de 150k / cobrar so' o que falta
   * nacao abencoada nao aceita mais doacao
   * abas globais EXP (350k) e POTIONS (400k) TAMBEM com POOL: qualquer valor
     acumula, a bencao ativa quando o pool bate a meta e, ativa, o pool nao
     aceita mais nada (nao cobra nem guarda pro proximo ciclo)
   * gold sai do inventario e, o que faltar, do banco
   * +5% do idle (getExpBonus) e +15% de cura das potions
     (getPotionHealMultiplier, consultado pelo bloodRoom/fullPotion.lua)
   * icone de buff so' para quem tem direito (nacao = statue_<elemento>,
     aba Potions = potion) - nos DOIS modos:
       - "raw"    = build antigo: manda opcode 100 na mao
       - "native" = buff.h novo + recompilado: doCreatureAddBuff
   * persistencia (save/restart): o estado vive no banco (relogio unix), entao
     pool e bencao viva sobrevivem; o reconcile (StatueDonation.sweep) devolve
     o icone que sumiu (morte limpa os buffs do creature) e o login reenvia
     tudo com force = true. O db fake do teste guarda as linhas de verdade
     (FAKEDB.rows) - o servidor tem VARIAS copias desta lib (um lua_State por
     categoria de script) e o banco e' a unica memoria compartilhada entre elas:
     com um banco de mentira vazio, o teste provaria so' a memoria de uma copia
   * bencao ativada por OUTRA interface (o bug do modulo mostrando "not blessed"
     com a bencao viva): abrir a janela/doar relê o banco e ja' responde o estado
     novo, em vez de ficar no retrato do primeiro uso daquela copia da lib
   * entradas invalidas (texto, valor negativo/absurdo, JSON quebrado)
   * expiracao (relogio falso: +12h derruba tudo e o pool volta a encher)
   * comando de staff !resetstatue (talkaction de verdade, carregada aqui):
     permissao, estado, chave invalida, zerar pool (nacao E aba global),
     encerrar bencao e tirar o buff de todos - de quem esta' online na hora e
     de quem loga depois (o estado novo nao reativa nada) - e o "all"

 Uso:
     python tools/test_statue_donation.py

 Precisa de um Lua 5.3/5.4 64-bit (o XAMPP traz um em
 C:/xampp/apache/bin/lua54.dll). O lua51.dll do servidor e' 32-bit e o
 Python deste host e' 64-bit, entao ele nao serve de host.
============================================================================
"""

import ctypes
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER_ROOT = os.path.dirname(HERE)
DATA_DIR = os.path.join(SERVER_ROOT, "data").replace("\\", "/") + "/"

DLL_CANDIDATES = [
    "C:/xampp/apache/bin/lua54.dll",
    "C:/xampp/apache/bin/lua53.dll",
    os.path.join(SERVER_ROOT, "lua51.dll"),
]

LUA_TESTS = r"""
unpack = table.unpack

local DIR = "__DIR__"
local NATIVE = __NATIVE__   -- true = buff oficial (build recompilado)

-- ===== relogio falso (a lib chama os.time() em runtime) =====
FAKE = 1000000
os.time = function() return FAKE end

-- ===== stubs do engine =====
SENT, BROADCASTS, QUERIES, STOR, BUFFS = {}, {}, {}, {}, {}
function doSendPlayerExtendedOpcode(cid, op, buf) table.insert(SENT, {cid=cid, op=op, buf=buf}) end
function doBroadcastMessage(text, t) table.insert(BROADCASTS, text) end
function doPlayerSendTextMessage(cid, t, msg) table.insert(SENT, {cid=cid, msg=msg}) end
function doPlayerSendCancel(cid, msg) table.insert(SENT, {cid=cid, msg=msg}) end
function doSendMagicEffect() end
function getThingPos(cid) return {x=0,y=0,z=0} end
function registerBuffType(...) return NATIVE end
function doCreatureAddBuffWithTime(cid, id, ms) BUFFS[id] = ms end
function doCreatureRemoveBuff(cid, id) BUFFS[id] = nil end
function doCreatureHasBuff(cid, id) return BUFFS[id] ~= nil end
-- no modo cru o engine NAO sabe responder isso: a lib cai no mapa interno
if not NATIVE then doCreatureHasBuff = nil end
function addEvent(fn, ms) return 1 end
function removeEvent() end
function getPlayersOnline() return {1} end
function getPlayerStorageValue(cid, k) return STOR[k] or -1 end
function setPlayerStorageValue(cid, k, v) STOR[k] = v end

MESSAGE_INFO_DESCR = 19
MESSAGE_STATUS_CONSOLE_BLUE = 24
CONST_ME_MAGIC_BLUE = 12

VOC = { [1]=1, [2]=2, [3]=3, [4]=4, [5]=5, [6]=6, [7]=7, [8]=8 }
P = { money = 600000, bank = 0 }
function isPlayer(cid) return VOC[cid] ~= nil end
function getPlayerVocation(cid) return VOC[cid] end
function getPlayerMoney(cid) return P.money end
function doPlayerRemoveMoney(cid, amount)
  if P.money < amount then return false end
  P.money = P.money - amount
  return true
end
function getPlayerBankBalance(cid) return P.bank end
function doPlayerSetBalance(cid, value)
  if value < 0 then return false end
  P.bank = value
  return true
end
function doPlayerAddMoney(cid, amount) P.money = P.money + amount; return true end

-- db fake COM MEMORIA: as linhas vivem aqui, como no MySQL do servidor.
--
-- Nao da' pra testar esta lib com um banco vazio: o estado (pool + bonus_until)
-- e' lido da tabela em toda mudanca, porque a engine roda data/lib uma vez por
-- categoria de script (actions, creatureevent, globalevent...) e cada copia
-- tem a sua propria memoria. O banco e' a UNICA memoria compartilhada entre
-- elas. Com um banco de mentira sem memoria, o teste provaria so' a memoria de
-- uma copia - e e' justamente a copia do ACTIONS ficando com o retrato velho o
-- bug que o usuario viu (icone do buff some e a janela diz "not blessed").
--
-- FAKEDB.rows e' publico de proposito: o teste escreve nele pra simular OUTRA
-- interface (outro lua_State) mexendo no banco, sem passar por esta copia.
-- applied = os UPDATEs que o banco REALMENTE aplicou (o WHERE casou). E' o que
-- prova "ativar 2x = 1 ciclo": as duas queries sao enviadas, mas so' uma entra.
FAKEDB = { rows = {}, applied = {} }   -- name -> { pool = n, bonus_until = n }

-- Gancho pra simular OUTRA copia da lib (outro lua_State) escrevendo no banco
-- NO MEIO de uma query nossa: e' assim que se testa a corrida de duas pontas
-- ativando o mesmo ciclo. Recebe o SQL que esta' prestes a ser aplicado e pode
-- mexer em FAKEDB.rows antes; quem instala se desinstala (FAKEDB.beforeWrite = nil).
FAKEDB.beforeWrite = nil

-- ---------------------------------------------------------------------------
-- Mini-SQL. Os UPDATEs da lib nao sao mais "escreve o valor X": eles fazem CONTA
-- e tem CONDICAO no proprio SQL (`pool` = `pool` - 150000 WHERE `bonus_until` <=
-- agora AND `pool` >= 150000). O banco de mentira precisa aplicar isso de
-- verdade - se ele ignorasse o WHERE, o teste passaria sem provar a trava que
-- garante "ativar 2x = 1 ciclo".
--   SET:   `col` = <numero>  |  `col` = `col` +|- <numero>
--   WHERE: `col` (=|<=|>=|<|>) <numero|'texto'>  ligadas por AND
-- ---------------------------------------------------------------------------
local function dbAssignments(clause)
  local out = {}
  for part in string.gmatch(clause .. ",", "(.-),") do
    -- [%w_]+: `%w` no Lua NAO inclui underscore, e as colunas desta tabela tem
    -- (`bonus_until` ficaria de fora)
    local col, expr = string.match(part, "`([%w_]+)`%s*=%s*(.-)%s*$")
    if col then
      local ref, op, n = string.match(expr, "^`([%w_]+)`%s*([%+%-])%s*(%-?%d+)$")
      if ref then
        out[#out + 1] = { col = col, ref = ref, op = op, value = tonumber(n) }
      else
        out[#out + 1] = { col = col, value = tonumber(expr) }
      end
    end
  end
  return out
end

local function dbConditions(clause)
  local out = {}
  for part in string.gmatch(clause .. " AND ", "(.-) AND ") do
    -- padrao Lua nao tem alternacao: o operador sai como classe ([<>=]+) e
    -- depois vale como texto mesmo ("=", "<", ">", "<=", ">=")
    local col, raw = string.match(part, "%s*`([%w_]+)`%s*(.-)%s*$")
    if col then
      local op, value = string.match(raw, "^([<>=]+)%s*(.-)%s*$")
      if op then
        local text = string.match(value, "^'(.*)'$")
        out[#out + 1] = { col = col, op = op, value = text or tonumber(value) }
      end
    end
  end
  return out
end

-- Aplica um UPDATE de verdade (condicoes no estado ANTERIOR, como o MySQL).
-- Devolve (linha, aplicou): aplicou = false quando o WHERE nao casou.
local function dbApplyUpdate(q)
  local setClause, whereClause = string.match(q, "SET (.-) WHERE (.-);?%s*$")
  if not setClause then
    return nil
  end

  local conds = dbConditions(whereClause)
  local name
  for _, c in ipairs(conds) do
    if c.col == "name" then name = c.value end
  end
  if not name then
    return nil
  end

  local row = FAKEDB.rows[name]
  assert(row, "o teste mandou mexer em `" .. tostring(name) .. "` sem a linha existir (ensureRow nao rodou)")

  for _, c in ipairs(conds) do
    -- `name` e' o seletor da linha (nao existe dentro da linha do fake)
    if c.col ~= "name" then
      local current = row[c.col]
      if current == nil then return row, false end
      local ok = (c.op == "=" and current == c.value)
        or (c.op == "<=" and current <= c.value)
        or (c.op == ">=" and current >= c.value)
        or (c.op == "<" and current < c.value)
        or (c.op == ">" and current > c.value)
      if not ok then return row, false end
    end
  end

  local before = { pool = row.pool, bonus_until = row.bonus_until }
  for _, s in ipairs(dbAssignments(setClause)) do
    if s.ref then
      local base = before[s.ref] or 0
      row[s.col] = s.op == "+" and (base + s.value) or (base - s.value)
    else
      row[s.col] = s.value
    end
  end
  row.updates = (row.updates or 0) + 1
  table.insert(FAKEDB.applied, q)
  return row, true
end

local function dbInsertQuery(q)
  return string.match(q, "VALUES %('([^']+)'", 1)
end

db = {
  executeQuery = function(q)
    table.insert(QUERIES, q)
    if string.find(q, "^CREATE TABLE IF NOT EXISTS", 1) then
      return true
    end
    if FAKEDB.beforeWrite then FAKEDB.beforeWrite(q) end

    local row, applied = dbApplyUpdate(q)
    if row then
      return applied
    end

    local name = dbInsertQuery(q)
    if name then
      if not FAKEDB.rows[name] then
        FAKEDB.rows[name] = { pool = 0, bonus_until = 0 }
      end
      return true
    end
    error("query que o teste nao sabe simular: " .. q)
  end,
  escapeString = function(s) return "'" .. tostring(s) .. "'" end,
  getResult = function(q)
    if not string.find(q, "^SELECT", 1) then return nil end
    local keys = {}
    for name in pairs(FAKEDB.rows) do table.insert(keys, name) end
    table.sort(keys)

    local res, i
    -- O cursor do MySQL ja' nasce NA primeira linha (a lib so' chama next() no
    -- fim do corpo do repeat).
    local advance = function()
      i = i + 1
      res._name = keys[i]
      return res._name ~= nil
    end
    -- A lib chama com DOIS PONTOS (res:getDataString("name")), como o Result do
    -- 004-database.lua: o primeiro parametro e' o proprio res (self).
    res = {
      getID = function(self) return 0 end,
      next = function(self) return advance() end,
      getDataString = function(self, col)
        if col == "name" then return self._name end
        return nil
      end,
      getDataLong = function(self, col)
        local row = FAKEDB.rows[self._name]
        if not row then return 0 end
        if col == "pool" then return row.pool end
        if col == "bonus_until" then return row.bonus_until end
        return 0
      end,
      free = function(self) end,
    }
    i = 0
    advance()
    return res
  end,
}
exhaustion = {
  check = function() return false end,
  set = function() end,
  get = function() return false end,
}

-- ===== lib real do datapack =====
dofile(DIR .. "lib/json.lua")
dofile(DIR .. "lib/statueDonation.lua")

local fails = 0
local function check(cond, msg)
  if cond then
    print("  OK   " .. msg)
  else
    print("  FAIL " .. msg)
    fails = fails + 1
  end
end

-- ultima mensagem do opcode 121 que seja um estado completo
local function lastState()
  for i = #SENT, 1, -1 do
    local m = SENT[i]
    if m.op == 121 then
      local ok, dec = pcall(json.decode, m.buf)
      if ok and type(dec) == "table" and dec.data and dec.data.nations then
        return dec
      end
    end
  end
  return nil
end

-- mensagem do opcode 100 (buff) para um cid/id/acao
local function buffMsg(cid, id, action)
  for i = #SENT, 1, -1 do
    local m = SENT[i]
    if m.op == 100 and m.cid == cid then
      local ok, dec = pcall(json.decode, m.buf)
      if ok and type(dec) == "table" and dec.action == action and dec.data and dec.data.id == id then
        return dec
      end
    end
  end
  return nil
end

-- ultima mensagem de texto que contenha `pattern` (busca literal). Cobre as
-- duas saidas da lib: doPlayerSendTextMessage/Cancel e o opcode 121 com
-- action "msg" (que e' como o servidor manda as recusas pro client).
local function lastText(pattern)
  for i = #SENT, 1, -1 do
    local m = SENT[i]
    local text = m.msg
    if not text and m.op == 121 then
      local ok, dec = pcall(json.decode, m.buf)
      if ok and type(dec) == "table" and dec.action == "msg" and dec.data then
        text = dec.data.msg
      end
    end
    if text and string.find(text, pattern, 1, true) then
      return text
    end
  end
  return nil
end

local function donate(target, amount)
  local payload = { action = "donate", data = { target = target } }
  if amount ~= nil then payload.data.amount = amount end
  StatueDonation.onOpcode(1, json.encode(payload))
end

print("== modo do buff: " .. (NATIVE and "oficial (doCreatureAddBuff)" or "cru (opcode 100)"))
check(type(StatueDonation) == "table", "a lib carregou sem erro")

print("== vocacao -> elemento")
local want = { [1]="fire", [2]="water", [3]="air", [4]="earth", [5]="fire", [6]="water", [7]="air", [8]="earth" }
local mapOk = true
for cid = 1, 8 do
  if StatueDonation.elementOf(cid) ~= want[cid] then mapOk = false end
end
check(mapOk, "as 8 vocacoes (4 base + 4 promovidas) mapeiam certo")
check(StatueDonation.elementOf(99) == nil, "cid invalido devolve nil")

print("== estado da janela")
StatueDonation.openWindow(1)
check(#QUERIES >= 2, "abrir a estatua inicializa a tabela (" .. #QUERIES .. " queries)")
local s0 = lastState()
check(s0 ~= nil and #s0.data.nations == 4 and #s0.data.globals == 2, "4 nacoes + 2 abas no estado")
check(s0 ~= nil and s0.data.goal == 150000 and s0.data.element == "fire", "meta 150000 e elemento do player")

print("== doacao nas nacoes")
-- Nacao tem POOL: doacao parcial acumula e NAO ativa. O que passar da meta
-- (150k) nao e' cobrado nem guardado pro proximo ciclo - e o recibo diz isso.
P.money = 600000
donate("earth", 100000)
check(P.money == 500000, "doar 100k cobra 100k (sobrou " .. P.money .. ")")
check(not StatueDonation.isActive("earth"), "pool parcial NAO ativa a bencao")
local s1 = lastState()
check(s1 ~= nil and s1.data.nations[4].pool == 100000, "o estado mostra o pool em 100000")

donate("fire", 999999)
check(P.money == 350000, "digitou 999999 mas so' faltavam 150k -> cobrou 150k (sobrou " .. P.money .. ")")
check(lastText("was NOT charged") ~= nil, "o recibo da nacao avisa que o excedente NAO foi cobrado")
check(StatueDonation.isActive("fire"), "FIRE abencoada ao bater a meta")
check(StatueDonation.isNationActive("fire") and not StatueDonation.isNationActive("water"), "isNationActive por elemento")
check(#BROADCASTS == 1, "anunciou a bencao no servidor")
local s2 = lastState()
check(s2 ~= nil and s2.data.nations[1].pool == 0, "o pool zera depois de abencoar")
check(s2 ~= nil and s2.data.nations[1].until_ > FAKE, "o estado manda o fim do bonus (timer do client)")

local moneyBefore = P.money
donate("fire", 10000)
check(P.money == moneyBefore, "nacao abencoada recusa doacao nova")
check(lastText("already blessed") ~= nil, "a recusa da nacao ativa diz que o pool so' enche depois do fim")

print("== abas globais: POOL (igual as nacoes)")
-- As abas globais TEM POOL: o player doa o QUANTO QUISER, o pool vai enchendo
-- com a doacao de todo mundo e a bencao (de TODO o servidor) so' liga quando o
-- pool bate a meta. O que passar da meta nao e' cobrado nem guardado.
BROADCASTS = {}
P.money = 100000
P.bank = 0
donate("exp", 100000)
check(P.money == 0 and not StatueDonation.isActive("exp"), "EXP: doar 100k cobra os 100k e NAO ativa (pool parcial)")
local sExp = lastState()
check(sExp ~= nil and sExp.data.globals[1].pool == 100000, "o estado mostra o pool da aba EXP (100000)")
check(sExp ~= nil and sExp.data.globals[1].goal == 350000, "o goal da aba EXP e' a meta (350000)")
check(lastText("gold left for the whole server") ~= nil, "o recibo diz quanto falta pro servidor inteiro")

-- Pedido sem valor: nao da' pra adivinhar quanto o player quis doar.
local moneyNoAmount = P.money
donate("exp")
check(P.money == moneyNoAmount and not StatueDonation.isActive("exp"),
  "doacao de aba sem valor e' recusada sem cobrar nada")

-- Digitou bem mais que a meta: cobra SO' o que faltava (250k) e ativa.
P.money = 400000
donate("exp", 999999)
check(P.money == 150000, "EXP: digitou 999999 mas faltavam 250k -> cobrou 250k (sobrou " .. P.money .. ")")
check(StatueDonation.isActive("exp"), "bencao EXP ativa quando o pool completa")
check(StatueDonation.getExpBonus() == 0.05, "getExpBonus = 0.05 (usado pelo idle.lua)")
check(lastText("completed it") ~= nil, "o recibo diz que completou o pool")
check(lastText("was NOT charged") ~= nil, "o recibo avisa que o excedente NAO foi cobrado")
check(#BROADCASTS == 1, "anunciou a bencao global no servidor")
local sExp2 = lastState()
check(sExp2 ~= nil and sExp2.data.globals[1].pool == 0, "o pool da aba zera depois de ativar")

local moneyActive = P.money
donate("exp", 50000)
check(P.money == moneyActive, "aba ativa nao cobra de novo (mesmo mandando valor no pedido)")
check(lastText("already active") ~= nil, "a recusa com a bencao ativa diz que o pool so' volta depois do fim")

print("== aba POTIONS: pool pago com pack + banco")
check(StatueDonation.getPotionHealMultiplier() == 1.0, "sem a aba POTIONS: cura x1.0")

P.money = 0
P.bank = 200000
donate("potion", 200000)
check(P.bank == 0 and not StatueDonation.isActive("potion"), "POTIONS: doacao parcial do banco acumula sem ativar")

P.money = 100000
P.bank = 200000
donate("potion", 99999999) -- falta 200k: cobra so' isso (pack 100k + banco 100k)
check(StatueDonation.isActive("potion"), "POTIONS ativa quando o pool completa (400k)")
check(P.money == 0 and P.bank == 100000, "inventario primeiro (100k), banco paga o resto (100k)")
check(StatueDonation.getPotionHealMultiplier() == 1.15, "getPotionHealMultiplier = 1.15 (fullPotion.lua)")

-- O recibo tem que dizer quanto saiu do pack e quanto do banco: era a duvida
-- "donatei 100k e ativou" (o resto saiu do banco).
local receipt = nil
for i = #SENT, 1, -1 do
  local m = SENT[i]
  if m.msg and string.find(m.msg, "Potions pool", 1, true) then
    receipt = m.msg
    break
  end
end
check(receipt ~= nil, "doacao de aba manda recibo do que saiu do pack e do banco")
check(receipt ~= nil and string.find(receipt, "Potions pool and completed it", 1, true) ~= nil,
  "o recibo de POTIONS diz que completou o pool")
check(receipt ~= nil and string.find(receipt, "backpack +", 1, true) ~= nil,
  "o recibo mostra o split pack/banco")
check(receipt ~= nil and string.find(receipt, "was NOT charged", 1, true) ~= nil,
  "recibo avisa que so' o que faltava foi cobrado")

print("== abrir a janela manda o estado completo")
-- Usar a estatua = openWindow. Este e' o UNICO pacote que faz a janela
-- aparecer no client (action "open"), entao ele tem que sair com a bencao
-- viva - era este caminho que a janela usava pra "saber" o status.
-- (sem limpar SENT: os checks do modo cru, logo abaixo, contam com os buffs
--  enviados antes; lastState() pega o ULTIMO estado, que agora e' este.)
StatueDonation.openWindow(1)
local openState = lastState()
check(openState ~= nil and openState.action == "open", "openWindow manda o estado com action=open")
if openState then
  local fireUntil
  for _, n in ipairs(openState.data.nations) do
    if n.key == "fire" then fireUntil = n.until_ end
  end
  check(fireUntil ~= nil and fireUntil > FAKE,
    "o estado que abre a janela ja' traz a bencao viva (until_ no futuro)")
  check(openState.data.element == "fire", "e o elemento do player (pra marcar a nacao dele)")
end

print("== buffs (fire ativo, exp e potions ativos)")
BUFFS = {}
StatueDonation.applyBuffs(1) -- cid 1 = fire bender
if NATIVE then
  check(BUFFS[13] ~= nil, "buff 13 (nacao fire) aplicado no sistema oficial")
  check(BUFFS[17] ~= nil and BUFFS[18] ~= nil, "buffs 17/18 (abas) aplicados")
  check(BUFFS[13] ~= nil and BUFFS[13] > 0, "o buff leva o tempo que falta (ms)")
  check(BUFFS[14] == nil, "buff 14 (water) NAO vai pro fire")
else
  local add13 = buffMsg(1, 13, "add")
  check(add13 ~= nil, "buff 13 (nacao fire) enviado no opcode 100")
  check(buffMsg(1, 17, "add") ~= nil and buffMsg(1, 18, "add") ~= nil, "buffs 17/18 enviados no opcode 100")
  check(buffMsg(1, 14, "add") == nil, "buff 14 (water) NAO e' enviado pro fire")
  if add13 then
    check(add13.data.icon == "statue_fire", "icone = statue_fire (arquivo em images/buffs)")
  local add18 = buffMsg(1, 18, "add")
  check(add18 ~= nil and add18.data.icon == "potion", "icone da aba POTIONS = potion (images/buffs/potion.png)")
    check(add13.data.endTime > 0 and add13.data.server_time > 0, "payload com endTime/server_time (timer do client)")
    check(add13.data.debuff == false, "buff nao e' debuff (fica na linha de cima)")
  end
  check(buffMsg(1, 14, "remove") ~= nil, "buff que nao vale mais e' removido no opcode 100")
end

BUFFS = {}
StatueDonation.applyBuffs(2) -- cid 2 = water
if NATIVE then
  check(BUFFS[13] == nil, "water puro nao recebe a bencao de FIRE")
else
  check(buffMsg(2, 13, "add") == nil, "water puro nao recebe add do buff de FIRE")
end

print("== persistencia: o estado do banco reaplica o icone (save/restart)")
-- Simula o que um save/restart (ou uma morte, que chama Creature::clearBuffs)
-- faz com os icones: o servidor perde os buffs do creature. O reconcile do
-- tique tem que devolver o icone de quem ainda tem bencao viva no banco.
if NATIVE then
  BUFFS = {}
  StatueDonation.sweep()
  check(BUFFS[13] ~= nil and BUFFS[17] ~= nil and BUFFS[18] ~= nil,
    "sweep reaplica os buffs de quem tem bencao viva")
  check(BUFFS[14] == nil, "sweep nao da' a bencao de outra nacao")
else
  -- caminho cru: o icone vive no client, quem reenvia e' o login (force)
  SENT = {}
  StatueDonation.onLogin(1)
  check(buffMsg(1, 17, "add") ~= nil, "login (force = true) reenvia o icone da aba EXP no opcode 100")
end

-- O login tambem manda o ESTADO (nao so' os icones). Sem isto, quem reloga com
-- a janela aberta (ou reabre depois de relogar) ficava vendo o pool/bencao da
-- sessao anterior, porque o client guarda o ultimo estado que recebeu.
SENT = {}
StatueDonation.onLogin(1)
local loginState = lastState()
check(loginState ~= nil, "login tambem manda o estado completo (opcode 121)")
if loginState then
  check(loginState.action == "state", "com action=state (nao abre a janela na cara de ninguem)")
  local fireLogin
  for _, n in ipairs(loginState.data.nations) do
    if n.key == "fire" then fireLogin = n.until_ end
  end
  check(fireLogin ~= nil and fireLogin > FAKE, "e ja' com a bencao viva no until_ do banco")
end

-- Reconcile nao cobra, nao ativa e nao encerra nada: so' olha o estado.
local moneySweep, fireBeforeSweep = P.money, StatueDonation.isActive("fire")
StatueDonation.sweep()
check(P.money == moneySweep and StatueDonation.isActive("fire") == fireBeforeSweep,
  "sweep nao cobra ouro nem muda estado de bencao")

print("== bencao ativada por OUTRA interface (o bug do 'not blessed')")
-- A engine cria um lua_State por categoria de script e CADA UM carrega data/lib
-- inteiro: esta lib vive em varias copias (actions = usar a estatua, 
-- creatureevent = opcode 121/login, globalevent = tique...), cada uma com o seu
-- proprio `state`. Aqui simulamos a copia do CREATURESCRIPTS abencoando WATER:
-- a linha vai direto pro banco, sem passar por esta copia. Antes, a copia do
-- ACTIONS nunca relia a tabela e ficava com o retrato do primeiro uso - ela
-- escondia o icone do buff e mandava "not blessed" pro client, que e' exatamente
-- o que acontecia ao abrir a janela com a bencao viva.
FAKEDB.rows.water.bonus_until = FAKE + 3600

SENT = {}
BUFFS = {}
StatueDonation.openWindow(2) -- cid 2 = water bender: usar a estatua
local sOther = lastState()
local waterUntil
for _, n in ipairs(sOther ~= nil and sOther.data.nations or {}) do
  if n.key == "water" then waterUntil = n.until_ end
end
check(waterUntil ~= nil and waterUntil > FAKE,
  "abrir a janela ja' traz a bencao ativada por outra interface (era o 'not blessed')")
check(sOther ~= nil and sOther.data.element == "water", "e o estado abre com o elemento do player")
if NATIVE then
  check(BUFFS[14] ~= nil, "o icone da bencao nova vai pro player de water na hora")
else
  check(buffMsg(2, 14, "add") ~= nil, "o icone da bencao nova vai pro player de water na hora")
end

-- Os getters de bonus (idle.lua / fullPotion.lua) andam de carona no cache
-- curto: no maximo CONFIG.stateTtl segundos de atraso.
FAKE = FAKE + 10
check(StatueDonation.isNationActive("water"), "o getter (idle.lua) ve a bencao quando o cache curto vence")

print("== ativar 2x o mesmo ciclo: vale UM ciclo (e uma consumicao do pool)")
-- A corrida que dobrava a bencao: a bencao nasce de um UPDATE condicional no
-- banco (`bonus_until` vencido E pool cheio), entao quem chega depois nao
-- escreve. Aqui a OUTRA copia da lib (outro lua_State) ativa o MESMO ciclo no
-- exato instante entre a nossa leitura e a nossa escrita: a nossa query e'
-- enviada e o banco recusa - a segunda tentativa tem que ter o efeito de zero.
BROADCASTS = {}
P.money, P.bank = 500000, 0
FAKEDB.rows.air.pool = 150000
FAKEDB.rows.air.bonus_until = 0
FAKEDB.applied = {}
FAKEDB.beforeWrite = function(q)
  if string.find(q, "`pool` = `pool` - 150000", 1, true) then
    -- 1s antes da nossa: e' o caso em que a releitura NAO devolve o until_
    -- que escrevemos (ou seja, nao fomos nos que abrimos o ciclo)
    FAKEDB.rows.air.pool = 0
    FAKEDB.rows.air.bonus_until = FAKE + 12 * 3600 - 1
  end
end
local moneyBeforeRace = P.money
donate("air", 1000)
FAKEDB.beforeWrite = nil
local appliedActivations = 0
for _, q in ipairs(FAKEDB.applied) do
  if string.find(q, "`pool` = `pool` - 150000", 1, true) then appliedActivations = appliedActivations + 1 end
end
check(appliedActivations == 0, "a nossa tentativa foi RECUSADA pelo banco (" .. appliedActivations .. " escrita)")
check(FAKEDB.rows.air.bonus_until == FAKE + 12 * 3600 - 1, "o ciclo gravado e' o da outra ponta (nao somou 2x o tempo)")
check(#BROADCASTS == 0, "quem perdeu a corrida NAO anuncia a bencao")
check(P.money == moneyBeforeRace, "e a doacao dele tambem nao foi cobrada")

print("== ciclo ativo: nao aceita doacao nova nem empurra o fim da bencao")
FAKE = FAKE + 60
local untilAir, moneyAir = FAKEDB.rows.air.bonus_until, P.money
FAKEDB.applied = {}
donate("air", 50000)
check(P.money == moneyAir and lastText("already blessed") ~= nil, "doacao em ciclo ativo e' recusada sem cobrar")
check(FAKEDB.rows.air.bonus_until == untilAir, "e o fim da bencao nao anda (nada de 2x o tempo)")
check(#FAKEDB.applied == 0, "nenhuma escrita no banco por um pedido em ciclo ativo")

print("== credito recusado: o ouro volta pro player (nada fica fora do pool)")
-- A outra ponta ativa a bencao entre a nossa leitura e o nosso credito: o credito
-- nao pode entrar num ciclo fechado, e o ouro NAO pode ficar cobrado.
BROADCASTS = {}
P.money, P.bank = 1000, 500
FAKEDB.rows.air.pool = 149900
FAKEDB.rows.air.bonus_until = 0
FAKEDB.beforeWrite = function(q)
  if string.find(q, "`pool` = `pool` + ", 1, true) then
    FAKEDB.rows.air.pool = 0
    FAKEDB.rows.air.bonus_until = FAKE + 12 * 3600
  end
end
local packBefore, bankBefore = P.money, P.bank
donate("air", 1000)
FAKEDB.beforeWrite = nil
check(P.money == packBefore and P.bank == bankBefore, "o ouro volta (pack " .. P.money .. " + banco " .. P.bank .. ")")
check(lastText("nothing was charged") ~= nil, "e a tela avisa que nada foi cobrado")
check(FAKEDB.rows.air.pool == 0, "o credito nao entrou num ciclo ja' fechado")
check(#BROADCASTS == 0, "e esta ponta nao anunciou nada")

print("== encerrar o ciclo NAO apaga doacao que chegou junto")
-- O UPDATE de expiracao so' zera `bonus_until`: o pool da memoria (que pode ser
-- de antes de uma doacao que chegou enquanto o tique rodava) nao sobrescreve o
-- banco - era o que o dbSave antigo fazia.
BROADCASTS = {}
FAKEDB.rows.air.pool = 5000
FAKEDB.rows.air.bonus_until = FAKE - 1
FAKEDB.beforeWrite = function(q)
  if string.find(q, "`bonus_until` = 0", 1, true) then
    FAKEDB.rows.air.pool = 20000 -- doacao que chegou no meio do tique
  end
end
-- O tique faz dbLoad(true) ANTES de olhar a expiracao (statueTick); adminList
-- e' o caminho publico que forca essa releitura.
StatueDonation.adminList()
StatueDonation.checkExpired()
FAKEDB.beforeWrite = nil
check(FAKEDB.rows.air.bonus_until == 0, "bencao vencida e' encerrada")
check(FAKEDB.rows.air.pool == 20000, "o pool ficou com a doacao que chegou junto (" .. FAKEDB.rows.air.pool .. ")")
check(not StatueDonation.isActive("air"), "e o getter de bonus volta a dizer inativo")
check(#BROADCASTS == 1, "anunciou o fim do ciclo (" .. #BROADCASTS .. " vez)")

print("== admin: API do reset (StatueDonation.resetKey / adminList)")
local list = StatueDonation.adminList()
check(type(list) == "table" and #list == 6, "adminList traz as 6 chaves (4 nacoes + 2 abas)")
check(list ~= nil and list[1].key == "fire" and list[3].key == "air" and list[5].key == "exp",
  "ordem: as 4 nacoes e depois as abas (mesma da janela)")
check(list ~= nil and list[4].key == "earth" and list[4].pool == 100000, "adminList mostra o pool atual do earth (100000)")

local qBefore = #QUERIES
local resetOk, resetInfo = StatueDonation.resetKey("earth", "pool")
check(resetOk == true and resetInfo.poolBefore == 100000 and resetInfo.poolAfter == 0, "resetKey zera o pool e devolve o antes/depois")
local savedPool0 = false
for i = qBefore + 1, #QUERIES do
  if string.find(QUERIES[i], "`pool` = 0", 1, true) then savedPool0 = true end
end
check(savedPool0, "o pool zerado vai pro banco na hora (UPDATE pontual)")
local sReset = lastState()
check(sReset ~= nil and sReset.data.nations[4].pool == 0, "a janela de quem esta' online recebe o pool novo (0)")

-- As abas globais TAMBEM tem pool agora: reset de pool vale pra elas - e
-- zerar o pool NAO pode derrubar a bencao ativa.
local expPoolOk, expPoolInfo = StatueDonation.resetKey("exp", "pool")
check(expPoolOk == true and expPoolInfo.poolAfter == 0, "resetKey('exp', 'pool') zera o pool da aba EXP")
check(StatueDonation.isActive("exp"), "resetar so' o POOL nao encerra a bencao ativa")
check(expPoolInfo.removed == nil, "reset de pool NAO mexe em buff (nada de icone tirado)")
local badOk = StatueDonation.resetKey("naoexiste")
check(badOk == false, "chave desconhecida nao reseta nada")

print("== admin: comando !resetstatue (talkaction)")
-- Stubs que o talkaction usa (doPlayerSendTextMessage ja' existe acima).
MESSAGE_EVENT_ADVANCE = 20
GROUP = 6
function getPlayerGroupId() return GROUP end
dofile(DIR .. "talkactions/scripts/resetstatue.lua")
check(type(onSay) == "function", "o talkaction resetstatue.lua carregou")

GROUP = 1
SENT = {}
onSay(1, "!resetstatue", "all", 0)
check(#SENT == 1 and lastText("permissao") ~= nil, "sem permissao: avisa e nao mexe em nada")
check(StatueDonation.isActive("fire"), "sem permissao a bencao ativa continua de pe")

GROUP = 6
SENT = {}
onSay(1, "!resetstatue", "", 0)
check(lastText("Estatua de Doacao:") ~= nil, "sem parametro: mostra o estado")
check(lastText("(Experience)") ~= nil and lastText("150,000") ~= nil, "o estado lista as chaves e os pools formatados")

SENT = {}
onSay(1, "!resetstatue", "nada", 0)
check(lastText("desconhecida") ~= nil and lastText("potion") ~= nil, "chave invalida: avisa e lista as chaves validas")

-- Pool com dinheiro doado e bencao de nacao ativa: 'pools' zera o pool mas NAO
-- encerra a bencao, 'potion' encerra a bencao (e tira o buff de quem esta' online).
P.money = 100000
donate("air", 100000)
SENT = {}
onSay(1, "!resetstatue", "pools", 0)
check(lastText("air: pool") ~= nil, "'pools' reporta o pool de cada nacao")
local sPools = lastState()
check(sPools ~= nil and sPools.data.nations[3].pool == 0, "'pools' zerou o pool do air (100000 -> 0)")
check(StatueDonation.isActive("fire"), "'pools' NAO encerra bencao ativa")

BUFFS = {}
if NATIVE then BUFFS[18] = 999999 end -- simula a aba POTIONS ativa na barra
SENT = {}
onSay(1, "!resetstatue", "potion", 0)
check(not StatueDonation.isActive("potion"), "'!resetstatue potion' encerrou a bencao da aba")
check(StatueDonation.getPotionHealMultiplier() == 1.0, "encerrada a aba: cura volta pra x1.0 na hora")
if NATIVE then
  check(BUFFS[18] == nil, "o buff da aba saiu de quem estava online")
else
  check(buffMsg(1, 18, "remove") ~= nil, "o buff da aba foi removido no opcode 100")
end
check(lastText("bencao encerrada") ~= nil, "o recibo diz quanto faltava da bencao encerrada")

SENT = {}
onSay(1, "!resetstatue", "water pool", 0)
check(lastText("water: pool") ~= nil, "da' pra resetar uma chave so', com a opcao (water pool)")

SENT = {}
onSay(1, "!resetstatue", "water zzz", 0)
check(lastText("invalida") ~= nil, "opcao invalida no segundo parametro e' recusada")

print("== entradas invalidas")
local before = P.money
donate("water", "abc")
donate("nada")
donate("earth", -5)
donate("earth", 2000000000)
check(P.money == before and not StatueDonation.isActive("earth"), "nenhum pedido invalido cobrou ou ativou")
check(pcall(function() return StatueDonation.onOpcode(1, "nao e' json") end) == true, "buffer invalido nao gera erro")

print("== expiracao (relogio +12h)")
FAKE = FAKE + (12 * 3600) + 1
check(not StatueDonation.isActive("fire"), "bencao da nacao expirou")
check(not StatueDonation.isActive("exp"), "aba EXP expirou")
check(not StatueDonation.isActive("potion"), "aba POTIONS expirou")
BUFFS = {}
StatueDonation.checkExpired()
check(StatueDonation.isActive("fire") == false, "checkExpired confirma a expiracao")
check(StatueDonation.getPotionHealMultiplier() == 1.0, "expirado: cura volta pra x1.0")
check(#BROADCASTS >= 4, "avisou o fim das bencaos (" .. #BROADCASTS .. " broadcasts)")

print("== nova rodada")
P.money = 150000
donate("fire", 150000)
check(StatueDonation.isActive("fire"), "depois de expirar, 150k reativa a nacao")
check(P.money == 0, "a nova doacao cobrou 150k")

-- 'all' no fim da bateria: zera pool E encerra bencao (sem isso os testes de
-- expiracao acima nao teriam o que expirar).
print("== admin: !resetstatue all")
BUFFS = {}
if NATIVE then BUFFS[13] = 999999 end
SENT = {}
onSay(1, "!resetstatue", "all", 0)
check(not StatueDonation.isActive("fire"), "'all' encerrou a bencao de nacao ativa")
check(lastText("fire: pool") ~= nil, "'all' tambem reporta o pool da nacao")
if NATIVE then
  check(BUFFS[13] == nil, "'all' tirou o buff de nacao de quem estava online")
else
  check(buffMsg(1, 13, "remove") ~= nil, "'all' removeu o buff de nacao no opcode 100")
end
local sAll = lastState()
local allPoolsZero = true
for _, n in ipairs(sAll ~= nil and sAll.data.nations or {}) do
  if n.pool ~= 0 then allPoolsZero = false end
end
check(allPoolsZero, "depois do 'all' nenhum pool tem sobra")

print("== reset: o buff sai de todos (online agora e no proximo login)")
-- Tres bencoes ativas (fire + exp + potion) com o player 1 "online" e o icone
-- aplicado (BUFFS no modo nativo, opcode 100 no cru).
P.money = 0
P.bank = 5000000
donate("fire", 150000)
donate("exp", 350000)
donate("potion", 400000)
check(StatueDonation.isActive("fire") and StatueDonation.isActive("exp") and StatueDonation.isActive("potion"),
  "fire + exp + potion ativas de novo")
-- pool parcial numa nacao, pra provar que resetar BENCAO nao toca no pool
donate("earth", 50000)

BUFFS = {}
SENT = {}
StatueDonation.applyBuffs(1, true) -- client do player 1 aberto, com os icones
if NATIVE then
  check(BUFFS[13] ~= nil and BUFFS[17] ~= nil and BUFFS[18] ~= nil, "os tres icones estao aplicados")
end

SENT = {}
onSay(1, "!resetstatue", "blessings", 0)
check(not StatueDonation.isActive("fire") and not StatueDonation.isActive("exp") and
  not StatueDonation.isActive("potion"), "'blessings' encerrou as tres bencoes")
check(lastText("icone tirado de") ~= nil, "o recibo diz de quantos players ONLINE o icone foi tirado")
check(lastText("Offline:") ~= nil, "o comando avisa como o offline perde o icone")

-- O remove vai pra TODOS os ids da estatua (nao so' o da chave resetada) e em
-- QUALQUER modo: e' o que impede icone fantasma no client de quem "pegou de
-- alguma forma" (relog do caminho cru, troca de modo, /reload).
local removedAll = true
for _, id in ipairs({13, 14, 15, 16, 17, 18}) do
  if buffMsg(1, id, "remove") == nil then removedAll = false end
end
check(removedAll, "quem estava online recebeu o remove de TODOS os ids da estatua")
if NATIVE then
  check(BUFFS[13] == nil and BUFFS[17] == nil and BUFFS[18] == nil,
    "os buffs sairam do creature de quem estava online")
end

local sAfterBless = lastState()
check(sAfterBless ~= nil and sAfterBless.data.nations[4].pool == 50000,
  "resetar BENCAO nao mexe no pool (earth continua com 50000)")

-- Quem estava OFFLINE no momento do reset nao pode receber nada ao voltar: o
-- estado do banco (bonus_until = 0) nao reativa nada e o login ainda manda o
-- "remove" de cada id (limpa icone fantasma de sessao anterior).
SENT = {}
StatueDonation.onLogin(2)
local readded = false
for _, id in ipairs({13, 14, 15, 16, 17, 18}) do
  if buffMsg(2, id, "add") ~= nil then readded = true end
end
check(not readded, "quem loga depois do reset NAO recebe buff nenhum")
local removedTo2 = true
for _, id in ipairs({13, 14, 15, 16, 17, 18}) do
  if buffMsg(2, id, "remove") == nil then removedTo2 = false end
end
check(removedTo2, "e o login dele ainda manda o remove de cada id")

print("")
print(fails == 0 and "== TODOS OS TESTES PASSARAM ==" or ("== " .. fails .. " FALHA(S) =="))
return fails
"""


def load_lua():
    for path in DLL_CANDIDATES:
        if not os.path.exists(path):
            continue
        try:
            return ctypes.CDLL(path), path
        except OSError:
            continue
    print("Nao achei um Lua carregavel. Instale um Lua 64-bit ou ajuste DLL_CANDIDATES.")
    sys.exit(2)


def run_mode(lua_path, native):
    lua = ctypes.CDLL(lua_path)

    def proto(restype, *argtypes):
        def wrap(name):
            addr = ctypes.cast(getattr(lua, name), ctypes.c_void_p).value
            return ctypes.CFUNCTYPE(restype, *argtypes)(addr)
        return wrap

    newstate = proto(ctypes.c_void_p)("luaL_newstate")
    openlibs = proto(None, ctypes.c_void_p)("luaL_openlibs")
    loadstring = proto(ctypes.c_int, ctypes.c_void_p, ctypes.c_char_p)("luaL_loadstring")
    tostring = proto(ctypes.c_char_p, ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p)("lua_tolstring")
    close = proto(None, ctypes.c_void_p)("lua_close")

    try:  # Lua 5.1 (lua51.dll) usa lua_pcall; 5.3+ usa lua_pcallk
        getattr(lua, "lua_pcall")
        pcall = proto(ctypes.c_int, ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int)("lua_pcall")
        call = lambda st: pcall(st, 0, 0, 0)
    except AttributeError:
        pcall = proto(
            ctypes.c_int, ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int,
            ctypes.c_int64, ctypes.c_void_p
        )("lua_pcallk")
        call = lambda st: pcall(st, 0, 0, 0, 0, None)

    state = newstate()
    openlibs(state)

    src = LUA_TESTS.replace("__DIR__", DATA_DIR).replace("__NATIVE__", "true" if native else "false")
    rc = loadstring(state, src.encode("utf-8"))
    if rc != 0:
        print("LOAD ERROR:", tostring(state, -1, None))
        close(state)
        return 1
    rc = call(state)
    if rc != 0:
        print("RUNTIME ERROR:", tostring(state, -1, None))
        close(state)
        return 1
    close(state)
    return 0


def main():
    lua_path = None
    for path in DLL_CANDIDATES:
        if not os.path.exists(path):
            continue
        try:
            ctypes.CDLL(path)
            lua_path = path
            break
        except OSError:
            continue
    if not lua_path:
        print("Nao achei um Lua carregavel. Instale um Lua 64-bit ou ajuste DLL_CANDIDATES.")
        return 2

    print("Lua host:", lua_path)
    rc = 0
    for native in (False, True):
        rc |= run_mode(lua_path, native)
        print("")
    return rc


if __name__ == "__main__":
    sys.exit(main())
