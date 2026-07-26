local loopTimeCheck = 5 --inMinutes (Aconselho deixar 5 minutos para não ficar muito pesada a verificação.)

local config = {
  doorActionId = 8909,
  directionEnter = NORTH,
  posExit = {x,y,z},
  playersInside = {}
}

local function teleportWithDelay(cid, pos)
  if isCreature(cid) then
    doTeleportThing(cid, pos)
    doCreatureSetNoMove(cid, false)
  end
end

local function loopCheck(cid)
  if isCreature(cid) then
    local timeLeft = getPlayerStorageValue(cid, config.storage)

    if timeLeft < os.time() then
      doTeleportThing(cid, cofig.posExit)
      playersInside[cid] = nil
    else
      playersInside[cid] = addEvent(loopCheck, loopTimeCheck*1000, cid)
    end
  else
    playersInside[cid] = nil  
  end
end

function validTrainerDoor(cid, actionId)
  if not (actionId == config.doorActionId) then
    return
  end

  print(123)

  if playersInside[cid] then
    addEvent(teleportWithDelay, 100, cid, fromPosition)
    playersInside[cid] = nil
  else
    local timeLeft = getPlayerStorageValue(cid, config.doorActionId)

    if timeLeft > os.time() then
      addEvent(teleportWithDelay, 100, cid, getPositionByDirection(getCreaturePosition(cid), config.directionEnter))
      playersInside[cid] = addEvent(loopCheck, loopTimeCheck*1000, cid)
    else
      addEvent(teleportWithDelay, 100, cid, fromPosition)
      setPlayerStorageValue(cid, config.doorActionId, -1)
    end
  end

  doCreatureSetNoMove(cid, true)
end