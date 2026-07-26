dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if itemEx.actionid == 251 and itemEx.uid == warlockRoom.uniqueIdDoor then
        doRemoveItem(itemEx.uid)
        doCreateItem(warlockRoom.newDoorId, 1, toPosition)
        return true
    end

    return false
end