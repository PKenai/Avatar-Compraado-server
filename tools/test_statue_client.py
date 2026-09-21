#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================================
 TESTE DO STATUE DONATION - LADO CLIENT (modules/statue_donation)
============================================================================
 Carrega o LUA DO MODULE DE VERDADE dentro de um stub do OTClient (g_ui,
 g_clock, ProtocolGame, scheduleEvent...) e confere o que a janela faz:

   * o card da nacao ATIVA mostra o tempo correndo e o botao fica travado
   * o titulo da janela lista o que esta' ativo ("ACTIVE: Earth Kingdom 11h57m")
     - era possivel "nao ver" que tinha relogio correndo
   * fechar e reabrir (o caso reportado) nunca deixa a janela com dado velho:
     show() PEDE o estado ao servidor (action "open") e a janela aberta
     re-sincroniza sozinha a cada SYNC_MS
   * fim de sessao (onGameEnd) zera o estado: a proxima abertura espera dado
     novo em vez de reusar o da sessao anterior
   * uma bencao inativa nao mostra tempo nenhum (nao fica "1h 00m" fantasma)

 Uso:
     python tools/test_statue_client.py

 Precisa de um Lua 5.3/5.4 64-bit (o XAMPP traz C:/xampp/apache/bin/lua54.dll)
 e do repo do CLIENT em CLIENT_ROOT (ajuste a constante abaixo se mudar de
 pasta). Nao abre o jogo: e' um stub.
============================================================================
"""

import ctypes
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER_ROOT = os.path.dirname(HERE)

CLIENT_ROOT = os.environ.get("STATUE_CLIENT_ROOT", r"C:\Users\imfis\Desktop\Avatar-comprado-client")
CLIENT_ROOT = CLIENT_ROOT.replace("\\", "/")

DLL_CANDIDATES = [
    "C:/xampp/apache/bin/lua54.dll",
    "C:/xampp/apache/bin/lua53.dll",
]

LUA_TESTS = r"""
unpack = table.unpack
local CL = "__CL__"

-- ====================== mock de widget ======================
local function newWidget(id)
  local w = {}
  w.id = id
  w.children = {}
  w.order = {}
  w.text = ""
  w.enabled = true
  w.visible = false
  w.percent = 0
  function w:getChildById(cid)
    if not self.children[cid] then
      local c = newWidget(cid)
      self.children[cid] = c
      table.insert(self.order, c)
    end
    return self.children[cid]
  end
  function w:getChildren() return self.order end
  function w:addChild(c)
    table.insert(self.order, c)
    if c.id then self.children[c.id] = c end
  end
  function w:setId(v) self.id = v end
  function w:getId() return self.id end
  function w:setText(v) self.text = tostring(v) end
  function w:getText() return self.text end
  function w:setEnabled(v) self.enabled = v end
  function w:isEnabled() return self.enabled end
  function w:setVisible(v) self.visible = v end
  function w:show() self.visible = true end
  function w:hide() self.visible = false end
  function w:isVisible() return self.visible end
  function w:raise() end
  function w:focus() end
  function w:destroy() end
  function w:setPercent(v) self.percent = v end
  function w:getPercent() return self.percent end
  function w:setColor(v) end
  function w:setBackgroundColor(v) end
  function w:setImageSource(v) end
  function w:setImageShader(v) end
  function w:setBorderColor(v) end
  function w:setBorderWidth(v) end
  function w:setTooltip(v) end
  return w
end

ROOT = newWidget("root")
CREATED = {}
g_ui = {
  createWidget = function(style, parent)
    local w = newWidget(style)
    -- o module registra o card no parent (nationsRow/globalsRow): e' assim que
    -- buildCards() sabe que os cards ja' existem
    if parent then parent:addChild(w) end
    CREATED[style] = CREATED[style] or {}
    table.insert(CREATED[style], w)
    return w
  end,
  displayUI = function() return ROOT end,
}

-- relogio do client, avancavel pelo teste (o module usa pra contar o tempo)
CLOCK = 1000
g_clock = { millis = function() return CLOCK end }

