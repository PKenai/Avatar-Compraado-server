creatureGetName = getCreatureName
reportsEnviados = {}
--[[function isInArray(array, value, caseSensitive)
  if(caseSensitive == nil or caseSensitive == false) and type(value) == "string" then
    local lowerValue = value:lower()
    for _, _value in ipairs(array) do
      if type(_value) == "string" and lowerValue == _value:lower() then
        return true
      end
    end
  else
    for _, _value in ipairs(array) do
      if (value == _value) then return true end
    end
  end

  return false
end--]]
vocMountOuts = 
{
	{ -- MALE
		{617, 518, 616, 618, 633, 634, 635, 636, 689, 688, 690, 691, 687}, -- FIRE
		{507, 620, 621, 619, 632, 631, 629, 630, 664, 663, 665, 666, 662}, -- WATER
		{495, 604, 605, 606, 649, 650, 651, 652, 684, 683, 685, 686, 682}, -- AIR
		{523, 612, 610, 611, 644, 642, 641, 643, 674, 672, 675, 676, 673} -- EARTH
	},
	{ -- FEMALE
		{613, 519, 614, 615, 637, 638, 639, 640, 694, 693, 695, 696, 692}, -- FIRE
		{509, 624, 623, 622, 628, 627, 625, 626, 658, 660, 659, 661, 657}, -- WATER
		{496, 601, 603, 602, 653, 654, 655, 656, 679, 678, 680, 681, 677}, -- AIR
		{524, 609, 607, 608, 648, 646, 645, 647, 669, 668, 670, 671, 667} -- EARTH
	}
}

function addMountsToPlayer(cid, voc, sex)
	local outList = vocMountOuts[2-sex][voc]
	for i = 1, #outList do
		if not canPlayerWearOutfit(cid, outList[i], 0) then 
			doPlayerAddOutfit(cid, outList[i], 0)
			if i == 1 then 
				local outfit = getCreatureOutfit(cid)
				outfit.lookType = outList[i]
				doCreatureChangeOutfit(cid, outfit)
			end 
		end
	end
end

function removeMountsFromPlayer(cid, voc, sex)
	local outList = vocMountOuts[2-sex][voc]
	for i = 1, #outList do
		if canPlayerWearOutfit(cid, outList[i], 0) then 
			doPlayerRemoveOutfit(cid, outList[i])
		end
	end
end


function doPlayerCancelFollow(cid)
	return true 
end 

function dismountPlayer(cid)
	if not isCreature(cid) then 
		return true
	end
    if getPlayerStorageValue(cid, "inMount") == 1 then
        doCreatureSetStorage(cid, "inMount", -1)
        doRemoveCondition(cid, CONDITION_OUTFIT)

        -- Guarda: bonusMount pode estar stale (morte/crash montado apos um doSlow,
        -- relogin etc). Remover mais do que o speed atual TEM viraria speed <= 0
        -- (servidor cancela a walk = "paralyze" ate o relogin).
        local speedAdded = getPlayerStorageValue(cid, "bonusMount")
        if type(speedAdded) ~= "number" or speedAdded < 0 then speedAdded = 0 end
        local atual = getCreatureSpeed(cid) - getCreatureBaseSpeed(cid)
        if speedAdded > atual then speedAdded = atual end
        if speedAdded > 0 then
            doChangeSpeed(cid, -speedAdded)
        end
        doCreatureSetStorage(cid, "bonusMount", 0)
        return true
    end    

    return false
end

function doPlayerAddItemNPC(cid, itemid, amount)
  local countToAdd = amount

  if amount > 100 and isItemStackable(itemid) then
    for x = 1, math.ceil(amount/100) do
      local amountToAdd = 0

      if amount > 100 then
        amountToAdd = 100
      else
        amountToAdd = amount
      end

      amount = amount-amountToAdd
      doPlayerGiveItem(cid, itemid, amountToAdd)
    end
  else
    doPlayerGiveItem(cid, itemid, amount)
  end
end

-- Remove acentos de uma string UTF-8 (mantem o resto intacto).
-- Permite que keywords com ou sem acento casem com o input do player.
function stripAccents(s)
  if(type(s) ~= "string") then
    return s
  end
  local map = {
    ["\195\160"] = "a", ["\195\161"] = "a", ["\195\162"] = "a",
    ["\195\163"] = "a", ["\195\164"] = "a", ["\195\165"] = "a",
    ["\195\167"] = "c",
    ["\195\168"] = "e", ["\195\169"] = "e", ["\195\170"] = "e",
    ["\195\171"] = "e",
    ["\195\172"] = "i", ["\195\173"] = "i", ["\195\174"] = "i",
    ["\195\175"] = "i",
    ["\195\177"] = "n",
    ["\195\178"] = "o", ["\195\179"] = "o", ["\195\180"] = "o",
    ["\195\181"] = "o", ["\195\182"] = "o",
    ["\195\185"] = "u", ["\195\186"] = "u", ["\195\187"] = "u",
    ["\195\188"] = "u",
    ["\195\189"] = "y", ["\195\191"] = "y",
    ["\195\128"] = "A", ["\195\129"] = "A", ["\195\130"] = "A",
    ["\195\131"] = "A", ["\195\132"] = "A", ["\195\133"] = "A",
    ["\195\135"] = "C",
    ["\195\136"] = "E", ["\195\137"] = "E", ["\195\138"] = "E",
    ["\195\139"] = "E",
    ["\195\140"] = "I", ["\195\141"] = "I", ["\195\142"] = "I",
    ["\195\143"] = "I",
    ["\195\145"] = "N",
    ["\195\146"] = "O", ["\195\147"] = "O", ["\195\148"] = "O",
    ["\195\149"] = "O", ["\195\150"] = "O",
    ["\195\153"] = "U", ["\195\154"] = "U", ["\195\155"] = "U",
    ["\195\156"] = "U",
    ["\195\157"] = "Y",
  }
  return (s:gsub("[\195][\128-\191]", map))
end

function checkMsg(message, keyword)
  if(type(keyword) == "table") then
    return table.isStrIn(keyword, message)
  end
  local keyword = stripAccents(keyword:lower())
  local message = stripAccents(message:lower())

  local a, b = message:find(keyword)
  if keyword == "hi" or keyword == "oi" then
    if a == 1 and b == 2 then
      return true
    end
  else
    if(a ~= nil and b ~= nil) then
      return true
    end
  end

  return false
end

function getNumbersInString(str)
  local tableResults = {}
  local str = tostring(str)
  for num in str:gmatch("(%d+)") do
    table.insert(tableResults, tonumber(num))
  end
  
  return tableResults
end

function doPlayerGiveItem(cid, itemid, amount, subType)
  local item = 0
  if(isItemStackable(itemid)) then
    item = doCreateItemEx(itemid, amount)
    if(doPlayerAddItemEx(cid, item, true) ~= RETURNVALUE_NOERROR) then
      return false
    end
  else
    for i = 1, amount do
      item = doCreateItemEx(itemid, subType)
      if(doPlayerAddItemEx(cid, item, true) ~= RETURNVALUE_NOERROR) then
        return false
      end
    end
  end

  return true
end

function doPlayerGiveItemContainer(cid, containerid, itemid, amount, subType)
  for i = 1, amount do
    local container = doCreateItemEx(containerid, 1)
    for x = 1, getContainerCapById(containerid) do
      doAddContainerItem(container, itemid, subType)
    end

    if(doPlayerAddItemEx(cid, container, true) ~= RETURNVALUE_NOERROR) then
      return false
    end
  end

  return true
end

function doPlayerTakeItem(cid, itemid, amount)
  return getPlayerItemCount(cid, itemid) >= amount and doPlayerRemoveItem(cid, itemid, amount)
end

function doPlayerSellItem(cid, itemid, count, cost)
  if(not doPlayerTakeItem(cid, itemid, count)) then
    return false
  end

  if(not doPlayerAddMoney(cid, cost)) then
    error('[doPlayerSellItem] Could not add money to: ' .. getPlayerName(cid) .. ' (' .. cost .. 'gp).')
  end

  return true
end

function doPlayerWithdrawMoney(cid, amount)
  if(not getBooleanFromString(getConfigInfo('bankSystem'))) then
    return false
  end

  local balance = getPlayerBalance(cid)
  if(amount > balance or not doPlayerAddMoney(cid, amount)) then
    return false
  end

  doPlayerSetBalance(cid, balance - amount)
  return true
end

function doPlayerDepositMoney(cid, amount)
  if(not getBooleanFromString(getConfigInfo('bankSystem'))) then
    return false
  end

  if(not doPlayerRemoveMoney(cid, amount)) then
    return false
  end

  doPlayerSetBalance(cid, getPlayerBalance(cid) + amount)
  return true
end

function doPlayerAddStamina(cid, minutes)
  return doPlayerSetStamina(cid, getPlayerStamina(cid) + minutes)
end

function isPremium(cid)
  return (isPlayer(cid) and (getPlayerPremiumDays(cid) > 0 or getBooleanFromString(getConfigValue('freePremium'))))
end

function getMonthDayEnding(day)
  if(day == "01" or day == "21" or day == "31") then
    return "st"
  elseif(day == "02" or day == "22") then
    return "nd"
  elseif(day == "03" or day == "23") then
    return "rd"
  end

  return "th"
end

function getMonthString(m)
  return os.date("%B", os.time{year = 1970, month = m, day = 1})
