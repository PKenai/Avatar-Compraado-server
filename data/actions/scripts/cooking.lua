-- ============================================================================
-- Cozinha -- clicar no caldeirao (1483) abre a janela de receitas.
-- ----------------------------------------------------------------------------
-- Fluxo completo do sistema:
--   1. jogador clica no caldeirao             -> este arquivo
--   2. servidor manda {action="open"}          -> client abre a janela de receitas
--   3. jogador clica em "Cook"                 -> client manda {action="craft"}
--   4. servidor cobra o ovo e manda {action="minigame"}
--                                               -> client abre a barra da mexida
--   5. cada espaco acerta a mexida             -> client manda {action="stir"}
--   6. 5 acertos seguidos = comida pronta      -> data/lib/cookingSystem.lua
--
-- Os dois lados conversam pelo extended opcode 107.

if type(json) ~= "table" then
  dofile(getDataDir() .. "lib/json.lua")
end

local PAN_ID      = 2563   -- frigideira (so o icone do minigame no client)
local COOKING_TABLE_IDS = {19219, 19220}   -- cooking tables (alvos do clique)

function onUse(cid, item, fromPosition, itemEx, toPosition)
  -- Clique direto na cooking table (item == 19219/19220). O itemEx tambem e
  -- aceito (frigideira na mesa) por compatibilidade. Devolver false deixa o
  -- clique cair no comportamento padrao do item.
  local itemId = (item and item.itemid) or 0
  local itemExId = (itemEx and itemEx.itemid) or 0
  local alvoMesa = table.find(COOKING_TABLE_IDS, itemId)
    or table.find(COOKING_TABLE_IDS, itemExId)
  if not alvoMesa then
    return false
  end

  if type(CookingSystem) ~= "table" then
    dofile(getDataDir() .. "lib/cookingSystem.lua")
  end

  registerCreatureEvent(cid, "ExtendedOpcode")

  CookingSystem.openWindow(cid, toPosition)
  return true
end