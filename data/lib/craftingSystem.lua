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
  -- ==================== BLACKSMITH - LUVAS (profId = 1) ====================
  {
    profId = 1,
    name = "Luva simples",
    tier = 1,
    resultItemId = 19098,
    resultCount = 1,
    cost = 100,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 3},  -- Linho x3
    },
  },
  {
    profId = 1,
    name = "Luva pegajosa",
    tier = 1,
    resultItemId = 19100,
    resultCount = 1,
    cost = 150,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 5},  -- Linho x5
      {itemId = 19101, count = 3},  -- Casca de besouro x3
    },
  },
  {
    profId = 1,
    name = "Luva funebre",
    tier = 1,
    resultItemId = 19102,
    resultCount = 1,
    cost = 200,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 8},  -- Linho x8
      {itemId = 19103, count = 5},  -- Cabeca de verme x5
      {itemId = 19101, count = 3},  -- Casca de besouro x3
    },
  },
  {
    profId = 1,
    name = "Luva pinca vermelha",
    tier = 1,
    resultItemId = 19104,
    resultCount = 1,
    cost = 300,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 10}, -- Linho x10
      {itemId = 19105, count = 6},  -- Pinca de carangueijo x6
      {itemId = 19101, count = 4},  -- Casca de besouro x4
    },
  },
  {
    profId = 1,
    name = "Luva de joaninha",
    tier = 1,
    resultItemId = 19106,
    resultCount = 1,
    cost = 400,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 12}, -- Linho x12
      {itemId = 19107, count = 8},  -- Antena de joaninha x8
      {itemId = 19101, count = 5},  -- Casca de besouro x5
    },
  },
  {
    profId = 1,
    name = "Luvas da fera",
    tier = 1,
    resultItemId = 19108,
    resultCount = 1,
    cost = 550,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 10}, -- Linho x10
      {itemId = 19109, count = 6},  -- Pelo de urso x6
      {itemId = 19111, count = 4},  -- Teia forte x4
    },
  },
  {
    profId = 1,
    name = "Luvas tecidas",
    tier = 1,
    resultItemId = 19110,
    resultCount = 1,
    cost = 750,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 10}, -- Linho x10
      {itemId = 19111, count = 6},  -- Teia forte x6
      {itemId = 19109, count = 4},  -- Pelo de urso x4
    },
  },
  {
    profId = 1,
    name = "Luvas da rainha",
    tier = 1,
    resultItemId = 19112,
    resultCount = 1,
    cost = 1000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 15}, -- Linho x15
      {itemId = 19113, count = 8},  -- Asas de abelha x8
      {itemId = 19111, count = 6},  -- Teia forte x6
      {itemId = 19109, count = 4},  -- Pelo de urso x4
    },
  },
  {
    profId = 1,
    name = "Luvas de teia",
    tier = 2,
    resultItemId = 19114,
    resultCount = 1,
    cost = 1500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 25}, -- Linho x25
      {itemId = 19115, count = 15}, -- Teia velha x15
      {itemId = 19111, count = 10}, -- Teia forte x10
      {itemId = 19109, count = 8},  -- Pelo de urso x8
    },
  },
  {
    profId = 1,
    name = "Luvas de barro",
    tier = 2,
    resultItemId = 19116,
    resultCount = 1,
    cost = 2000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 20}, -- Linho x20
      {itemId = 19117, count = 12}, -- Frasco com barro x12
      {itemId = 19111, count = 8},  -- Teia forte x8
      {itemId = 19101, count = 6},  -- Casca de besouro x6
    },
  },
  {
    profId = 1,
    name = "Luvas reluzentes",
    tier = 2,
    resultItemId = 19118,
    resultCount = 1,
    cost = 3000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 25}, -- Linho x25
      {itemId = 19119, count = 15}, -- Frasco de luz x15
      {itemId = 19107, count = 10}, -- Antena de joaninha x10
      {itemId = 19111, count = 8},  -- Teia forte x8
    },
  },
  {
    profId = 1,
    name = "Luvas reais",
    tier = 2,
    resultItemId = 19120,
    resultCount = 1,
    cost = 4500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 30}, -- Linho x30
      {itemId = 19121, count = 18}, -- Juba de leao x18
      {itemId = 19109, count = 12}, -- Pelo de urso x12
      {itemId = 19111, count = 10}, -- Teia forte x10
      {itemId = 19107, count = 6},  -- Antena de joaninha x6
    },
  },
  {
    profId = 1,
    name = "Luvas metalicas",
    tier = 3,
    resultItemId = 19122,
    resultCount = 1,
    cost = 6000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 35}, -- Linho x35
      {itemId = 19123, count = 20}, -- Peca metalica x20
      {itemId = 19111, count = 15}, -- Teia forte x15
      {itemId = 19117, count = 10}, -- Frasco com barro x10
      {itemId = 19101, count = 8},  -- Casca de besouro x8
    },
  },
  {
    profId = 1,
    name = "Luvas gosmentas",
    tier = 3,
    resultItemId = 19124,
    resultCount = 1,
    cost = 8500,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 40}, -- Linho x40
      {itemId = 19125, count = 22}, -- Frasco de caracol x22
      {itemId = 19111, count = 15}, -- Teia forte x15
      {itemId = 19107, count = 10}, -- Antena de joaninha x10
      {itemId = 19109, count = 8},  -- Pelo de urso x8
    },
  },
  {
    profId = 1,
    name = "Luvas de couro cinza",
    tier = 3,
    resultItemId = 19126,
    resultCount = 1,
    cost = 12000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 40}, -- Linho x40
      {itemId = 19127, count = 22}, -- Couro de elefante x22
      {itemId = 19109, count = 15}, -- Pelo de urso x15
      {itemId = 19111, count = 12}, -- Teia forte x12
      {itemId = 19113, count = 8},  -- Asas de abelha x8
    },
  },
  {
    profId = 1,
    name = "Luvas da terra",
    tier = 3,
    resultItemId = 19128,
    resultCount = 1,
    cost = 17000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 40}, -- Linho x40
      {itemId = 19129, count = 22}, -- Bico de pica-pau x22
      {itemId = 19111, count = 15}, -- Teia forte x15
      {itemId = 19101, count = 10}, -- Casca de besouro x10
      {itemId = 19117, count = 8},  -- Frasco com barro x8
    },
  },
  {
    profId = 1,
    name = "Luvas da natureza",
    tier = 3,
    resultItemId = 19130,
    resultCount = 1,
    cost = 24000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 45}, -- Linho x45
      {itemId = 19131, count = 25}, -- Perna de grilo x25
      {itemId = 19111, count = 18}, -- Teia forte x18
      {itemId = 19109, count = 12}, -- Pelo de urso x12
      {itemId = 19113, count = 10}, -- Asas de abelha x10
    },
  },
  {
    profId = 1,
    name = "Luvas carniceiras",
    tier = 3,
    resultItemId = 19132,
    resultCount = 1,
    cost = 33000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 50}, -- Linho x50
      {itemId = 19133, count = 28}, -- Ferrao de abelha urubu x28
      {itemId = 19111, count = 20}, -- Teia forte x20
      {itemId = 19109, count = 15}, -- Pelo de urso x15
      {itemId = 19119, count = 10}, -- Frasco de luz x10
    },
  },
  {
    profId = 1,
    name = "Luvas cascudas",
    tier = 4,
    resultItemId = 19134,
    resultCount = 1,
    cost = 47000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 55}, -- Linho x55
      {itemId = 19135, count = 30}, -- Pedriscos de mordecasca x30
      {itemId = 19111, count = 22}, -- Teia forte x22
      {itemId = 19101, count = 15}, -- Casca de besouro x15
      {itemId = 19109, count = 12}, -- Pelo de urso x12
    },
  },
  {
    profId = 1,
    name = "Luvas da rebeliao",
    tier = 4,
    resultItemId = 19136,
    resultCount = 1,
    cost = 66000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 65}, -- Linho x65
      {itemId = 19137, count = 35}, -- Pano sombrio x35
      {itemId = 19111, count = 25}, -- Teia forte x25
      {itemId = 19109, count = 18}, -- Pelo de urso x18
      {itemId = 19113, count = 12}, -- Asas de abelha x12
      {itemId = 19117, count = 8},  -- Frasco com barro x8
    },
  },
  {
    profId = 1,
    name = "Luvas da coragem",
    tier = 4,
    resultItemId = 19140,
    resultCount = 1,
    cost = 93000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 80}, -- Linho x80
      {itemId = 19141, count = 42}, -- Pele de onca x42
      {itemId = 19111, count = 30}, -- Teia forte x30
      {itemId = 19101, count = 20}, -- Casca de besouro x20
      {itemId = 19107, count = 15}, -- Antena de joaninha x15
      {itemId = 19109, count = 10}, -- Pelo de urso x10
    },
  },
  {
    profId = 1,
    name = "Luvas marinhas",
    tier = 4,
    resultItemId = 19138,
    resultCount = 1,
    cost = 130000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 80}, -- Linho x80
      {itemId = 19139, count = 42}, -- Escamas marinhas x42
      {itemId = 19111, count = 30}, -- Teia forte x30
      {itemId = 19109, count = 20}, -- Pelo de urso x20
      {itemId = 19119, count = 15}, -- Frasco de luz x15
      {itemId = 19121, count = 10}, -- Juba de leao x10
    },
  },
  {
    profId = 1,
    name = "Luvas do hermitao",
    tier = 4,
    resultItemId = 19142,
    resultCount = 1,
    cost = 184000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 90}, -- Linho x90
      {itemId = 19143, count = 48}, -- Concha de hermitao x48
      {itemId = 19111, count = 35}, -- Teia forte x35
      {itemId = 19109, count = 22}, -- Pelo de urso x22
      {itemId = 19113, count = 18}, -- Asas de abelha x18
      {itemId = 19117, count = 12}, -- Frasco com barro x12
    },
  },
  {
    profId = 1,
    name = "Luvas do conhecimento",
    tier = 4,
    resultItemId = 19144,
    resultCount = 1,
    cost = 258000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 90}, -- Linho x90
      {itemId = 19145, count = 48}, -- Paginas estranhas x48
      {itemId = 19111, count = 35}, -- Teia forte x35
      {itemId = 19101, count = 22}, -- Casca de besouro x22
      {itemId = 19109, count = 18}, -- Pelo de urso x18
      {itemId = 19119, count = 12}, -- Frasco de luz x12
    },
  },
  {
    profId = 1,
    name = "Luvas da dobra obscura",
    tier = 5,
    resultItemId = 19146,
    resultCount = 1,
    cost = 363000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 100}, -- Linho x100
      {itemId = 19147, count = 55},  -- Pata negra x55
      {itemId = 19111, count = 40},  -- Teia forte x40
      {itemId = 19109, count = 25},  -- Pelo de urso x25
      {itemId = 19117, count = 20},  -- Frasco com barro x20
      {itemId = 19121, count = 15},  -- Juba de leao x15
    },
  },
  {
    profId = 1,
    name = "Luvas deserticas",
    tier = 5,
    resultItemId = 19148,
    resultCount = 1,
    cost = 511000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 120}, -- Linho x120
      {itemId = 19149, count = 65},  -- Pedras do deserto x65
      {itemId = 19111, count = 50},  -- Teia forte x50
      {itemId = 19109, count = 30},  -- Pelo de urso x30
      {itemId = 19119, count = 22},  -- Frasco de luz x22
      {itemId = 19127, count = 18},  -- Couro de elefante x18
      {itemId = 19129, count = 12},  -- Bico de pica-pau x12
    },
  },
  {
    profId = 1,
    name = "Luvas de pedregulho",
    tier = 5,
    resultItemId = 19150,
    resultCount = 1,
    cost = 718000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 120}, -- Linho x120
      {itemId = 19151, count = 65},  -- Mineral esquisito x65
      {itemId = 19111, count = 50},  -- Teia forte x50
      {itemId = 19109, count = 30},  -- Pelo de urso x30
      {itemId = 19107, count = 22},  -- Antena de joaninha x22
      {itemId = 19113, count = 18},  -- Asas de abelha x18
      {itemId = 19117, count = 12},  -- Frasco com barro x12
    },
  },
  {
    profId = 1,
    name = "Luvas do conhecimento perdido",
    tier = 5,
    resultItemId = 19152,
    resultCount = 1,
    cost = 1000000,
    requiredSkill = 1,
    storageRequirement = 0,
    ingredients = {
      {itemId = 19099, count = 130}, -- Linho x130
      {itemId = 19153, count = 70},  -- Paginas gigantes x70
      {itemId = 19111, count = 55},  -- Teia forte x55
      {itemId = 19101, count = 35},  -- Casca de besouro x35
      {itemId = 19109, count = 25},  -- Pelo de urso x25
      {itemId = 19119, count = 20},  -- Frasco de luz x20
      {itemId = 19121, count = 15},  -- Juba de leao x15
      {itemId = 19123, count = 10},  -- Peca metalica x10
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

  print("[CraftingSystem] Enviando JSON para cid=" .. cid .. " tamanho=" .. #json_data .. " recipes=" .. #recipes)

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
