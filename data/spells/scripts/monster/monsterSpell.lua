--[[
  monsterSpell.lua - motor unico das spells proprias dos monstros.

  Cada monstro tem UMA spell assinatura (nome, elemento, formato e visual dela).
  Todas apontam para este arquivo no spells.xml: o script descobre qual e' a
  spell pelo nome do monstro que esta' conjurando (getCreatureName) e le' a
  configuracao em data/lib/monsterSpellBook.lua.

  O DANO NAO FICA AQUI. Ele vem do <attack min=".." max=".."> no XML do
  monstro: Monster::doAttacking grava minCombatValue/maxCombatValue antes de
  chamar a spell e Combat::getMinMaxValues usa isso. Balancear = mexer no XML.

  REGRA DESTE SERVER (foi o que quebrou a primeira versao deste arquivo):
  createCombatObject/setCombatParam/setCombatArea so' funcionam enquanto o
  script esta' sendo CARREGADO (luascript.cpp checa getScriptId() ==
  EVENT_ID_LOADING). Chamados dentro do onCastSpell, eles falham com "This
  function can only be used while loading the script" e o doCombat seguinte
  responde "Combat not found" - a spell aparece bonita e nao da' dano nenhum.
  As condicoes (createConditionObject/addDamageCondition/setConditionParam)
  tambem sao criadas aqui: a carga guarda em m_conditionMap, que e' o mapa que
  o doAddCondition(cid, cond) procura por padrao; criadas no cast elas iriam
  para m_tempConditionMap e o doAddCondition nao acharia nada.
  Entao: combates e condicoes nascem UMA vez, la' embaixo, e onCastSpell so'
  usa os ids guardados.

  Formatos suportados (campo `shape` no SpellBook):
    blast  - um tiro no alvo atual (missile + efeito de impacto)
    burst  - explosao 3x3/5x5... centrada no ALVO (raio = radius)
    nova   - explosao quadrada centrada no PROPRIO monstro (raio = radius)
    wave   - onda que caminha na direcao que ele olha (length x width)
    beam   - linha reta na direcao que ele olha (length sqms)
    breath - cone/"bafo" que abre na direcao que ele olha (length sqms)
    rain   - `count` impactos sorteados em volta do alvo (raio = radius)
]]

-- Visual e tipo de dano de cada elemento. Os ids sao os que as proprias dobras
-- de cada elemento usam (data/spells/scripts/<elemento>), entao o monstro bate
-- com o mesmo visual que o jogador ja conhece.
-- CUIDADO: efeito de area (CONST_ME_*) e projetil (CONST_ANI_*) sao tabelas
-- DIFERENTES e a de projetil so' vai ate 45. Fogo/agua/ar/terra estavam com id
-- de efeito no lugar do projetil, e a spell saia sem missile nenhum.
local ELEMENTS = {
  fire     = {combat = COMBAT_FIREDAMAGE,     hit = CONST_ME_FIREAREA,     shoot = CONST_ANI_FIRE},
  water    = {combat = COMBAT_DROWNDAMAGE,    hit = CONST_ME_WATERSPLASH,  shoot = CONST_ANI_ICE},
  ice      = {combat = COMBAT_ICEDAMAGE,      hit = CONST_ME_ICEAREA,      shoot = CONST_ANI_ICE},
  air      = {combat = COMBAT_AIRDAMAGE,      hit = CONST_ME_NEWVII,       shoot = CONST_ANI_NEWIV},
  earth    = {combat = COMBAT_EARTHDAMAGE,    hit = CONST_ME_GROUNDSHAKER, shoot = CONST_ANI_LARGEROCK},
  poison   = {combat = COMBAT_POISONDAMAGE,   hit = CONST_ME_HITBYPOISON,  shoot = CONST_ANI_POISON},
  energy   = {combat = COMBAT_ENERGYDAMAGE,   hit = CONST_ME_ENERGYHIT,    shoot = CONST_ANI_ENERGY},
  death    = {combat = COMBAT_DEATHDAMAGE,    hit = CONST_ME_MORTAREA,     shoot = CONST_ANI_DEATH},
  physical = {combat = COMBAT_PHYSICALDAMAGE, hit = CONST_ME_HITAREA,      shoot = CONST_ANI_SMALLSTONE},
  holy     = {combat = COMBAT_HOLYDAMAGE,     hit = CONST_ME_HOLYDAMAGE,   shoot = CONST_ANI_SMALLHOLY}
}

