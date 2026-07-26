local config = {
  fragsToRedSkull = getConfigValue('fragsToRedSkull'),
  redSkullLength = getConfigValue('redSkullLength'),
  fragTime = getConfigValue('fragTime'),
  fragsToBanishment = getConfigValue('fragsToBanishment'),
  banKillLength = getConfigValue('banKillLength'),
  countLimit = 7 * 10 * 60 * 60
}

local furiaPassivaTime = 3

local function executeInjustKillFunc(cid)
  local currentTime, timeLimit = os.time(), addFragTimeInPlayer(cid)
  local fragsNumber = getPlayerFrags(cid)

  setPlayerStorageValue(cid, "lastFragTime", currentTime+furiaPassivaTime)

  if fragsNumber >= config.fragsToRedSkull then
    if fragsNumber >= config.fragsToBanishment then
       addPlayerBan(getCreatureName(cid), config.banKillLength, "Unjustified player killing")
    --elseif fragsNumber == config.fragsToRedSkull then 
  else
      doPlayerSetSkullEnd(cid, getFragTimes(cid), SKULL_RED)
  --else 
    --  doPlayerSetSkullEnd(cid, getFragTimes(cid)+config.fragTime, SKULL_RED)
    end
  end
end

function onInjustKill(cid)
  local lastFragTime = getPlayerStorageValue(cid, "lastFragTime")

  if lastFragTime >= os.time() then
    return false
  end
	local killerLevel = getPlayerLevel(cid)
	if killerLevel >= 100 then
		local levelVitima = tonumber(getPlayerStorageValue(cid, "36293"))
		if levelVitima ~= -1 and levelVitima > 0 and levelVitima <= killerLevel*0.5 then
			addEvent(valid(executeInjustKillFunc), 1, cid) -- extra frag ao matar level menor ou igual a metade sendo 100+
			if killerLevel >= 150 and levelVitima <= killerLevel/3 then
				addEvent(valid(executeInjustKillFunc), 1, cid) -- outro extra frag ao matar level menor ou igual a 1/3 sendo 100+
			end
		end
	end
  addEvent(valid(executeInjustKillFunc), 1, cid)
  return true
end