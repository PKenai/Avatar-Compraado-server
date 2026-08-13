

local hasDestroyed = false
local gatePosesO = {{x = 1150, y = 945, z = 4},
{x = 1150, y = 946, z = 4},
{x = 1150, y = 947, z = 4},
{x = 1156, y = 945, z = 4},
{x = 1156, y = 946, z = 4},
{x = 1156, y = 947, z = 4}
}
local gatePosesT = {{x=1150, y=930, z=7},
{x = 1151, y = 930, z = 7},
{x = 1153, y = 930, z = 7},
{x = 1154, y = 930, z = 7},
{x = 1145, y = 943, z = 4},
{x = 1146, y = 943, z = 4},
{x = 1152, y = 949, z = 4},
{x = 1153, y = 949, z = 4},
{x = 1154, y = 949, z = 4},
{x = 1155, y = 949, z = 4}
}

-- se for mudar essa tabela, precisa copiar a atualizacao tambem na que esta em easter lua, npcs scripts
-- pois la tb pega p fazer checagem de qual mob eh e qnts precisa matar na parte atual do evento
local pascoaMissions = 
{
  [1] = {monsterName = "Crystal Spider", count = 25},
  [2] = {monsterName = "Frost Giantess", count = 30},
  [3] = {monsterName = "Draken Elite", count = 40},
  [4] = {monsterName = "Crystal Golem", count = 80},
  [5] = {monsterName = "Water Outlaw", count = 100},
  [6] = {monsterName = "Dark Fury", count = 120},
  [7] = {monsterName = "Dread Intruder", count = 140},
}
-- tb precisa att esse p entrar no codigo de test da pascoa se matar algum mob q faz parte, minusculos
local pascoaMonsters = {"crystal spider", "frost giantess", "draken elite", "crystal golem", "dread intruder", "water outlaw", "dark fury"}

function onKill(cid, target, lastHit)
  if isMonster(target) then
    if isSummon(target) then
      return true
    end
  

    local monsterName = getCreatureName(target):lower()
    doSetStorage("count"..monsterName, getStorage("count"..monsterName)+1)


  if getPlayerStorageValue(cid, "inPascoaTask") == 1 and isInArray(pascoaMonsters, monsterName) then
    local atual = getPlayerStorageValue(cid, "easter2018State")
    local monsterNameNormal = getCreatureName(target)
    if pascoaMissions[atual] and pascoaMissions[atual].monsterName == monsterNameNormal then
      local killsCount = getPlayerStorageValue(cid, "easter2018Kills")
      if killsCount < pascoaMissions[atual].count then
        setPlayerStorageValue(cid, "easter2018Kills", killsCount+1)
        if killsCount+1 == pascoaMissions[atual].count then
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, getLangString(cid, atual .. "� Christmas Mission completed! Please, report to NPC Santa Claus.", atual .. "� Miss�o de Natal completada! Por favor, reporte ao NPC Santa Claus."))
        else            
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, getLangString(cid, "Christmas Mission - Progress: "..(killsCount+1).."/"..pascoaMissions[atual].count.." "..monsterNameNormal.."(s).", "Miss�o de Natal - Progresso: "..(killsCount+1).."/"..pascoaMissions[atual].count.." "..monsterNameNormal.."(s)."))
        end
        
      end
    end
  end
  

  if monsterName == "gate" then
     for i = 1, #gatePosesO do
      local v = getTileItemById(gatePosesO[i], 1546).uid
      if v > 0 then
        doRemoveItem(v)
      end 
     end
    for i = 1, #gatePosesT do
      local v = getTileItemById(gatePosesT[i], 1547).uid
      if v > 0 then
        doRemoveItem(v)
      end 
    end
    return true
  elseif monsterName == "supreme abadeer" then
      if not hasDestroyed then
        local stoneId = 1304
        local firstPos = {x=682,y=467,z=9}

            for x = firstPos.x, firstPos.x+1 do
                for y = firstPos.y, firstPos.y+1 do
                    removeTileItemById({x=x,y=y,z=firstPos.z}, stoneId, 2)
                end
            end

            hasDestroyed = true
        end
    end
  end

  return true
end