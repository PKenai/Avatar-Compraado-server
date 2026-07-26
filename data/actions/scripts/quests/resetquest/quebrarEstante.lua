dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if itemEx.actionid == 3509 then
        doRemoveItem(itemEx.uid)
        doSendMagicEffect(toPosition, 2)
        doCreateItem(2253, 1, toPosition)
        return true
    end

    return false
end