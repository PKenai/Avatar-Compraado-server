-- ============================================================
-- COOKING SYSTEM - 100% Server-Side
-- Forja (craftingSystem.lua) fundida com o minigame da pesca:
-- ao cozinhar, o jogador precisa acertar a "mexida" da panela
-- (minigame da barra) STIR_TOTAL vezes seguidas. Errou 1 = queimou.
-- O client e APENAS interface visual (modules/game_cooking).
-- ============================================================

CookingSystem = {}

-- Carrega json se nao estiver disponivel
if type(json) ~= "table" then
  dofile(getDataDir().."lib/json.lua")
end

local COOKING_OPCODE = 107

-- Storages do sistema. Mude aqui se conflitarem com o seu servidor.
local STORAGE_ACTIVE      = 47020  -- 1 = cozinhando agora (minigame aberto)
local STORAGE_RECIPE      = 47021  -- receita em andamento (globalId)
local STORAGE_ATTEMPTS    = 47022  -- quantas mexidas certas ate agora
local STORAGE_CAULDRON_X  = 47023  -- posicao do caldeirao (efeitos)
local STORAGE_CAULDRON_Y  = 47024
local STORAGE_CAULDRON_Z  = 47025

-- Itens do sistema
local PAN_ID        = 2563   -- frigideira (item usado no caldeirao)
local CAULDRON_ID   = 1483   -- caldeirao (alvo do clique)
local FRIED_EGG_ID  = 18879  -- placeholder do ovo frito

-- Quantas mexidas certas sao necessarias para a comida dar certo.
local STIR_TOTAL = 5

-- Efeitos
local EFFECT_STIR   = CONST_ME_SMOKE      -- fumaquinha a cada mexida certa
local EFFECT_FIRE   = CONST_ME_FIREAREA   -- fogo no caldeirao enquanto cozinha
local EFFECT_FAIL   = CONST_ME_POFF       -- queimou

-- ============================================================
-- DEFINICAO DE RECEITAS (server-side)
-- Todos os IDs sao reais do items.xml
-- ============================================================

local RECIPES = {
  {
    id = 1,
    name = "Ovo Frito",
    tier = 1,
    resultItemId = 18879,
    resultCount = 1,
    cost = 0,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 2695, count = 1},  -- Ovo x1
    },
  },
}

-- ============================================================
-- HELPERS
-- ============================================================

local function limparEstado(cid)
  setPlayerStorageValue(cid, STORAGE_ACTIVE, -1)
  setPlayerStorageValue(cid, STORAGE_RECIPE, -1)
  setPlayerStorageValue(cid, STORAGE_ATTEMPTS, -1)
end

local function posicaoCaldeirao(cid)
  local x = tonumber(getPlayerStorageValue(cid, STORAGE_CAULDRON_X)) or -1
  local y = tonumber(getPlayerStorageValue(cid, STORAGE_CAULDRON_Y)) or -1
  local z = tonumber(getPlayerStorageValue(cid, STORAGE_CAULDRON_Z)) or -1
  if x > 0 and y > 0 then
    return {x = x, y = y, z = z}
  end
  return nil
end

-- Converte server ID -> client ID usando ItemType
local function toClientId(serverId)
  if serverId and serverId > 0 then
    local ok, result = pcall(ItemType, serverId)
    if ok and result and not result:isNull() then
      local cid = result:getClientId()
      if cid and cid > 0 then return cid end
    end
  end
  return serverId or 0
end

local function enviar(cid, dados)
  local json_ok, json_data = pcall(json.encode, dados)
  if not json_ok then
    print("[CookingSystem] ERRO json.encode: " .. tostring(json_data))
    return
  end
  pcall(doSendPlayerExtendedOpcode, cid, COOKING_OPCODE, json_data)
end

