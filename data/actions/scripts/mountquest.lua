local config = {
effect = 29,
msg = "Você ganhou 20 event tokens.",
item = 6527,
count = 20
}
function onUse(cid, item, fromPosition, itemEx, toPosition)
	if getPlayerStorageValue(cid, "MountQuest") ~= 1 then 
		setPlayerStorageValue(cid, "MountQuest", 1)
		doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, config.msg)
		doSendMagicEffect(getCreaturePosition(cid), config.effect)
		doPlayerAddItem(cid, config.item, config.count)
	  else doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, getLangString(cid, "The chest is empty.", "Esse chest está vazio."))
	end
	return true
end