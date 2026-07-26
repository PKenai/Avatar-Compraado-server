local function filterNumber(number)
  local number = tonumber(number)

  if number > 180 then
    return 180
  end

  if number <= 0 then
    return 1
  end

  return number
end


function onSay(cid, words, param, channel)
  local param = string.explode(param, ",")

  if param[1] == nil then
    sendBlueMessage(cid, "Wrong format! Correct format: /banChannel NAMEPLAYER, MINUTES")
    return true
  end

  if not param[2] then
    param[2] = 60
  end

  if not isNumber(param[2]) then
    sendBlueMessage(cid, "Wrong format! Correct format: /banChannel NAMEPLAYER, MINUTES")
    return true
  end

  local pid = getPlayerByName(param[1])

  if isPlayer(pid) then

    if tonumber(param[2]) <= 0 then
      setPlayerStorageValue(pid, "getPlayerHasBanned", 0)
      sendBlueMessage(cid, param[1].." has to desbanned to talk in public channels successfully.")
    else
      local timeBanned = getPlayerStorageValue(pid, "getPlayerHasBanned")

      if timeBanned > os.time() then
        sendBlueMessage(cid, "This player is already banned to talk in public channels.")
      else
        local time, minutes = filterNumber(param[2])*60, filterNumber(param[2])
        setPlayerStorageValue(pid, "getPlayerHasBanned", os.time()+time)
        sendBlueMessage(cid, param[1].." has to banned to talk in public channels successfully for "..minutes.." minutes.")
        doPlayerSendTextMessage(pid, MESSAGE_STATUS_WARNING, getLangString(pid, "You have been banned from speaking in public chats for "..minutes.." minute(s).", "Você foi banido de falar em chats publicos por "..minutes.." minuto(s)."))
      end
    end
  else
    sendBlueMessage(cid, "A player with this name is not exist.")
  end

  return true
end