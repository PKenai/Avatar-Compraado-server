dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if itemEx.actionid == bossFinal.statueActionId then
        doRemoveItem(item.uid, 1)
        doRemoveItem(itemEx.uid, 1)
        doSendMagicEffect(toPosition, 6)
        
        doCreateMonster(bossFinal.name, toPosition, nil, true)
        return true
    end

    return false
end