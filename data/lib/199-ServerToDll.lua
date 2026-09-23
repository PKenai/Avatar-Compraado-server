--[[
 * File destinado á comunicação server -> DLL. (barra de moves, etc)
]]--

fireSpells = { --[[MUITO IMPORTANTE: Tem que estar na ordem dos leveis.]]
  "firewhip",
  "firerecover",
  "firekick",
  "fireskyfall",
  "firejump",
  "fireimpulse",
  "firebolt",
  "firecinder",
  "firestar",
  "firecannon",
  "firewrath",
  "firefocus",
  "firelightning",
  "firebomb",
  "fireclock",
  "firethunderbolt",
  "firemeteor",
  "firestriker",
  "fireoverload",
  "fireexplosion",
  "firevoltage",
  "firethunderstorm",
  "firedischarge",
  "fireconflagration",
  "firesearcher"
}

earthSpells = { --[[MUITO IMPORTANTE: Tem que estar na ordem dos leveis.]]
  "earthcrush",
  "earthrecover",
  "earthpunch",
  "earthrock",
  "earthjump",
  "earthpull",
  "earthgrowth",
  "earthcollapse",
  "earthtrack",
  "earthpetrify",
  "earthfury",
  "earthcontrol",
  "earthleech",
  "earthsmash",
  "earthingrain",
  "earthfists",
  "eartharena",
  "earthcurse",
  "earthquake",
  "earthcataclysm",
  "earthaura",
  "eartharmor",
  "earthlavaball",
  "earthmetalwall",
  "earthsearcher"
}

waterSpells = { --[[MUITO IMPORTANTE: Tem que estar na ordem dos leveis.]]
  "waterwhip",
  "waterrecover",
  "waterexplosion",
  "waterheal",
  "waterjump",
  "watericeSpikes",
  "waterfreeze",
  "watershards",
  "watersurf",
  "watercannon",
  "waterregen",
  "waterbloodControl",
  "waterpunch",
  "waterdragon",
  "waterrain",
  "waterbubbles",
  "waterprotect",
  "watericebolt",
  "waterflow",
  "watericeGolem",
  "watertsunami",
  "waterclock",
  "waterblizzard",
  "waterbloodBending",
  "watersearcher"
}

airSpells = { --[[MUITO IMPORTANTE: Tem que estar na ordem dos leveis.]] 
  "airball",
  "airrecover",
  "airburst",
  "airrun",
  "airjump",
  "airforce",
  "airgust",
  "airgale",
  "airboost",
  "airfan",
  "airwings",
  "airsuffocation",
  "airhurricane",
  "airtempest",
  "airwindblast",
  "airtornado",
  "airbarrier",
  "airtrap",
  "airdoom",
  "airbomb",
  "airwindstorm",
  "airstormcall",
  "airvortex",
  "airdeflection",
  "airsearcher"
}

function sendCDToClient(cid, element, spellname, time)
  if time == 0 or time == nil or not (isPlayer(cid)) then
    return true
  end

  trySpellExp(cid, string.lower(element), string.lower(spellname)) -- treina spell

  local tableElement = {
    ["fire"] = fireSpells, 
    ["water"] = waterSpells,
    ["earth"] = earthSpells,
    ["air"] = airSpells
  }
  
  if tableElement[element] ~= nil then
    for x = 1, #tableElement[element] do
      if tableElement[element][x] == element..spellname then
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "#m#"..x..","..time..";")
        return true
      end
    end
  end
end

function sendPrevCDToClient(cid, element, spellname, time)
  if time == 0 or time == nil or not (isPlayer(cid)) then
    return true
  end
  local elementId = getElementId(element)
  local tableElement = {
    ["fire"] = fireSpells, 
    ["water"] = waterSpells,
    ["earth"] = earthSpells,
    ["air"] = airSpells
  }
  
  if tableElement[element] ~= nil then
    for x = 1, #tableElement[element] do
      if tableElement[element][x] == element..spellname then
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "#m#"..x..","..-time..";")
        return true
      end
    end
  end
end

function workAllCdAndAndPrevCd(cid, element, spellname, time, timeAllExausteds)
  if (timeAllExausteds == nil or timeAllExausteds <= 1) and (time == 0 or time == nil) or not (isPlayer(cid)) then
    return true
  end
  local stringToSend = ""
  local elementId = getElementId(element)
  local tableElement = {
  ["fire"] = fireSpells, 
  ["water"] = waterSpells,
  ["earth"] = earthSpells,
  ["air"] = airSpells
  }  

  if tableElement[element] ~= nil then
    if timeAllExausteds > 1 then
      local currentTime = os.time()

      for x = 1, #tableElement[element] do
        local delayTime = getPlayerStorageValue(cid, "exausted"..tableElement[element][x])
        if tableElement[element][x] ~= element..spellname then
          if delayTime <= currentTime+timeAllExausteds then 
            stringToSend = stringToSend.."#m#"..x..","..timeAllExausteds..";"
          end
        end
      end
    end

    if stringToSend ~= "" then
      doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, stringToSend)
    end

    sendPrevCDToClient(cid, element, spellname, time)
  end
end

function sendAllCdToClient(cid, element, inlogin)
  if not isPlayer(cid) then
    return false
  end
  local tableElement = {
  ["fire"] = fireSpells, 
  ["water"] = waterSpells,
  ["earth"] = earthSpells,
  ["air"] = airSpells
  }  

  local string = ""

  if tableElement[element] ~= nil then
    for x = 1, #tableElement[element] do
      local delayTime, currentTime = getPlayerStorageValue(cid, "exausted"..tableElement[element][x]), os.time()
      if delayTime >= currentTime then
        string = string.."#m#"..x..","..delayTime-currentTime..";"
      else
        string = string.."#m#"..x..",0;"    
      end
    end
    if inlogin then
      return string
    else
      return doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string)
    end
  else
    return ""
  end
end

function sendWaterPounchToClient(cid, water, inLogin, isSpell)
  if isSpell then 
    return false 
  end 
  if inLogin then
    if water == nil then
      return ""
    end
    
    if water == 0 then
      return ""
    end

    return "#w#"..water..";"
  else
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "#w#"..water..";")
    return true
  end
end

function getPlayerClientConfigs(cid)
  local string = ""

  for x = 7, 1, (-1) do
    local storage = getPlayerStorageValue(cid, "saveClientConfig"..x)
    if storage >= 0 then
      string = string.."#c#"..x..","..storage..";"
    end
  end

  return string
end

function sendWebsiteToPlayer(cid, web)
  doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "@link@"..web)  
  sendBlueMessage(cid, "@link@"..web)
end

function sendAntiBotQuestions(cid, correct)
  return doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "#b#"..correct..";")
end

function cancelAntiBotQuestions(cid)
  return doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "#b#-1;")
end