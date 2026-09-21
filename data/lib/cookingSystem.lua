-- ============================================================================
-- COOKING SYSTEM - 100% Server-Side (opcode 107)
-- ----------------------------------------------------------------------------
-- Clicar na cooking table (19219/19220) abre a janela de receitas; cada
-- receita transforma 1 peixe cru no peixe ASSADO correspondente (bonus +10%
-- e o shader "gostoso" no client).
--
-- COMO FUNCIONA A PROGRESSAO:
--   * cozinhar exige nivel de Cooking (cookLvl) - os peixes grandes ficam
--     travados ate' a pessoa subir a skill;
--   * cada acerto da' XP de Cooking (cookXp do peixe). A skill vive em
--     storages (data/lib/fishSystem.lua) e o client mostra na skillBar;
--   * errar a mexida queima o peixe (perde o ingrediente).
--
-- Pescaria e cozinha sao duas carreiras longas: da' pra fazer as duas, mas
-- chegar no ultimo assado leva um tempinho - a ideia e' escolher uma.
--
-- Os dados (quais peixes, XP, mexidas) ficam em data/lib/fishSystem.lua.
-- ============================================================================

CookingSystem = CookingSystem or {}

if type(json) ~= "table" then
  dofile(getDataDir() .. "lib/json.lua")
end

if type(FishSystem) ~= "table" then
  dofile(getDataDir() .. "lib/fishSystem.lua")
end

local COOKING_OPCODE = 107

-- Storages do minigame (a skill de Cooking fica no fishSystem).
local STORAGE_ACTIVE      = 47020  -- 1 = cozinhando agora (minigame aberto)
local STORAGE_RECIPE      = 47021  -- receita em andamento (indice do peixe)
local STORAGE_ATTEMPTS    = 47022  -- quantas mexidas certas ate agora
local STORAGE_CAULDRON_X  = 47023  -- posicao do caldeirao (efeitos)
local STORAGE_CAULDRON_Y  = 47024
local STORAGE_CAULDRON_Z  = 47025
local STORAGE_REPEAT      = 47026  -- 1 = "Cook All" (repete enquanto tiver peixe)

-- Itens do sistema
local PAN_ID        = 2563   -- frigideira (icone do minigame no client)
local CAULDRON_ID   = 1483   -- caldeirao (alvo do clique)

-- Efeitos
local EFFECT_STIR   = CONST_ME_SMOKE      -- fumaquinha a cada mexida certa
local EFFECT_FIRE   = CONST_ME_FIREAREA   -- fogo no caldeirao enquanto cozinha
local EFFECT_FAIL   = CONST_ME_POFF       -- queimou
local EFFECT_OK     = CONST_ME_MAGIC_GREEN

-- ============================================================================
-- HELPERS
-- ============================================================================

local function limparEstado(cid)
  setPlayerStorageValue(cid, STORAGE_ACTIVE, -1)
  setPlayerStorageValue(cid, STORAGE_RECIPE, -1)
  setPlayerStorageValue(cid, STORAGE_ATTEMPTS, -1)
  setPlayerStorageValue(cid, STORAGE_REPEAT, -1)
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

-- Texto do bonus pro tooltip/descricao da receita.
local function describeBonus(fish)
  local b = fish.bonus or {}
  local parts = {}
  if b.hp then table.insert(parts, "+" .. b.hp .. " HP max") end
  if b.mana then table.insert(parts, "+" .. b.mana .. " Mana max") end
  if b.magic then table.insert(parts, "+" .. b.magic .. " Bending") end
  if b.shield then table.insert(parts, "+" .. b.shield .. " Shielding") end
  if b.speed then table.insert(parts, "+" .. b.speed .. " Speed") end
  if b.hpRegen then table.insert(parts, "+" .. b.hpRegen .. " HP regen") end
  if b.manaRegen then table.insert(parts, "+" .. b.manaRegen .. " Mana regen") end
  if #parts == 0 then return "No bonus" end
  return table.concat(parts, ", ")
end

-- Nome do prato assado: mesmo prefixo que o fishSystem usa na barra de buffs e
-- que o items.xml usa nos itens ("Roasted X").
local function cookedName(fish)
  return "Roasted " .. fish.name
end

-- ============================================================================
-- JANELA DE RECEITAS
-- ============================================================================

function CookingSystem.openWindow(cid, cauldronPos)
  if cauldronPos and cauldronPos.x > 0 then
    setPlayerStorageValue(cid, STORAGE_CAULDRON_X, cauldronPos.x)
    setPlayerStorageValue(cid, STORAGE_CAULDRON_Y, cauldronPos.y)
    setPlayerStorageValue(cid, STORAGE_CAULDRON_Z, cauldronPos.z)
  end

  local cookLevel = FishSystem.getCookingLevel(cid)
  local recipes = {}

  for i, fish in ipairs(FishSystem.LIST) do
    local r = {
      globalId = i,
      spriteId = toClientId(fish.cooked),
      count = 1,
      name = cookedName(fish),
      tier = fish.tier,
      desc = "Bonus: " .. describeBonus(fish) .. " (+10% roasted)",
      cost = 0,
      requiredSkill = fish.cookLvl,
      locked = cookLevel < fish.cookLvl,
      storagevalue = 0,
      ingredients = {},
    }

    table.insert(r.ingredients, {
      name = fish.name,
      spriteId = toClientId(fish.id),
      count = 1,
      playerCount = getPlayerItemCount(cid, fish.id) or 0,
    })

    table.insert(recipes, r)
  end

  enviar(cid, {
    action = "open",
    skill = {
      level = cookLevel,
      percentage = FishSystem.getCookingPercent(cid),
      xp = FishSystem.getCookingXp(cid),
      xpNext = FishSystem.xpForLevel(cookLevel + 1),
    },
    recipes = recipes,
  })
