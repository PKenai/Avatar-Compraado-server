function onSay(cid, words, param, channel)
  local player = db.getResult("SELECT * FROM players WHERE id > '0'")
  local skills, players, playersCorrigidos = 0, 0, 0

  if (player:getID() ~= -1) then
       repeat
         local currentId = result:getDataInt("id")
         players = players+1

         for x = 0, 5 do
           local skill = db.getResult("SELECT * FROM player_skills WHERE player_id = '"..currentId.."' AND skillid = '"..x.."'")
                if skill:getID() == -1 then
                    if x == 0 then
                        playersCorrigidos = playersCorrigidos+1
                    end
             db.executeQuery("INSERT INTO `player_skills` (`player_id`, `skillid`, `value`, `count`) VALUES ('"..currentId.."', '"..x.."', '0', '0')")
             skills = skills+1
           end
         end
       until not result:next()
  end

  sendBlueMessage(cid, players.." players checados, "..skills.." skills corrigidos, "..playersCorrigidos.." players corrigidos;")
  return true
end
