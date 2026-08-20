function onStepIn(cid, item, position, fromPosition)
  if not isPlayer(cid) then
    return true
  end
  local newPos = {x=position.x,y=position.y,z=position.z+1}
  doTeleportThing(cid, newPos)
  return true
end