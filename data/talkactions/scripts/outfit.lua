function onSay(cid, words, param, channel)
  if(param == '') then
    return true
  end
  sendOutfitToNormal(getCreatureByName(param))
  return true
end
