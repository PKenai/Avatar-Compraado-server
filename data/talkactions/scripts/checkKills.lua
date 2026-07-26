function onSay(cid, words, param, channel)
    local count = getStorage("count"..param:lower())+1

  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, count.." "..param.."(s) killed until now.")
  return true
end
