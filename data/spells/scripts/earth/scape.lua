local MyLocal = {}

MyLocal.spots = {384, 418, 8278, 8592}

function onCastSpell(cid, var)
    if getSpellCancels(cid, "earth") == true then
        return false
    end
  local position = getThingPosition(cid)
  position.stackpos = 0
  local ground = getThingFromPos(position)
  if(isInArray(MyLocal.spots, ground.itemid)) then
    if getPlayerExaust(cid, "earth", "scape") == false then
        return false
      end
      if getPlayerHasStun(cid) then
          return true
      end
    doPlayerAddExaust(cid, "earth", "scape", earthExausted.scape)
    local newPosition = position
    newPosition.y = newPosition.y + 1
    newPosition.z = newPosition.z - 1

    if not hasSqm(newPosition) or not getPlayerCanWalk({player = cid, position = newPosition, checkPZ = true, checkHouse = true}) then
      doPlayerSendDefaultCancel(cid, RETURNVALUE_NOTPOSSIBLE)
      doSendMagicEffect(position, CONST_ME_POFF)
      return false
    end

        posPlayer = getCreaturePosition(cid)
        doSendMagicEffect(getPlayerPosition(cid), 81)
        addEvent(valid(doTeleportThing), 500, cid, newPosition, false)
        setCreatureNoMoveTime(cid, 500)
    return true
  else
    doPlayerSendDefaultCancel(cid, RETURNVALUE_NOTPOSSIBLE)
    doSendMagicEffect(position, CONST_ME_POFF)
    return false
  end
end