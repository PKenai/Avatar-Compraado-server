local InspectOpcode = 164

-- Debug: escreve no terminal do servidor
local function dbg(msg)
  print("[InspectServer] " .. msg)
end

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
  dbg("=== onSay called ===")
  dbg("words: '" .. tostring(words) .. "'")
  dbg("param: '" .. tostring(param) .. "'")
  dbg("channel: " .. tostring(channel))

  if param == nil or param:trim() == "" then
    dbg("ERROR: Empty parameter!")
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      "Usage: !inspect MonsterName")
    return true
  end

  param = param:trim()
  dbg("Looking up monster: '" .. param .. "'")

  local monster = getMonsterInfo(param)
  if not monster then
    dbg("ERROR: Monster '" .. param .. "' not found!")
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      param .. " does not exist.")
    return true
  end
  dbg("Monster found! Name: '" .. tostring(monster.name) .. "'")

  if isInArray(forbiddenNames, param) then
    dbg("Monster is forbidden!")
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
      monster.name .. " information is locked.")
    return true
  end

  -- Get loot if not already loaded
  if not monster.loot then
    dbg("Loading loot list...")
    monster.loot = getMonsterLootList(param)
    dbg("Loot loaded, items: " .. tostring(#monster.loot))
  end

  local monsterData = {}
  monsterData.name = monster.name
  dbg("Building monster data for: " .. monster.name)

  -- Try to get outfit from spawned creature
  local creature = getCreatureByName(monster.name)
  if creature then
    dbg("Creature found in world, getting outfit")
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
      dbg("Outfit obtained from creature")
    end
  else
    dbg("Creature not found in world, using XML look")
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
    dbg("Fallback outfit used")
  end

  monsterData.loot = {}

  if monster.loot then
    dbg("Processing " .. #monster.loot .. " loot items")

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
    dbg("Total loot entries (with children): " .. #allLoot)

    -- Sort by chance descending
    local itemsAdded = 0
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
        itemsAdded = itemsAdded + 1
      end
    end
    dbg("Items added to loot list: " .. itemsAdded)
  end

  dbg("Sending data via extended opcode " .. InspectOpcode .. "...")
  local dataString = table.tostring(monsterData)
  dbg("Data string length: " .. #dataString)
  dbg("First 100 chars: " .. dataString:sub(1, 100))
  doSendPlayerExtendedOpcode(cid, InspectOpcode, dataString)
  dbg("=== onSay COMPLETE ===")

  return true
end
