function onSay(cid, words, param, channel)
  if(param == '') then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Command param required.")
    return true
  end

  local t = string.explode(param, " ", 1)
  if cleanAllCds(cid, t[1]) then
    sendBlueMessage(cid, "Success! All "..t[1].." CDs cleaned.")
  else
    sendBlueMessage(cid, "Invalid element name, please use: air, fire, water or air.")
  end
  return true
end
