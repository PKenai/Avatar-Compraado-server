local function prepareShutdown(minutes, reason)
  local minute = 0

  if(minutes <= 0) then
    doSetGameState(GAMESTATE_SHUTDOWN)
    return false
  end

  if tostring(minutes):len() < 2 then
    minute = "0"..minutes
  end

  local change, r = 5, (reason ~= "" and " Reason: "..reason or "")

  if(minutes == 1) then
    doBroadcastMessage("Avatar is going down in " .. minute .. " minute, please go to a safe place now!" .. r)
  elseif(minutes <= 5) then
    doBroadcastMessage("Avatar is going down in " .. minute .. " minutes, please go to a safe place." .. r)
    change = 1
  else
    doBroadcastMessage("Avatar is going down in " .. minute .. " minutes." .. r)
    change = 1
  end

  addEvent(prepareShutdown, (change * 60 * 1000), minutes - change, reason)
  return true
end

function onThink(interval)
  prepareShutdown(15)
  return true
end