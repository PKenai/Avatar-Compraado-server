function onSay(cid, words, param, channel)
  if channel > 1 and channel < 15 then
    if getPlayerStorageValue(cid, "getPlayerHasBanned") > os.time() then
      local timeString = getSecsString(getPlayerStorageValue(cid, "getPlayerHasBanned")-os.time())
      doPlayerSendCancel(cid, getLangString(cid, "You have been banned from speaking in public chats, please wait "..timeString.." to speak again.", "Você foi banido de falar em chats públicos, por favor aguarde "..timeString.." para falar novamente."))
      return true
    end
  end
	--if getPlayerAccess(cid) == 3 then 
	--	return true
	--end
    local blocked = {}

    for x = 1, #blocked do
        if checkMsg(words.." "..param, blocked[x]) then
            return true
        end
    end


  return false
end