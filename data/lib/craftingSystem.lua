-- ============================================================
-- CRAFTING SYSTEM - 100% Server-Side
-- Toda a logica de recipes, validacao e craft fica AQUI.
-- O client E APENAS uma interface visual.
-- ============================================================

CraftingSystem = {}

-- Carrega json se nao estiver disponivel
if type(json) ~= "table" then
  dofile(getDataDir().."lib/json.lua")
end

local CRAFTING_OPCODE = 106

-- ============================================================
-- DEFINICAO DE RECEITAS (server-side)
-- Todos os IDs sao reais do items.xml
-- ============================================================

-- Profissoes
local PROFESSIONS = {
  [1] = {name = "Blacksmith", image = "/images/topbuttons/skills"},
  [2] = {name = "Alchemy",    image = "/images/topbuttons/shop"},
  [3] = {name = "Cooking",    image = "/images/topbuttons/drop"},
  [4] = {name = "Enchanting", image = "/images/topbuttons/market"},
}

-- Receitas: TUDO definido no server
local RECIPES = {
  -- ==================== BLACKSMITH (profId = 1) ====================
  {
    profId = 1,
    name = "Leather Armor",
    tier = 1,
    resultItemId = 2467,    -- leather armor
    resultCount = 1,
    cost = 50,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5876, count = 3},  -- lizard leather x3
      {itemId = 18232, count = 1}, -- fire fruit x1
    },
  },
  {
    profId = 1,
    name = "Chain Armor",
    tier = 1,
    resultItemId = 2464,    -- chain armor
    resultCount = 1,
    cost = 100,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5876, count = 5},  -- lizard leather x5
      {itemId = 18232, count = 2}, -- fire fruit x2
    },
  },
  {
    profId = 1,
    name = "Spike Sword",
    tier = 2,
    resultItemId = 2383,    -- spike sword
    resultCount = 1,
    cost = 300,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5877, count = 3},  -- green dragon leather x3
      {itemId = 18232, count = 2}, -- fire fruit x2
    },
  },
  {
    profId = 1,
    name = "Plate Armor",
    tier = 2,
    resultItemId = 2463,    -- plate armor
    resultCount = 1,
    cost = 500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5877, count = 5},  -- green dragon leather x5
      {itemId = 18232, count = 3}, -- fire fruit x3
    },
  },
  {
    profId = 1,
    name = "Mastermind Shield",
    tier = 3,
    resultItemId = 2514,    -- mastermind shield
    resultCount = 1,
    cost = 1000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5877, count = 8},  -- green dragon leather x8
      {itemId = 18232, count = 5}, -- fire fruit x5
    },
  },
  {
    profId = 1,
    name = "Demon Armor",
    tier = 3,
    resultItemId = 2494,    -- demon armor
    resultCount = 1,
    cost = 2000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 18232, count = 5},  -- fire fruit x5
    },
  },

  -- ==================== ALCHEMY (profId = 2) ====================
  {
    profId = 2,
    name = "Devil Helmet",
    tier = 1,
    resultItemId = 2462,    -- devil helmet
    resultCount = 1,
    cost = 80,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5876, count = 4},  -- lizard leather x4
      {itemId = 18232, count = 1}, -- fire fruit x1
    },
  },
  {
    profId = 2,
    name = "Demon Helmet",
    tier = 2,
    resultItemId = 2493,    -- demon helmet
    resultCount = 1,
    cost = 200,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 5877, count = 3},  -- green dragon leather x3
      {itemId = 18232, count = 2}, -- fire fruit x2
    },
  },
}

-- ============================================================
-- SKILL DESABILITADO - todos podem craftar
-- ============================================================

function CraftingSystem.getSkillLevel(cid)
  return 100
end

function CraftingSystem.getSkillPercentage(cid)
  return 100
end

-- ============================================================
-- FUNCOES DE VALIDACAO (server-side)
-- ============================================================

-- Verifica se o player tem gold suficiente
local function hasGold(cid, amount)
  return getPlayerMoney(cid) >= amount
end

-- Verifica se o recipe esta desbloqueado
local function isRecipeUnlocked(cid, recipe)
  if recipe.storageRequirement > 0 then
    return getPlayerStorageValue(cid, recipe.storageRequirement) == 1
  end
  return true
end

-- Conta quantas vezes o player pode craftar um recipe
local function getMaxCraftAmount(cid, recipe)
  if not isRecipeUnlocked(cid, recipe) then return 0 end
  if getPlayerMoney(cid) < recipe.cost then return 0 end

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
-- FUNCAO DE CRAFT (server-side)
-- ============================================================