end

-- ============================================================================
-- COMECAR A COZINHAR (client clicou em "Cook")
-- ============================================================================

local function handleCraft(cid, dados)
  if getPlayerStorageValue(cid, STORAGE_ACTIVE) == 1 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, "You are already cooking.")
    return true
  end

  local index = tonumber(dados.recipeId)
  local fish = index and FishSystem.LIST[index]
  if not fish then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Invalid recipe.")
    return true
  end

  -- Travada por nivel de Cooking?
  local cookLevel = FishSystem.getCookingLevel(cid)
  if cookLevel < fish.cookLvl then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
      "You need Cooking " .. fish.cookLvl .. " to roast " .. fish.name .. ".")
    return true
  end

  if getPlayerItemCount(cid, fish.id) < 1 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
      "You don't have " .. fish.name .. " to cook.")
    return true
  end

  if not doPlayerRemoveItem(cid, fish.id, 1) then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Error removing ingredient.")
    return true
  end

  -- Estado do minigame
  setPlayerStorageValue(cid, STORAGE_ACTIVE, 1)
  setPlayerStorageValue(cid, STORAGE_RECIPE, index)
  setPlayerStorageValue(cid, STORAGE_ATTEMPTS, 0)
  -- "Cook All" (repeatAll): o servidor lembra e emenda a proxima receita.
  -- (a chave NAO pode se chamar "repeat": 'repeat' e' palavra reservada do
  -- Lua e "dados.repeat" nem compila.)
  setPlayerStorageValue(cid, STORAGE_REPEAT, dados.repeatAll and 1 or -1)

  local cauldronPos = posicaoCaldeirao(cid)
  if cauldronPos then
    doSendMagicEffect(cauldronPos, EFFECT_FIRE)
  end

  enviar(cid, {
    action = "minigame",
    ticks = fish.stirs,
    remaining = fish.stirs,
    toolId = toClientId(PAN_ID),
  })

  return true
end

-- ============================================================================
-- MEXIDA (client mandou o resultado de uma tentativa)
-- ============================================================================

local function handleStir(cid, acertou)
  if getPlayerStorageValue(cid, STORAGE_ACTIVE) ~= 1 then
    return true  -- pacote atrasado ou forjado
  end

  local index = tonumber(getPlayerStorageValue(cid, STORAGE_RECIPE))
  local fish = index and FishSystem.LIST[index]
  if not fish then
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
  if attempts < fish.stirs then
    enviar(cid, {
      action = "stir_result",
      remaining = fish.stirs - attempts,
    })
    return true
  end

  -- Acertos suficientes: comida pronta!
  -- "Cook All": em vez de fechar o estado agora, a gente emenda a proxima
  -- receita no fim (ver o bloco repeatCook).
  local repeatCook = getPlayerStorageValue(cid, STORAGE_REPEAT) == 1

  local item = doCreateItemEx(fish.cooked, 1)
  if item and doPlayerAddItemEx(cid, item) ~= RETURNVALUE_NOERROR then
    limparEstado(cid)
    doSendMagicEffect(getCreaturePosition(cid), EFFECT_FAIL)
    enviar(cid, {
      action = "result",
      success = false,
      message = "You have no room for the food.",
    })
    return true
  end

  -- XP de Cooking (+ aviso de level up).
  local levels = FishSystem.addCookingXp(cid, fish.cookXp)
  local after = FishSystem.getCookingLevel(cid)

  if cauldronPos then
    doSendMagicEffect(cauldronPos, EFFECT_FIRE)
  end
  doSendMagicEffect(getCreaturePosition(cid), EFFECT_OK)

  local msg = "You cooked a " .. cookedName(fish) .. "! (+" .. fish.cookXp .. " Cooking XP)"
  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, msg)

  if levels > 0 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Your Cooking skill advanced to " .. after .. ".")
  end

  -- Atualiza a skillBar do client.
  FishSystem.sendCookingSkill(cid)

  -- Cook All: continua so' se o nivel ainda permite e sobrou peixe cru. O
  -- estado fica ATIVO (mesma receita) e o client reabre a mexida sozinho.
  if repeatCook and after >= fish.cookLvl and getPlayerItemCount(cid, fish.id) >= 1 then
    if doPlayerRemoveItem(cid, fish.id, 1) then
      setPlayerStorageValue(cid, STORAGE_ATTEMPTS, 0)
      enviar(cid, {
        action = "minigame",
        ticks = fish.stirs,
        remaining = fish.stirs,
        toolId = toClientId(PAN_ID),
      })
      return true
    end
  end

  limparEstado(cid)
  enviar(cid, {
    action = "result",
    success = true,
    message = msg,
  })

  return true
end

-- ============================================================================
-- HANDLER DE OPCODE (chamado pelo opcode.lua)
-- ============================================================================

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
  elseif action == "skill" then
    -- O client pede a skill ao abrir a HUD/entrar no jogo.
    FishSystem.sendCookingSkill(cid)
    return true
  end

  return false
end

-- Chame no logout (loginLogout/logout.lua): sem isso, deslogar no meio da
-- cozinha deixaria o jogador "cozinhando" pra sempre ao relogar.
function CookingSystem.onLogout(cid)
  limparEstado(cid)
end
