function onUse(cid, item, fromPosition, itemEx, toPosition)
  local getPlayerTemple = getPlayerTown(cid)
  if getPlayerTemple == 4 then
    doPlayerSendCancel(cid, "You're already a citizen of North Water Tribe.")
  else
    sendBlueMessage(cid, "Now you're a North Water Tribe citizen.")
	doPlayerSetTown(cid, 4)
  end
  return true
end