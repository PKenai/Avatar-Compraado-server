--[[
 * Daily Hunt System
 * Cada jogador recebe 5 monstros aleatórios para matar 250 de cada por dia.
 * 2/5 completos → 10% do level atual como XP
 * 5/5 completos → 50% do level atual como XP
 * Reseta quando o servidor reinicia (GlobalSaveDays muda)
]]

DailyHunt = {
  opcode = 166,
  monstersPerDay = 5,
  killsRequired = 250,
}

-- Carrega TODAS as criaturas do monsters.xml via função C++ nativa
-- NOTA: não carregamos aqui porque quando a lib é carregada,
-- monsters.xml ainda não foi parseado. Carregamos lazy (sob demanda).
DailyHunt.allMonsters = nil
DailyHunt.allMonstersLoaded = false

function DailyHunt.loadMonsters()
  if DailyHunt.allMonstersLoaded then
    return true
  end

  local ok, list = pcall(getMonsterTypeList)
  if ok and type(list) == "table" and #list > 0 then
    local seen = {}
    DailyHunt.allMonsters = {}
    for _, name in ipairs(list) do
      local lower = name:lower()
      if not seen[lower] then
        seen[lower] = true
        table.insert(DailyHunt.allMonsters, name)
      end
    end
    DailyHunt.allMonstersLoaded = true
    print("[DailyHunt] Loaded " .. #DailyHunt.allMonsters .. " monsters from getMonsterTypeList()")
    return true
  end

  print("[DailyHunt] getMonsterTypeList() not available yet, will retry on next request")
  return false
end

function DailyHunt.getPlayerDay(cid)
  return getPlayerStorageValue(cid, "DailyHunt_Day")
end

function DailyHunt.setPlayerDay(cid, day)
  setPlayerStorageValue(cid, "DailyHunt_Day", day)
end

function DailyHunt.getMonsterName(cid, slot)
  return getPlayerStorageValue(cid, "DailyHunt_Monster_" .. slot)
end

function DailyHunt.setMonsterName(cid, slot, name)
  setPlayerStorageValue(cid, "DailyHunt_Monster_" .. slot, name)
end

function DailyHunt.getKillCount(cid, slot)
  local count = getPlayerStorageValue(cid, "DailyHunt_Kill_" .. slot)
  if type(count) ~= "number" or count < 0 then
    return 0
  end
  return count
end

function DailyHunt.setKillCount(cid, slot, count)
  setPlayerStorageValue(cid, "DailyHunt_Kill_" .. slot, count)
end

function DailyHunt.getCompletedSlots(cid)
  local completed = 0
  for i = 1, DailyHunt.monstersPerDay do
    if DailyHunt.getKillCount(cid, i) >= DailyHunt.killsRequired then
      completed = completed + 1
    end
  end
  return completed
end

function DailyHunt.getRewardClaimed(cid, milestone)
  local val = getPlayerStorageValue(cid, "DailyHunt_Claimed_" .. milestone)
  return val == 1
end

function DailyHunt.setRewardClaimed(cid, milestone)
  setPlayerStorageValue(cid, "DailyHunt_Claimed_" .. milestone, 1)
end

function DailyHunt.generateNewHunt(cid)
  if not DailyHunt.loadMonsters() or #DailyHunt.allMonsters == 0 then
    print("[DailyHunt] ERROR: no monsters available, cannot generate hunt!")
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Daily Hunt is not available yet. Try again in a few seconds."
    )
    return
  end

  local pool = {}
  for _, name in ipairs(DailyHunt.allMonsters) do
    table.insert(pool, name)
  end

  local selected = {}
  for i = 1, DailyHunt.monstersPerDay do
    if #pool == 0 then break end
    local idx = math.random(1, #pool)
    local monster = pool[idx]
    table.remove(pool, idx)
    table.insert(selected, monster)
  end

  local day = getDayID()
  DailyHunt.setPlayerDay(cid, day)
  for i = 1, DailyHunt.monstersPerDay do
    local name = selected[i] or DailyHunt.allMonsters[math.random(1, #DailyHunt.allMonsters)]
    DailyHunt.setMonsterName(cid, i, name)
    DailyHunt.setKillCount(cid, i, 0)
  end

  setPlayerStorageValue(cid, "DailyHunt_Claimed_2", 0)
  setPlayerStorageValue(cid, "DailyHunt_Claimed_5", 0)

  return selected
end

function DailyHunt.sendDataToClient(cid)
  if not DailyHunt.allMonstersLoaded then
    DailyHunt.loadMonsters()
  end

  local day = DailyHunt.getPlayerDay(cid)
  local currentDay = getDayID()

  -- If day changed, generate new hunt
  if day ~= currentDay then
    DailyHunt.generateNewHunt(cid)
  end

  -- Build pipe-delimited string for client with outfit data
  local monsterNames = {}
  local killCounts = {}
  local outfits = {}

  for i = 1, DailyHunt.monstersPerDay do
    local name = DailyHunt.getMonsterName(cid, i)
    if name == -1 or type(name) ~= "string" then
      name = "Unknown"
    end
    table.insert(monsterNames, name)
    table.insert(killCounts, tostring(DailyHunt.getKillCount(cid, i)))

    -- Get monster outfit: try live creature first, fallback to monster info
    local lookType = 0
    local lookHead = 0
    local lookBody = 0
    local lookLegs = 0
    local lookFeet = 0
    local lookAddons = 0

    local creature = getCreatureByName(name)
    if creature then
      local outfit = getCreatureOutfit(creature)
      if outfit then
        lookType = outfit.lookType or 0
        lookHead = outfit.lookHead or 0
        lookBody = outfit.lookBody or 0
        lookLegs = outfit.lookLegs or 0
        lookFeet = outfit.lookFeet or 0
        lookAddons = outfit.lookAddons or 0
      end
    end

    if lookType == 0 then
      local monsterInfo = getMonsterInfo(name)
      if monsterInfo and monsterInfo.outfit then
        lookType = monsterInfo.outfit.lookType or 0
        lookHead = monsterInfo.outfit.lookHead or 0
        lookBody = monsterInfo.outfit.lookBody or 0
        lookLegs = monsterInfo.outfit.lookLegs or 0
        lookFeet = monsterInfo.outfit.lookFeet or 0
        lookAddons = monsterInfo.outfit.lookAddons or 0
      end
    end

    table.insert(outfits, string.format("%d_%d_%d_%d_%d_%d_%d",
      lookType, lookHead, lookBody, lookLegs, lookFeet, lookAddons, 0))
  end

  local reward2 = DailyHunt.getRewardClaimed(cid, 2) and 1 or 0
  local reward5 = DailyHunt.getRewardClaimed(cid, 5) and 1 or 0

  local data = "day:" .. currentDay
    .. "|monsters:" .. table.concat(monsterNames, ",")
    .. "|kills:" .. table.concat(killCounts, ",")
    .. "|killsRequired:" .. DailyHunt.killsRequired
    .. "|outfits:" .. table.concat(outfits, ";")
    .. "|rewards:" .. reward2 .. "," .. reward5

  doSendPlayerExtendedOpcode(cid, DailyHunt.opcode, data)
end

function DailyHunt.onMonsterKill(cid, monsterName)
  local day = DailyHunt.getPlayerDay(cid)
  local currentDay = getDayID()

  if day ~= currentDay then
    DailyHunt.generateNewHunt(cid)
    return
  end

  local lowerKill = monsterName:lower()

  for i = 1, DailyHunt.monstersPerDay do
    local targetName = DailyHunt.getMonsterName(cid, i)
    if targetName and type(targetName) == "string" and targetName:lower() == lowerKill then
      local current = DailyHunt.getKillCount(cid, i)
      if current < DailyHunt.killsRequired then
        current = current + 1
        DailyHunt.setKillCount(cid, i, current)

        -- Check milestones
        local completed = DailyHunt.getCompletedSlots(cid)

        -- Reward for 2 monsters completed (10% of current level XP)
        if current >= DailyHunt.killsRequired and completed >= 2 and not DailyHunt.getRewardClaimed(cid, 2) then
          DailyHunt.setRewardClaimed(cid, 2)
          local level = getPlayerLevel(cid)
          local expReward = (getExperienceForLevel(level + 1) - getExperienceForLevel(level)) * 0.1
          doPlayerAddExperience(cid, math.ceil(expReward))
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            "Daily Hunt: You completed 2/5 and received 10% of your level as bonus XP!"
          )
          doSendMagicEffect(getThingPos(cid), 28)
        end

        -- Reward for all 5 monsters completed (50% of current level XP)
        if completed >= DailyHunt.monstersPerDay and not DailyHunt.getRewardClaimed(cid, 5) then
          DailyHunt.setRewardClaimed(cid, 5)
          local level = getPlayerLevel(cid)
          local expReward = (getExperienceForLevel(level + 1) - getExperienceForLevel(level)) * 0.5
          doPlayerAddExperience(cid, math.ceil(expReward))
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            "Daily Hunt: COMPLETE! All 5 monsters hunted! You received 50% of your level as bonus XP!"
          )
          doSendMagicEffect(getThingPos(cid), 30)
        end

        -- Send update to client
        DailyHunt.sendDataToClient(cid)
      end
      break
    end
  end
end

function DailyHunt.claimReward(cid)
  local day = DailyHunt.getPlayerDay(cid)
  local currentDay = getDayID()

  if day ~= currentDay then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Your Daily Hunt has expired. Open the window to get new monsters."
    )
    DailyHunt.sendDataToClient(cid)
    return
  end

  local completed = DailyHunt.getCompletedSlots(cid)

  if completed >= 5 and not DailyHunt.getRewardClaimed(cid, 5) then
    DailyHunt.setRewardClaimed(cid, 5)
    local level = getPlayerLevel(cid)
    local expReward = (getExperienceForLevel(level + 1) - getExperienceForLevel(level)) * 0.5
    doPlayerAddExperience(cid, math.ceil(expReward))
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Daily Hunt: COMPLETE! All 5 monsters hunted! You received 50% of your level as bonus XP!"
    )
    doSendMagicEffect(getThingPos(cid), 30)

  elseif completed >= 2 and not DailyHunt.getRewardClaimed(cid, 2) then
    DailyHunt.setRewardClaimed(cid, 2)
    local level = getPlayerLevel(cid)
    local expReward = (getExperienceForLevel(level + 1) - getExperienceForLevel(level)) * 0.1
    doPlayerAddExperience(cid, math.ceil(expReward))
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Daily Hunt: You completed 2/5 and received 10% of your level as bonus XP!"
    )
    doSendMagicEffect(getThingPos(cid), 28)

  else
    if completed < 2 then
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
        "You need to complete at least 2 monsters to claim a reward. Current: " .. completed .. "/5"
      )
    else
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
        "You already claimed your reward for " .. completed .. "/5 monsters."
      )
    end
  end

  DailyHunt.sendDataToClient(cid)
end