end

function getArticle(str)
  return str:find("[AaEeIiOoUuYy]") == 1 and "an" or "a"
end

function doNumberFormat(i)
  local str, found = string.gsub(i, "(%d)(%d%d%d)$", "%1,%2", 1), 0
  repeat
    str, found = string.gsub(str, "(%d)(%d%d%d),", "%1,%2,", 1)
  until found == 0
  return str
end

function doPlayerAddAddons(cid, addon)
  for i = 0, table.maxn(maleOutfits) do
    doPlayerAddOutfit(cid, maleOutfits[i], addon)
  end

  for i = 0, table.maxn(femaleOutfits) do
    doPlayerAddOutfit(cid, femaleOutfits[i], addon)
  end
end

function getTibiaTime(num)
  local minutes, hours = getWorldTime(), 0
  while (minutes > 60) do
    hours = hours + 1
    minutes = minutes - 60
  end

  if(num) then
    return {hours = hours, minutes = minutes}
  end

  return {hours =  hours < 10 and '0' .. hours or '' .. hours, minutes = minutes < 10 and '0' .. minutes or '' .. minutes}
end

function doWriteLogFile(file, text)
  local f = io.open(file, "a+")
  if(not f) then
    return false
  end

  f:write("[" .. os.date("%d/%m/%Y %H:%M:%S") .. "] " .. text .. "\n")
  f:close()
  return true
end

function getExperienceForLevel(lv)
  lv = lv - 1
  return (((50 * lv * lv * lv) - (150 * lv * lv) + (400 * lv)) / 3)
end

function doMutePlayer(cid, time)
  local condition = createConditionObject(CONDITION_MUTED, (time == -1 and time or time * 1000))
  return doAddCondition(cid, condition, false)

end

function doSummonCreature(name, pos)
  local cid = doCreateMonster(name, pos, false, false)
  if(not cid) then
    cid = doCreateNpc(name, pos)
  end

  return cid
end

function getPlayersOnlineEx()
  local players = {}
  for i, cid in ipairs(getPlayersOnline()) do
    table.insert(players, getCreatureName(cid))
  end

  return players
end

function getPlayerByName(name)
  local cid = getCreatureByName(name)
  return isPlayer(cid) and cid or nil
end

function isPlayer(cid)
  return isCreature(cid) and cid >= AUTOID_PLAYERS and cid < AUTOID_MONSTERS
end

function isPlayerGhost(cid)
  return isPlayer(cid) and (getCreatureCondition(cid, CONDITION_GAMEMASTER, GAMEMASTER_INVISIBLE, CONDITIONID_DEFAULT) or getPlayerFlagValue(cid, PLAYERFLAG_CANNOTBESEEN))
end

function isMonster(cid)
  return isCreature(cid) and cid >= AUTOID_MONSTERS and cid < AUTOID_NPCS
end

function isNpc(cid)
  -- Npc IDs are over int32_t range (which is default for lua_pushnumber),
  -- therefore number is always a negative value.
  return isCreature(cid) and (cid < 0 or cid >= AUTOID_NPCS)
end

function isUnderWater(cid)
  return isInArray(underWater, getTileInfo(getCreaturePosition(cid)).itemid)
end

function doPlayerAddLevel(cid, amount, round)
  local experience, level, amount = 0, getPlayerLevel(cid), amount or 1
  if(amount > 0) then
    experience = getExperienceForLevel(level + amount) - (round and getPlayerExperience(cid) or getExperienceForLevel(level))
  else
    experience = -((round and getPlayerExperience(cid) or getExperienceForLevel(level)) - getExperienceForLevel(level + amount))
  end

  return doPlayerAddExperience(cid, experience)
end

--[[function doPlayerAddMagLevel(cid, amount)
  local amount = amount or 1
  for i = 1, amount do
    doPlayerAddSpentMana(cid, getPlayerRequiredMana(cid, getPlayerMagLevel(cid, true) + 1) - getPlayerSpentMana(cid), true)
  end

  return true
end--]]

function doPlayerAddMagicLevel(cid, amount) --By Mirto (12/02/13)
  if not isPlayer(cid) then
    return false
  end

  local amount, currentMagic = amount or 1, getPlayerMagLevel(cid)
  
  for x = 1, amount do
    doPlayerAddMagLevel(cid)
  end

  doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "You advanced to bend level "..currentMagic+amount..".")
  return true
end

function doPlayerAddSkill(cid, skill, amount, round)
  local amount = amount or 1
  if(skill == SKILL__LEVEL) then
    return doPlayerAddLevel(cid, amount, round)
  elseif(skill == SKILL__MAGLEVEL) then
    return doPlayerAddMagLevel(cid, amount)
  end

  for i = 1, amount do
    doPlayerAddSkillTry(cid, skill, getPlayerRequiredSkillTries(cid, skill, getPlayerSkillLevel(cid, skill) + 1) - getPlayerSkillTries(cid, skill), false)
  end

  return true
end

function isPrivateChannel(channelId)
  return channelId >= CHANNEL_PRIVATE
end

function doBroadcastMessage(text, class)
  local class = class or MESSAGE_STATUS_WARNING
  if(type(class) == 'string') then
    local className = MESSAGE_TYPES[class]
    if(className == nil) then
      return false
    end

    class = className
  elseif(class < MESSAGE_FIRST or class > MESSAGE_LAST) then
    return false
  end

  for _, pid in ipairs(getPlayersOnline()) do
    doPlayerSendTextMessage(pid, class, text)
  end

  print("> Broadcasted message: \"" .. text .. "\".")
  return true
end

function doPlayerBroadcastMessage(cid, text, class, checkFlag, ghost)
  local checkFlag, ghost, class = checkFlag or true, ghost or false, class or TALKTYPE_BROADCAST
  if(checkFlag and not getPlayerFlagValue(cid, PLAYERFLAG_CANBROADCAST)) then
    return false
  end

  if(type(class) == 'string') then
    local className = TALKTYPE_TYPES[class]
    if(className == nil) then
      return false
    end

    class = className
  elseif(class < TALKTYPE_FIRST or class > TALKTYPE_LAST) then
    return false
  end

  for _, pid in ipairs(getPlayersOnline()) do
    doCreatureSay(cid, text, class, ghost, pid)
  end

  print("> " .. getCreatureName(cid) .. " broadcasted message: \"" .. text .. "\".")
  return true
end

function doCopyItem(item, attributes)
  local attributes = ((type(attributes) == 'table') and attributes or { "aid" })

  local ret = doCreateItemEx(item.itemid, item.type)
  for _, key in ipairs(attributes) do
    local value = getItemAttribute(item.uid, key)
    if(value ~= nil) then
      doItemSetAttribute(ret, key, value)
    end
  end

  if(isContainer(item.uid)) then
    for i = (getContainerSize(item.uid) - 1), 0, -1 do
      local tmp = getContainerItem(item.uid, i)
      if(tmp.itemid > 0) then
        doAddContainerItemEx(ret, doCopyItem(tmp, true).uid)
      end
    end
  end

  return getThing(ret)
end

function doSetItemText(uid, text, writer, date)
  local thing = getThing(uid)
  if(thing.itemid < 100) then
    return false
  end

  doItemSetAttribute(uid, "text", text)
  if(writer ~= nil) then
    doItemSetAttribute(uid, "writer", tostring(writer))
    if(date ~= nil) then
      doItemSetAttribute(uid, "date", tonumber(date))
    end
  end

  return true
end

function getItemWeightById(itemid, count, precision)
  local item, count, precision = getItemInfo(itemid), count or 1, precision or false
  if(not item) then
    return false
  end

  if(count > 100) then
    -- print a warning, as its impossible to have more than 100 stackable items without "cheating" the count
    print('[Warning] getItemWeightById', 'Calculating weight for more than 100 items!')
  end

  local weight = item.weight * count
  return precission and weight or math.round(weight, 2)
end

