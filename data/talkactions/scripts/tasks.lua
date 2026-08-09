dofile(getDataDir().."lib/isoled/152-npcTaskSystem.lua")

function onSay(cid, words, param, channel)
  doShowTextDialog(cid, 18157, getAdvancedTaskList(cid))
  return true
end
