local function isNonPvp(cid)
return getPlayerStorageValue(cid, "canAttackable") == 1
end 

local function isInPz(cid)
local tileInfo = getTileInfo(getCreaturePosition(cid))
if tileInfo.protection or tileInfo.hardcore or tileInfo.optional then
	return true
end
return false
end 

local function isGM(cid)
return getPlayerGroupId(cid) >= 3
end 

local function searchAvatar()
local avatar = 0
local possiveisNovos = {}
local possiveisOlds = {}

	for _, pid in ipairs(getPlayersOnline()) do
		if  not isNonPvp(pid) and not isInPz(pid) and getPlayerStorageValue(pid, "isAvatar") ~= 1 then
			table.insert(possiveisOlds, pid)
			if getPlayerStorageValue(pid, "isAvatar") ~= 0 then
				table.insert(possiveisNovos, pid)
			end
		end
	end
	if possiveisNovos and #possiveisNovos > 0 then
		avatar = possiveisNovos[math.random(1, #possiveisNovos)]
	elseif possiveisOlds and #possiveisOlds > 0 then
		avatar = possiveisOlds[math.random(1, #possiveisOlds)]
	end
return avatar
end

function onSay(cid, words, param, channel)
	local avatar = searchAvatar()
	if avatar ~= 0 then
		doBroadcastMessage("O dobrador "..getCreatureName(avatar).." é o novo Avatar escolhido.", MESSAGE_STATUS_CONSOLE_BLUE)
		setPlayerStorageValue(avatar, "isAvatar", 1)
		local oldAvatar = 0
		if getStorage(73991) > 0 then
			oldAvatar = getPlayerByNameWildcard(getPlayerNameByGUID(getStorage(73991)))
		end
		doSetStorage(73991, getPlayerGUIDByName(getCreatureName(avatar)))
		if oldAvatar and oldAvatar > 0 and isCreature(oldAvatar) then
			setPlayerStorageValue(oldAvatar, "isAvatar", 0)
		end
		local avatarPos = getCreaturePosition(avatar)
		doSendMagicEffect({x=avatarPos.x+1, y=avatarPos.y+1, z=avatarPos.z}, 134)
		doSendMagicEffect({x=avatarPos.x+1, y=avatarPos.y+1, z=avatarPos.z}, 135)
		doSendMagicEffect({x=avatarPos.x+1, y=avatarPos.y+1, z=avatarPos.z}, 121)
	end
return TRUE
end