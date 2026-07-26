function onUse(cid, item, fromPosition, itemEx, toPosition)
  if itemEx.actionid == 62124 and item.itemid == 4856 and isInArray({354, 355}, itemEx.itemid) then
    doTransformItem(itemEx.uid, 392)
    doDecayItem(itemEx.uid)
    doSendMagicEffect(toPosition, CONST_ME_POFF)
    return true
  end
  return true
end