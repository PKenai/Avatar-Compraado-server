function onSay(cid, words, param, channel)
  local param = string.explode(param, ":")

  if param[1] and param[2] then
    if isNumber(param[1]) and isNumber(param[2]) then
      setPlayerStorageValue(cid, "saveClientConfig"..param[1], param[2])
    end
  end

  return true
end
