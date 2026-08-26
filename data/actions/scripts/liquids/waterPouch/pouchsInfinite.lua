-- ============================================================
-- USE: Agua milagrosa do oasis (ID 18999)
-- Item infinito de agua - sempre cheio, nunca seca
-- ============================================================

function onUse(cid, item, fromPosition, itemEx, toPosition)
  -- Quando usar na agua: ja esta cheio, so mostra mensagem
  if isAvaliableTileWaterByPos(toPosition) == true or isAvaliableItemWaterById(itemEx.itemid) == true then
    doSendMagicEffect(toPosition, 25)
    sendBlueMessage(cid, getLangString(cid, "Your oasis water is already full!", "Sua agua do oasis ja esta cheia!"))
  else
    doPlayerSendCancel(cid, getLangString(cid, "This water is infinite, it never dries.", "Essa agua e infinita, nunca seca."))
  end
  return true
end
