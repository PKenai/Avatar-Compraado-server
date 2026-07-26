local function isGM(cid)
return getPlayerGroupId(cid) >= 3
end 

local function isAttackingHitbox(cid)
local target = getCreatureTarget(cid)
if not target or target == 0 then 
	return true 
end
return target and getCreatureName(target) == "Target"
end 

function onSay(cid, words, param, channel)
	local strings, i, position, added, showGamemasters = {""}, 1, 1, false, getBooleanFromString(getConfigValue('displayGamemastersWithOnlineCommand'))
	for _, pid in ipairs(getPlayersOnline()) do
		if(added) and not isGM(pid) then
			if(i > (position * 7)) then
				strings[position] = strings[position] .. ","
				position = position + 1
				strings[position] = ""
			else
				strings[position] = i == 1 and "" or strings[position] .. ", "
			end
		end

		added = false
		if(not isGM(pid)) and not isAttackingHitbox(pid) then
			strings[position] = strings[position] .. getCreatureName(pid) .. " [" .. getPlayerLevel(pid) .. "]"
			i = i + 1
			added = true
		end
	end

	local total = i - 1

	for i, str in ipairs(strings) do
		if(str:sub(str:len()) ~= ",") then
			str = str .. "."
		end

		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, str)
	end
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, (total) .. " jogador" .. (total > 1 and "es" or "") .. " atacando algum monstro.")

	return true
end
