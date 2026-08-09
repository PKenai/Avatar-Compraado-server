dofile(getDataDir().."lib/isoled/152-npcTaskSystem.lua")

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
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, getLangString(cid, atual .. "º Christmas Mission completed! Please, report to NPC Santa Claus.", atual .. "º Missão de Natal completada! Por favor, reporte ao NPC Santa Claus."))
        else            
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, getLangString(cid, "Christmas Mission - Progress: "..(killsCount+1).."/"..pascoaMissions[atual].count.." "..monsterNameNormal.."(s).", "Missão de Natal - Progresso: "..(killsCount+1).."/"..pascoaMissions[atual].count.." "..monsterNameNormal.."(s)."))
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
  end
    if monsterName == "elemental" then
      doSetStorage("resetQuestBauOpen", 1)
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

    local identifier = getTaskIdentifierByMonster(getCreatureName(target))
    if #identifier > 0 then
      for k, v in pairs(identifier) do
        if playerHasTaskInProgress(cid, v) then
          local taskInfo = getTaskInfosByIdentifier(v)

         -- if taskInfo.cantDoInParty then
          --  if getPlayerParty(cid) then
           --   return true
          --  end
          --end

          addMonsterInTaskCourse(cid, v)
          if getMonstersHasKilled(cid, v) < taskInfo.amount then
            local number, monsterName = taskInfo.amount-getMonstersHasKilled(cid, v), taskInfo.monsterName
      local ttInfo = getTaskInfosByIdentifier(v)
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, getLangString(cid, "General Task - "..ttInfo.name..": "..number.." "..monsterName.."(s) left to kill.", "Task Geral - "..ttInfo.name..": Falta matar "..number.." "..monsterName.."(s)."))
          else
            --if taskInfo.endAutomatic then
            if not getPlayerHasEndTask(cid, v) then
                endTaskInPlayer(cid, v)
        addEvent(doSendAnimatedText, 50, getThingPos(cid), "Task completed!", 215)
        local ttInfo = getTaskInfosByIdentifier(v)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, getLangString(cid, "General Tasks: "..ttInfo.name.." completed!", "Tasks Gerais: "..ttInfo.name.." completada!"))

        if ttInfo.customParagon then
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Task Reward: You gained +"..ttInfo.customParagon.." Paragon Level.")
          local oldParagon = getPlayerResets(cid)
          local newParagon = oldParagon + ttInfo.customParagon
          setPlayerResets(cid, newParagon)
          for i = 1, ttInfo.customParagon do
            onUpgradeParagon(cid, oldParagon + i)
          end
        else
          doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Task Reward: You gained +1 Paragon Level.")
          local newParagonDois = getPlayerResets(cid)+1
          setPlayerResets(cid, newParagonDois)
          onUpgradeParagon(cid, newParagonDois)
        end
            end
            --end
          end

          break
        end
      end
    end
  end

  return true
end