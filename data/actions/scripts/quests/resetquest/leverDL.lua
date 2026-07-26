dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

local isOpen = {
    [3485] = false,
    [3486] = false
}

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if not isOpen[item.actionid] then
        local stonePos = leverDL.poses[item.actionid]
        removeTileItemByIds(stonePos, {leverDL.stoneID}, 3)
        isOpen[item.actionid] = true
        doTransformLever(item)
        sendBlueMessage(cid, getLangString(cid, "You have removed one Protect Stone.", "Você removeu uma Protect Stone."))
    else
        doPlayerSendCancel(cid, getLangString(cid, "This Protect Stone is already broken.", "Essa Protect Stone já está quebrada."))
    end

    return true
end