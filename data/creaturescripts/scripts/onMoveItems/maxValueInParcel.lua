local parcelId = 2595
local mailId = 2334
local maxItens = 150
function onMoveItem(cid, item, formPosition, toPosition, fromItem, toItem, fromGround, toGround, status)
  if not canPlayerMoveItens(cid) then
    doPlayerSendCancel(cid, getLangString(cid, "You are unable to move any item now.", "Você está, impossibilitado de mover qualquer item agora."))
    return false
  end

  if getPlayerAccess(cid) == 3 then
    doPlayerSendCancel(cid, getLangString(cid, "You are unable to move any item now.", "Você está, impossibilitado de mover qualquer item agora."))
    return false
  end

  if item.itemid == parcelId then
    local itemInPos = getTileItemById(toPosition, mailId)
    if itemInPos.itemid == mailId then
      if getTotalItensInContainer(item.uid) > maxItens then
        doPlayerSendCancel(cid, getLangString(cid, "Sorry, you cannot send more of "..maxItens.." items in one parcel.", "Desculpe, você não pode enviar mais que "..maxItens.." items em uma parcel."))
        return false
      end
    end
  end
  return true
end