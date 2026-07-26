function onSay(cid, words, param, channel)
  if param then
    local param = tonumber(param)
    if isNumber(param) then
      if param > 0 then
        setExpBackupToPlayers(param)
        sendBackupExpToAllPlayersOnline()
        sendBlueMessage(cid, "Success, now all players who died "..param.." hours ago have returned their exp.")
      else
        sendBlueMessage(cid, "You need put a param in hours (1-72).")  
      end
    else
      sendBlueMessage(cid, "You need put a param in hours (1-72).")  
    end
  else
    sendBlueMessage(cid, "You need put an correct param: time (ex: 24 = 24 deathes on hours ago, will be returned).")  
  end

  return true
end