-- protocolo de mentira: guarda o que o module MANDA pro servidor
SENT_OP = {}
local protocol = {
  sendExtendedOpcode = function(self, op, buf) table.insert(SENT_OP, { op = op, buf = buf }) end,
}
g_game = {
  isOnline = function() return true end,
  getProtocolGame = function() return protocol end,
}

EVENTS = {}
function scheduleEvent(fn, ms) table.insert(EVENTS, fn); return #EVENTS end
function removeEvent() end
function connect() end
function disconnect() end
function displayInfoBox() end
ProtocolGame = {
  registerExtendedOpcode = function() end,
  unregisterExtendedOpcode = function() end,
}

local M = {}
modules = { statue_donation = M }

dofile(CL .. "/modules/corelib/json.lua")
dofile(CL .. "/modules/statue_donation/statue_donation.lua")
for _, name in ipairs({"select", "donate", "hide", "show", "toggle", "onAmountKeyPress",
                       "onExtendedOpcode", "applyState", "init", "prepare", "terminate",
                       "onGameEnd"}) do
  M[name] = _G[name]
end

local fails = 0
local function check(c, m) print((c and "  OK   " or "  FAIL ") .. m); if not c then fails = fails + 1 end end

local function find(style, id)
  for _, w in ipairs(CREATED[style] or {}) do if w.id == id then return w end end
  return nil
end
local function nationCard(key) return find("NationCard", "nation_" .. key) end
local function globalCard(key) return find("GlobalCard", "global_" .. key) end
local function cardStatus(key)
  local card = nationCard(key) or globalCard(key)
  if not card then return "<sem card>" end
  return card:getChildById("cardStatus").text
end

