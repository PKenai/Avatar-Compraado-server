local MyLocal = {}
MyLocal.playerCanUse = {}


function onSay(cid, words, param, channel)
  if MyLocal.playerCanUse[cid] ~= nil then
    doPlayerSendCancel(cid, "You need re-logout to use this command again.")
    return true
  end

  local param = param:lower()

  if param == "on" then
    setPlayerStorageValue(cid, "getTurnMsgPoints", -1)
    sendBlueMessage(cid, "Configuration saved, warning on upLevel are enabled.")
    MyLocal.playerCanUse[cid] = false
  elseif param == "off" then
    sendBlueMessage(cid, "Configuration saved, warning on upLevel are disabled.")
    MyLocal.playerCanUse[cid] = false
    setPlayerStorageValue(cid, "getTurnMsgPoints", 1)  
  else
    sendBlueMessage(cid, "You need put a correct param, ex: '!warning off' or '!warning on'.")
  end

  return true
end
