local topLeftPosition, underRightPosition = {x=716, y=430}, {x=726,y=435}

local function randomizeRarod(cid)
  local currentPosition, count = nil, 0

  repeat
    currentPosition = {x=math.random(topLeftPosition.x, underRightPosition.x),y=math.random(topLeftPosition.y, underRightPosition.y), z=9}
  until getPlayerCanWalk({player = cid, position = currentPosition, checkPZ = true, checkHouse = true, checkWater = true, checkNoLogout = true, checkHardcore = true})

  local monster = doCreateMonster("Brown Rarod", currentPosition, nil, true)
end

local chance = 100
local stringEN, stringPT = "A mysterious creature round the world of Avatar... Some call him Rarod, save youself if it possible!", "Uma criatura misteriosa ronda o mundo de Avatar... Alguns o chamam de Rarod, outros de besta da morte, salve-se quem puder!"

function onThink(interval)

  return true
end