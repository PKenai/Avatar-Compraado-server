function canPlayerMoveItens(cid)
    if getPlayerStorageValue(cid, "hasActiveInQuest") == 1 then
        if getPlayerStorageValue(cid, "playerCanMoveItemsGenericQuest") == 1 then
            return false
        end
    end
  
  return true
end

function canPlayerStartFly(cid)
    if isPlayerPzLocked(cid) or isPlayerBattle(cid) then
        doPlayerSendCancelEf(cid, getLangString(cid, "You can't fly with battle active.", "Você não pode voar com battle ativo."))
        return false
    end

    if getThingPos(cid).z > 7 then
        doPlayerSendCancelEf(cid, getLangString(cid, "You can't fly up there.", "Você não pode voar aqui."))
        return false
    end

  return true
end