-- ============================================================================
-- Peixes (crus e assados) - comer aplica o bonus do peixe.
-- ----------------------------------------------------------------------------
-- Um unico script cuida dos 36 itens (19398-19415 crus / 19417-19434 assados).
-- Os dados (bonus, comida, duracao) vem de data/lib/fishSystem.lua.
-- ============================================================================

local MAX_FOOD = 1200

function onUse(cid, item, fromPosition, itemEx, toPosition)
  if type(FishSystem) ~= "table" then
    dofile(getDataDir() .. "lib/fishSystem.lua")
  end

  local fish, cooked = FishSystem.get(item.itemid)
  if not fish then
    return false
  end

  -- Barriga cheia? Nao vale a pena (nem desperdica) o peixe bom.
  if getPlayerFood(cid) + fish.food > MAX_FOOD then
    doPlayerSendCancel(cid, "You are full.")
    return true
  end

  doPlayerFeed(cid, fish.food)
  FishSystem.applyBonus(cid, fish, cooked)

  doRemoveItem(item.uid, 1)

  doCreatureSay(cid, cooked and "Delicious!" or "Munch.", TALKTYPE_MONSTER)

  local minutes = math.floor((fish.duration or 120) / 60)
  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
    (cooked and "Roasted: " or "") .. fish.name ..
    " - bonus active for " .. minutes .. " min.")

  return true
end
