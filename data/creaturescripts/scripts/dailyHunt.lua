dofile(getDataDir() .. "lib/dailyHunt.lua")

function onKill(cid, target, lastHit)
  if not isMonster(target) then
    return true
  end
  if isSummon(target) then
    return true
  end

  local monsterName = getCreatureName(target)
  DailyHunt.onMonsterKill(cid, monsterName)

  return true
end

function onExtendedOpcode(cid, opcode, buffer)
  if opcode ~= DailyHunt.opcode then
    return true
  end

  if buffer == "request" then
    DailyHunt.sendDataToClient(cid)
  elseif buffer == "claim" then
    DailyHunt.claimReward(cid)
  end

  return true
end
