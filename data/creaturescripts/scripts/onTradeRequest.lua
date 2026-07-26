function onTradeRequest(cid, target, item)
  if not isMovable(item.uid) or item.itemid == 9775 then
    doPlayerSendCancel(cid, getLangString(cid, "You cannot trade imovable things.", "Você não pode iniciar trade com coisas imoveis."))
    return false
  end

    if item.itemid == 12325 then --item do reset (nao funfa, feito pela source)
        doPlayerSendCancel(cid, getLangString(cid, "You cannot trade this item.", "Você não pode iniciar trade com esse item."))
        return false
    end

  return true
end