-- Conta quantas vezes o player pode cozinhar um recipe
local function getMaxCookAmount(cid, recipe)
  local maxAmount = 0
  local tempIngredients = {}
  for _, ingr in ipairs(recipe.ingredients) do
    tempIngredients[ingr.itemId] = getPlayerItemCount(cid, ingr.itemId)
  end

  local proceed = true
  while proceed do
    for _, ingr in ipairs(recipe.ingredients) do
      if (tempIngredients[ingr.itemId] or 0) < ingr.count then
        proceed = false
        break
      end
    end
    if not proceed then break end

    for _, ingr in ipairs(recipe.ingredients) do
      tempIngredients[ingr.itemId] = tempIngredients[ingr.itemId] - ingr.count
    end
    maxAmount = maxAmount + 1
    if maxAmount >= 100 then break end
  end

  return maxAmount
end

-- ============================================================
-- CHAMADO PELA ACTION (frigideira no caldeirao): guarda o
-- caldeirao e abre a janela de receitas.
-- ============================================================

function CookingSystem.openWindow(cid, cauldronPos)
  if cauldronPos and cauldronPos.x > 0 then
    setPlayerStorageValue(cid, STORAGE_CAULDRON_X, cauldronPos.x)
    setPlayerStorageValue(cid, STORAGE_CAULDRON_Y, cauldronPos.y)
    setPlayerStorageValue(cid, STORAGE_CAULDRON_Z, cauldronPos.z)
  end

  -- Mesmo formato da janela de craft (game_crafting) para o client
  -- copiado funcionar sem mudancas: action = "open" + recipes.
  local recipes = {}
  for i, recipe in ipairs(RECIPES) do
    local info = getItemInfo(recipe.resultItemId)
    local lookDesc = recipe.name or 'Unknown'
    if info then
      if info.description and info.description ~= "" then
        lookDesc = lookDesc .. "\n" .. info.description
      end
      local attrs = {}
      if info.armor and info.armor > 0 then
        table.insert(attrs, "Armor: " .. info.armor)
      end
      if info.attack and info.attack > 0 then
        table.insert(attrs, "Attack: " .. info.attack)
      end
      if info.defense and info.defense > 0 then
        table.insert(attrs, "Defense: " .. info.defense)
      end
      if info.weight and info.weight > 0 then
        table.insert(attrs, "Weight: " .. info.weight .. " oz")
      end
      if #attrs > 0 then
        lookDesc = lookDesc .. "\n" .. table.concat(attrs, ", ")
      end
    end

    local r = {
      globalId = i,
      spriteId = toClientId(recipe.resultItemId) or 0,
      count = recipe.resultCount or 1,
      name = recipe.name or 'Unknown',
      tier = recipe.tier or 1,
      desc = lookDesc,
      cost = recipe.cost or 0,
      requiredSkill = recipe.requiredSkill or 1,
      recipestorage = recipe.storageRequirement or 0,
      storagevalue = getPlayerStorageValue(cid, recipe.storageRequirement or 0) or 0,
      ingredients = {},
    }

    for _, ingr in ipairs(recipe.ingredients) do
      local ingrName = getItemNameById(ingr.itemId)
      if not ingrName or ingrName == '' then ingrName = 'Unknown' end
      table.insert(r.ingredients, {
        name = ingrName,
        spriteId = toClientId(ingr.itemId) or 0,
        count = ingr.count or 1,
        playerCount = getPlayerItemCount(cid, ingr.itemId) or 0,
      })
    end

    table.insert(recipes, r)
  end

  enviar(cid, {
    action = "open",
    skill = {
      level = 100,
      percentage = 100,
      profId = 3,  -- Cooking (so para o titulo da janela no client)
    },
    recipes = recipes,
  })
end

-- ============================================================
-- COMEÇAR A COZINHAR (client clicou em "Cook")
-- Cobra os ingredientes e abre o minigame da mexida.
-- ============================================================