-- Condicoes opcionais (campo `cond` no SpellBook). Sapecam no alvo depois do dano.
local CONDITION_BUILDERS = {
  poison = function()
    local c = createConditionObject(CONDITION_POISON)
    setConditionParam(c, CONDITION_PARAM_DELAYED, 1)
    addDamageCondition(c, 5, 2000, -3, -8)
    return c
  end,
  corrode = function()
    local c = createConditionObject(CONDITION_POISON)
    setConditionParam(c, CONDITION_PARAM_DELAYED, 1)
    addDamageCondition(c, 4, 2000, -5, -12)
    return c
  end,
  burn = function()
    local c = createConditionObject(CONDITION_FIRE)
    setConditionParam(c, CONDITION_PARAM_DELAYED, 1)
    addDamageCondition(c, 4, 2000, -6, -14)
    return c
  end,
  shock = function()
    local c = createConditionObject(CONDITION_ENERGY)
    setConditionParam(c, CONDITION_PARAM_DELAYED, 1)
    addDamageCondition(c, 4, 2000, -6, -14)
    return c
  end,
  bleed = function()
    local c = createConditionObject(CONDITION_BLEEDING)
    setConditionParam(c, CONDITION_PARAM_DELAYED, 1)
    addDamageCondition(c, 4, 2000, -4, -10)
    return c
  end,
  curse = function()
    local c = createConditionObject(CONDITION_CURSED)
    setConditionParam(c, CONDITION_PARAM_DELAYED, 1)
    addDamageCondition(c, 3, 2000, -8, -16)
    return c
  end
}

-- ---------------------------------------------------------------------------
-- Nasce na CARGA do script (ver a nota do cabecalho): um combate por elemento
-- e uma condicao por tipo. O que fica guardado aqui e' o id devolvido por eles.
-- ---------------------------------------------------------------------------
local combats = {}
for element, el in pairs(ELEMENTS) do
  local combat = createCombatObject()
  setCombatParam(combat, COMBAT_PARAM_TYPE, el.combat)
  setCombatParam(combat, COMBAT_PARAM_EFFECT, el.hit)
  combats[element] = combat
end

local conditions = {}
for name, builder in pairs(CONDITION_BUILDERS) do
  conditions[name] = builder()
end

-- ---------------------------------------------------------------------------
-- Helpers de cast
-- ---------------------------------------------------------------------------

local function getCombat(element)
  return combats[element] or combats.physical
end

local function getCondition(cond)
  if not cond then
    return nil
  end
  return conditions[cond]
end

local function getBook(cid)
  if type(monsterSpellBook) ~= "table" then
    return nil
  end
  return monsterSpellBook[getCreatureName(cid)]
end

local function resolveTarget(cid, var)
  if type(var) == "number" and isCreature(var) then
    return var
  end

  local target = getCreatureTarget(cid)
  if isCreature(target) then
    return target
  end

  return nil
end

local function tileIsHittable(pos, origin)
  if not pos or not hasSqm(pos) then
    return false
  end

  local info = getTileInfo(pos)
  if info and info.protection then
    return false
  end

  if origin and (pos.x ~= origin.x or pos.y ~= origin.y) then
    if not isSightClear(origin, pos, true) then
      return false
    end
  end

  return true
end

-- Da' o dano da spell no sqm (o valor vem do min/max do <attack> do monstro).
local function hitSqm(cid, cfg, pos, applyCondition)
  local el = ELEMENTS[cfg.element] or ELEMENTS.physical
  doCombat(cid, getCombat(cfg.element), {type = 2, pos = pos})
  doSendMagicEffect(pos, el.hit)

  if applyCondition then
    local condition = getCondition(cfg.cond)
    -- getSpectators devolve nil quando nao ha ninguem na tile (luascript.cpp),
    -- entao o ipairs aqui precisa da guarda.
    local spectators = condition and getSpectators(pos, 0, 0) or nil
    if spectators then
      for _, uid in ipairs(spectators) do
        if uid ~= cid and isCreature(uid) then
          doAddCondition(uid, condition)
        end
      end
    end
  end
end

local function forEachSqmInSquare(center, radius, fn)
  for x = center.x - radius, center.x + radius do
    for y = center.y - radius, center.y + radius do
      fn({x = x, y = y, z = center.z})
    end
  end
end

local DIRECTION_DELTA = {
  [NORTH] = {x = 0, y = -1},
  [EAST] = {x = 1, y = 0},
  [SOUTH] = {x = 0, y = 1},
  [WEST] = {x = -1, y = 0}
}

local function castBlast(cid, cfg, var)
  local target = resolveTarget(cid, var)
  local el = ELEMENTS[cfg.element] or ELEMENTS.physical

  if not target then
    return false
  end

  local fromPos = getThingPos(cid)
  local targetPos = getThingPos(target)

  doSendDistanceShoot(fromPos, targetPos, el.shoot)
  doCombat(cid, getCombat(cfg.element), numberToVariant(target))
  doSendMagicEffect(targetPos, el.hit)

  local condition = getCondition(cfg.cond)
  if condition then
    doAddCondition(target, condition)
  end

  return true
end

