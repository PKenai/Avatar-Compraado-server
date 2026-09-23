--[[
 * File destinado aos Exausted, separado por tables.
]]--

-- Atk = porcentagem do dano. 100 = dano original da fórmula, 70 = 30% menor do que o dano original da fórmula. Se colocar 0, só irá tirar 1 de dano
-- "heal" funciona igual o atk, só muda nome pra informar que muda a cura 
spellsInfo =
{
["air ball"] = {atk = 24},
["air barrier"] = {atk = 149, slowPercent = 30, slowTempo = 1000, duracao = 5000},
["air bomb"] = {atk = 102, segundosParaExplosao = 3},
["air boost"] = {segundos = 30},
["air burst"] = {atk = 22},
["air deflection"] = {atk = 23},
["air doom"] = {atk = 29},
["air fan"] = {atk = 16},
["air force"] = {atk = 95},
["air gust"] = {atk = 29},
["air gale"] = {atk = 30}, -- a formula passou a multiplicar por atk/100: 100 = dano do modelo antigo (calibrar com --bar --emit)
["air hurricane"] = {atk = 18},
["air icywind"] = {atk = 158, frozzenTime = 2000},
["air jail"] = {segundos = 4},
["air suffocation"] = {atk = 7, segundos = 3},
["air jump"] = {duracao = 5000},
["air run"] = {duracao = 30000},
["air stormcall"] = {atk = 12}, -- era 9, mas o atk nunca era aplicado (bug de sombreamento no script): media 7,63x o orcamento e matava player do MESMO level num cast. 12 = alvo do modelo (11 no L100, 13 no L300). Ver secao 23.
["air tempest"] = {atk = 21},
["air tornado"] = {atk = 40, segundos = 2},
["air trap"] = {segundos = 15},
["air vortex"] = {atk = 10},
["air windblast"] = {atk = 68},
["air windstorm"] = {atk = 17},
["air wings"] = {atk = 11},
["earth arena"] = {duracao = 8000},
["earth aura"] = {atk = 15, duracao = 4000},
["earth armor"] = {duracao = 10000},
["earth cataclysm"] = {atk = 102},
["earth collapse"] = {atk = 38},
["earth control"] = {atk = 130},
["earth crush"] = {atk = 10},
["earth curse"] = {atk = 409},
["earth fists"] = {atk = 38},
["earth growth"] = {atk = 41}, -- a formula passou a multiplicar por atk/100: 100 = dano do modelo antigo (calibrar com --bar --emit)
["earth ingrain"] = {heal = 100, segundos = 7},
["earth jump"] = {duracao = 5000},
["earth fury"] = {atk = 59},
["earth lavaball"] = {atk = 35},
["earth leech"] = {atk = 263},
["earth metalwall"] = {atk = 118},
["earth petrify"] = {atk = 116, segundos = 4},
["earth pull"] = {atk = 66},
["earth punch"] = {atk = 71},
["earth quake"] = {atk = 104},
["earth rock"] = {atk = 29},
["earth smash"] = {atk = 69},
["earth storm"] = {atk = 60},
["earth track"] = {segundos = 30},
["earth wall"] = {segundos = 10},
["fire blast"] = {atk = 18},
["fire bolt"] = {atk = 54},
["fire bomb"] = {atk = 33},
["fire cannon"] = {atk = 15},
["fire conflagration"] = {atk = 31},
["fire clock"] = {atk = 51},
["fire discharge"] = {atk = 22},
["fire explosion"] = {atk = 18},
["fire impulse"] = {segundos = 30},
["fire kick"] = {atk = 11},
["fire jump"] = {duracao = 5000},
["fire lightning"] = {atk = 68},
["fire meteor"] = {atk = 11},
["fire overload"] = {atk = 88},
["fire cinder"] = {atk = 23},
["fire skyfall"] = {atk = 15},
["fire star"] = {atk = 115},
["fire striker"] = {atk = 9},
["fire thunderbolt"] = {atk = 14},
["fire thunderstorm"] = {atk = 16},
["fire voltage"] = {atk = 500},
["fire wave"] = {atk = 220},
["fire whip"] = {atk = 23},
["fire wrath"] = {segundos = 2},
["water blizzard"] = {atk = 7},
["water bloodbending"] = {atk = 20},
["water bloodcontrol"] = {atk = 199},
["water bubbles"] = {atk = 65, bolhas = 5},
["water cannon"] = {atk = 60},
["water clock"] = {atk = 15},
["water dragon"] = {atk = 25, chanceFrozzen = 35},
["water explosion"] = {atk = 37},
["water heal"] = {heal = 300},
["water flow"] = {atk = 14},
["water jump"] = {duracao = 5000},
["water sheal"] = {heal = 300},
["water icebeam"] = {atk = 68, frozzenTime = 2000, frozzenChance = 70},
["water icebolt"] = {atk = 59, frozzenTime = 3000},
["water icegolem"] = {segundos = 60},
["water icespikes"] = {atk = 73},
["water protect"] = {duracao = 4000},
["water punch"] = {atk = 25, slowPercent = 50, slowTempo = 3000},
["water rain"] = {atk = 27},
["water regen"] = {segundos = 60, quantia = 50},
["water sregen"] = {segundos = 60, quantia = 55},
["water freeze"] = {atk = 116, segundos = 4},
["water shards"] = {atk = 7},
["water surf"] = {segundos = 30},
["water tsunami"] = {atk = 19},
["water wave"] = {atk = 115}, -- atk da magia antiga "Water Wave" (water/wave.lua, removida do spells.xml)
["water whip"] = {atk = 118}, -- dobra que hoje aparece como "Water Wave" na spellbar (water/whip.lua). ATENCAO: esta chave e' lida tambem por water/whip man.lua -- ver %MODEL_SKIP em tools/spell_balance_report.pl
}




 earthExausted = {
  arena = 45,
  armor = 70,
  lavaball = 60,
  metalwall = 90,
  wall = 1,
  control = 30,
  crush = 3,
  cataclysm = 45,
  collapse = 10,
  curse = 30,
  growth = 9,
  ingrain = 40,
  jump = 12,
  fury = 14,
  petrify = 30,
  pull = 4,
  punch = 4,
  push = 2,
  quake = 45,
  rock = 3,
  aura = 45,
  fists = 15,
  recover = 2,
  storm = 45,
  smash = 7,
  spikes = 5,
  leech = 15, -- modelo v2: era 3s (filler com dano de core e cura embutida)
  track = 30,
  searcher = 5
}
 
 
fireExausted = {
  whip = 2,
  recover = 2,
  lightning = 8,
  thunderbolt = 15, -- modelo v2: era 12s (atk de core num CD de 12s)
  explosion = 25,
  thunderstorm = 30,
  wave = 3,
  blast = 2,
  bolt = 10,
  jump = 12,
  skyfall = 3,
  star = 25,
  impulse = 30,
  focus = 60,
  meteor = 45,
  bomb = 20,
  overload = 30,
  wrath = 20,
  cannon = 8,
  striker = 45,
  discharge = 60,
  conflagration = 90,
  cinder = 8,
  voltage = 120,
  kick = 3,
  clock = 20,
  searcher = 5
}
 
 
 waterExausted = {
  whip = 2,
  recover = 2,
  explosion = 2,
  heal = 3,
  iceSpikes = 4, -- corrente de gelo: 4s no servidor e na spellbar (dobras lvl 5: -3)
  clock = 45,
  blizzard = 60,
  bloodBending = 90,
  icebolt = 20,
  jump = 12,
  wave = 3,
  fang = 1,
  cannon = 8,
  regen = 45,
  mregen = 15,
  flow = 30,
  iceBeam = 10,
  iceGolem = 120,
  surf = 30,
  punch = 10, -- modelo v2: era 6s (atk 556 + slow 50%)
  bloodControl = 45,
  dragon = 25,
  rain = 45,
  protect = 65,
  tsunami = 45,
  freeze = 30,
  bubbles = 12,
  searcher = 5,
  shards = 12
}
 
 
 airExausted = {
  recover = 2,
  run = 40,
  ball = 3, -- modelo v2: era 1s (443 DPS no L100, mais que qualquer ultimate)
  burst = 2,
  force = 4,
  windstorm = 45,
  barrier = 40,
  bomb = 30,
  gust = 6,
  fan = 30,
  wings = 14,
  icywind = 20,
  gale = 15,
  jump = 12,
  jail = 35,
  suffocation = 35,
  boost = 30,
  hurricane = 13,
  trap = 12,
  doom = 45,
  stormcall = 45,
  vortex = 60,
  deflection = 90,
  searcher = 5,
  tornado = 20,
  tempest = 25,
  windblast = 20
}

