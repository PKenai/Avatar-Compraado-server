local teleports = {
  [2772] = {x=582,y=965,z=9},
  [2773] = {x=404,y=400,z=3}
}


function onUse(cid, item, fromPosition, itemEx, toPosition)
  doTeleportCreature(cid, teleports[item.actionid], 10)
  return true
end
