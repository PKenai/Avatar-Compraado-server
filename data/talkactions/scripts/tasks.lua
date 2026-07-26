dofile(getDataDir().."lib/isoled/152-npcTaskSystem.lua")
dofile(getDataDir().."lib/isoled/153-npcTaskDaily.lua")

function onSay(cid, words, param, channel)
  --doShowTextDialog(cid, 8983, getAdvancedTaskList(cid).."\n\n"..getDailyTaskList(cid))
  doShowTextDialog(cid, 18157, getDailyTaskList(cid).."\n\n ".. getAdvancedTaskList(cid))
  return true
end
