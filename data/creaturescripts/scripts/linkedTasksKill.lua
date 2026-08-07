-- Linked Tasks - contagem de kills
-- Evento registrado em data/creaturescripts/creaturescripts.xml (type="kill")
-- e registrado por player no login (loginFuncs.lua)

dofile(getDataDir().."lib/256-LinkedTasks.lua")

function onKill(cid, target, lastHit)
  -- mortes sem player (ambiente/efeitos) nao contam
  if not isPlayer(cid) then
    return true
  end

  if not isMonster(target) then
    return true
  end

  -- summons nao contam
  if isSummon(target) then
    return true
  end

  local monsterName = string.lower(getCreatureName(target))

  for roomId, room in pairs(linkedTasksRooms) do
    for i = 1, #room.tasks do
      local task = room.tasks[i]
      -- suporta lista de monstros (ex: os 3 ciclopes contam para a mesma task)
      if linkedTaskMatchesMonster(task, monsterName) then
        -- so conta se a task estiver ATIVA (status 1)
        if linkedTaskStatus(cid, task) == 1 then
          local kills = linkedTaskKills(cid, task) + 1
          setPlayerStorageValue(cid, task.storage + 1, kills)

          if kills >= task.amount then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, "Linked Task - " .. task.name .. ": " .. kills .. "/" .. linkedTaskGoalText(task) .. ". Kills completos! Clique no display da task para ENTREGAR.")
            linkedTaskReadyToClaim(cid, roomId, task)
          else
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, "Linked Task - " .. task.name .. ": " .. kills .. "/" .. linkedTaskGoalText(task) .. ". Faltam " .. (task.amount - kills) .. ".")
          end
        end
        break
      end
    end
  end

  return true
end
