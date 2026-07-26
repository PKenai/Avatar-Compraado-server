function onSay(cid, words, param, channel)
  --sendBlueMessage(cid, "Abrindo web: "..tostring(param)..";")
  --sendWebsiteToPlayer(cid, param)
  doCreatureSay(cid, param)
  return true
end