function choose(...)
  local arg, ret = {...}

  if type(arg[1]) == 'table' then
    ret = arg[1][math.random(#arg[1])]
  else
    ret = arg[math.random(#arg)]
  end

  return ret
end

function doPlayerAddExpEx(cid, amount)
  if(not doPlayerAddExp(cid, amount)) then
    return false
  end

  local position = getThingPosition(cid)
  doPlayerSendTextMessage(cid, MESSAGE_EXPERIENCE, "You gained " .. amount .. " experience.", amount, COLOR_WHITE, position)

  local spectators, name = getSpectators(position, 7, 7), getCreatureName(cid)
  for _, pid in ipairs(spectators) do
    if(isPlayer(pid) and cid ~= pid) then
      doPlayerSendTextMessage(pid, MESSAGE_EXPERIENCE_OTHERS, name .. " gained " .. amount .. " experience.", amount, COLOR_WHITE, position)
    end
  end

  return true
end

function getItemTopParent(uid)
  local parent = getItemParent(uid)
  if(not parent or parent.uid == 0) then
    return nil
  end

  while(true) do
    local tmp = getItemParent(parent.uid)
    if(tmp and tmp.uid ~= 0) then
      parent = tmp
    else
      break
    end
  end

  return parent
end

function getItemHolder(uid)
  local parent = getItemParent(uid)
  if(not parent or parent.uid == 0) then
    return nil
  end

  local holder = nil
  while(true) do
    local tmp = getItemParent(parent.uid)
    if(tmp and tmp.uid ~= 0) then
      if(tmp.itemid == 1) then -- a creature
        holder = tmp
        break
      end

      parent = tmp
    else
      break
    end
  end

  return holder
end

function valid(f)
  return function(p, ...)
    if(isCreature(p)) then
      return f(p, ...)
    end
  end
end

function getPlayerElementPoints(cid, element)
         local element = string.lower(element)
         local avaliabeElements = {"fire", "water", "earth", "air"}
         local isAvaliabe = false

         for x = 1, #avaliabeElements do
             if avaliabeElements[x] == element then
                isAvaliabe = true
                break
             end   
         end
         if isAvaliabe == false then
            return false
         end 
         local value = getCreatureStorage(cid, "getPoints"..element)
         if value < 0 then
            return 0
         else
             return value
         end
end

function getPlayerElement(cid, isCapital)
  if isPlayer(cid) then
    local elements = {"fire", "water", "air", "earth"}
    local elementsC = {"Fire", "Water", "Air", "Earth"}
    local vocation = getPlayerVocation(cid)

    if not isCapital then
      return elements[vocation]
    else
      return elementsC[vocation]
    end
  else
    return false
  end
end

function getStoneItemId(element)
  local elements = {["fire"] = 12686, ["water"] = 12688, ["air"] = 12689, ["earth"] = 12687}
  return elements[element]
end

function doPlayerSetElementPoints(cid, element, amount)
         element = string.lower(element)
         local avaliabeElements = {"fire", "water", "earth", "air"}
         local isAvaliabe = false
         for x = 1, #avaliabeElements do
             if avaliabeElements[x] == element then
                isAvaliabe = true
                break
             end   
         end
         if isAvaliabe == false then
            return false
         end
         doCreatureSetStorage(cid, "getPoints"..element, amount)
         return true      
end

function sendBlueMessage(cid, msg, id)
    if id == nil then
          return doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, msg)
        else
          return doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, msg)
        end
end

function isWalkable(pos, cid, proj, pz, ignore, ignoreTwo)-- by Nord
  if getThingfromPos({x = pos.x, y = pos.y, z = pos.z, stackpos = 0}).itemid == 0 and not ignore then 
    return false 
  elseif ignore then
    doCreateTile(460, pos)
  end

  for stack = 0, 255 do
    pos.stackpos = stack
    local item = getThingfromPos(pos)

    if item.uid == 0 and stack > 10 then
      break
    end

    if isCreature(item.uid) == false and item.uid > 0 and (ignoreTwo == nil or ignoreTwo == false) then
      if stack == 0 then
        if (hasItemProperty(item.uid, CONST_PROP_BLOCKSOLID) and hasItemProperty(item.uid, CONST_PROP_BLOCKPROJECTILE) and hasItemProperty(item.uid, CONST_PROP_BLOCKPATHFIND)) then
          return false
        end
      else
        if hasItemProperty(item.uid, CONST_PROP_BLOCKSOLID) or hasItemProperty(item.uid, CONST_PROP_BLOCKPROJECTILE) or hasItemProperty(item.uid, CONST_PROP_BLOCKPATHFIND) or hasItemProperty(item.uid, CONST_PROP_BLOCKINGANDNOTMOVABLE) then
          return false
        end
      end
    end
  end
  return true
end

function getPlayerCanWalk(params) 
  -- {player = cid, position = pos, createTile = true, checkPZ = true, checkHouse = true, checkWater = false, acceptTileMonsteable = false}
  if isWaterBlock({x=params.position.x,y=params.position.y,z=7,stackpos=0}) then
    return false
  end

  local tileItem = getThingfromPos({x=params.position.x, y=params.position.y, z=params.position.z, stackpos=0})

  if tileItem.itemid == 0 and not params.createTile then 
    return false 
  elseif params.createTile then
    doCreateTile(460, params.position)
  end 

  local tile = getTileInfo(params.position)

  if params.checkPZ then
    if tile.protection then
      return false
    end
  end

  if params.checkNoLogout then
    if tile.noLogout then
      return false
    end
  end

  if params.checkHardcore then
    if tile.hardcore then
      return false
    end
  end

  if params.checkHouse then
    if getHouseFromPos(params.checkHouse) ~= false then
      return false
    end
  end

  if params.checkWater then
    if isAvaliableTileWaterByPos(params.position, nil, params.acceptTileMonsteable) then
      return false
    end
  end

  for x = 0, 10 do
    local tileItem = getThingfromPos({x=params.position.x, y=params.position.y, z=params.position.z, stackpos=x})
    if isInArray(actionidPlayerCantWalk, tileItem.actionid) then
      return false
    end
  end

  if doTileQueryAdd(params.player, params.position) == 0 then
    return true
  end
end

function hasSqm(pos, id)
  pos.stackpos = 0

  if id ~= nil then
    return getThingfromPos(pos).itemid == id
  else
    return getThingfromPos(pos).itemid ~= 0
  end
end

function getPosesAround(pos)
    local poses = {}
    table.insert(poses, pos)
    table.insert(poses, {x=pos.x,y=pos.y-1,z=pos.z})
    table.insert(poses, {x=pos.x-1,y=pos.y-1,z=pos.z})
    table.insert(poses, {x=pos.x-1,y=pos.y,z=pos.z})
    table.insert(poses, {x=pos.x-1,y=pos.y+1,z=pos.z})
    table.insert(poses, {x=pos.x,y=pos.y+1,z=pos.z})
    table.insert(poses, {x=pos.x+1,y=pos.y+1,z=pos.z})
    table.insert(poses, {x=pos.x+1,y=pos.y,z=pos.z})
    table.insert(poses, {x=pos.x+1,y=pos.y-1,z=pos.z})
    table.insert(poses, {x=pos.x,y=pos.y-1,z=pos.z})
    return poses
end

function removeTiles(tablePos)
  if tablePos[1] == nil then
    return true
  end
  for x = 1, #tablePos do
    tablePos[x].stackpos = 0
    local itemUid = getThingFromPos(tablePos[x]).uid
    if itemUid > 0 then
      doRemoveItem(itemUid)
    end
  end
end

function doCreateTiles(id, pos)
  local posesAround = getPosesAround(pos)
  local tilesPoses = {}

  for x = 1, #posesAround do
    if not hasSqm(posesAround[x]) then
      doAreaCombatHealth(0, 0, posesAround[x], 0, 0, 0, 255)
      local tileUid = doCreateItem(id, 1, posesAround[x])
      table.insert(tilesPoses, posesAround[x])
    end
  end
  addEvent(removeTiles, 100, tilesPoses)
end

function doCreateTile(id, pos)
  local posCreated = nil

  if not hasSqm(pos) then
    doAreaCombatHealth(0, 0, pos, 0, 0, 0, 255)
    local tileUid = doCreateItem(id, 1, pos)
    posCreated = pos
  end
  addEvent(removeTiles, 490, {posCreated})
end

function doPlayerAddUp(cid)
   local currentPos = getCreaturePosition(cid)
   local newPos = {x=currentPos.x,y=currentPos.y,z=currentPos.z-1}

   if (hasSqm(newPos) == false and not(getThingfromPos(newPos, false).uid > 0) and newPos.z ~= 0) then
         doCreateTile(460, newPos)
    doTeleportThing(cid, newPos)
    setPlayerStorageValue(cid, "playerOnAir", 1)
    return true
  else
     return false
   end
end

function doPlayerDown(cid)
    local currentPosition = getThingPos(cid)
    local newPosition = {x=currentPosition.x,y=currentPosition.y,z=currentPosition.z+1}

    if newPosition.z > 15 or newPosition.z < 0 then
      return false
    end

    local item = getThingfromPos({x=currentPosition.x, y=currentPosition.y, z=currentPosition.z, stackpos=0})
    if item.itemid ~= 1 and item.itemid ~= 460 and item.itemid ~= 0 then
       setPlayerStorageValue(cid, "playerOnAir", -1)
       return false
    end

    if hasSqm(newPosition) == false then
       doCreateTile(460, newPosition)
    end

    if getPlayerCanWalk({player = cid, position = newPosition, createTile = true, checkPZ = false, checkHouse = true}) then
    doTeleportThing(cid, newPosition)
  end

    currentPosition = getThingPos(cid)
    item = getThingfromPos({x=currentPosition.x, y=currentPosition.y, z=currentPosition.z, stackpos=0})

  if item.itemid ~= 1 and item.itemid ~= 460 then
         setPlayerStorageValue(cid, "playerOnAir", -1)

         if getPlayerInWater(cid) then
           doSendMagicEffect(newPosition, 53)
         else
           doSendMagicEffect(newPosition, 34)
      end
    end
  return true
end

function getPlayerInWater(cid)
  local tilePos = getCreaturePosition(cid)
  return isInArray(tilesWater, getThingfromPos({x=tilePos.x,y=tilePos.y,z=tilePos.z,stackpos=0}).itemid)
end

function isAvaliableTileWaterByPos(pos, forDragon, acceptMonsterWalkable)
  local items = {4825, 4820, 4821, 4822, 4823, 4824, 4619, 4666, 4608, 4613, 4614, 
           4664, 4616, 4618, 4617, 4619, 4665, 4611, 493, 5405, 5406, 5407, 5408, 5409, 5410, 15217, 15218, 15219, 15220, 15221, 15222, 15235, 15236, 15237, 15238, 15239, 15240}  

  local itemId = getThingfromPos({x=pos.x,y=pos.y,z=pos.z,stackpos=0}).itemid
	if itemId > 15000 and pos.z <= 7 then
		return false
	end
  -- Retorna false caso o tile seja "andavel" para os monstros
  if acceptMonsterWalkable then
    if isMonsteableWater(itemId) then
      return false
    end
  end
  -- FiM --

  if not forDragon then
    return isInArray(items, itemId)

  else
    for x = 1, #items do
      if itemId == items[x] then
        return x
      end
    end
  end

  return false
end

function isAvaliableItemWaterById(itemId)
  local items = {1378, 5739, 4648, 4649, 4650, 4651, 4652, 4653, 4654, 4655, 4656, 4657, 4656, 4657, 4658, 4659, 4660, 4661, 4662, 
                 7943, 7944, 7945, 7946, 7947, 7948, 7949, 7950, 7951, 7952, 7953, 7954, 5076, 5077, 5078, 5079, 1427, 1360, 1361, 1362, 1363,
                  1370, 1371, 1372, 1373, 1364, 1365, 1366, 1367, 5740, 12040, 12042, 12043, 5660, 17505, 17506, 17507, 17508, 17509, 17510, 17511, 17512, 17513, 17514, 17515, 17516, 17517, 17518, 17519, 17520}
  return isInArray(items, itemId)
end


--[Checa se o tile é "andavel por monstros", ex. embaixo da água]
function isMonsteableWater(itemId)
  local items = {5405, 5406, 5407, 5408, 5409, 5410, 15217, 15218, 15219, 15220, 15221, 15222, 15235, 15236, 15237, 15238, 15239, 15240}

  return isInArray(items, itemId)
end

function testItensWater(poses)
  local items = {4825, 4820, 4821, 4822, 4823, 4824, 4619, 4666, 4608, 4613, 4614, 
           4664, 4616, 4618, 4617, 4619, 4665, 4611, 493, 5405, 5406, 5407, 5408, 5409, 5410, 15217, 15218, 15219, 15220, 15221, 15222, 15235, 15236, 15237, 15238, 15239, 15240}
  for x = 1, #items do
    doCreateItem(items[x], poses[x])
    if tostring(x):len() == 1 then
      clockDraw({x=poses[x].x+1,y=poses[x].y,z=poses[x].z}, "00:0"..x)
    else
      clockDraw({x=poses[x].x+1,y=poses[x].y,z=poses[x].z}, "00:"..x)
    end
  end 
end

function isWaterWayFree(p1, p2, checkCreature)
  local p = {x=p1.x,y=p1.y,z=p1.z}
  for i=1,getDistanceBetween(p1,p2) do
    p = getPosByDir({x=p.x,y=p.y,z=p.z}, getDirectionTo(p, {x=p2.x,y=p2.y,z=p2.z}))
    p.stackpos = 255
    if isAvaliableTileWaterByPos(p) then
      return true
    end
    if not isWalkable(p) or (checkCreature and isCreature((getThingfromPos(p) or {uid=0}).uid)) then
      return false
    end
  end
  return true
end

function getPoses(p1, p2)
  local p = {x=p1.x,y=p1.y,z=p1.z}
  local tablePoses = {}
  if p1.x == p2.x and p1.y == p2.y then
    return true
  end
  for i=1,getDistanceBetween(p1,p2) do
    p = getPosByDir({x=p.x,y=p.y,z=p.z}, getDirectionTo(p, {x=p2.x,y=p2.y,z=p2.z}))
    table.insert(tablePoses, p)
  end
  return tablePoses
end


function getPlayerCanUseAmbientWater(cid, distance)
  local position = getCreaturePosition(cid)
  for x = -distance, distance do
    for y = -distance, distance do
      if isAvaliableTileWaterByPos({x=position.x+x,y=position.y+y,z=position.z}) == true then
        if isWaterWayFree(position, {x=position.x+x,y=position.y+y,z=position.z}) == true then
          return true
        end
      end
    end
  end
  return false
end


function getTimeInString(time)
  interval = time - os.time()
    timeTable = {}
    timeTable.hour = math.floor(interval/(60*60))
    timeTable.minute = math.floor((math.fmod(interval, 60*60))/60) 
    timeTable.second = math.fmod(math.fmod(interval, 60*60),60) 
    for i, v in pairs(timeTable) do
    if tostring(v):len() < 2 then
      timeTable[i] = "0"..timeTable[i]
      end
    end
    return timeTable
end

function clockDraw(pos, time)
if pos.x > 501 and pos.x < 520 and pos.y > 318 and pos.y < 327 and pos.z == 8 then 
	return false
end 
  local timeSepared, clockIds = {}, {}
  timeSepared[1] = string.sub(time, 1, 1)
  timeSepared[2] = string.sub(time, 2, 2)
  timeSepared[3] = string.sub(time, 3, 3)
  timeSepared[4] = string.sub(time, 4, 4)
  timeSepared[5] = string.sub(time, 5, 5)
  
  for k, v in pairs(clockParts) do
    table.insert(clockIds, v)
  end

  for counter = 0, 4 do
    removeTileItemByIds({x=pos.x+counter,y=pos.y,z=pos.z}, clockIds, nil, true)
  end

  for x = 1, #timeSepared do
    doCreateItem(clockParts[timeSepared[x]], {x=pos.x+(x-1),y=pos.y,z=pos.z})
  end
end

function clockWork(pos, time)
  local time = getTimeInString(time)
    clockDraw(pos, time.minute..":"..time.second)
end

function zerarClock(pos)
  clockDraw(pos, "00:00")
end

function sendTimesOnAnimatedText(pos, other, notIsTime)
   if notIsTime then
       doSendAnimatedText(pos, other, COLOR_GREY)      
   else
       local time = getTimeInString(other) 
      doSendAnimatedText(pos, time.minute..":"..time.second, COLOR_GREY)       
    end  
end

function getSecsString(sec)
  local sec = tonumber(sec)
  local days = 0
  local hours = 0
  local minutes = 0
  local seconds = 0

  repeat
    if sec >= 60 then
      minutes = minutes+1
      sec = sec-60
    end
  until sec < 60

  repeat
    if minutes >= 60 then
      hours = hours+1
      minutes = minutes-60
    end
  until minutes < 60

  repeat
    if hours >= 24 then
      days = days+1
      hours = hours-24
    end
  until hours < 24

  if days > 0 then
    if tostring(days):len() < 2 then
      days = "0"..days
    end
  end

  if hours > 0 then
    if tostring(hours):len() < 2 then
      hours = "0"..hours
    end
  end

  if minutes > 0 then
    if tostring(minutes):len() < 2 then
      minutes = "0"..minutes
    end
  end

  if sec > 0 then
    if tostring(sec):len() < 2 then
      sec = "0"..sec
    end
  end

  if tonumber(days) > 0 then
    return days.." day(s), "..hours.." hour(s), "..minutes.." minute(s) and "..sec.." second(s)"
  elseif tonumber(hours) > 0 then
    return hours.." hour(s), "..minutes.." minute(s) and "..sec.." second(s)"
  else
    if tonumber(minutes) > 0 then
      return minutes.." minute(s) and "..sec.." second(s)"
    else
      return sec.." second(s)"
    end
  end
end

function getTimeString(time)
  local time = getTimeInString(time)

  if tonumber(time.hour) > 24 then
    local days = 0
    repeat
      days = days+1
      time.hour = time.hour-24
    until time.hour < 24

    if tostring(time.hour):len() < 2 then
      time.hour = "0"..time.hour
      end

      if tostring(days):len() < 2 then
        days = "0"..days
      end

    return days.." day(s), "..time.hour.." hour(s), "..time.minute.." minute(s) and "..time.second.." second(s)" 
  end  

  if tonumber(time.hour) > 0 then
    return time.hour.." hour(s), "..time.minute.." minute(s) and "..time.second.." second(s)"
  else
    if tonumber(time.minute) > 0 then
      return time.minute.." minute(s) and "..time.second.." second(s)"
    else
      return time.second.." second(s)"  
    end
  end
end

function doPushCreature(uid, direction, distance, speed, ignoreMove, itsFlySpell, diagonalPos, onlyDir, _noJump)
  if isNpc(uid) or not isCreature(uid) or getCreatureSpeed(uid) < 30 then
    return false
  end
  if getCreatureNoMove(uid) and ignoreMove ~= true then
    return false
  end

  local pos = getThingPos(uid)
  local d, dir, newtile, rand
  local PARAM = {{1}, {500}}
  local DIRECTION = {{{0,0},{6,7},{1,3}}, {{1,1},{5,7},{0,2}}, {{2,2},{4,5},{1,3}}, {{3,3},{4,6},{0,2}},{{4,4},{2,3}}, {{5,5}, {1,2}}, {{6,6},{0,1}}, {{7,7},{0,3}}}
  table.insert(PARAM[1], distance)
  table.insert(PARAM[2], speed)
  for dvar = 1, #DIRECTION[direction+1] do
    rand = math.random(2)
    d = DIRECTION[direction+1][dvar][rand]
    dir = {x = (math.fmod(d,2)*(-(d-2))+math.floor(d/4)*math.fmod(d,2)*d-math.floor(d/4)), y = (((d-1)*(d-1-(d-1)*math.abs(d-2))*(1-math.floor(d/4)))-(math.floor(d/4)*(math.floor(d/6)*2-1)))}
    newtile = {x = (pos.x+dir.x), y = (pos.y+dir.y), z = pos.z}
    if diagonalPos then newtile = {x=diagonalPos.x, y=diagonalPos.y, z=diagonalPos.z} end
    if getPlayerCanWalk({player = uid, position = newtile, checkPZ = false, checkHouse = true, createTile = itsFlySpell and isPlayer(uid)}) then
      break
    elseif diagonalPos then
      newtile = {x = (pos.x+dir.x), y = (pos.y+dir.y), z = pos.z}
      if getPlayerCanWalk({player = uid, position = newtile, checkPZ = false, checkHouse = true, createTile = itsFlySpell and isPlayer(uid)}) then
        break
      end
    elseif onlyDir then
      return false
    end
    rand = (math.fmod(rand,2)+1)
    d = DIRECTION[direction+1][dvar][rand]
    dir = {x = (math.fmod(d,2)*(-(d-2))+math.floor(d/4)*math.fmod(d,2)*d-math.floor(d/4)), y = (((d-1)*(d-1-(d-1)*math.abs(d-2))*(1-math.floor(d/4)))-(math.floor(d/4)*(math.floor(d/6)*2-1)))}
    newtile = {x = (pos.x+dir.x), y = (pos.y+dir.y), z = pos.z}
    if diagonalPos then newtile = {x=diagonalPos.x, y=diagonalPos.y, z=diagonalPos.z} end
    if getPlayerCanWalk({player = uid, position = newtile, checkPZ = false, checkHouse = true, createTile = itsFlySpell and isPlayer(uid)}) then
      break
    elseif diagonalPos then
      newtile = {x = (pos.x+dir.x), y = (pos.y+dir.y), z = pos.z}
      if getPlayerCanWalk({player = uid, position = newtile, checkPZ = false, checkHouse = true, createTile = itsFlySpell and isPlayer(uid)}) then
        break
      end
    end
    if (dvar == #DIRECTION[direction+1]) then
      newtile = pos
    end
  end

  -- Primeira chamada: levita a criatura
  if not _noJump then
    local spd  = speed or PARAM[2][#PARAM[2]] or 500
    local dist = distance or PARAM[1][#PARAM[1]] or 1
    local floatDuration = dist * spd
    local specs = getSpectators(pos, 12, 12)
    if specs then
      local startPayload = "float|" .. uid .. "|" .. floatDuration
      for _, spec in ipairs(specs) do
        if isPlayer(spec) then
          doSendPlayerExtendedOpcode(spec, 108, startPayload)
        end
      end
    end
  end

  -- Move 1 sqm
  doTeleportThing(uid, newtile, true, true)

  if (PARAM[1][#PARAM[1]] > 1) then
    -- Ainda tem hops: continua
    addEvent(doPushCreature, PARAM[2][#PARAM[2]], uid, direction, (distance-1), speed, nil, nil, diagonalPos, true)
  else
    -- Último hop: pousa a criatura
    local specs2 = getSpectators(newtile, 12, 12)
    if specs2 then
      local stopPayload = "stopfloat|" .. uid
      for _, spec in ipairs(specs2) do
        if isPlayer(spec) then
          doSendPlayerExtendedOpcode(spec, 108, stopPayload)
        end
      end
    end
  end
end









function removeTileItemById(pos, itemId, effect)
  --[[if type(pos) ~= "table" then
    return false
  end--]]

  for i = 0, 255 do
    pos.stackpos = i
    local item = getThingFromPos(pos)
    if item.itemid == itemId then
      if effect ~= nil then
        doSendMagicEffect(pos, effect)
      end
      doRemoveItem(item.uid, 1)
      return true
    end
  end
  
   return false
end

function removeTileItemByIds(pos, itemIds, effect, actionid)
  for i = 0, 255 do
    pos.stackpos = i
    local item = getThingFromPos(pos)
    for x = 1, #itemIds do
      if item.itemid == itemIds[x] and (item.actionid == 0 or actionid == nil) then
        if effect ~= nil then
          doSendMagicEffect(pos, effect)
        end
        doRemoveItem(item.uid, 1)
        return true
      end
    end
  end
   return false
end

function changePosByDir(pos, dir, sqms)
  local direction = {{0,-1},{1,0},{0,1},{-1,0},{-1,1},{1,1},{-1,-1},{1,-1}}
  local delta = direction[dir+1]
  return {x=pos.x+delta[1]*sqms,y=pos.y+delta[2]*sqms,z=pos.z}
end

function doCreatureRemoveHealth(cid, value)
  if value < 0 then
    print("You can't use 'doCreatureRemoveHealth' with negative numbers.")
    return false
  end
  doSendAnimatedText(getCreaturePosition(cid), value, 156) 
  doCreatureAddHealth(cid, -value)
end


function setCreatureNoMoveTime(cid, time, immuneTime)
	if not immuneTime then
		immuneTime = 0
	elseif immuneTime > 0 then
		immuneTime = immuneTime + time
	end
	doCreatureSetNoMove(cid, false, time, immuneTime)
--	doPlayerCancelFollow(cid)
  --doCreatureSetNoMove(cid, true)
  --addEvent(valid(doCreatureSetNoMove), time, cid, false)
end

function cantReceiveDisable(caster, cid)
	if isMonster(cid) then 
		if getCreatureNoMove(cid) then
			if isPlayer(caster) then
				doPlayerSendCancelEf(caster, "Your target cant be disabled right now.")
			end
			return true
		end
		return false 
	end
	local immuneTimeEnd = getCreatureMoveImmuneTime(cid)
	if immuneTimeEnd > 0 then
		local restante = immuneTimeEnd - os.mtime()
		if restante > 0 then
			if isPlayer(caster) then
				if getLang(caster) == PT then
					doPlayerSendCancelEf(caster, "Seu alvo não pode sofrer prisões pelos próximos "..((math.round(restante/100))/10).."s.")
				else
					doPlayerSendCancelEf(caster, "Your target cant be disabled for the next "..((math.round(restante/100))/10).."s.")
				end
			end
			return true
		end
	end
	return false
end

function isDisableImmune(cid)
	if isMonster(cid) then 
		if getCreatureNoMove(cid) then
			return true
		end
		return false 
	end
	local immuneTimeEnd = getCreatureMoveImmuneTime(cid)
	if immuneTimeEnd > 0 then
		local restante = immuneTimeEnd - os.mtime()
		if restante > 0 then
			return true
		end
	end
	return false
end

function shuffleList(table)
  if not table then
      return {}
  end
  local newTable = {}
  local randOne, randTwo
  for x = 1, #table do
    newTable[x] = table[x]
  end
  for x = 1, (#newTable/2) do
    repeat
      randOne = math.random(1, #newTable)
      randTwo = math.random(1, #newTable)
    until randOne ~= randTwo
    mem = newTable[randOne]
    newTable[randOne] = newTable[randTwo]
    newTable[randTwo] = mem
  end
  return newTable
end

function itemAsEffect(items, pos)
  for x = 1, #items do
    for y = 1, #items[x] do
      addEvent(doCreateItem, 100*x, items[x][y], pos)
      addEvent(removeTileItemById, 100*x, pos, items[x][y])
    end
  end
end

function doTransformLever(item)
  if item.itemid == 1945 then
      doTransformItem(item.uid, 1946)
    else
        doTransformItem(item.uid, 1945)
    end
    return true
end

function registrePosesBetween(pos1, pos2, stackpos)
  local poses = {}
  for x = pos1.x, pos2.x do
    for y = pos1.y, pos2.y do
      table.insert(poses, {x=x,y=y,z=pos1.z, stackpos = stackpos})
    end
  end
  return poses
end

function clearItemsArea(area, ids)
  for h = 1, #area do
    for j = 1, #ids do
      removeTileItemById(area[h], ids[j])
    end  
  end
end

function doTeleportCreature(cid, pos, effect)
  if effect == nil or getPlayerAccess(cid) > 3 then
    doTeleportThing(cid, pos)
  else
    doSendMagicEffect(getThingPos(cid), effect)
    doTeleportThing(cid, pos)
    doSendMagicEffect(getThingPos(cid), effect)
  end
end

function getPlayerInPos(cid, posinicial, posfinal, andar) --by mirto
    local player_pos

    if type(cid) == "table" then
      player_pos = cid
    else
      player_pos = getPlayerPosition(cid)
    end
    
         local pos = {inicial = posinicial, final = posfinal}
         for s = 1, #pos do
             if pos.inicial[s] == nil or pos.final[s] == nil then
                return print('error in getPlayerInPos, parametros invalidos')
             end
         end
         if (player_pos.x <= pos.inicial.x and player_pos.y <= pos.inicial.y) and (player_pos.x >= pos.final.x and player_pos.y >= pos.final.y) then
            if not(andar == nil) then
               if player_pos.z == andar then
                  return true
               else
                  return false
               end
            else
               return true
            end
         else
            return false
         end
end

function table.search(string, table)
  for x = 1, #table do
    if table[x] == string then
      return true
    end
  end
  return false
end

function tileIsIce(pos)
  local tilesIds = {670, 671, 6580, 6581, 6582, 6583, 6584, 6585, 6586, 6587, 6588, 6589, 6590, 6591, 6592, 6593, 6594, 6595, 6596, 6597, 6598, 6599,
            6600, 6601, 6602, 6603, 6604, 6605, 6606, 6607, 6608, 6683, 6684, 6685, 6686}
  pos.stackpos = 0
  local itemId = getThingfromPos(pos).itemid
  for x = 1, #tilesIds do
    if itemId == tilesIds[x] then
      return true
    end
  end
  return false
end

function setWaterOnPounchPlayer(cid, water, waterPounch)
  local waterPounchFull = 4864
  local waterPounchEmpty = 4863
  local infinitePouchId = 18999
--  local waterPounch = getPlayerSlotItem(cid, 10)

  -- Agua milagrosa do oasis - item infinito, sempre retorna true
  if waterPounch.itemid == infinitePouchId then
    return true
  end

  if waterPounch.itemid == waterPounchFull or waterPounch.itemid == waterPounchEmpty then
    if water <= 0 or water == nil then
      if waterPounch.itemid == waterPounchFull then
        doTransformItem(waterPounch.uid, waterPounchEmpty)
      end
      sendWaterPounchToClient(cid, 0, false, waterPounch.uid ~= getPlayerSlotItem(cid, 10).uid)
      doItemSetAttribute(waterPounch.uid, "water", 0)
      doItemSetAttribute(waterPounch.uid, "description", "it is empty.")
    else
      if waterPounch.itemid == waterPounchEmpty then
        doTransformItem(waterPounch.uid, waterPounchFull)
      end
      doItemSetAttribute(waterPounch.uid, "water", water)
      sendWaterPounchToClient(cid, water, false, waterPounch.uid ~= getPlayerSlotItem(cid, 10).uid)
      doItemSetAttribute(waterPounch.uid, "description", "it is "..water.."% of water.")
    end
    return true
  else
    return false
  end
end

function setItemWaterFullByBorean(uid, isCan)
  if isCan == true then
    doItemSetAttribute(uid, "water", 100)    
  end
end

function playerHasWaterPounchInSlot(cid)
  local table = {}
  local waterPounchFull = 4864
  local waterPounchEmpty = 4863
  local slot = getPlayerSlotItem(cid, 10)

  if slot.itemid == waterPounchFull then
    table.full = true
    return table
  elseif slot.itemid == waterPounchEmpty then
    table.empty = true
    return table
  else
    return nil
  end
end

function setPlayerHasImune(cid, time)
  return setPlayerStorageValue(cid, "playerHasTotalAbsorve", os.time()+time)
end

local paralyzeCondition = createConditionObject(CONDITION_PARALYZE)
setConditionParam(paralyzeCondition, CONDITION_PARAM_TICKS, 3000)
setConditionFormula(paralyzeCondition, -0.9, 0, -0.9, 0)

function doFrozzenCreature(cid, time)
	if isNpc(cid) then
		return false
	end
	if getCreatureName(cid) == "Water Man" and isMonster(cid) then
		return false
	end
	if isDisableImmune(cid) then
		doSlow(0, cid, 25, 2500)
	    addEvent(function(cid, text, color)
			if isCreature(cid) then
				doSendAnimatedText(getThingPos(cid), text, color)
			end
		end, 300, cid, "Slowed!", COLOR_LIGHTBLUE) 
		return true
	end 
	local time = 3000
    local mypos = getThingPos(cid)
	if isPlayer(cid) then
		time = 2000
		doSendMagicEffect({x=mypos.x+1, y=mypos.y+1, z=mypos.z}, 139) --  custom animation com 2s
	else
		doSendMagicEffect({x=mypos.x+1, y=mypos.y+1, z=mypos.z}, 52)
	end
    --doAddCondition(cid, paralyzeCondition)
    doPlayerCancelFollow(cid) 
    setCreatureNoMoveTime(cid, time, time/2)
	if isPlayer(cid) then 
		exhaustion.set(cid, "stopDashs", 2) 
	end 
    addEvent(function(cid, text, color)
      if isCreature(cid) then
          doSendAnimatedText(getThingPos(cid), text, color)
      end
  end, 300, cid, "Frozzen!", COLOR_LIGHTBLUE)   
end

function filterString(cid, string) -- caso de tradução nas magias (temporario)
  return tr(cid, string)
end

function doPlayerSendCancelEf(cid, msg)
  if isPlayer(cid) then
    doPlayerSendCancel(cid, filterString(cid, msg))
    doSendMagicEffect(getThingPos(cid), 2, cid)
  end
end

function orgazineStrings(table)
  local string = ""
  for x = 1, #table do

    if x == #table-1 then
      string = string..table[x].." and "
    elseif x == #table then
      string = string..table[x]
    else
      string = string..table[x]..", "
    end
  end

  return string
end

function isPlayerBattle(cid)
  return getCreatureCondition(cid, CONDITION_INFIGHT) and not getTileInfo(getThingPos(cid)).protection
end

function isPlayerInExpCondition(cid)
  return getCreatureCondition(cid, CONDITION_SOUL)
end

function getElementId(element)
  local tableElements = {
  ["fire"] = 1,
  ["water"] = 2,
  ["earth"] = 4,
  ["air"] = 3
  }
  return tableElements[element]
end

function getAttack(v)
  if getItemAttribute(v.uid,'attack')  == nil then
    doItemSetAttribute(v.uid, "attack",getItemInfo(v.itemid).attack)
  end
  return tonumber(getItemAttribute(v.uid,'attack'))
end

function getArmor(v)
  if getItemAttribute(v.uid,'armor') == nil then
    doItemSetAttribute(v.uid, "armor",getItemInfo(v.itemid).armor)
  end
  return tonumber(getItemAttribute(v.uid,'armor'))
end

function getDefense(v)
  if getItemAttribute(v.uid,'defense') == nil then
    doItemSetAttribute(v.uid,"defense", getItemInfo(v.itemid).defense)
  end
  return tonumber(getItemAttribute(v.uid,'defense'))
end

function isItemArmor(v)
  if getArmor(v) ~= 0 then
    return true
  end
  return false
end

function isItemWeapon(v)
  if getAttack(v) ~= 0 then
    return true
  end
  return false
end

function isItemShield(v)
  if getDefense(v) ~= 0 and getAttack(v) == 0 then
    return true
  end
  return false
end

function isPickupableById(itemid)
  local weight = getItemDescriptionsById(itemid).weight
  if weight ~= 0 then
    return true
  else
    return false
  end
end

function setMiniGameRank(cid, miniGame, points)
  return db.executeQuery('INSERT INTO `gamesrank` (`name`, `points`, `game`) VALUES ("'..getCreatureName(cid)..'", "'..points..'", "'..miniGame..'")')
end

function getMiniGameRank(cid, miniGame, order, another, individual, showDisplay)
  --[[Order Type: ASC, DESC]]--

  local rankTable, string, result, names = {}, "", nil, {}

  if individual then
    result = db.getResult("SELECT * FROM gamesrank WHERE game = '"..string.lower(miniGame).."' AND name = '"..getCreatureName(cid).."' ORDER BY points "..order.." LIMIT 5")
  else
    result = db.getResult("SELECT * FROM gamesrank WHERE game = '"..string.lower(miniGame).."' ORDER BY points "..order.." LIMIT 10")
  end


  if (result:getID() ~= -1) then
       repeat
         table.insert(rankTable, {searchPoint = result:getDataInt("points"), searchName = result:getDataString("name")})
       until not result:next()
  end

  if individual then
    string = "-- My Personal Highscores --\n\n"
    if #rankTable == 0 then
      string = string.."[1] Empty"
      names = nil
    else
      for x = 1, #rankTable do
        if miniGame == "All Mini Games" then
          string = string.."["..x.."] "..rankTable[x].searchName.." - "..string.sub(rankTable[x].searchPoint, 1, 1)..string.sub(rankTable[x].searchPoint, 2, 2).."/"..string.sub(rankTable[x].searchPoint, 3, 3)..string.sub(rankTable[x].searchPoint, 4, 4).."/"..string.sub(rankTable[x].searchPoint, 5, 5)..string.sub(rankTable[x].searchPoint, 6, 6).."\n"  
        else
          string = string.."["..x.."] "..rankTable[x].searchName.." - "..rankTable[x].searchPoint.." "..another.."\n"
        end
      end
    end

  else
    string = "-- Global "..miniGame.." Highscores --\n\n"
    for x = 1, 10 do
      if miniGame == "All Mini Games" then
        if rankTable[x] ~= nil then
          string = string.."["..x.."] "..rankTable[x].searchName.." - "..string.sub(rankTable[x].searchPoint, 1, 1)..string.sub(rankTable[x].searchPoint, 2, 2).."/"..string.sub(rankTable[x].searchPoint, 3, 3)..string.sub(rankTable[x].searchPoint, 4, 4).."/"..string.sub(rankTable[x].searchPoint, 5, 5)..string.sub(rankTable[x].searchPoint, 6, 6).."\n"
        else
          string = string.."["..x.."] Empty\n"  
        end
      else
        if rankTable[x] ~= nil then
          string = string.."["..x.."] "..rankTable[x].searchName.." - "..rankTable[x].searchPoint.." "..another.."\n"
          table.insert(names, rankTable[x].searchName)
        else
          string = string.."["..x.."] Empty\n"
        end
      end
    end
  end

  if showDisplay == false then
    local bla = nil
  else
    doShowTextDialog(cid, 1810, string) 
  end

  if individual then
    return names
  else
    return true
  end

end

function setPlayerHasDeath(cid, killedBy, expLoss, hasBless)
  if expLoss < 0 then
    return
  end

  if hasBless then
    hasBless = 1
  else
    hasBless = 0
  end
  return db.executeQuery('INSERT INTO `deaths_record` (`name`, `id`, `expLost`, `date`, `monsterName`, `bless`) VALUES ("'..getCreatureName(cid)..'", "'..getPlayerGUID(cid)..'", "'..expLoss..'", "'..os.time()..'", "'..killedBy..'", "'..hasBless..'")')  
end

function setExpBackupToPlayers(hoursAgo)
  local result = db.getResult("SELECT * FROM deaths_record WHERE date > '"..os.time()-(hoursAgo*20*60).."' AND used = 0 ORDER BY date DESC")

  if (result:getID() ~= -1) then
       repeat
         db.executeQuery("UPDATE `deaths_record` SET `used` = 1 WHERE `id` = '"..result:getDataInt("id").."' AND `date` = '"..result:getDataInt("date").."'")
         db.executeQuery("INSERT INTO `deaths_record_touse` (`id`, `expLost`, `bless`) VALUES ('"..result:getDataInt("id").."', '"..result:getDataInt("expLost").."', '"..result:getDataInt("bless").."')")
       until not result:next()
  end  
end

function setExpBackUpToPlayer(hoursAgo, playerName)
  local result = db.getResult("SELECT * FROM deaths_record WHERE date > '"..os.time()-(hoursAgo*60*60).."' AND used = 0 AND name = '"..playerName.."' ORDER BY date DESC")

  if (result:getID() ~= -1) then
       repeat
         db.executeQuery("UPDATE `deaths_record` SET `used` = 1 WHERE `id` = '"..result:getDataInt("id").."' AND `date` = '"..result:getDataInt("date").."'")
         db.executeQuery("INSERT INTO `deaths_record_touse` (`id`, `expLost`, `bless`) VALUES ('"..result:getDataInt("id").."', '"..result:getDataInt("expLost").."', '"..result:getDataInt("bless").."')")
       until not result:next()
  end  
end

function sendBackupToPlayer(cid)
  local playerGuid, hasWorked = getPlayerGUID(cid), false
  local result = db.getResult("SELECT * FROM deaths_record_touse WHERE id = '"..playerGuid.."' ORDER BY expLost DESC")
  local maxRepeats, current = 100, 0

  if (result:getID() ~= -1) then
       repeat
         current = current+1
         doPlayerAddExperience(cid, result:getDataInt("expLost"))
		setPlayerStorageValue(cid, "hasPassiveDeathActive", os.time())
         doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You received your experience lost in your last death. We apologize for the inconvenience.", "Devido a queda de conexão, você recebeu a experiência da sua última morte, pedimos deculpas pelo transtorno."))
         if result:getDataInt("bless") == 1 and getPlayerStorageValue(cid, "playerWithBless") ~= 1 then
           setPlayerStorageValue(cid, "playerWithBless", 1)
           doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You has received the blessing of Sony.", "Você recebeu a benção de Sony."))
         end
         db.executeQuery("DELETE FROM deaths_record_touse WHERE id = "..playerGuid.." AND expLost = "..result:getDataInt("expLost"))
         hasWorked = true
       until not result:next() or current > maxRepeats
  end  

  return hasWorked
end

function sendBackupExpToAllPlayersOnline()
  for _, pid in pairs(getPlayersOnline()) do
    sendBackupToPlayer(pid)  
  end
end

function isWaterBlock(pos)
  local ids = {4664, 4666, 4665, 4608, 4611, 4665, 4609, 4610, 4612, 4613, 4614, 4615, 4616, 4617, 4618, 4619, 13264}
  return isInArray(ids, getThingfromPos({x=pos.x,y=pos.y,z=7,stackpos=0}).itemid)
end

function doDamage(attacker, cid, combat, value)
  if(combat == 16) then
    return true
  end
  doTargetCombatHealth(attacker, cid, combat, -value, -value, 0)   
  return false
end

function getTotalItensInContainer(uid, number)
  local number = number or 0
  
  if not isContainer(uid) then
    return false
  end

  for x = 0, getContainerCap(uid) do
    local currentItem = getContainerItem(uid, x)
    if currentItem.uid > 0 then
      if isContainer(currentItem.uid) then
        number = number+getTotalItensInContainer(currentItem.uid, 1)
      else
        number = number+1
      end
    end
  end
  return number
end

function getItensInContainer(uid)
  if not isContainer(uid) then
    return false
  end

  local items = {}
  for x = 0, getContainerCap(uid) do
    local currentItem = getContainerItem(uid, x)

    if currentItem.uid > 0 then
      table.insert(items, currentItem)
    end
  end

  return items --getThing(uid)
end

function registerPosInStorage(cid, storage, pos)
  setPlayerStorageValue(cid, storage.."X", pos.x)
  setPlayerStorageValue(cid, storage.."Y", pos.y)
  setPlayerStorageValue(cid, storage.."Z", pos.z)  
end

function getPosInStorage(cid, storage)
  return {x=getPlayerStorageValue(cid, storage.."X"),y=getPlayerStorageValue(cid, storage.."Y"),z=getPlayerStorageValue(cid, storage.."Z")}
end

function getPlayerHasInQuest(cid, questName)
  return getPlayerStorageValue(cid, "genericQuestString") == questName and getPlayerStorageValue(cid, "hasActiveInQuest") == 1
end

function registerPlayerInQuest(params) --{player, posExit, globalStorage, cannotMoveItems, cantUseSpells, blockDeath}
  local cantUseSpells = params.cantUseSpells or {}

  if params.cannotMoveItems then
    params.cannotMoveItems = 1
  else
    params.cannotMoveItems = -1
  end

  setPlayerStorageValue(params.player, "hasActiveInQuest", 1)
  setPlayerStorageValue(params.player, "genericQuestString", params.globalStorage)
  setPlayerStorageValue(params.player, "playerCanMoveItemsGenericQuest", params.cannotMoveItems)
  registerPosInStorage(params.player, "genericQuestPos", params.posExit)

  if params.blockDeath then
    setPlayerStorageValue(params.player, "genericQuestBlockDeath", 1)
  else
    setPlayerStorageValue(params.player, "genericQuestBlockDeath", -1)
  end

  for x = 1, 20 do
    if cantUseSpells[x] then
      setPlayerStorageValue(params.player, "canUseSpell"..x, cantUseSpells[x])
    else
      setPlayerStorageValue(params.player, "canUseSpell"..x, -1)
    end
  end
end

function getPointsUsedInSkill(cid, skill)
  if skill == "hp" or skill == "health" or skill == "life" then
    return math.max(1, getPlayerStorageValue(cid, "getPointsInHealth")+1)-1
  elseif skill == "mana" then
    return math.max(1, getPlayerStorageValue(cid, "getPointsInMana")+1)-1
  elseif skill == "bend level" or skill == "bend" then
    return (math.max(1, getPlayerStorageValue(cid, "getPointsInBendLevel")+1)-1)
  elseif skill == "dodge" then
    return math.max(1, getPlayerStorageValue(cid, "getPointsInDodge")+1)-1

  elseif skill == "stones" or skill == "stone" then
    return math.max(1, getPlayerStorageValue(cid, "getPointsInStones")+1)-1
  else
    print("Error in getPointsUsedInSkill(cid, skill)")
  end
end

function addPointsInSkill(cid, skill, points)
  if skill == "hp" or skill == "health" or skill == "life" then
    return setPlayerStorageValue(cid, "getPointsInHealth", getPointsUsedInSkill(cid, skill)+points)
  elseif skill == "mana" then
    return setPlayerStorageValue(cid, "getPointsInMana", getPointsUsedInSkill(cid, skill)+points)
  elseif skill == "bend level" or skill == "bend" then
    return setPlayerStorageValue(cid, "getPointsInBendLevel", getPointsUsedInSkill(cid, skill)+points)
  elseif skill == "dodge" then
    return setPlayerStorageValue(cid, "getPointsInDodge", getPointsUsedInSkill(cid, skill)+points)

  elseif skill == "stone" or skill == "stones" then
    return setPlayerStorageValue(cid, "getPointsInStones", getPointsUsedInSkill(cid, skill)+points)
  else
    print("Error in addPointsInSkill(cid, skill, points)")
  end
end

function addPlayerBan(guid_name, seconds, reason)
  doAddPlayerBanishment(guid_name, PLAYERBAN_BANISHMENT, os.time()+seconds, reason or "Broke the rules.")

  local cid = getPlayerByName(guid_name)
  if isPlayer(cid) then
    return doRemoveCreature(cid)
  else
    return true
  end
end

function getFragTimes(cid)
  return db.getResult("SELECT `fragTime` FROM `players` WHERE id = "..getPlayerGUID(cid)):getDataInt("fragTime")
end

function addFragTimeInPlayer(cid)
  local time, timePut = getFragTimes(cid), 0
  local config = {fragTime = getConfigValue('fragTime')}

  if time < os.time() then
    timePut = os.time()+config.fragTime
  else
    timePut = time+config.fragTime
  end

  db.executeQuery("UPDATE `players` SET `fragTime` = "..timePut.." WHERE id = "..getPlayerGUID(cid))
  return timePut
end

function getPlayerFrags(cid)
  local timeLimit, config = getFragTimes(cid), {fragTime = getConfigValue('fragTime')}

  return math.ceil((timeLimit-os.time())/config.fragTime)
end


function doSendItensToDepot(name, town, itens, isDonation, msg)
  --[[itens = {{itemId = x, amount = x}}]]--
  if playerExists(name) then
    local parcel = doCreateItemEx(ITEM_PARCEL)

    for x = 1, #itens do
      doAddContainerItem(parcel, itens[x].itemId, itens[x].amount or 1)
    end

    if isDonation then
      local msg = msg or ""

      local letter = doCreateItemEx(ITEM_LETTER)
      doSetItemText(letter, msg, "Avatar Team", os.time(), false)
      doAddContainerItemEx(parcel, letter)
    end

    return doPlayerSendMailByName(name, parcel, town) 
  end
end

function removePotionExp(cid)
  if isPlayer(cid) then
    doPlayerSendCancel(cid, getLangString(cid, "Your pot of experience has ended.", "Seu potion de expêriencia terminou."))
    if isPremium(cid) then
      doPlayerSetExperienceRate(cid, 1.1)
    else
      doPlayerSetExperienceRate(cid, 1)
    end
    doSendMagicEffect(getThingPos(cid), 13)
  end
end

function selectLang(cid)
  local result = db.getResult("SELECT * FROM accounts WHERE id = '"..getPlayerAccountId(cid).."'")
  if result:getDataInt("lang_server") == 1 then
    setLang(cid, EN)
  else
    setLang(cid, PT)
  end
end

function doPlayerResetMagicLevel(cid, keepBend)
  if type(keepBend) ~= "number" or keepBend < 0 then
    keepBend = 0
  end
  local guid = getPlayerGUID(cid)
  doRemoveCreature(cid)
  db.executeQuery('UPDATE `players` SET `maglevel` = "'..(keepBend)..'", `manaspent` = "0" WHERE `id` = "'..guid..'"')
end

function getPlayerItens(cid, itens) --itens = {itemid = x, amount = x}
  for x = 1, #itens do
    if getPlayerItemCount(cid, itens[x].itemid) < itens[x].amount then
      return false
    end
  end

  return true
end

function doPlayerRemoveItens(cid, itens)
  if getPlayerItens(cid, itens) then
    for x = 1, #itens do
      doPlayerRemoveItem(cid, itens[x].itemid, itens[x].amount)
    end
    return true
  else
    return false
  end
end


function addPlayerTimeOnline(cid, secs)
  if not isPlayer(cid) then return end
  local guid = getPlayerGUID(cid)
  if not guid or guid == 0 then return end
  local result = db.getResult("SELECT * FROM players WHERE id = '"..guid.."'")
  if result:getID() == -1 then return end
  local timeLogin = getPlayerStorageValue(cid, "timeLogin")
  if not timeLogin or timeLogin == -1 then timeLogin = os.time() end
  local newTime = result:getDataInt("timeOnline") + (os.time() - timeLogin)
  if newTime < 0 then newTime = 0 end
  db.executeQuery('UPDATE `players` SET `timeOnline` = "'..newTime..'" WHERE `id` = "'..guid..'"')
end

function getWeaponSkill(itemuid)
    if itemuid == 0 then
        return 0
    end

    local skill = {[0] = 0, [1] = 2, [2] = 1, [3] = 3, [7] = 4, [6] = 7}
    return skill[getItemWeaponType(itemuid)]
end

function canDoAttack(cid, target)
  if cid == target then
    return false
  end

  if isMonster(cid) and isMonster(target) then
    -- Aqui falta dar uma melhorada, colocar caso tenha master e etc; (summon)
    return false;
  end


  -- Checa se a vitima o master do summon, membro da party, ela mesmo e etc;
  if isPlayer(target) then
    local currentParty = nil
    local master = getCreatureMaster(cid)

    if master ~= nil then
      if master == target then
        return false
      end

      currentParty = getPlayerParty(master)
    else
      if not isPlayer(cid) then
        return false
      end

      currentParty = getPlayerParty(cid)
    end

    if currentParty ~= nil then
      local partyMembers = getPartyMembers(currentParty)

      if partyMembers then

        for index, member in pairs(partyMembers) do
          if member == target then
            return false
          end
        end
      end
    end
  end

  return true
end

function banimentoBot(cid)
	if getPlayerStorageValue(cid, "antibotSecond") ~= 1 then
		setPlayerStorageValue(cid, "antibotSecond", 1)
		addPlayerBan(getPlayerName(cid), 4*60*60, "[Anti-Bot System] Primeiro banimento com duração de 4h, aguarde o fim de sua punição.")
	elseif getPlayerStorageValue(cid, "antibotThird") ~= 1 then
		setPlayerStorageValue(cid, "antibotThird", 1)
		addPlayerBan(getPlayerName(cid), 24*60*60, "[Anti-Bot System] Segundo banimento com duração de 24h, aguarde o fim de sua punição.")
	else
		addPlayerBan(getPlayerName(cid), 7*24*60*60, "[Anti-Bot System] Terceiro banimento com duração de 7 dias, aguarde o fim de sua punição.")
	end
	-- todo: primeira vez 4h, depois 24h e entao 7 dias
	return true
end

function checkafkBot(cid)
	if isCreature(cid) then
		if getPlayerStorageValue(cid, "ativoBot") == 1 and os.time() > getPlayerStorageValue(cid, "horarioBot") then
			local theName = getCreatureName(cid)
			banimentoBot(cid)
			print("[Anti-Bot] Jogador "..theName.." banido.")
		end
	end
	return true
end

function keepShowQuestion(cid, valorUm, operador, valorDois)
if not isCreature(cid) then return false end 

 if getPlayerStorageValue(cid, "ativoBot") == 1 and os.time() < getPlayerStorageValue(cid, "horarioBot") then
	local playerPos = getCreaturePosition(cid)
    addEvent(function(cid) if isCreature(cid) then doSendAnimatedText({x=playerPos.x-1, y=playerPos.y, z=playerPos.z}, valorUm, 215, cid) end end, math.random(50, 75), cid)
    doSendAnimatedText(getCreaturePosition(cid), operador, 215, cid)
    addEvent(function(cid) if isCreature(cid) then doSendAnimatedText({x=playerPos.x+1, y=playerPos.y, z=playerPos.z}, valorDois, 215, cid) end end, math.random(50, 75), cid)
    addEvent(keepShowQuestion, math.random(1000, 1500), cid, valorUm, operador, valorDois)
  end 

end

function verifyBot(cid)
	local valorUm = math.random(1, 10)
	local valorDois = math.random(1, 10)
	local resposta = valorUm + valorDois
	local operador = " + "
	if valorUm > valorDois and math.random(1, 100) > 50 then -- subtrair
		resposta = valorUm - valorDois
		operador = " - "
	end
	local curta = getLangString(cid, "Look on screen.", "Veja na tela.")
	local textoENG = "[Anti-Bot Question] Question shown by floating animation on top of your character, look at the screen. To respond, type in the transparent window that appeared the result of the question."
	local textoBR = "[Anti-Bot Question] Questão mostrada por animação flutuante em cima de seu personagem, observe na tela. Para responder, digite na janela transparente que apareceu o resultado da questão."
	setPlayerStorageValue(cid, "respostaBot", resposta)
	setPlayerStorageValue(cid, "horarioBot", os.time() + 120) -- usar como base pro cooldown
	setPlayerStorageValue(cid, "ativoBot", 1)
	setPlayerStorageValue(cid, "valorUmBot", valorUm)
	setPlayerStorageValue(cid, "valorDoisBot", valorDois)
	setPlayerStorageValue(cid, "operadorBot", operador)
	setPlayerStorageValue(cid, "trysBot", 3)
	keepShowQuestion(cid, valorUm, operador, valorDois)
	sendBlueMessage(cid, getLangString(cid, textoENG, textoBR))
	doSendPlayerExtendedOpcode(cid, 167, curta .. ",120")
	addEvent(checkafkBot, (2*60*1000)+3000, cid) -- nao respondeu
	return true
end

function sendItemTierOpcode(cid, itemUid)
	if not isPlayer(cid) or not itemUid or itemUid <= 0 then return end
	local tier = getItemAttribute(itemUid, "tier")
	if tier ~= nil and tier ~= "" then
		tier = tonumber(tier) or 0
		if tier > 0 and tier <= 10 then
			local item = getThing(itemUid)
			if item and item.itemid > 0 then
				local clientId = 0
				local ok, result = pcall(ItemType, item.itemid)
				if ok and result and not result:isNull() then
					local c = result:getClientId()
					if c and c > 0 then clientId = c end
				end
				if clientId == 0 then clientId = item.itemid end
				doSendPlayerExtendedOpcode(cid, 111, "set," .. clientId .. "," .. tier)
			end
		end
	end
end

function syncPlayerItemTiers(cid)
	if not isPlayer(cid) then return end

	local function checkAndSend(itemUid)
		if not itemUid or itemUid <= 0 then return end
		sendItemTierOpcode(cid, itemUid)
		if isContainer(itemUid) then
			local size = getContainerSize(itemUid)
			for slot = 0, size - 1 do
				local subItem = getContainerItem(itemUid, slot)
				if subItem and subItem.uid > 0 then
					checkAndSend(subItem.uid)
				end
			end
		end
	end

	for slot = 1, 10 do
		local item = getPlayerSlotItem(cid, slot)
		if item and item.uid > 0 then
			checkAndSend(item.uid)
		end
	end
end