local function castSquare(cid, cfg, center)
  local ok = false
  local radius = cfg.radius or 1

  forEachSqmInSquare(center, radius, function(pos)
    if tileIsHittable(pos) then
      hitSqm(cid, cfg, pos, true)
      ok = true
    end
  end)

  return ok
end

local function castBurst(cid, cfg, var)
  local target = resolveTarget(cid, var)
  if not target then
    return false
  end

  local el = ELEMENTS[cfg.element] or ELEMENTS.physical
  doSendDistanceShoot(getThingPos(cid), getThingPos(target), el.shoot)

  return castSquare(cid, cfg, getThingPos(target))
end

local function castNova(cid, cfg)
  local center = getThingPos(cid)
  local radius = cfg.radius or 1
  local ok = false

  -- o proprio sqm do monstro fica de fora: ele nao leva a propria explosao
  forEachSqmInSquare(center, radius, function(pos)
    if (pos.x ~= center.x or pos.y ~= center.y) and tileIsHittable(pos) then
      hitSqm(cid, cfg, pos, true)
      ok = true
    end
  end)

  local el = ELEMENTS[cfg.element] or ELEMENTS.physical
  doSendMagicEffect(center, el.hit)

  return ok
end

local function castLine(cid, cfg, cone)
  local origin = getThingPos(cid)
  local dir = getCreatureLookDirection(cid)
  local delta = DIRECTION_DELTA[dir]
  local el = ELEMENTS[cfg.element] or ELEMENTS.physical
  local length = cfg.length or 4
  local ok = false

  for step = 1, length do
    local halfWidth = 0
    if cone then
      halfWidth = math.floor(step / 2) - 1
      if halfWidth < 0 then
        halfWidth = 0
      end
    end

    local perp = {x = -delta.y, y = delta.x}
    local center = {x = origin.x + (delta.x * step), y = origin.y + (delta.y * step), z = origin.z}

    for side = -halfWidth, halfWidth do
      local pos = {x = center.x + (perp.x * side), y = center.y + (perp.y * side), z = origin.z}
      if tileIsHittable(pos, origin) then
        hitSqm(cid, cfg, pos, true)
        ok = true
      end
    end

    doSendDistanceShoot({x = origin.x + (delta.x * (step - 1)), y = origin.y + (delta.y * (step - 1)), z = origin.z},
      center, el.shoot)
  end

  return ok
end

local function waveStep(cid, cfg, origin, delta, step)
  if not isCreature(cid) then
    return false
  end

  local el = ELEMENTS[cfg.element] or ELEMENTS.physical
  local perp = {x = -delta.y, y = delta.x}
  local center = {x = origin.x + (delta.x * step), y = origin.y + (delta.y * step), z = origin.z}
  local width = cfg.width or 0

  for side = -width, width do
    local pos = {x = center.x + (perp.x * side), y = center.y + (perp.y * side), z = origin.z}
    if tileIsHittable(pos, origin) then
      hitSqm(cid, cfg, pos, true)
    end
  end

  doSendDistanceShoot({x = origin.x + (delta.x * (step - 1)), y = origin.y + (delta.y * (step - 1)), z = origin.z},
    center, el.shoot)

  if step < (cfg.length or 4) then
    addEvent(waveStep, 120, cid, cfg, origin, delta, step + 1)
  end

  return true
end

local function castWave(cid, cfg)
  local dir = getCreatureLookDirection(cid)
  local delta = DIRECTION_DELTA[dir]
  if not delta then
    return false
  end

  return waveStep(cid, cfg, getThingPos(cid), delta, 1)
end

local function castRain(cid, cfg, var)
  local target = resolveTarget(cid, var)
  local center = target and getThingPos(target) or getThingPos(cid)
  local el = ELEMENTS[cfg.element] or ELEMENTS.physical
  local count = cfg.count or 6
  local radius = cfg.radius or 2

  for drop = 1, count do
    local pos = {
      x = center.x + math.random(-radius, radius),
      y = center.y + math.random(-radius, radius),
      z = center.z
    }

    if tileIsHittable(pos) then
      doSendDistanceShoot({x = pos.x, y = pos.y, z = pos.z - 3}, pos, el.shoot)
      hitSqm(cid, cfg, pos, true)
    end
  end

  return true
end

function onCastSpell(cid, var)
  if not isCreature(cid) then
    return false
  end

  local cfg = getBook(cid)
  if not cfg then
    return false
  end

  local shape = cfg.shape

  if shape == "blast" then
    return castBlast(cid, cfg, var)
  elseif shape == "burst" then
    return castBurst(cid, cfg, var)
  elseif shape == "nova" then
    return castNova(cid, cfg)
  elseif shape == "wave" then
    return castWave(cid, cfg)
  elseif shape == "beam" then
    return castLine(cid, cfg, false)
  elseif shape == "breath" then
    return castLine(cid, cfg, true)
  elseif shape == "rain" then
    return castRain(cid, cfg, var)
  end

  return false
end
