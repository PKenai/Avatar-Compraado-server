dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    doTeleportCreature(cid, elementalRoom.positionBorn, 10)
    return true
end