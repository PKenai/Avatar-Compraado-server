-- ============================================================================
-- FISH SYSTEM (server) - dados centrais dos peixes, bonus ao comer,
-- skill de Cooking (storage-based) e o sorteio da pesca.
-- ----------------------------------------------------------------------------
-- Este arquivo e' o "banco de dados" do sistema. Tudo que muda de balance
-- (nome, dificuldade, bonus, XP) esta' na tabela FISH abaixo - mexa so' aqui.
--
-- IDs (ja existem no items.otb):
--   cru    : 19398 .. 19415   (client ids 18400 .. 18417)
--   assado : 19417 .. 19434   (client ids 18419 .. 18436)
--   (19416 e' um item solto do otb, nao usado pelo sistema)
--
-- Regras gerais:
--   * quanto MAIOR o indice, mais dificil de pescar/cozinhar;
--   * os 4 ultimos (19412-19415) sao os "Bender", 1 pra cada vocacao
--     (fogo=1, agua=2, ar=3, terra=4) - todos podem comer, mas quem e' da
--     vocacao do peixe ganha um bonus extra;
--   * assado = mesmo peixe, bonus +10% (cookBonus) e o shader "gostoso".
--
-- BUFF NA BARRA DE CIMA E PERSISTENCIA:
--   * comer cria um ICONE (data/images/buffs/Fish buffs.png) na barra de
--     buffs do client com o tempo do bonus correndo;
--   * o que foi comido fica gravado em storages do player, entao o icone volta
--     SOZINHO depois de logout/relogin enquanto o bonus ainda estiver valendo
--     (ver FishSystem.restoreBuff, chamado por loginLogout/login.lua).
--
-- Pescaria e cozinha sao duas carreiras longas: pra chegar no ultimo peixe
-- assado a pessoa escolhe uma pra vida. As curvas de XP ficam nas constantes
-- abaixo - se quiser mais leve/mais pesado, e' so' mexer nos numeros.
-- ============================================================================

FishSystem = FishSystem or {}

if type(json) ~= "table" then
  dofile(getDataDir() .. "lib/json.lua")
end

local COOKING_OPCODE = 107

-- Storages do Cooking (nao conflitam com os do cookingSystem.lua/minigame).
local STORAGE_COOK_LEVEL = 47030
local STORAGE_COOK_XP    = 47031

-- Quanto de bonus extra um peixe assado ganha (10%).
local COOK_BONUS = 1.10

-- Curva de XP de Cooking: XP necessario pra subir do nivel L pro L+1.
-- 30 * L^1.35 e' proposital: comeca leve e pesa no fim (nivel ~60 pede
-- uma sessao de jogo inteira).
local function xpForLevel(level)
  if level < 1 then return 0 end
  return math.floor(30 * (level ^ 1.35)) + 20
end

