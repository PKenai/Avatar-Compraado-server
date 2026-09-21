function onDirection(cid, old, current)
  if getCreatureNoMove(cid) then
    if (tonumber(getPlayerStorageValue(cid, "playerCanMoveDirection")) or -1) < os.time() then
      return false
    end
  end
  return true
end