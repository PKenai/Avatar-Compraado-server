shutdownEvent = {}

function onSay(cid, words, param, channel)
  if(param == '') then
    doSetGameState(GAMESTATE_SHUTDOWN)
    return true
  end

  params = string.explode(param, ",")
  local action, reason, mins  = "", "", 0
  if(not tonumber(params[1])) then
    action = string.trim(params[1]:lower())
  else
    mins = string.trim(params[1])
    if(table.maxn(params) > 1) then
      reason = params[2]
    end
  end
  
  if(action) then
    if(action == "cancel" or action == "stop") then
      if(#shutdownEvent ~= 0) then
        for x = 1, #shutdownEvent do
          stopEvent(shutdownEvent[x])
        end
        
        shutdownEvent = {}
        doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Shutdown cancelled.")
      else
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Server is not in the shutdown phase.")
      end
      return true
    elseif(action == "kill") then
      os.exit()
      return true
    end
  end
  
  mins = tonumber(mins)
  if(not mins or mins < 0) then
    doPlayerSendCancel(cid, "Numeric param may not be lower than 0.")
    return true
  end
  
  if(#shutdownEvent ~= 0) then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Server is already in a shutdown state. To cancel shutdown use the \"/shutdown stop\" command.")
    return true
  end
  
  return prepareShutdown(math.abs(math.ceil(mins)), reason)
end


function prepareShutdown(minutes, reason, current)
  local time = 0
  shutdownEvent = {}

  if not current then
    for x = minutes, 0, -1 do
      shutdownEvent[x+1] = addEvent(prepareShutdown, time*60*1000, nil, reason, x)
      time = time+1
    end

  else
    local a = ""
    local r = reason or ""

    if current > 1 then
      a = "Avatar is going down in " .. current .. " minutes, please go to a safe place. "..r
    else
      a = "Avatar is going down in " .. current .. " minute, please go to a safe place now! "..r
    end

    doBroadcastMessage(a)

    if current == 0 then
      doSetGameState(GAMESTATE_SHUTDOWN)
    end
  end

  return true
end