-- ============================================================================
-- TABELA DOS PEIXES
-- ----------------------------------------------------------------------------
-- campos:
--   id        id cru (server)
--   cooked    id assado (server)      -> id + 19
--   name      nome cru
--   tier      1..5 (raridade/forca)
--   food      quanto enche a barriga
--   reqFish   skill de fishing minima pra esse peixe entrar no sorteio
--   weight    peso no sorteio (maior = mais comum)
--   skillGain quanto a skill de fishing ajuda a desbloquear o peixe
--   cookLvl   nivel de Cooking minimo pra assar
--   cookXp    XP de Cooking por acerto
--   stirs     mexidas certas no minigame (dificuldade do cozimento)
--   duration  tempo do bonus, em segundos
--   voc       vocacao "dona" do peixe (fogo=1 agua=2 ar=3 terra=4) - so nos top
--   bonus     o que o peixe da' ao ser comido
--   vocBonus  bonus EXTRA se quem comeu for da vocacao do peixe
-- ============================================================================
local FISH = {
  -- ---------------------------------------------------------------- tier 1
  {
    id = 19398, cooked = 19417, name = "Sardine", tier = 1,
    food = 40, reqFish = 10, weight = 1000, skillGain = 0.05,
    -- cookLvl = 0 DE PROPOSITO: quem nunca cozinhou tem Cooking 0, e a
    -- primeira receita precisa ser cozinhavel nesse nivel - senao TODAS
    -- ficavam travadas e nao existia jeito de subir a skill (o botao
    -- "Cook" nascia desabilitado). A Sardinha e' a porta de entrada.
    cookLvl = 0, cookXp = 20, stirs = 3, duration = 120,
    bonus = { hp = 25, hpRegen = 3 },
  },
  {
    id = 19399, cooked = 19418, name = "Anchovy", tier = 1,
    food = 45, reqFish = 10, weight = 900, skillGain = 0.05,
    cookLvl = 2, cookXp = 22, stirs = 3, duration = 120,
    bonus = { mana = 20, manaRegen = 3 },
  },
  {
    id = 19400, cooked = 19419, name = "Minnow", tier = 1,
    food = 50, reqFish = 12, weight = 850, skillGain = 0.05,
    cookLvl = 3, cookXp = 24, stirs = 3, duration = 130,
    bonus = { hp = 20, mana = 20 },
  },
  {
    id = 19401, cooked = 19420, name = "Tilapia", tier = 1,
    food = 55, reqFish = 14, weight = 800, skillGain = 0.05,
    cookLvl = 4, cookXp = 26, stirs = 3, duration = 140,
    bonus = { hp = 35 },
  },

  -- ---------------------------------------------------------------- tier 2
  {
    id = 19402, cooked = 19421, name = "Croaker", tier = 2,
    food = 70, reqFish = 17, weight = 520, skillGain = 0.06,
    cookLvl = 7, cookXp = 50, stirs = 4, duration = 180,
    bonus = { shield = 1, hpRegen = 5 },
  },
  {
    id = 19403, cooked = 19422, name = "Porgy", tier = 2,
    food = 75, reqFish = 20, weight = 460, skillGain = 0.06,
    cookLvl = 9, cookXp = 55, stirs = 4, duration = 180,
    bonus = { mana = 50, manaRegen = 5 },
  },
  {
    id = 19404, cooked = 19423, name = "Sea Bass", tier = 2,
    food = 80, reqFish = 23, weight = 400, skillGain = 0.06,
    cookLvl = 11, cookXp = 60, stirs = 4, duration = 200,
    bonus = { hp = 60, speed = 20 },
  },

  -- ---------------------------------------------------------------- tier 3
  {
    id = 19405, cooked = 19424, name = "Dorado", tier = 3,
    food = 100, reqFish = 27, weight = 240, skillGain = 0.07,
    cookLvl = 15, cookXp = 120, stirs = 5, duration = 240,
    bonus = { shield = 2, hpRegen = 8, speed = 20 },
  },
  {
    id = 19406, cooked = 19425, name = "Arapaima", tier = 3,
    food = 110, reqFish = 31, weight = 200, skillGain = 0.07,
    cookLvl = 18, cookXp = 140, stirs = 5, duration = 240,
    bonus = { hp = 120, hpRegen = 8 },
  },
  {
    id = 19407, cooked = 19426, name = "Peacock Bass", tier = 3,
    food = 105, reqFish = 35, weight = 180, skillGain = 0.07,
    cookLvl = 21, cookXp = 160, stirs = 5, duration = 240,
    bonus = { magic = 2, manaRegen = 10 },
  },

  -- ---------------------------------------------------------------- tier 4
  {
    id = 19408, cooked = 19427, name = "Tambaqui", tier = 4,
    food = 150, reqFish = 39, weight = 90, skillGain = 0.08,
    cookLvl = 26, cookXp = 300, stirs = 6, duration = 300,
    bonus = { hp = 200, mana = 150, hpRegen = 12 },
  },
  {
    id = 19409, cooked = 19428, name = "Spotted Catfish", tier = 4,
    food = 160, reqFish = 43, weight = 70, skillGain = 0.08,
    cookLvl = 29, cookXp = 340, stirs = 6, duration = 300,
    bonus = { shield = 4, hp = 150, speed = 30 },
  },
  {
    id = 19410, cooked = 19429, name = "Sturgeon", tier = 4,
    food = 170, reqFish = 47, weight = 55, skillGain = 0.08,
    cookLvl = 32, cookXp = 380, stirs = 6, duration = 300,
    bonus = { magic = 4, mana = 250, manaRegen = 15 },
  },
  {
    id = 19411, cooked = 19430, name = "Electric Eel", tier = 4,
    food = 165, reqFish = 51, weight = 45, skillGain = 0.08,
    cookLvl = 35, cookXp = 420, stirs = 6, duration = 300,
    bonus = { speed = 50, magic = 3, manaRegen = 12 },
  },

  -- ------------------------------------------- tier 5 (Bender, 1 por vocacao)
  {
    id = 19412, cooked = 19431, name = "Firebender Fish", tier = 5,
    food = 220, reqFish = 54, weight = 12, skillGain = 0.10,
    cookLvl = 40, cookXp = 800, stirs = 8, duration = 420,
    voc = 1, -- fire
    bonus = { magic = 6, mana = 400, manaRegen = 20, hp = 150 },
    vocBonus = { magic = 4, manaRegen = 10 },
  },
  {
    id = 19413, cooked = 19432, name = "Waterbender Fish", tier = 5,
    food = 220, reqFish = 56, weight = 10, skillGain = 0.10,
    cookLvl = 42, cookXp = 850, stirs = 8, duration = 420,
    voc = 2, -- water
    bonus = { hp = 400, mana = 300, hpRegen = 25, manaRegen = 15 },
    vocBonus = { hpRegen = 15, manaRegen = 10 },
  },
  {
    id = 19414, cooked = 19433, name = "Airbender Fish", tier = 5,
    food = 220, reqFish = 58, weight = 8, skillGain = 0.10,
    cookLvl = 44, cookXp = 900, stirs = 8, duration = 420,
    voc = 3, -- air
    bonus = { speed = 80, shield = 5, magic = 4 },
    vocBonus = { speed = 40, shield = 3 },
  },
  {
    id = 19415, cooked = 19434, name = "Earthbender Fish", tier = 5,
    food = 220, reqFish = 60, weight = 6, skillGain = 0.10,
    cookLvl = 46, cookXp = 1000, stirs = 8, duration = 420,
    voc = 4, -- earth
    bonus = { hp = 600, shield = 8, hpRegen = 30, speed = 30 },
    vocBonus = { hp = 300, shield = 4 },
  },
}

