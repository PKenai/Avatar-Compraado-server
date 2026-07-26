local MyLocal = {}
MyLocal.enterPos = {x=532,y=539,z=4}


function onUse(cid, item, fromPosition, itemEx, toPosition)
--  if isPremium(cid) then
    doTeleportCreature(cid, MyLocal.enterPos, 10)
--    return true
--  else
--    sendBlueMessage(cid, getLangString(cid, WITHOUTPREMIUM, WITHOUTPREMIUMBR))
--  end

  return false
end