local function handleCraft(cid, dados)
  if getPlayerStorageValue(cid, STORAGE_ACTIVE) == 1 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, "You are already cooking.")
    return true
  end

  local recipe = RECIPES[tonumber(dados.recipeId)]
  if not recipe then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Invalid recipe.")
    return true
  end

  local maxCook = getMaxCookAmount(cid, recipe)
  if maxCook <= 0 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "You don't have the ingredients.")
    return true
  end

  -- Remove ingredientes (o ovo e cobrado aqui, nao devolve se errar a mexida)
  for _, ingr in ipairs(recipe.ingredients) do
    if not doPlayerRemoveItem(cid, ingr.itemId, ingr.count) then
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Error removing ingredient.")
      return true
    end
  end

  -- Estado do minigame
  setPlayerStorageValue(cid, STORAGE_ACTIVE, 1)
  setPlayerStorageValue(cid, STORAGE_RECIPE, recipe.id)
  setPlayerStorageValue(cid, STORAGE_ATTEMPTS, 0)

  local cauldronPos = posicaoCaldeirao(cid)
  if cauldronPos then
    doSendMagicEffect(cauldronPos, EFFECT_FIRE)
  end

  enviar(cid, {
    action = "minigame",
    ticks = STIR_TOTAL,
    remaining = STIR_TOTAL,
    toolId = toClientId(PAN_ID),
  })

  return true
end

-- ============================================================
-- MEXIDA (client mandou o resultado de uma tentativa)
-- Acertou 5 seguidas = comida pronta. Errou 1 = queimou.
-- ============================================================

local function handleStir(cid, acertou)
  if getPlayerStorageValue(cid, STORAGE_ACTIVE) ~= 1 then
    return true  -- pacote atrasado ou forjado
  end

  local recipe = RECIPES[getPlayerStorageValue(cid, STORAGE_RECIPE)]
  if not recipe then
    limparEstado(cid)
    return true
  end

  -- Errou a mexida: queimou a comida na hora.
  if not acertou then
    limparEstado(cid)
    doSendMagicEffect(getCreaturePosition(cid), EFFECT_FAIL)
    enviar(cid, {
      action = "result",
      success = false,
      message = "You burned the food!",
    })
    return true
  end

  local attempts = getPlayerStorageValue(cid, STORAGE_ATTEMPTS) + 1
  setPlayerStorageValue(cid, STORAGE_ATTEMPTS, attempts)

  local cauldronPos = posicaoCaldeirao(cid)
  if cauldronPos then
    doSendMagicEffect(cauldronPos, EFFECT_STIR)
  end

  -- Ainda faltam mexidas: continua o minigame.
  if attempts < STIR_TOTAL then
    enviar(cid, {
      action = "stir_result",
      remaining = STIR_TOTAL - attempts,
    })
    return true
  end

  -- STIR_TOTAL acertos: comida pronta!
  limparEstado(cid)

  local item = doCreateItemEx(recipe.resultItemId, recipe.resultCount)
  if item and doPlayerAddItemEx(cid, item) ~= RETURNVALUE_NOERROR then
    doSendMagicEffect(getCreaturePosition(cid), EFFECT_FAIL)
    enviar(cid, {
      action = "result",
      success = false,
      message = "You have no room for the food.",
    })
    return true
  end

  if cauldronPos then
    doSendMagicEffect(cauldronPos, EFFECT_FIRE)
  end
  doSendMagicEffect(getCreaturePosition(cid), EFFECT_STIR)

  enviar(cid, {
    action = "result",
    success = true,
    message = "You cooked 1x " .. recipe.name .. "!",
  })
  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
    "You cooked 1x " .. recipe.name .. "!")

  return true
end

-- ============================================================
-- HANDLER DE OPCODE (chamado pelo opcode.lua)
-- ============================================================

function CookingSystem.onOpcode(cid, buffer)
  local json_ok, json_data = pcall(function() return json.decode(buffer) end)

  if not json_ok or type(json_data) ~= "table" then
    return false
  end

  local action = json_data.action

  if action == "craft" then
    handleCraft(cid, json_data)
    return true
  elseif action == "stir" then
    handleStir(cid, json_data.success == true)
    return true
  elseif action == "cancel" then
    limparEstado(cid)
    return true
  end

  return false
end

-- Chame no logout (loginLogout/logout.lua): sem isso, deslogar no meio da
-- cozinha deixaria o jogador "cozinhando" pra sempre ao relogar.
function CookingSystem.onLogout(cid)
  limparEstado(cid)
end