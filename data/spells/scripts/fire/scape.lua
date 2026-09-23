--focus ready--

local MyLocal = {}

MyLocal.spots = {384, 418, 8278, 8592}

local function toPosition(x,y,z)
    return {x=x,y=y,z=z}
end

function onCastSpell(cid, var)
  local position = getThingPosition(cid)
  position.stackpos = 0
  local ground = getThingFromPos(position)
  if(isInArray(MyLocal.spots, ground.itemid)) then
    if getSpellCancels(cid, "fire") == true then
          return false
      end
        if doPlayerAddExaust(cid, "fire", "scape", fireExausted.scape) == false then
        return false
       end
       if getPlayerHasStun(cid) then
            workAllCdAndAndPrevCd(cid, "fire", "scape", nil, 1)
          return true
        end
    local newPosition = position
    newPosition.y = newPosition.y + 1
    newPosition.z = newPosition.z - 1

    if not hasSqm(newPosition) or not getPlayerCanWalk({player = cid, position = newPosition, checkPZ = true, checkHouse = true}) then
      doPlayerSendDefaultCancel(cid, RETURNVALUE_NOTPOSSIBLE)
      doSendMagicEffect(position, CONST_ME_POFF)
      return false
    end

        posPlayer = getCreaturePosition(cid)
        doSendMagicEffect(position, CONST_ME_FIREAREA)
        doSendMagicEffect(toPosition(posPlayer.x+1,posPlayer.y,posPlayer.z), CONST_ME_FIREAREA)
        doSendMagicEffect(toPosition(posPlayer.x-1,posPlayer.y,posPlayer.z), CONST_ME_FIREAREA)
        doSendMagicEffect(toPosition(posPlayer.x,posPlayer.y+1,posPlayer.z), CONST_ME_FIREAREA)
        doSendMagicEffect(toPosition(posPlayer.x,posPlayer.y-1,posPlayer.z), CONST_ME_FIREAREA)
        addEvent(valid(doTeleportThing), 500, cid, newPosition, false)
        setCreatureNoMoveTime(cid, 500)
        addEvent(doSendMagicEffect, 500, newPosition, CONST_ME_FIREAREA)
        getPlayerOverPower(cid, "fire", true, true)
        workAllCdAndAndPrevCd(cid, "fire", "scape", nil, 1)
    return true
  else
    doPlayerSendDefaultCancel(cid, RETURNVALUE_NOTPOSSIBLE)
    doSendMagicEffect(position, CONST_ME_POFF)
    return false
  end
end