function blockPlayerUseMagic(cid, time)
  return setPlayerStorageValue(cid, "playerBlockMagic", os.time()+time)
end

function getPlayerBlockMagic(cid)
  return (tonumber(getPlayerStorageValue(cid, "playerBlockMagic")) or -1) > os.time()
end

--[[function getPlayerExaust(cid, element, spellName)
  if isMonster(cid) then
    return true
  end

  local storageString, strError = "exausted"..element..spellName, nil
  local currentTime, delayTime = os.time(), getPlayerStorageValue(cid, storageString)

  if delayTime >= currentTime then
    local stringTime = getSecsString(delayTime-currentTime)
    local tableTime = getTimeInString(delayTime)

    if tonumber(tableTime.second) >= 1 then
      strError = getLangString(cid, "You need wait "..stringTime.." to use this fold again.", "Você precisa esperar "..stringTime.." para usar essa dobra novamente.")
    else
      strError = getLangString(cid, "You need wait a few moments to use this fold again.", "Você precisa esperar alguns instantes para usar essa dobra novamente.")
    end

    doPlayerSendCancelEf(cid, strError)
    return false
  end
  return true
end]]--


function doPlayerAddExaust(cid, element, spellName, time)
  if isMonster(cid) then
    return true
  end

 --[[ if getPlayerSkullType(cid) > 3 then
    if time == 0 then
      time = 1
    end
    time = time*2
  end]]

  if (tonumber(getPlayerStorageValue(cid, "timeInEffectCdReduction")) or -1) > os.time() then
    if time >= 5 then
      time = math.ceil(time-(time*0.3))
    end
  end
  
  if getPlayerStorageValue(cid, 13403) == 1 then
    if time >= 5 then
      time = math.ceil(time-(time*0.08))
    end
  end

  -- Talent Tree: Cooldown Reduction (max 30% via talentos)
  if isPlayer(cid) then
    local talentCDR = getPlayerStorageValue(cid, "talentCooldownReduction")
    if type(talentCDR) == "number" and talentCDR > 0 and time >= 5 then
      local cdrPct = math.min(talentCDR, 30) -- cap at 30%
      time = math.ceil(time - (time * cdrPct / 100))
    end
  end

  if time == nil then
    print("problem with spellExausted name "..spellName.." in element "..element)
    doPlayerSendCancelEf(cid, "Error with this spell, report to gameMaster.")
    sendBlueMessage(cid, "Error with this spell, report to gameMaster." )
    return false
  elseif time == 0 then
    sendCDToClient(cid, element, spellName, 1)
    return true
  end

  if not getPlayerExaust(cid, element, spellName) then
    return false
  end

  sendCDToClient(cid, element, spellName, time)
  setPlayerStorageValue(cid, "exausted"..element..spellName, os.time()+time)
  return true
