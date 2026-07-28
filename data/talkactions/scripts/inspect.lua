local InspectOpcode = 164

local forbiddenNames = {
  "Draptor", "Tyrn", "Devil Skeleton", "Kraken", "Death Wing",
  "The Duke Of The Depths", "Mouth of Hell", "Marsh Prince",
  "Machine King", "Arachnophobica", "Tannyl"
}

local function spairs(t, order)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

function onSay(cid, words, param, channel)
  if param == nil or param:trim() == "" then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Usage: !inspect MonsterName")
    return true
  end

  param = param:trim()

  local monster = getMonsterInfo(param)
  if not monster then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      param .. " does not exist.")
    return true
  end

  if isInArray(forbiddenNames, param) then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      monster.name .. " information is locked.")
    return true
  end

  -- Get loot if not already loaded
  if not monster.loot then
    monster.loot = getMonsterLootList(param)
  end

  local monsterData = {}
  monsterData.name = monster.name

  -- Try to get outfit from spawned creature
  local creature = getCreatureByName(monster.name)
  if creature then
    local outfit = getCreatureOutfit(creature)
    if outfit then
      monsterData.outfit = {
        type = outfit.lookType or 0,
        feet = outfit.lookFeet or 0,
        addons = outfit.lookAddons or 0,
        legs = outfit.lookLegs or 0,
        auxType = outfit.lookTypeEx or 0,
        head = outfit.lookHead or 0,
        body = outfit.lookBody or 0
      }
    end
  end

  -- Fallback: use look type from monster info
  if not monsterData.outfit and monster.look then
    monsterData.outfit = {
      type = monster.look.type or 0,
      feet = monster.look.feet or monster.look.lookFeet or 0,
      addons = monster.look.addons or monster.look.lookAddons or 0,
      legs = monster.look.legs or monster.look.lookLegs or 0,
      auxType = monster.look.typeEx or monster.look.lookTypeEx or 0,
      head = monster.look.head or monster.look.lookHead or 0,
      body = monster.look.body or monster.look.lookBody or 0
    }
  end

  monsterData.loot = {}

  if monster.loot then
    -- Collect all loot items including children
    local allLoot = {}
    local count = 0

    for _, item in pairs(monster.loot) do
      count = count + 1
      allLoot[count] = item
      if item.child then
        for _, child in pairs(item.child) do
          count = count + 1
          allLoot[count] = child
        end
      end
    end

    -- Sort by chance descending
    for _, item in spairs(allLoot, function(t, a, b)
      return t[b].chance and t[a].chance and t[b].chance < t[a].chance
    end) do
      local itemName = getItemNameById(item.id)
      if itemName and itemName ~= "" and itemName ~= "bag" then
        -- Determine rarity label
        local rarity = "-"
        if item.chance then
          if item.chance >= 100000 then
            rarity = "Always"
          elseif item.chance >= 20000 then
            rarity = "Common"
          elseif item.chance >= 5000 then
            rarity = "Uncommon"
          elseif item.chance >= 1000 then
            rarity = "Semi Rare"
          elseif item.chance >= 200 then
            rarity = "Rare"
          elseif item.chance >= 50 then
            rarity = "Very Rare"
          else
            rarity = "Extremely Rare"
          end
        end

        local itemInfo = getItemInfo(item.id)
        table.insert(monsterData.loot, {
          id = itemInfo and itemInfo.clientId or item.id,
          name = itemName,
          count = item.countMax or item.count or 0,
          chance = rarity
        })
      end
    end
  end

  local dataString = table.tostring(monsterData)
  doSendPlayerExtendedOpcode(cid, InspectOpcode, dataString)

  return true
end
