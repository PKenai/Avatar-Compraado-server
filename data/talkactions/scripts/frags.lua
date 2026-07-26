--[[function onSay(cid, words, param, channel)
  if(not getBooleanFromString(getConfigValue('useFragHandler'))) then
    return false
  end

  local time = os.time()
  local times = {today = (time - 86400), week = (time - (7 * 86400))}

  local contents, result = {day = {}, week = {}, month = {}}, db.getResult("SELECT `pd`.`date`, `pd`.`level`, `p`.`name` FROM `player_killers` pk LEFT JOIN `killers` k ON `pk`.`kill_id` = `k`.`id` LEFT JOIN `player_deaths` pd ON `k`.`death_id` = `pd`.`id` LEFT JOIN `players` p ON `pd`.`player_id` = `p`.`id` WHERE `pk`.`player_id` = " .. getPlayerGUID(cid) .. " AND `k`.`unjustified` = 1 AND `k`.`war` = 0 AND `pd`.`date` >= " .. (time - (30 * 86400)) .. " ORDER BY `pd`.`date` DESC")
  
  if(result:getID() ~= -1) then
    repeat
      local content = {
        name = result:getDataString("name"),
        level = result:getDataInt("level"),
        date = result:getDataInt("date")
      }
      if(content.date > times.today) then
        table.insert(contents.day, content)
      elseif(content.date > times.week) then
        table.insert(contents.week, content)
      else
        table.insert(contents.month, content)
      end
    until not result:next()
    result:free()
  end

  local size = {
    day = table.maxn(contents.day),
    week = table.maxn(contents.week),
    month = table.maxn(contents.month)
  }

  if(getBooleanFromString(getConfigValue('advancedFragList'))) then

    local result = "Frags gained today: " .. size.day .. "."
    
    if(size.day > 0) then
      for _, content in ipairs(contents.day) do
        result = result .. "\n* " .. os.date("%d %B %Y %X at ", content.date) .. content.name .. " on level " .. content.level
      end

      result = result .. "\n"
    end

    result = result .. "\nFrags gained this week: " .. (size.day + size.week) .. "."
    if(size.week > 0) then
      for _, content in ipairs(contents.week) do
        result = result .. "\n* " .. os.date("%d %B %Y %X at ", content.date) .. content.name .. " on level " .. content.level
      end

      result = result .. "\n"
    end

    result = result .. "\nFrags gained this month: " .. (size.day + size.week + size.month) .. "."
    if(size.month > 0) then
      for _, content in ipairs(contents.month) do
        result = result .. "\n* " .. os.date("%d %B %Y %X at ", content.date) .. content.name .. " on level " .. content.level
      end

      result = result .. "\n"
    end

    local skullEnd = getPlayerSkullEnd(cid)
    if(skullEnd > 0) then
      result = result .. "\nYour " .. (getCreatureSkullType(cid) == SKULL_RED and "red" or "black") .. " skull will expire at " .. os.date("%d %B %Y %X", skullEnd)
    end

    doPlayerPopupFYI(cid, result)
  else
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You currently have " .. (size.day + size.week) .. " this week.")
    if(size.week > 0) then
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Last frag at " .. os.date("%d %B %Y %X", contents.day[1].date) .. " on level " .. contents.day[1].level .. " (" .. contents.day[1].name .. ").")
    end

    local skullEnd = getPlayerSkullEnd(cid)
    if(skullEnd > 0) then
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Your " .. (getCreatureSkullType(cid) == SKULL_RED and "red" or "black") .. " skull will expire at " .. os.date("%d %B %Y %X", skullEnd))
    end
  end

  return true
end--]]

local config = {
  fragsToRedSkull = getConfigValue('fragsToRedSkull'),
  redSkullLength = getConfigValue('redSkullLength'),
  fragTime = getConfigValue('fragTime'),
  fragsToBanishment = getConfigValue('fragsToBanishment'),
  banKillLength = getConfigValue('banKillLength'),
  countLimit = 7 * 10 * 60 * 60
}

function onSay(cid, words, param, channel)
  local timeLimit, fragsNumber, string, isGmString

  if param ~= "" and getPlayerGroupId(cid) >= 5 then
    local pid = getCreatureByName(param)
    if isPlayer(pid) then
      timeLimit, fragsNumber, string, isGmString = getFragTimes(pid), getPlayerFrags(pid), "", getCreatureName(pid)..": "
    else
      sendBlueMessage(cid, "A player with this name is not exist.")
      return true
    end
  else
    timeLimit, fragsNumber, string = getFragTimes(cid), getPlayerFrags(cid), ""
  end

  local isGmString = isGmString or ""

  if timeLimit > os.time() then
    string = getLangString(cid, isGmString.."Current Frags: "..fragsNumber..".\n\nYour(s) frag(s) will expire in: "..getSecsString(timeLimit-os.time())..".\n\nAttention: with "..config.fragsToRedSkull.." frags you will get a Red Skull.",
    isGmString.."Frags Ativas: "..fragsNumber..".\n\nSua(s) frag(s) vão(ai) expirar em: "..getSecsString(timeLimit-os.time())..".\n\nAtenção: com "..config.fragsToRedSkull.." frags você ganhará Red Skull.")
  else
    string = getLangString(cid, isGmString.."Congratulations! You don't have any active frag.", isGmString.."Parábens! Você não possui nenhuma frag ativa.")
  end

  doPlayerPopupFYI(cid, string)
  return true
end
