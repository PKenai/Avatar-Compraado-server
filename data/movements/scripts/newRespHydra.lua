dofile(getDataDir().."lib/isoled/152-npcTaskSystem.lua")

function onStepIn(cid, item, position, fromPosition)
  if isPlayer(cid) then
    if not getPlayerHasEndTask(cid, 6) then
      doTeleportThing(cid, fromPosition, false)
      doPlayerSendCancel(cid, getLangString(cid, "You need complete the Hydras Hard Task to enter here.", "Você precisa ter completado a task Hydras Hard para entrar aqui."))
    end

    if not isPremium(cid) then
      doTeleportThing(cid, fromPosition, false)
      sendBlueMessage(cid, getLangString(cid, WITHOUTPREMIUM, WITHOUTPREMIUMBR))
      return true
    end
  end
  return true
end
