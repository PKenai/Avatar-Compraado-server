dofile(getDataDir() .. "lib/dailyHunt.lua")

function onSay(cid, words, param, channel)
  DailyHunt.sendDataToClient(cid)
  return true
end
