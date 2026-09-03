-- Swimming outfit dependendo da vocation do player
-- 1=Fire, 2=Water, 3=Air, 4=Earth (5-8 = promoted, mesmo elemento)
-- Also applied by C++ trashholder.cpp for swimming pool tiles

local swimmingOutfits = {
    [1] = 1345, -- Fire
    [2] = 1344, -- Water
    [3] = 1347, -- Air
    [4] = 1346, -- Earth
    [5] = 1345, -- Fire (promoted)
    [6] = 1344, -- Water (promoted)
    [7] = 1347, -- Air (promoted)
    [8] = 1346, -- Earth (promoted)
}

function onStepIn(cid, item, position, lastPosition, fromPosition, toPosition, actor)
  local swimLookType = swimmingOutfits[getPlayerVocation(cid)] or 267
  if(hasCondition(cid, CONDITION_OUTFIT, 0, CONDITIONID_COMBAT) and getCreatureOutfit(cid).lookType == swimLookType) then
    doRemoveCondition(cid, CONDITION_OUTFIT)
    if(not isPlayerGhost(cid)) then
      doSendMagicEffect(position, CONST_ME_POFF)
    end
  end

  return true
end

function onStepOut(cid, item, position, lastPosition, fromPosition, toPosition, actor)
  if(not isPlayer(cid)) then
    return true
  end

  local tmp = getTileInfo(toPosition)
  if(tmp.trashHolder) then
    if(doTileQueryAdd(cid, toPosition, 4) ~= RETURNVALUE_NOERROR) then
      return false
    end

    if(not isPlayerGhost(cid)) then
      doSendMagicEffect(fromPosition, CONST_ME_POFF)
      doSendMagicEffect(toPosition, CONST_ME_WATERSPLASH)
    end

    doRemoveConditions(cid, true)

    local swimLookType = swimmingOutfits[getPlayerVocation(cid)] or 267
    local outfit = {lookType = swimLookType, lookHead = 0, lookBody = 0, lookLegs = 0, lookFeet = 0, lookTypeEx = 0, lookAddons = 0}
    doSetCreatureOutfit(cid, outfit, -1)
  end

  return true
end
