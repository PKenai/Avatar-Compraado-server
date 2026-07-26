local testQuest = createQuest("NewTestQuest")

testQuest:setResetFunction(
function()
  variavel = "lala"
  cid = 2
end)

testQuest:setStopFunction(
function(cid)
  sendBlueMessage(cid, "Desligando")
  testQuest:reset()
end)

testQuest:setStartFunction(
function(cid)
  sendBlueMessage(cid, "Ligando")
end)

testQuest:setLoopFunction(
function()
  print("printando")
end, 5000)

dofile(getDataDir().."lib/isoled/152-npcTaskSystem.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
  if not serverInTest then
    return false
  end

local totalMounts = {
    "winterwolf",
    "polarbear",
    "crystalspider",
    "bear",
    "warwolf",
    "giantspider",
    "lion",
    "tiger",
    "dragonlord",
    "panda",
    "tilehorned",
    "ancientscarab"
}

    for x = 1, #totalMounts do
        setPlayerStorageValue(cid, totalMounts[x], 1)
    end

  local out, string = getCreatureOutfit(cid), ''
  local returnTable = {
    ["lookAddons"] = "addons",
    ["lookType"] = "type",
    ["lookHead"] = "head", 
    ["lookLegs"] = "legs",
    ["lookBody"] = "body",
    ["lookFeet"] = "feet"
  }

  for k, v in pairs(out) do
    if k ~= "lookTypeEx" then
      string = string..returnTable[k]..'="'..v..'" '
    end
  end

  --[[for x = 1, #tasks do
    setPlayerStorageValue(cid, "taskInCourse"..tasks[x].identifier, 2)
  end--]]
  --doPlayerAddLevel(cid, 100)


  --doCreatureSetStorage(cid, "outfitx", 1)

    registerAllMonsters()


  return true
end

local monsters = {}
local totalMonstros = 0

function registerAllMonsters()
    print("-- COMECANDO ANALISE MONSTROS --")

    local topPos = {x=57, y=37}
    local bottomPos = {x=882,y=874}


    local totalTiles = ((bottomPos.x-topPos.x) * (bottomPos.y-topPos.y)) * 13


    for x = topPos.x, bottomPos.x do
        for y = topPos.y, bottomPos.y do
            for z = 3, 15 do

                local currentPos = {x=x,y=y,z=z,stackpos=253}
                local thingUid = getThingfromPos(currentPos).uid

                if thingUid > 0 then
                    if isMonster(thingUid) then
                        local name = getCreatureName(thingUid)
                        local currentTableMonster = monsters[name]

                        if not currentTableMonster then
                            monsters[name] = 1
                        else
                            monsters[name] = currentTableMonster+1
                        end
                    end

                    totalMonstros = totalMonstros+1
                    print(totalMonstros .. " MONSTROS ENCONTRADOS.")
                end
            end
        end
    end

    local file = io.open("data/logs/monstros/monstros.txt", "w")
    
    for k, v in pairs(monsters) do
        file:write(k .. ":" .. v .. "\n")
    end

    file:close()

    print("ANALISE CONCLUIDA E ARMAZENADA EM: data/logs/monstros/monstros.txt")


end