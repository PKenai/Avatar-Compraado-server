function canPlayerMoveItens(cid)
    if getPlayerStorageValue(cid, "hasActiveInQuest") == 1 then
        if getPlayerStorageValue(cid, "playerCanMoveItemsGenericQuest") == 1 then
            return false
        end
    end
  
  return true
end