function copyItem(item)
    if (isContainer(item.uid) == TRUE) then
        return copyContainer(item.uid, item.itemid)
    else
        return doCreateItemEx(item.itemid, getCharges(item.uid))
    end
end

function copyContainer(uid, itemid)
    local container = doCreateItemEx(itemid, 1)
    local iterator = getContainerSize(uid)
    while iterator >= 0  do
        doAddContainerItemEx(container, copyItem(getContainerItem(uid, iterator)))
        iterator = iterator - 1
    end
    return container
end

function doAddContainerItemsFromContainer(containerFrom, containerTo)
	doAddContainerItem(containerTo.uid, 1988)
	containerTo = getContainerItem(containerTo.uid, 0)
	local size = getContainerSize(containerFrom.uid)
	if size >= 0 then 
		for i = 0, size-1 do 
			--doAddContainerItemEx(containerTo.uid, getContainerItem(containerFrom.uid, i).uid)
			local item = getContainerItem(containerFrom.uid, (size-1)-i)
			doAddContainerItem(containerTo.uid, item.itemid, item.type)
			if type(item.type) == "number" and item.type >= 2 then 
				doRemoveItem(item.uid, item.type)
			else
				doRemoveItem(item.uid)
			end 
		end 
	end 

end 


function onDeath(cid, corpse, deathList)
  if restoreAppaOutfit then
    restoreAppaOutfit(cid)
  end
  --local expLoss, hasBless = getLostExp(cid), false
--	 doAddContainerItemEx(corpse, copyItem(getPlayerSlotItem(cid, CONST_SLOT_RING)))
-- doAddContainerItemsFromContainer(getPlayerSlotItem(cid, CONST_SLOT_RING), corpse)
if getPlayerLevel(cid) < 50 then 
	setPlayerStorageValue(cid, "morreuD", 1)
end
  if getPlayerStorageValue(cid, "hasActiveInQuest") ~= 1 then
    if getPlayerStorageValue(cid, "playerWithBless") == 1 or getPlayerLevel(cid) < 50 then
	  if getPlayerStorageValue(cid, "playerWithBless") == 1 then 
			setPlayerStorageValue(cid, "blessExp", 1)
	  end 
	    setPlayerStorageValue(cid, "playerWithBless", -1)
	  doPlayerSetLossPercent(cid, PLAYERLOSS_CONTAINERS, 0)
	elseif getPlayerSlotItem(cid, 2).itemid == 13851 then 
		doPlayerSetLossPercent(cid, PLAYERLOSS_CONTAINERS, 0)
	elseif getPlayerSlotItem(cid, 2).itemid == 2173 then 
		doRemoveItem(getPlayerSlotItem(cid, 2).uid)
    end

    setPlayerStorageValue(cid, "expBeforeDie", getPlayerExperience(cid))
  end
  
  return true
end