end


function canUseWaterSpell(cid, countWater, distance, onlyAmbient)
  local fullPouchId = 4864
  local emptyPouchId = 4863
  
  if isMonster(cid) then
    return true
  end

  if getPlayerCanUseAmbientWater(cid, distance) == true then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, getLangString(cid, "Using ambient water.", "Usando água ambiente."))
    return true
  end

  if onlyAmbient == true then
    doPlayerSendCancelEf(cid, getLangString(cid, "This fold requires a lot of water, only ambient water.", "Essa dobra requer uma grande quantidade de água, apenas água ambiente."))
    return false
  end

  -- Agua milagrosa do oasis (ID 18999) - item infinito, nunca consome agua
  local infinitePouch = getPlayerItemById(cid, true, 18999)
  if infinitePouch.uid > 0 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, getLangString(cid, "Using infinite oasis water.", "Usando agua infinita do oasis."))
    return true
  end

--  local waterPouch, pouchWater = getPlayerSlotItem(cid, 10), nil
  local waterPouch, pouchWater = getPlayerItemById(cid, true, 4864), nil
  
  if waterPouch.uid > 0 then
    pouchWater = getItemAttribute(waterPouch.uid, "water")
  end

  if pouchWater == nil then
    if waterPouch.uid > 0 and (waterPouch.itemid == fullPouchId or waterPouch.itemid == emptyPouchId) then
      doItemSetAttribute(waterPouch.uid, "water", 0)
    end
    doPlayerSendCancelEf(cid, getLangString(cid, "To use this fold you need a water source.", "Para usar essa dobra, você precisa de uma fonte de água."))
    return false
  end
  local waterPouchCount = getPlayerItemCount(cid, 4864)
  if waterPouch.itemid == fullPouchId then
    if pouchWater < countWater then
      setWaterOnPounchPlayer(cid, 0, waterPouch)
      doPlayerSendCancel(cid, getLangString(cid, "The water we had was not enough to fold and was discarded.", "Essa água não serve para essa dobra, portanto, ela foi descartada."))
      doDecayItem(doCreateItem(2017, getCreaturePosition(cid)))
      return false
    elseif pouchWater == countWater then
      setWaterOnPounchPlayer(cid, 0, waterPouch)
    if waterPouchCount <= 1 then 
      doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "Using water pounch, your water pouch dried.", "Usando water pouch, acabou a água."))
    else
      doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "One water pouch dried, you now have "..(waterPouchCount-1).." more.", "Um water pouch secou, você tem mais "..(waterPouchCount-1).."."))
    end 
      return true
    else
      setWaterOnPounchPlayer(cid, pouchWater-countWater, waterPouch)
      if waterPouchCount <= 1 then 
      doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "Using last water pounch ("..pouchWater.."%).", "Usando último water pouch ("..pouchWater.."%)."))
    else 
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, getLangString(cid, "Using one ("..pouchWater.."%) of "..waterPouchCount.." water pounchs.", "Usando um ("..pouchWater.."%) de "..waterPouchCount.." water pouchs."))
    end 
      return true
    end
  else
    doPlayerSendCancelEf(cid, getLangString(cid, "To use this fold you need a water source.", "Para usar essa dobra, você precisa de uma fonte de água."))
    return false
  end
