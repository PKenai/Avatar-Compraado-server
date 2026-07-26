local depotIds = {1618, 1645, 1620, 1643, 2589, 2590, 2591, 2592}
function onMoveItem(cid, item, fromPosition, toPosition, fromItem, toItem, fromGround, toGround, status)
	if item.itemid == 9775 or castleWar.isOnCastle(cid) then 
		return false
	end 
	if getDistanceBetween(getCreaturePosition(cid), toPosition) > 1 then
		for i = 1, #depotIds do
			if getTileItemById(toPosition, depotIds[i]).uid > 0 then
				doPlayerSendCancel(cid, "You need to get closer to throw an item in this tile.")
				return false
			end
		end
	end
	return true
end 