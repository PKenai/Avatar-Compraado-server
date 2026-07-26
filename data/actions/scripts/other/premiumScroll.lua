local premiumDays = 30

function onUse(cid, item, fromPosition, itemEx, toPosition)
  doPlayerAddPremiumDays(cid, premiumDays)
  sendBlueMessage(cid, getLangString(cid, premiumDays.." Premium Account days have been added to your account.", premiumDays.." dias de Premium Account foram adicionados em sua conta."))
  doSendMagicEffect(getThingPos(cid), 29)
  doRemoveItem(item.uid, 1)
  return true
end