-- roda o ultimo evento agendado (o timer de 1s da janela)
local function runTimer()
  local fn = EVENTS[#EVENTS]
  local ok, err = pcall(fn)
  if not ok then print("    [erro no timer] " .. tostring(err)) end
end

local function lastRequest()
  local m = SENT_OP[#SENT_OP]
  if not m then return nil end
  local ok, dec = pcall(json.decode, m.buf)
  if not ok then return nil end
  return dec
end

-- ====================== estado que o servidor manda ======================
local T = os.time()
local function makeState(earthLeft, potionLeft)
  return {
    serverTime = T,
    element = "earth",
    nationDamage = 5,
    nationHours = 12,
    money = 50000, bank = 0,
    nations = {
      { key="fire",  label="Fire Nation",   element="fire",  image="/x", color="#ff7a45", pool=0, goal=150000, until_=0 },
      { key="water", label="Water Tribe",   element="water", image="/x", color="#4fc3ff", pool=0, goal=150000, until_=0 },
      { key="air",   label="Air Nomads",    element="air",   image="/x", color="#bfe9ff", pool=0, goal=150000, until_=0 },
      { key="earth", label="Earth Kingdom", element="earth", image="/x", color="#9ede7c", pool=0, goal=150000,
        until_ = earthLeft and (T + earthLeft) or 0 },
    },
    globals = {
      { key="exp",    label="Experience", cost=350000, goal=350000, pool=0, hours=8, bonus=5,
        detail="experience from creatures", image="/x", color="#ffe9a3", until_=0 },
      { key="potion", label="Potions", cost=400000, goal=400000, pool=0, hours=8, bonus=15,
        detail="potion healing", image="/x", color="#e7a6ff",
        until_ = potionLeft and (T + potionLeft) or 0 },
    },
  }
end

print("== a janela mostra a bencao ativa (o caso que o dono reportou) ==")
M.applyState(makeState(3600), true)
check(ROOT.visible, "a janela abriu")
check(cardStatus("earth") == "Blessed for 1h 00m",
      "card da nacao ativa mostra o tempo correndo (got: " .. tostring(cardStatus("earth")) .. ")")
check(cardStatus("fire") == "Not blessed", "card inativo continua 'Not blessed'")
check(ROOT:getChildById("donateButton").enabled == false, "botao desabilitado com bencao ativa")
check(ROOT:getChildById("donateButton").text == "Blessed for 1h 00m",
      "botao diz que a nacao esta' abencoada (got: " .. tostring(ROOT:getChildById("donateButton").text) .. ")")
check(string.find(ROOT.text, "ACTIVE: Earth Kingdom 1h 00m", 1, true) ~= nil,
      "o TITULO da janela diz o que esta' ativo (got: " .. tostring(ROOT.text) .. ")")

print("== fechar a janela e reabrir NAO mostra dado velho ==")
M.hide()
check(not ROOT.visible, "janela fechada")
SENT_OP = {}
M.show()
check(ROOT.visible, "janela reaberta")
local req = lastRequest()
check(req ~= nil and req.action == "open",
      "reabrir PEDE o estado ao servidor (action=open) -> nao depende do que o servidor empurrou")
check(cardStatus("earth") == "Blessed for 1h 00m", "e o card continua certo ate' a resposta chegar")

print("== o timer re-sincroniza a janela aberta ==")
SENT_OP = {}
CLOCK = CLOCK + 20000 -- 20s depois: passou do SYNC_MS (15s)
runTimer()
local req2 = lastRequest()
check(req2 ~= nil and req2.action == "open",
      "com a janela aberta o timer re-sincroniza sozinho (cobre server restart / reset de admin)")

print("== fim de sessao (relog/desconexao) zera o estado ==")
M.onGameEnd()
check(string.find(ROOT.text, "waiting for the server", 1, true) ~= nil,
      "o titulo avisa que ainda nao tem estado (got: " .. tostring(ROOT.text) .. ")")
SENT_OP = {}
M.show()
local req3 = lastRequest()
check(req3 ~= nil and req3.action == "open", "e a proxima abertura pede estado novo de novo")

print("== bencao inativa nao deixa texto fantasma ==")
M.applyState(makeState(nil), true)
check(cardStatus("earth") == "Not blessed",
      "sem bencao o card volta pra 'Not blessed' (got: " .. tostring(cardStatus("earth")) .. ")")
check(ROOT:getChildById("donateButton").enabled == true, "e o botao volta a aceitar doacao")
check(string.find(ROOT.text, "ACTIVE", 1, true) == nil, "titulo sem 'ACTIVE' quando nada esta' ativo")

print("== aba global ativa aparece no titulo com o tempo ==")
M.applyState(makeState(nil, 7200), true)
check(cardStatus("potion") == "ACTIVE for 2h 00m",
      "card da aba Potions mostra ACTIVE + tempo (got: " .. tostring(cardStatus("potion")) .. ")")
check(cardStatus("exp") == "Not active",
      "a aba EXP inativa nao repete os numeros do pool (a barra ja' mostra) " ..
      "(got: " .. tostring(cardStatus("exp")) .. ")")
check(string.find(ROOT.text, "ACTIVE: Potions 2h 00m", 1, true) ~= nil,
      "titulo lista a aba ativa (got: " .. tostring(ROOT.text) .. ")")

print("")
print(fails == 0 and "== CLIENT OK ==" or ("== " .. fails .. " FALHA(S) NO CLIENT =="))
return fails
"""


def load_lua():
    for path in DLL_CANDIDATES:
        if not os.path.exists(path):
            continue
        try:
            ctypes.CDLL(path)
            return path
        except OSError:
            continue
    print("Nao achei um Lua carregavel. Ajuste DLL_CANDIDATES.")
    sys.exit(2)


def main():
    lua_path = load_lua()
    print("Lua host:", lua_path)
    print("Client  :", CLIENT_ROOT)

    module = os.path.join(CLIENT_ROOT.replace("/", os.sep),
                          "modules", "statue_donation", "statue_donation.lua")
    if not os.path.exists(module):
        print("Nao achei o module do client: " + module)
        print("Ajuste CLIENT_ROOT (ou a env STATUE_CLIENT_ROOT).")
        return 2

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
    try:
        getattr(lua, "lua_pcall")
        pcall = proto(ctypes.c_int, ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int)("lua_pcall")
        call = lambda st: pcall(st, 0, 0, 0)
    except AttributeError:
        pcall = proto(ctypes.c_int, ctypes.c_void_p, ctypes.c_int, ctypes.c_int,
                      ctypes.c_int, ctypes.c_int64, ctypes.c_void_p)("lua_pcallk")
        call = lambda st: pcall(st, 0, 0, 0, 0, None)

    state = newstate()
    openlibs(state)
    src = LUA_TESTS.replace("__CL__", CLIENT_ROOT)
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


if __name__ == "__main__":
    sys.exit(main())