-- Indice por id (cru e assado) pra busca rapida.
local BY_ID = {}
for i, f in ipairs(FISH) do
  f.index = i
  f.cookBonus = COOK_BONUS
  BY_ID[f.id] = f
  BY_ID[f.cooked] = f
end

FishSystem.LIST = FISH
FishSystem.COOK_BONUS = COOK_BONUS
FishSystem.STORAGE_COOK_LEVEL = STORAGE_COOK_LEVEL
FishSystem.STORAGE_COOK_XP = STORAGE_COOK_XP
FishSystem.xpForLevel = xpForLevel

-- ============================================================================
-- HELPERS
-- ============================================================================

-- Retorna o peixe (cru ou assado) e se ele e' a versao assada.
function FishSystem.get(itemId)
  local f = BY_ID[itemId]
  if not f then return nil, false end
  return f, f.cooked == itemId
end

-- Nivel de fishing atual do jogador (o engine guarda a skill; comeca em 10).
function FishSystem.getFishingLevel(cid)
  local lvl = getPlayerSkill(cid, SKILL_FISHING)
  if type(lvl) ~= "number" then return 10 end
  return lvl
end

-- Vocacao base (fire=1 agua=2 ar=3 terra=4), ignorando a promocao.
function FishSystem.baseVocation(cid)
  local v = getPlayerVocation(cid)
  if type(v) ~= "number" or v < 1 then return 0 end
  return ((v - 1) % 4) + 1
end

