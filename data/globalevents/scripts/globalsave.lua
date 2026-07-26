
function prepareShutdown(minutes, current)
  local time = 0
  shutdownEvent = {}

  if not current then
    for x = minutes, 0, -1 do
      shutdownEvent[x+1] = addEvent(prepareShutdown, time*60*1000, nil, x)
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
	if type(getStorage("GlobalSaveDays")) ~= "number" or getStorage("GlobalSaveDays") < 0 then 
		doSetStorage("GlobalSaveDays", 0)
	end 
    if current == 0 then
	  doSetStorage("GlobalSaveDays", getStorage("GlobalSaveDays")+1)
      doSetGameState(GAMESTATE_SHUTDOWN)
    end
  end

  return true
end



function onTime(interval)
prepareShutdown(5)
return TRUE
end