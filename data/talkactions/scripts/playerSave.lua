function onSay(cid)
	if getPlayerStorageValue(cid, "storage_save") < os.time() then
		return doPlayerSendCancel(cid, "Você não pode usar esse comando ainda")
	else
		setPlayerStorageValue(cid, "storage_save", os.time() + 1000 * 60)
		return doSavePlayer(cid)
	end
end