-- ============================================================================
-- SORTEIO DA PESCA
-- ----------------------------------------------------------------------------
-- Quanto maior a skill, mais peso os peixes raros ganham (skillGain), mas os
-- peixes de ID maior continuam MUITO mais raros que os comuns. Quem nao tem
-- skill minima nem entra no sorteio.
-- ============================================================================
function FishSystem.rollFish(cid)
  local skill = FishSystem.getFishingLevel(cid)

  local total, pool = 0, {}
  for _, f in ipairs(FISH) do
    if skill >= f.reqFish then
      -- peso cresce com o quanto a skill passou do requisito
      local w = f.weight * (1 + (skill - f.reqFish) * f.skillGain)
      pool[#pool + 1] = { fish = f, w = w }
      total = total + w
    end
  end

  -- skill muito baixa: garante pelo menos o peixe mais comum
  if total <= 0 then return FISH[1] end

  local r = math.random() * total
  local acc = 0
  for _, entry in ipairs(pool) do
    acc = acc + entry.w
    if r <= acc then return entry.fish end
  end
  return pool[#pool].fish
end

-- ============================================================================
-- SKILL DE COOKING (storage-based, mostrada no client via opcode 107)
-- ============================================================================

function FishSystem.getCookingLevel(cid)
  local lvl = tonumber(getPlayerStorageValue(cid, STORAGE_COOK_LEVEL)) or 0
  if lvl < 0 then lvl = 0 end
  return lvl
end

function FishSystem.getCookingXp(cid)
  local xp = tonumber(getPlayerStorageValue(cid, STORAGE_COOK_XP)) or 0
  if xp < 0 then xp = 0 end
  return xp
end

-- % de progresso do nivel atual (pro client desenhar a barra).
function FishSystem.getCookingPercent(cid)
  local lvl = FishSystem.getCookingLevel(cid)
  local need = xpForLevel(lvl + 1)
  if need <= 0 then return 100 end
  local pct = math.floor((FishSystem.getCookingXp(cid) / need) * 100)
  if pct > 100 then pct = 100 end
  return pct
end

-- Adiciona XP e sobe de nivel quantas vezes couber. Retorna quantos niveis subiu.
function FishSystem.addCookingXp(cid, amount)
  if type(amount) ~= "number" or amount <= 0 then return 0 end

  local lvl = FishSystem.getCookingLevel(cid)
  local xp = FishSystem.getCookingXp(cid) + amount
  local levels = 0

  while true do
    local need = xpForLevel(lvl + 1)
    if xp < need then break end
    xp = xp - need
    lvl = lvl + 1
    levels = levels + 1
    if lvl >= 200 then xp = 0 break end -- trava de seguranca
  end

  setPlayerStorageValue(cid, STORAGE_COOK_LEVEL, lvl)
  setPlayerStorageValue(cid, STORAGE_COOK_XP, xp)
  return levels
end

-- Manda level/xp pro client (o cooking.lua mostra na skillBar).
function FishSystem.sendCookingSkill(cid)
  if type(json) ~= "table" then
    dofile(getDataDir() .. "lib/json.lua")
  end

  local lvl = FishSystem.getCookingLevel(cid)
  local payload = {
    action = "skill",
    skill = {
      level = lvl,
      percentage = FishSystem.getCookingPercent(cid),
      xp = FishSystem.getCookingXp(cid),
      xpNext = xpForLevel(lvl + 1),
    },
  }
  pcall(doSendPlayerExtendedOpcode, cid, COOKING_OPCODE, json.encode(payload))
end

-- ============================================================================
-- BUFF NA BARRA DE CIMA (mods/game_buffs, opcode 100)
-- ----------------------------------------------------------------------------
-- Ao comer, o peixe tambem vira um ICONE na barra de buffs (icone
-- data/images/buffs/Fish buffs.png), com o tempo do bonus correndo.
--
-- Mesmo esquema da estatua de doacao: se o id 19 estiver no binario
-- (sources/buff.h -> BUFF_FISH_FEAST) o buff e' "oficial" (o engine remove
-- sozinho quando acaba); se o .exe for antigo o registerBuffType devolve
-- false e o envio direto do opcode 100 faz o mesmo trabalho - o icone nunca
-- depende de recompilar.
-- ============================================================================

local BUFF_ID     = 19              -- BUFF_FISH_FEAST (sources/buff.h)
local BUFF_ICON   = "Fish buffs"    -- data/images/buffs/Fish buffs.png
local BUFF_BORDER = "frame-2-gold"

local buffRegistered = false
local buffTried = false

local function ensureBuffType()
  if buffTried then return buffRegistered end
  buffTried = true

  if type(registerBuffType) ~= "function" then return false end
  local ok, result = pcall(registerBuffType, BUFF_ID, "Fish Feast",
    "You are well fed.", BUFF_ICON, BUFF_BORDER, false, 1, -1, false, false)
  buffRegistered = ok and result == true
  return buffRegistered
end

-- name/desc vem de quem comeu (leva o peixe exato e o bonus ja' calculado).
function FishSystem.sendBuff(cid, name, desc, ms)
  if type(cid) ~= "number" or type(ms) ~= "number" or ms <= 0 then return end

  if ensureBuffType() and type(doCreatureAddBuffWithTime) == "function" then
    pcall(doCreatureAddBuffWithTime, cid, BUFF_ID, ms)
  end

  -- Envio direto (o MESMO JSON que o C++ manda no opcode 100). O client
  -- destroi o icone antigo do mesmo id e recria com este nome/tempo, entao
  -- comer outro peixe so' atualiza o buff - nunca empilha icone.
  pcall(doSendPlayerExtendedOpcode, cid, 100, json.encode({
    action = "add",
    data = {
      id = BUFF_ID,
      name = name,
      description = desc ~= "" and desc or "You are well fed.",
      icon = BUFF_ICON,
      border = BUFF_BORDER,
      stacks = 1,
      ticks = ms,
      endTime = (os.time() + math.floor(ms / 1000)) * 1000,
      server_time = os.time(),
      debuff = false,
    },
  }))
end

-- ============================================================================
-- NUMEROS DO BONUS (unica fonte)
-- ----------------------------------------------------------------------------
-- computeBonus e' a UNICA fonte dos numeros: comer e reaplicar o buff no login
-- passam por aqui, entao o tooltip do icone nunca diverge do que as condicoes
-- estao realmente aplicando.
-- cooked = true aplica COOK_BONUS (+10%) em TODOS os numeros.
-- ============================================================================

-- Nome do peixe como ele aparece na barra de buffs. O prefixo tem que ser o
-- mesmo que o cookingSystem usa nas receitas e que o items.xml usa nos itens
-- assados ("Roasted X").
local function fishBuffName(fish, cooked)
  return cooked and ("Roasted " .. fish.name) or fish.name
end

function FishSystem.computeBonus(fish, cooked, withVoc)
  local b = fish.bonus or {}
  local extra = withVoc and fish.vocBonus or nil
  local mult = cooked and COOK_BONUS or 1

  local function attr(value)
    return math.floor((value or 0) * mult)
  end

  local values = {
    hp        = attr(b.hp)        + attr(extra and extra.hp),
    mana      = attr(b.mana)      + attr(extra and extra.mana),
    magic     = attr(b.magic)     + attr(extra and extra.magic),
    shield    = attr(b.shield)    + attr(extra and extra.shield),
    hpRegen   = attr(b.hpRegen)   + attr(extra and extra.hpRegen),
    manaRegen = attr(b.manaRegen) + attr(extra and extra.manaRegen),
    speed     = attr(b.speed)     + attr(extra and extra.speed),
  }

  local parts = {}
  if values.hp > 0 then table.insert(parts, "+" .. values.hp .. " HP max") end
  if values.mana > 0 then table.insert(parts, "+" .. values.mana .. " Mana max") end
  if values.magic > 0 then table.insert(parts, "+" .. values.magic .. " Bending") end
  if values.shield > 0 then table.insert(parts, "+" .. values.shield .. " Shielding") end
  if values.hpRegen > 0 then table.insert(parts, "+" .. values.hpRegen .. " HP regen") end
  if values.manaRegen > 0 then table.insert(parts, "+" .. values.manaRegen .. " Mana regen") end
  if values.speed > 0 then table.insert(parts, "+" .. values.speed .. " Speed") end
  values.text = table.concat(parts, ", ")

  return values
end

-- ============================================================================
-- PERSISTENCIA DO BUFF (sobrevive a logout / crash / restart)
-- ----------------------------------------------------------------------------
-- O que o jogador comeu e quando acaba ficam em storages do PLAYER, gravados
-- no banco. As CONDICOES do bonus (HP/Mana max, Bending, Shielding, speed,
-- regen) ja' sao serializadas pelo proprio engine no logout (iologindata grava
-- a coluna `conditions` e elas voltam ativas no login) - mas o engine NAO
-- manda icone nenhum por causa disso: a barra de buffs do client reinicia
-- VAZIA. Por isso o icone precisa ser reenviado a mao em todo login/relogin.
-- ============================================================================

local STORAGE_BUFF_UNTIL  = 47032  -- unix do fim do bonus
local STORAGE_BUFF_FISH   = 47033  -- indice do peixe na tabela FISH
local STORAGE_BUFF_COOKED = 47034  -- 1 = era assado
local STORAGE_BUFF_VOC    = 47035  -- 1 = ganhou o extra de vocacao

function FishSystem.saveBuff(cid, fish, cooked, withVoc, ms)
  setPlayerStorageValue(cid, STORAGE_BUFF_FISH, fish.index or 0)
  setPlayerStorageValue(cid, STORAGE_BUFF_COOKED, cooked and 1 or -1)
  setPlayerStorageValue(cid, STORAGE_BUFF_VOC, withVoc and 1 or -1)
  setPlayerStorageValue(cid, STORAGE_BUFF_UNTIL, os.time() + math.floor(ms / 1000))
end

-- Reaplica o ICONE (e o buff nativo, se o binario tiver o id) se o bonus do
-- peixe ainda estiver correndo. Chamado no login E no relogin por
-- loginLogout/login.lua -> restorePersistentBuffs(cid).
--
-- A vocacao usada e' a que estava gravada (e nao a atual do player): as
-- condicoes que voltaram do banco foram as aplicadas com aquele extra, entao o
-- tooltip tem que descrever o mesmo que esta' valendo.
function FishSystem.restoreBuff(cid)
  local until_ = tonumber(getPlayerStorageValue(cid, STORAGE_BUFF_UNTIL)) or 0
  local now = os.time()
  if until_ <= now then return false end

  local index = tonumber(getPlayerStorageValue(cid, STORAGE_BUFF_FISH)) or 0
  local fish = FISH[index]
  if not fish then return false end

  local cooked = (tonumber(getPlayerStorageValue(cid, STORAGE_BUFF_COOKED)) or 0) == 1
  local withVoc = (tonumber(getPlayerStorageValue(cid, STORAGE_BUFF_VOC)) or 0) == 1

  local values = FishSystem.computeBonus(fish, cooked, withVoc)
  local name = fishBuffName(fish, cooked)
  if withVoc then name = name .. " (vocation)" end

  FishSystem.sendBuff(cid, name, values.text, (until_ - now) * 1000)
  return true
end

-- ============================================================================
-- APLICAR BONUS AO COMER
-- ============================================================================

function FishSystem.applyBonus(cid, fish, cooked)
  -- Bonus extra pra quem e' da vocacao do peixe (so' nos Bender).
  local withVoc = fish.voc ~= nil and fish.voc == FishSystem.baseVocation(cid)
  local v = FishSystem.computeBonus(fish, cooked, withVoc)
  local duration = (fish.duration or 120) * 1000

  -- -------- atributos (max hp/mana, magic, shield, speed) --------
  local attrs = createConditionObject(CONDITION_ATTRIBUTES)
  setConditionParam(attrs, CONDITION_PARAM_TICKS, duration)
  local hasAttr = false
  if v.hp > 0 then setConditionParam(attrs, CONDITION_PARAM_STAT_MAXHEALTH, v.hp) hasAttr = true end
  if v.mana > 0 then setConditionParam(attrs, CONDITION_PARAM_STAT_MAXMANA, v.mana) hasAttr = true end
  if v.magic > 0 then setConditionParam(attrs, CONDITION_PARAM_STAT_MAGICLEVEL, v.magic) hasAttr = true end
  if v.shield > 0 then setConditionParam(attrs, CONDITION_PARAM_SKILL_SHIELD, v.shield) hasAttr = true end
  if hasAttr then doAddCondition(cid, attrs) end

  -- -------- regeneracao (hp/mana por tick) --------
  if v.hpRegen > 0 or v.manaRegen > 0 then
    local regen = createConditionObject(CONDITION_REGENERATION)
    setConditionParam(regen, CONDITION_PARAM_TICKS, duration)
    if v.hpRegen > 0 then
      setConditionParam(regen, CONDITION_PARAM_HEALTHGAIN, v.hpRegen)
      setConditionParam(regen, CONDITION_PARAM_HEALTHTICKS, 2000)
    end
    if v.manaRegen > 0 then
      setConditionParam(regen, CONDITION_PARAM_MANAGAIN, v.manaRegen)
      setConditionParam(regen, CONDITION_PARAM_MANATICKS, 2000)
    end
    doAddCondition(cid, regen)
  end

  -- -------- velocidade (haste) --------
  if v.speed > 0 then
    local haste = createConditionObject(CONDITION_HASTE)
    setConditionParam(haste, CONDITION_PARAM_TICKS, duration)
    setConditionParam(haste, CONDITION_PARAM_SPEED, v.speed)
    doAddCondition(cid, haste)
  end

  -- Efeito visual de "comida boa".
  local pos = getThingPosition(cid)
  if cooked then
    doSendMagicEffect(pos, CONST_ME_MAGIC_GREEN)
  else
    doSendMagicEffect(pos, CONST_ME_LOSEENERGY)
  end

  -- Icone na barra de cima + registro, pra ele voltar sozinho no proximo login.
  local name = fishBuffName(fish, cooked)
  if withVoc then name = name .. " (vocation)" end
  FishSystem.saveBuff(cid, fish, cooked, withVoc, duration)
  FishSystem.sendBuff(cid, name, v.text, duration)
end
