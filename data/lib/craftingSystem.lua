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
  -- ==================== BLACKSMITH - GLOVES (profId = 1) ====================
  {
    profId = 1,
    name = "Simple Glove",
    tier = 1,
    resultItemId = 19098,
    resultCount = 1,
    cost = 100,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 3},  -- Linen x3
    },
  },
  {
    profId = 1,
    name = "Sticky Glove",
    tier = 1,
    resultItemId = 19100,
    resultCount = 1,
    cost = 150,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 5},  -- Linen x5
      {itemId = 19101, count = 3},  -- Earth Beetle Shell x3
    },
  },
  {
    profId = 1,
    name = "Funeral Glove",
    tier = 1,
    resultItemId = 19102,
    resultCount = 1,
    cost = 200,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 8},  -- Linen x8
      {itemId = 19103, count = 5},  -- Worm Head x5
      {itemId = 19101, count = 3},  -- Earth Beetle Shell x3
    },
  },
  {
    profId = 1,
    name = "Red Pincer Glove",
    tier = 1,
    resultItemId = 19104,
    resultCount = 1,
    cost = 300,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 10}, -- Linen x10
      {itemId = 19105, count = 6},  -- Crab Pincer x6
      {itemId = 19101, count = 4},  -- Earth Beetle Shell x4
    },
  },
  {
    profId = 1,
    name = "Ladybug Glove",
    tier = 1,
    resultItemId = 19106,
    resultCount = 1,
    cost = 400,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 12}, -- Linen x12
      {itemId = 19107, count = 8},  -- Ladybug Antenna x8
      {itemId = 19101, count = 5},  -- Earth Beetle Shell x5
    },
  },
  {
    profId = 1,
    name = "Beast Gloves",
    tier = 1,
    resultItemId = 19108,
    resultCount = 1,
    cost = 550,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 10}, -- Linen x10
      {itemId = 19109, count = 6},  -- Bear Fur x6
      {itemId = 19111, count = 4},  -- Strong Web x4
    },
  },
  {
    profId = 1,
    name = "Woven Gloves",
    tier = 1,
    resultItemId = 19110,
    resultCount = 1,
    cost = 750,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 10}, -- Linen x10
      {itemId = 19111, count = 6},  -- Strong Web x6
      {itemId = 19109, count = 4},  -- Bear Fur x4
    },
  },
  {
    profId = 1,
    name = "Queen's Gloves",
    tier = 1,
    resultItemId = 19112,
    resultCount = 1,
    cost = 1000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 15}, -- Linen x15
      {itemId = 19113, count = 8},  -- Mud Bee Wings x8
      {itemId = 19111, count = 6},  -- Strong Web x6
      {itemId = 19109, count = 4},  -- Bear Fur x4
    },
  },
  {
    profId = 1,
    name = "Web Gloves",
    tier = 2,
    resultItemId = 19114,
    resultCount = 1,
    cost = 1500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 25}, -- Linen x25
      {itemId = 19115, count = 15}, -- Old Web x15
      {itemId = 19111, count = 10}, -- Strong Web x10
      {itemId = 19109, count = 8},  -- Bear Fur x8
    },
  },
  {
    profId = 1,
    name = "Mud Gloves",
    tier = 2,
    resultItemId = 19116,
    resultCount = 1,
    cost = 2000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 20}, -- Linen x20
      {itemId = 19117, count = 12}, -- Flask of Mud x12
      {itemId = 19111, count = 8},  -- Strong Web x8
      {itemId = 19101, count = 6},  -- Earth Beetle Shell x6
    },
  },
  {
    profId = 1,
    name = "Gleaming Gloves",
    tier = 2,
    resultItemId = 19118,
    resultCount = 1,
    cost = 3000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 25}, -- Linen x25
      {itemId = 19119, count = 15}, -- Flask of Light x15
      {itemId = 19107, count = 10}, -- Ladybug Antenna x10
      {itemId = 19111, count = 8},  -- Strong Web x8
    },
  },
  {
    profId = 1,
    name = "Royal Gloves",
    tier = 2,
    resultItemId = 19120,
    resultCount = 1,
    cost = 4500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 30}, -- Linen x30
      {itemId = 19121, count = 18}, -- Lion Mane x18
      {itemId = 19109, count = 12}, -- Bear Fur x12
      {itemId = 19111, count = 10}, -- Strong Web x10
      {itemId = 19107, count = 6},  -- Ladybug Antenna x6
    },
  },
  {
    profId = 1,
    name = "Metallic Gloves",
    tier = 3,
    resultItemId = 19122,
    resultCount = 1,
    cost = 6000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 35}, -- Linen x35
      {itemId = 19123, count = 20}, -- Metallic Sin x20
      {itemId = 19111, count = 15}, -- Strong Web x15
      {itemId = 19117, count = 10}, -- Flask of Mud x10
      {itemId = 19101, count = 8},  -- Earth Beetle Shell x8
    },
  },
  {
    profId = 1,
    name = "Slimy Gloves",
    tier = 3,
    resultItemId = 19124,
    resultCount = 1,
    cost = 8500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 40}, -- Linen x40
      {itemId = 19125, count = 22}, -- Snail Liquid Flask x22
      {itemId = 19111, count = 15}, -- Strong Web x15
      {itemId = 19107, count = 10}, -- Ladybug Antenna x10
      {itemId = 19109, count = 8},  -- Bear Fur x8
    },
  },
  {
    profId = 1,
    name = "Grey Leather Gloves",
    tier = 3,
    resultItemId = 19126,
    resultCount = 1,
    cost = 12000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 40}, -- Linen x40
      {itemId = 19127, count = 22}, -- Elephant Leather x22
      {itemId = 19109, count = 15}, -- Bear Fur x15
      {itemId = 19111, count = 12}, -- Strong Web x12
      {itemId = 19113, count = 8},  -- Mud Bee Wings x8
    },
  },
  {
    profId = 1,
    name = "Earth Gloves",
    tier = 3,
    resultItemId = 19128,
    resultCount = 1,
    cost = 17000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 40}, -- Linen x40
      {itemId = 19129, count = 22}, -- Woodpecker Beak x22
      {itemId = 19111, count = 15}, -- Strong Web x15
      {itemId = 19101, count = 10}, -- Earth Beetle Shell x10
      {itemId = 19117, count = 8},  -- Flask of Mud x8
    },
  },
  {
    profId = 1,
    name = "Nature Gloves",
    tier = 3,
    resultItemId = 19130,
    resultCount = 1,
    cost = 24000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 45}, -- Linen x45
      {itemId = 19131, count = 25}, -- Cricket Leg x25
      {itemId = 19111, count = 18}, -- Strong Web x18
      {itemId = 19109, count = 12}, -- Bear Fur x12
      {itemId = 19113, count = 10}, -- Mud Bee Wings x10
    },
  },
  {
    profId = 1,
    name = "Butcher Gloves",
    tier = 3,
    resultItemId = 19132,
    resultCount = 1,
    cost = 33000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 50}, -- Linen x50
      {itemId = 19133, count = 28}, -- Vulture Bee Stinger x28
      {itemId = 19111, count = 20}, -- Strong Web x20
      {itemId = 19109, count = 15}, -- Bear Fur x15
      {itemId = 19119, count = 10}, -- Flask of Light x10
    },
  },
  {
    profId = 1,
    name = "Tough Gloves",
    tier = 4,
    resultItemId = 19134,
    resultCount = 1,
    cost = 47000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 55}, -- Linen x55
      {itemId = 19135, count = 30}, -- Mordecasca Pebbles x30
      {itemId = 19111, count = 22}, -- Strong Web x22
      {itemId = 19101, count = 15}, -- Earth Beetle Shell x15
      {itemId = 19109, count = 12}, -- Bear Fur x12
    },
  },
  {
    profId = 1,
    name = "Rebellion Gloves",
    tier = 4,
    resultItemId = 19136,
    resultCount = 1,
    cost = 66000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 65}, -- Linen x65
      {itemId = 19137, count = 35}, -- Sombre Cloth x35
      {itemId = 19111, count = 25}, -- Strong Web x25
      {itemId = 19109, count = 18}, -- Bear Fur x18
      {itemId = 19113, count = 12}, -- Mud Bee Wings x12
      {itemId = 19117, count = 8},  -- Flask of Mud x8
    },
  },
  {
    profId = 1,
    name = "Courage Gloves",
    tier = 4,
    resultItemId = 19140,
    resultCount = 1,
    cost = 93000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 80}, -- Linen x80
      {itemId = 19141, count = 42}, -- Jaguar Skin x42
      {itemId = 19111, count = 30}, -- Strong Web x30
      {itemId = 19101, count = 20}, -- Earth Beetle Shell x20
      {itemId = 19107, count = 15}, -- Ladybug Antenna x15
      {itemId = 19109, count = 10}, -- Bear Fur x10
    },
  },
  {
    profId = 1,
    name = "Marine Gloves",
    tier = 4,
    resultItemId = 19138,
    resultCount = 1,
    cost = 130000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 80}, -- Linen x80
      {itemId = 19139, count = 42}, -- Marine Scales x42
      {itemId = 19111, count = 30}, -- Strong Web x30
      {itemId = 19109, count = 20}, -- Bear Fur x20
      {itemId = 19119, count = 15}, -- Flask of Light x15
      {itemId = 19121, count = 10}, -- Lion Mane x10
    },
  },
  {
    profId = 1,
    name = "Hermit's Gloves",
    tier = 4,
    resultItemId = 19142,
    resultCount = 1,
    cost = 184000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 90}, -- Linen x90
      {itemId = 19143, count = 48}, -- Hermit's Shell x48
      {itemId = 19111, count = 35}, -- Strong Web x35
      {itemId = 19109, count = 22}, -- Bear Fur x22
      {itemId = 19113, count = 18}, -- Mud Bee Wings x18
      {itemId = 19117, count = 12}, -- Flask of Mud x12
    },
  },
  {
    profId = 1,
    name = "Knowledge Gloves",
    tier = 4,
    resultItemId = 19144,
    resultCount = 1,
    cost = 258000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 90}, -- Linen x90
      {itemId = 19145, count = 48}, -- Strange Pages x48
      {itemId = 19111, count = 35}, -- Strong Web x35
      {itemId = 19101, count = 22}, -- Earth Beetle Shell x22
      {itemId = 19109, count = 18}, -- Bear Fur x18
      {itemId = 19119, count = 12}, -- Flask of Light x12
    },
  },
  {
    profId = 1,
    name = "Dark Fold Gloves",
    tier = 5,
    resultItemId = 19146,
    resultCount = 1,
    cost = 363000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 100}, -- Linen x100
      {itemId = 19147, count = 55},  -- Black Paw x55
      {itemId = 19111, count = 40},  -- Strong Web x40
      {itemId = 19109, count = 25},  -- Bear Fur x25
      {itemId = 19117, count = 20},  -- Flask of Mud x20
      {itemId = 19121, count = 15},  -- Lion Mane x15
    },
  },
  {
    profId = 1,
    name = "Desert Gloves",
    tier = 5,
    resultItemId = 19148,
    resultCount = 1,
    cost = 511000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 120}, -- Linen x120
      {itemId = 19149, count = 65},  -- Desert Stones x65
      {itemId = 19111, count = 50},  -- Strong Web x50
      {itemId = 19109, count = 30},  -- Bear Fur x30
      {itemId = 19119, count = 22},  -- Flask of Light x22
      {itemId = 19127, count = 18},  -- Elephant Leather x18
      {itemId = 19129, count = 12},  -- Woodpecker Beak x12
    },
  },
  {
    profId = 1,
    name = "Boulder Gloves",
    tier = 5,
    resultItemId = 19150,
    resultCount = 1,
    cost = 718000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 120}, -- Linen x120
      {itemId = 19151, count = 65},  -- Odd Mineral x65
      {itemId = 19111, count = 50},  -- Strong Web x50
      {itemId = 19109, count = 30},  -- Bear Fur x30
      {itemId = 19107, count = 22},  -- Ladybug Antenna x22
      {itemId = 19113, count = 18},  -- Mud Bee Wings x18
      {itemId = 19117, count = 12},  -- Flask of Mud x12
    },
  },
  {
    profId = 1,
    name = "Lost Knowledge Gloves",
    tier = 5,
    resultItemId = 19152,
    resultCount = 1,
    cost = 1000000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 130}, -- Linen x130
      {itemId = 19153, count = 70},  -- Giant Pages x70
      {itemId = 19111, count = 55},  -- Strong Web x55
      {itemId = 19101, count = 35},  -- Earth Beetle Shell x35
      {itemId = 19109, count = 25},  -- Bear Fur x25
      {itemId = 19119, count = 20},  -- Flask of Light x20
      {itemId = 19121, count = 15},  -- Lion Mane x15
      {itemId = 19123, count = 10},  -- Metallic Sin x10
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
    return {success = false, message = "Invalid recipe."}
  end

  amount = tonumber(amount) or 1
  if amount < 1 or amount > 100 then
    return {success = false, message = "Invalid amount."}
  end

  if not isRecipeUnlocked(cid, recipe) then
    return {success = false, message = "Recipe not unlocked."}
  end

  local maxCraft = getMaxCraftAmount(cid, recipe)
  if maxCraft <= 0 then
    return {success = false, message = "Insufficient materials."}
  end

  if amount > maxCraft then
    amount = maxCraft
  end

  local totalCost = recipe.cost * amount
  if getPlayerMoney(cid) < totalCost then
    return {success = false, message = "Not enough gold. Required: " .. totalCost}
  end

  -- REMOVER materiais
  for _, ingr in ipairs(recipe.ingredients) do
    local totalNeeded = ingr.count * amount
    if not doPlayerRemoveItem(cid, ingr.itemId, totalNeeded) then
      return {success = false, message = "Failed to remove material: " .. ingr.itemId}
    end
  end

  -- REMOVER gold
  if not doPlayerRemoveMoney(cid, totalCost) then
    for _, ingr in ipairs(recipe.ingredients) do
      doPlayerAddItem(cid, ingr.itemId, ingr.count * amount)
    end
    return {success = false, message = "Failed to charge gold."}
  end

  -- CRIAR item resultado
  local totalResult = recipe.resultCount * amount
  local item = doCreateItemEx(recipe.resultItemId, totalResult)
  if item and doPlayerAddItemEx(cid, item) ~= RETURNVALUE_NOERROR then
    doPlayerAddMoney(cid, totalCost)
    for _, ingr in ipairs(recipe.ingredients) do
      doPlayerAddItem(cid, ingr.itemId, ingr.count * amount)
    end
    return {success = false, message = "Inventory full. Items returned."}
  end

  return {
    success = true,
    message = "You created " .. totalResult .. "x " .. recipe.name .. "!",
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
  -- Todos os campos estao presentes para compatibilidade com game_crafting.
  local recipes = {}
  local globalIdx = 0
  for i, recipe in ipairs(RECIPES) do
    globalIdx = globalIdx + 1
    if recipe.profId == profId then
      -- Gera descricao estilo "look" do item (usando getItemInfo)
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
        globalId = globalIdx,
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

  print("[CraftingSystem] Sending JSON to cid=" .. cid .. " size=" .. #json_data .. " recipes=" .. #recipes)

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
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Invalid craft request.")
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
