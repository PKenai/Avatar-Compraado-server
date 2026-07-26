dofile(getDataDir().."actions/scripts/quests/poi/const.lua")


--Pode pegar todos.
function onUse(cid, item, fromPosition, itemEx, toPosition)
--    if getPlayerStorageValue(cid, "POIQuestProgress") == -1 and getPlayerAccess(cid) < 4 then
 --       sendBlueMessage(cid, "Possível bug, favor reportar ao GM. (Cod. 2891, POIQUEST).")
  --      return false
   -- end


    if getPlayerStorageValue(cid, "90501"..item.actionid) == -1 then
        setPlayerStorageValue(cid, "90501"..item.actionid, 1)
        doPlayerAddItem(cid, rewardOne[item.actionid].itemid, rewardOne[item.actionid].amount)

        if getPlayerStorageValue(cid, "POIQuestProgress") == 3 then
            setPlayerStorageValue(cid, "POIQuestProgress", 4)
        end

        local itemDesc = rewardOne[item.actionid].amount.." "..getItemNameById(rewardOne[item.actionid].itemid).."(s)."
        sendBlueMessage(cid, getLangString(cid, "You have found a Survival Quest Reward: "..itemDesc, "Você coletou a Survival Quest Reward: "..itemDesc))
    else
        doPlayerSendCancel(cid, getLangString(cid, "This chest is empty.", "Esse baú está vazio."))
    end


    return true
end