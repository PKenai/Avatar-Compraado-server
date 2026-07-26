function onSay(cid, words, param, channel)
  local param = string.explode(param, ",")

  if param[1] == nil or param[2] == nil then
    sendBlueMessage(cid, "Wrong format! Correct format: /setexpbackupind NAMEPLAYER, hours;")
  end

  local current = getCreatureByName(param[1])

  if current then
    if isNumber(param[2]) then
      param[2] = tonumber(param[2])
      
      if param[2] > 0 then
        setExpBackupToPlayer(param[2], getCreatureName(current))
        sendBackupToPlayer(current)
        sendBlueMessage(cid, "Sucesso! "..getCreatureName(curret).." teve sua exp devolvida.")
      else
        sendBlueMessage(cid, "You need put a param in hours (1-72).")  
      end
    else
      sendBlueMessage(cid, "You need put a param in hours (1-72).")  
    end
  else
    sendBlueMessage(cid, "This player don't exist.")
  end

  return true
end
