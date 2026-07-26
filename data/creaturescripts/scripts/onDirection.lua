function onDirection(cid, old, current)
  if getCreatureNoMove(cid) then
    if getPlayerStorageValue(cid, "playerCanMoveDirection") < os.time() then
      return false
    end
  end
  return true
end