local enterPos = {x=377,y=686,z=7}

function onUse(cid, item, fromPosition, itemEx, toPosition)
  --if isPremium(cid) then
    doTeleportCreature(cid, enterPos, 10)
    --return true
  --else
    --sendBlueMessage(cid, getLangString(cid, WITHOUTPREMIUM, WITHOUTPREMIUMBR))
  --end

  return true
end