end

function getSpellCancels(cid, spellName, isFury, isDash)
  if isMonster(cid) then
    return false
  end
 
  if getCreatureNoMove(cid) or exhaustion.check(cid, "airtrapped") then
    doPlayerSendCancelEf(cid, getLangString(cid, "You are unable to bend now.", "Você não pode dobrar agora."))  
    return true
  end
  if isDash then
    return false
  end

  if spellName == "earth" or spellName == "fire" or spellName == "water" then
    local currentPosition = getCreaturePosition(cid)
    -- isSqmVoid (050-function.lua) varre o stack: quando o player esta em cima
    -- do piso falso (460), o stackpos 0 devolve a propria criatura (itemid 1) e
    -- o teste antigo nao enxergava que ele estava no ar.
    local isSqmFlying = isSqmVoid(currentPosition)

    if getPlayerStorageValue(cid, "playerOnAir") == 1 or isSqmFlying then
      doPlayerSendCancelEf(cid, getLangString(cid, "You can't use this bend on air.", "Você não pode usar essa dobra no ar."))
      return true
    end

    return false
  elseif spellName == "air" then
    return false
  end
end

function setPlayerOverPower(cid, element, time)
  setPlayerStorageValue(cid, element.."overPower", os.time()+time)
end

function getPlayerOverPower(cid, element, disable, animatedText)
  if isMonster(cid) then
    return false
  end

  local time = getPlayerStorageValue(cid, element.."overPower")
  if disable == true then
    setPlayerStorageValue(cid, element.."overPower", 0)
  end
  if os.time() < time then
    if animatedText == true then
      doSendAnimatedText(getThingPos(cid), "Focused!", COLOR_DARKRED)
    end
    return true
  else
    return false
  end
end

function setPlayerStuned(cid, time)
  if time == nil or time == 0 or time == false then
    setPlayerStorageValue(cid, "playerHasStun", 0)
  else
    setPlayerStorageValue(cid, "playerHasStun", os.time()+time)
  end
end

function getPlayerHasStun(cid)
  if (tonumber(getPlayerStorageValue(cid, "playerHasStun")) or -1) >= os.time() then
    if math.random(1, 6) ~= 6 then
      doSendAnimatedText(getThingPos(cid), "Miss!", COLOR_WHITE)
      return true
    else
      return false
    end
  else
    return false
  end
end

function cleanAllCds(cid, element)
  local tableElement = {
  ["fire"] = fireSpells, 
  ["water"] = waterSpells,
  ["earth"] = earthSpells,
  ["air"] = airSpells
  }

  if tableElement[element] ~= nil then
    for x = 1, #tableElement[element] do
      setPlayerStorageValue(cid, "exausted"..tableElement[element][x], -1)
    end
    sendAllCdToClient(cid, element)
    return true
  end
  return false
end