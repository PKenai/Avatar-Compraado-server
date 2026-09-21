exhaustion =
{
  check = function (cid, storage)
    if(getPlayerFlagValue(cid, PLAYERFLAG_HASNOEXHAUSTION)) then
      return false
    end

    return (tonumber(getPlayerStorageValue(cid, storage)) or -1) >= os.time()
  end,

  get = function (cid, storage)
    if(getPlayerFlagValue(cid, PLAYERFLAG_HASNOEXHAUSTION)) then
      return false
    end

    local exhaust = tonumber(getPlayerStorageValue(cid, storage)) or -1
    if(exhaust > 0) then
      local left = exhaust - os.time()
      if(left >= 0) then
        return left
      end
    end

    return false
  end,

  set = function (cid, storage, time)
    setPlayerStorageValue(cid, storage, os.time() + time)
  end,

  make = function (cid, storage, time)
    local exhaust = exhaustion.get(cid, storage)
    if(not exhaust) then
      exhaustion.set(cid, storage, time)
      return true
    end

    return false
  end
}
