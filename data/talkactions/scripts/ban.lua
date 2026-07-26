--[[local TYPE_ACCESS = {
  [1] = { "Player" },
  [2] = { "Player" },
  [3] = { "Account", "Player" },
  [4] = { "Account", "Player" },
  [5] = { "Account", "Player", "IP" }
}

function onSay(cid, words, param, channel)
  unregisterCreatureEventType(cid, "channelrequest")
  unregisterCreatureEventType(cid, "textedit")

  doPlayerSendChannels(cid, TYPE_ACCESS[getPlayerAccess(cid)])
  registerCreatureEvent(cid, "Ban_Type")
  return true
end--]]

function onSay(cid, words, param, channel)
  local param = string.explode(param, ",")

  if param[1] == nil or param[2] == nil then
    sendBlueMessage(cid, "Wrong format! Correct format: /ban NAMEPLAYER, MINUTES, REASON (OPTIONAL);")
  else
    if playerExists(param[1]) then
      if not isNumber(param[2]) then
        sendBlueMessage(cid, "Wrong format! Correct format: /ban NAMEPLAYER, MINUTES, REASON (OPTIONAL);")
        return true
      end
      if not isPlayerBanished(param[1], PLAYERBAN_BANISHMENT) then
        addPlayerBan(param[1], param[2]*60, param[3])
        sendBlueMessage(cid, param[1].." has banned successfully for "..param[2].." minutes(s).")
      else
        sendBlueMessage(cid, "This player is already banned.")
      end
    else
      sendBlueMessage(cid, "A player with this name is not exist.")
    end
  end
  return true
end