function CraftingSystem.craft(cid, recipeId, amount)
  local recipe = RECIPES[recipeId]
  if not recipe then
    return {success = false, message = "Receita invalida."}
  end

  amount = tonumber(amount) or 1
  if amount < 1 or amount > 100 then
    return {success = false, message = "Quantidade invalida."}
  end

  if not isRecipeUnlocked(cid, recipe) then
    return {success = false, message = "Receita nao desbloqueada."}
  end

  local maxCraft = getMaxCraftAmount(cid, recipe)
  if maxCraft <= 0 then
    return {success = false, message = "Materiais insuficientes."}
  end

  if amount > maxCraft then
    amount = maxCraft
  end

  local totalCost = recipe.cost * amount
  if getPlayerMoney(cid) < totalCost then
    return {success = false, message = "Gold insuficiente. Necessario: " .. totalCost}
  end

  -- REMOVER materiais
  for _, ingr in ipairs(recipe.ingredients) do
    local totalNeeded = ingr.count * amount
    if not doPlayerRemoveItem(cid, ingr.itemId, totalNeeded) then
      return {success = false, message = "Erro ao remover material: " .. ingr.itemId}
    end
  end

  -- REMOVER gold
  if not doPlayerRemoveMoney(cid, totalCost) then
    for _, ingr in ipairs(recipe.ingredients) do
      doPlayerAddItem(cid, ingr.itemId, ingr.count * amount)
    end
    return {success = false, message = "Erro ao cobrar gold."}
  end

  -- CRIAR item resultado
  local totalResult = recipe.resultCount * amount
  local item = doCreateItemEx(recipe.resultItemId, totalResult)
  if item and doPlayerAddItemEx(cid, item) ~= RETURNVALUE_NOERROR then
    doPlayerAddMoney(cid, totalCost)
    for _, ingr in ipairs(recipe.ingredients) do
      doPlayerAddItem(cid, ingr.itemId, ingr.count * amount)
    end
    return {success = false, message = "Inventario cheio. Itens devolvidos."}
  end

  return {
    success = true,
    message = "Voce criou " .. totalResult .. "x " .. recipe.name .. "!",
  }
end

-- ============================================================
-- FUNCAO PARA ENVIAR JANELA DE CRAFTING (server -> client)
-- ============================================================

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

function CraftingSystem.sendWindow(cid, profId)
  profId = profId or 1
  local prof = PROFESSIONS[profId]
  if not prof then prof = PROFESSIONS[1] end

  local skill = {
    level = CraftingSystem.getSkillLevel(cid),
    percentage = CraftingSystem.getSkillPercentage(cid),
    profId = profId,
  }

  -- Coleta receitas da profissao (converte IDs para client)
  local recipes = {}
  local globalIdx = 0
  for i, recipe in ipairs(RECIPES) do
    globalIdx = globalIdx + 1
    if recipe.profId == profId then
      -- Gera descricao estilo "look" do item (usando getItemInfo)
      local info = getItemInfo(recipe.resultItemId)
      local lookDesc = recipe.name
      if info then
        -- Descricao real do item
        if info.description and info.description ~= "" then
          lookDesc = lookDesc .. "\n" .. info.description
        end
        -- Atributos do item
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
        globalId = globalIdx,
        spriteId = toClientId(recipe.resultItemId),
        count = recipe.resultCount,
        name = recipe.name,
        tier = recipe.tier,
        desc = lookDesc,
        cost = recipe.cost,
        requiredSkill = recipe.requiredSkill,
        recipestorage = recipe.storageRequirement,
        storagevalue = getPlayerStorageValue(cid, recipe.storageRequirement),
        ingredients = {},
      }

      -- Conta quantos itens o player tem de cada ingrediente (converte IDs)
      for _, ingr in ipairs(recipe.ingredients) do
        table.insert(r.ingredients, {
          name = getItemNameById(ingr.itemId),
          spriteId = toClientId(ingr.itemId),
          count = ingr.count,
          playerCount = getPlayerItemCount(cid, ingr.itemId),
        })
      end

      table.insert(recipes, r)
    end
  end

  local json_ok, json_data = pcall(json.encode, {
    action = "open",
    skill = skill,
    recipes = recipes,
  })

  if not json_ok then
    print("[CraftingSystem] ERRO json.encode: " .. tostring(json_data))
    return
  end

  local send_ok, send_err = pcall(doSendPlayerExtendedOpcode, cid, CRAFTING_OPCODE, json_data)
  if not send_ok then
    print("[CraftingSystem] ERRO ao enviar opcode: " .. tostring(send_err))
  end
end

-- ============================================================
-- HANDLER DE OPCODE (chamado pelo opcode.lua)
-- ============================================================

function CraftingSystem.onOpcode(cid, buffer)
  local json_ok, json_data = pcall(function() return json.decode(buffer) end)

  if not json_ok or type(json_data) ~= "table" then
    return false
  end

  local action = json_data.action

  if action == "craft" then
    local recipeId = tonumber(json_data.recipeId)
    local amount = tonumber(json_data.amount) or 1

    if not recipeId then
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Pedido de craft invalido.")
      return true
    end

    local result = CraftingSystem.craft(cid, recipeId, amount)

    doSendPlayerExtendedOpcode(cid, CRAFTING_OPCODE, json.encode({
      action = "result",
      success = result.success,
      error = result.message,
    }))

    if result.success then
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, result.message)
    else
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, result.message)
    end

    local profId = tonumber(json_data.profId) or 1
    addEvent(function()
      if isPlayer(cid) then
        CraftingSystem.sendWindow(cid, profId)
      end
    end, 500)

    return true

  elseif action == "close" then
    return true
  end

  return false
end
