dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
    local isOpen = getStorage("resetQuestBauOpen") == 1

    if isOpen and getPlayerStorageValue(cid, "hasCompletedResetQuest") == -1 then
        local lootBag = getItensInContainer(getPlayerSlotItem(cid, CONST_SLOT_RING).uid)

        if #lootBag >= 36 then
            doPlayerSendCancel(cid, getLangString(cid, "You need be a 1 slot free in your loot bag.", "Você precisa de 1 espaço livre na sua loot bag."))
            return true
        end

        setPlayerStorageValue(cid, "hasCompletedResetQuest", 1)
        setPlayerStorageValue(cid, "canStartResetQuest", -1)

        doPlayerAddItem(cid, bossFinal.rewardItemId, 1, false, CONST_SLOT_RING)
        setPlayerStorageValue(cid, "hasActiveInQuest", -1)
        doTeleportCreature(cid, posExitFinal, 10)
        doBroadcastMessage("Parábens ao bravo dobrador "..getCreatureName(cid)..", os poderes dos Deuses agora o acompanham rumo ao seu "..(getPlayerResets(cid)+1).."° reset.")
        clearAllItems(cid)
    else
        doPlayerSendCancel(cid, getLangString(cid, "It is locked.", "O báu está trancado."))
    end

    return true
end