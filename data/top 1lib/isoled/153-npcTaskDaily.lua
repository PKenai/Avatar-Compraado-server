
--[[
 * File destinado as Tasks díarias do Servidor.
]]--

local dailyTasks = {
  easy = {
    monsters = {
      "Cyclops", "Dwarve", "Troll", "Ghoul", "Nomad", "Zuko's Disciple", "Elf", "Gargoyle",
      "Tarantula", "Monk", "Orc", "Sibang", "Kongra", "Larva", "Scarab",
      "Tortoise"
    },

    level = {min = 1, max = 30}, reward = {stones = false, points = 1, exp = 0, items = false},
    monsterNum = {min = 15, max = 20}
  },

  medium = {
    monsters = {
      "Ice Witch", "Cyclops Smith", "Demon Skeleton", "Dragon Hatchling", "Black Knight", "Terror Bird", "Son of Water", "Orc Berserker",
      "Stone Golem", "Bloody Hunter", "Quara Constrictor", "Quara Hydromancer",
      "Quara Pincher", "Ice Golem", "Giant Spider", "Fire Devil", "Marcelline", "Wyvern", "Orc Warlord", "Banshee", "Tilehorned", 
      "Spirit of Water"
    },

    level = {min = 31, max = 60}, reward = {stones = false, points = 1, exp = 0, items = false},
    monsterNum = {min = 20, max = 25}
  },

  hard = {
    monsters = {
      "Hydra", "Mutated Rat", "Mutated Human", "Mutated Bat", "Dragon", "Frost Dragon", "Son of Verminor", "Behemoth", "Sea Serpent", "Kashek", "Munrah", "Ancient Scarab",
      "Worker Golem", "War Golem"
    },
    level = {min = 61, max = 80}, reward = {stones = false, points = 1, exp = 0, items = false},
    monsterNum = {min = 25, max = 30}
  },

  hardcore = {
    monsters = {
      "Hydramat", "Lizard Chosen", "Lizard High Guard", "Lizard Zaogun", "Lizard Legionnaire", "Dragon Lord", "Abadeer", "Hellspawn", "Magma Crawler", "Vulcongra", "Orewalker", "Frazzlemaw", "Choking Fear",
      "Guzzlemaw", "Askarak Demon", "Askarak Lord", "Shaburak Demon", "Shaburak Lord", "Nightfiend", "The Pale Count", "Vicious Manbat",
      "Enslaved Dwarf", "Lost Berserker", "Lost Basher", "Frost Giantess", "Lost Thrower"
      },
    level = {min = 81, max = 100}, reward = {stones = false, points = 1, exp = 0, items = false},
    monsterNum = {min = 25, max = 30}
  },

  extreme = {
    monsters = {
      "Dragon Lord",
      "Draken Elite",
      "Draken Warmaster",
      "Draken Spellweaver",
      "Lizard Zaogun",
      "Frost Giantess",
      "Frost Giant",
      "Lizard High Guard",
      "Lizard Chosen",
      "Humongous Fungus",
      "Hideous Fungus",
      "Crystal Crusher",
      "Hydramat",
      "Crystal Golem",
      "Abadeer",
      "Hellspawn",
      "Magma Crawler",
      "Primate",
      "Vulcongra",
      "Orewalker",
      "Frazzlemaw",
      "Choking Fear",
      "Guzzlemaw",
      "Askarak Demon",
      "Askarak Lord",
      "Shaburak Demon",
      "Shaburak Lord",
      "Nightfiend",
      "The Pale Count",
      "Vicious Manbat",
      "Enslaved Dwarf",
      "Lost Berserker",
      "Lost Basher",
      "Lost Thrower",
      "Weeper",
      "Mawhawk",
      "Vampire Viscount",
      "Lost Husher",
      "Shaburak Prince",
      "Askarak Prince",
      "Minotaur Amazon",
      "Minotaur Hunter",
      "Cliff Strider",
      "Deepling Scout", 
      "Deepling Spellsinger",
      "Deepling Tyrant",
      "Warlock",
      "Sandstone Scorpion",
      "Undead Gladiator",
      "Insectoid Scout",
      "Plaguesmith",
      "Water Outlaw",
      "Serpent Spawn",
      "Diremaw",
      "Deepling Warrior"
    },
   level = {
      min = 101, 
      max = 150
    }, 
    reward = {stones = false, points = 2, exp = 0, items = false},
    monsterNum = {
      min = 45, 
      max = 50
    }
  },

  challenger = {
    monsters = {
      "Jaul",
      "Moohtant",
      "Lava Golem",
      "King Scorpianus",
      "Demodras",
      "Hellflayer",
      "Spider Queen",
      "Olaf",
      "Abyssador"
    },
   level = {
      min = 151, 
      max = 1000
    }, 
    reward = {stones = false, points = 2, exp = 0, items = false},
    monsterNum = {
      min = 1, 
      max = 4
    }
  },
}

function table.removar(tabela, element)
if tabela == nil or tabela == {} then 
return tabela
end
local novatabela = {}
for t, k in pairs(tabela) do 
if k == element then 
table.remove(tabela, t)
return tabela
elseif t == element then
  for t, k in pairs(tabela) do
    if t ~= element then  
    table.insert(novatabela, t, k)
    end
  end
return novatabela
end
end
return tabela
end

function randomizeDailyTasks()
local challengers = {"Jaul", "Moohtant", "Lava Golem", "King Scorpianus", "Demodras", "Hellflayer", "Spider Queen", "Olaf", "Abyssador"}
for i = 0, 3 do 
  for k, v in pairs(dailyTasks) do
    local monster, count = v.monsters[math.random(1, #v.monsters)], math.random(v.monsterNum.min, v.monsterNum.max)
  if k == "challenger" then 
    monster = challengers[math.random(1, #challengers)]
    table.removar(challengers, monster)
  end
    doSetStorage("daily"..k.."monster"..i, monster)
    doSetStorage("daily"..k.."count"..i, count)
  end
end


end

dailyLevels = {
  {min = dailyTasks.easy.level.min, max = dailyTasks.easy.level.max},
  {min = dailyTasks.medium.level.min, max = dailyTasks.medium.level.max},
  {min = dailyTasks.hard.level.min, max = dailyTasks.hard.level.max},
  {min = dailyTasks.hardcore.level.min, max = dailyTasks.hardcore.level.max},
  {min = dailyTasks.extreme.level.min, max = dailyTasks.extreme.level.max},
  {min = dailyTasks.challenger.level.min, max = dailyTasks.challenger.level.max}
}

function getDailyDificult(cid)
  local level = getPlayerLevel(cid)
  local dificults, current = {"easy", "medium", "hard", "hardcore", "extreme", "challenger"}

  for x = 1, #dailyLevels do
    if level >= dailyLevels[x].min and level <= dailyLevels[x].max then
      current = dificults[x]
    end
  end

  --if current == dificults[4] then
    --if getPlayerDailysCompleted(cid) < 5 then
      --return dificults[3]
    --end
  --end

  return current
end

function convertPvp(cid, numero)
  if numero > 500000 then -- limitador de xp por cada diaria
    numero = 500000
  end
  return math.ceil(numero)
end

function getDailyTaskInfos(cid, dificult, forceCourse)
  local dificult = dificult or getPlayerStorageValue(cid, "getDailyDificult"..getDayID())
  local course = getDailyCourse(cid)
  if type(course) ~= "number" or course <= 0 then 
  setPlayerStorageValue(cid, "getCompletedDaily"..getDayID(), 0)
  course = 0
  elseif course >= 4 then 
    course = 3
  end 
  if forceCourse then
    course = forceCourse
  end
  local monster, count = getStorage("daily"..dificult.."monster"..course), getStorage("daily"..dificult.."count"..course)
  local current = dailyTasks[dificult]

  if not current then
    return
  end

  local info = {
    exp = convertPvp(cid, math.ceil((getMonsterInfo(monster).experience*count)*current.reward.exp)),
    count = count, 
    monster = monster, 
    stones = current.reward.stones, 
    points = current.reward.points,
    dificult = dificult,
    items = current.reward.items
  }

  if current.reward.exp == 0 then
    info.exp = 0
  end


  return info
end

function getPlayerDailysCompleted(cid, dificult)
  local storage

  if not dificult then
    storage = getPlayerStorageValue(cid, "getTotalDailys")
  else
    storage = getPlayerStorageValue(cid, "getTotalDailys"..dificult)
  end

  if storage <= 0 then
    return 0
  else
    return storage
  end
end

function getDailyCourse(cid)
  return getPlayerStorageValue(cid, "getCompletedDaily"..getDayID())
end

function canStartDaily(cid)
  if getDailyCourse(cid) < 4 then
    return true
  end

  return false
end

function startDailyTask(cid)
  local dayId = getDayID()

  if canStartDaily(cid) then
    local dificult = getDailyDificult(cid)
    doPlayerSetStorageValue(cid, "getDailyDificult"..dayId, dificult)
    --doPlayerSetStorageValue(cid, "getCompletedDaily"..dayId, 1)
    doPlayerSetStorageValue(cid, "getDailyCount"..dayId, 0)
  doPlayerSetStorageValue(cid, "isInDailyTask", 1)
    return dificult
  end

  return false
end

function getDailyMonsterCount(cid, dailyMaxOnly)
  if not dailyMaxOnly then
    return getPlayerStorageValue(cid, "getDailyCount"..getDayID())
  else
    local infos = getDailyTaskInfos(cid)
    local storage = getPlayerStorageValue(cid, "getDailyCount"..getDayID())

    if storage >= infos.count then
      return infos.count
    else
      return storage
    end
  end
end

function addDailyMonsterCount(cid)
  local dayId = getDayID() 
  local count = getPlayerStorageValue(cid, "getDailyCount"..dayId)
  doPlayerSetStorageValue(cid, "getDailyCount"..dayId, count+1)

  return count+1
end

function addColdownDailyTask(cid)
  local delayTime = 24 -- inHours

  doPlayerSetStorageValue(cid, "dailyTaskColdown", os.time()+delayTime*60*60)
end

function checkDelayIsFree(cid)
  local storage = getPlayerStorageValue(cid, "dailyTaskColdown")

  if os.time() > storage then
    return {state = true, time = 0}
  end

  return {state = false, time = (storage-os.time())}
end

function endDailyTask(cid)
  local infos = getDailyTaskInfos(cid)

  if getPlayerStorageValue(cid, "isInDailyTask") == 1 then
    if getDailyMonsterCount(cid) >= infos.count then
      local element = getPlayerElement(cid)
      local experience, dificult, items = infos.exp, infos.dificult, infos.items

      --registro--
      doPlayerSetStorageValue(cid, "getTotalDailys", getPlayerDailysCompleted(cid)+1)
      doPlayerSetStorageValue(cid, "getTotalDailys"..dificult, getPlayerDailysCompleted(cid, dificult)+1)
      --end--

      doPlayerSetStorageValue(cid, "getCompletedDaily"..getDayID(), getPlayerStorageValue(cid, "getCompletedDaily"..getDayID())+1)
    doPlayerSetStorageValue(cid, "isInDailyTask", 0)

      -- experiencia esta habilitada?
      if experience > 0 then
        --doPlayerAddExperience(cid, experience)
      end

      if type(items) == 'table' then
        premio = items[math.random(#items)]
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, 
            'Você finalizou com sucesso uma task, como recompensa recebeu um presente que foi enviado para seu depot!',
            'You have successfully completed a task, as a reward received a gift that was sent to your depot!'
        ))

        doSendItensToDepot(getCreatureName(cid), 1, {{ itemId = premio.id, amount = math.random(premio.countmin, premio.countmax)} }, true, 'Recompensa por completar reward.')

      end 

      local string = "Daily Reward:"

      if infos.points then
     --   doPlayerSetElementPoints(cid, element, getPlayerElementPoints(cid, element)+infos.points)
    --    addPointsInSkill(cid, "stones", infos.points)
       -- string = string..infos.points..getLangString(cid, " element point(s), ", " ponto(s) elemental(is), ")
      end

      if infos.itens then

      end

      if infos.stones then
        if dificult == "hardcore" then
          if getPlayerDailysCompleted(cid, dificult) <= 20 then
          --  doPlayerAddItem(cid, getStoneItemId(element), infos.stones)
          --  string = string..infos.stones.." "..element.." stones(s), "
          end
        else
        --  doPlayerAddItem(cid, getStoneItemId(element), infos.stones)
         -- string = string..infos.stones.." "..element.." stones(s), "
        end
      end
  if getPlayerStorageValue(cid, "getCompletedDaily"..getDayID()) >= 4 then 
    addColdownDailyTask(cid)
  end
  if getDailyDificult(cid) == "extreme" then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, string.." +2 Paragon Level.")
    local newParagon = getPlayerResets(cid)+2
    setPlayerResets(cid, newParagon)
    onUpgradeParagon(cid, newParagon-1)
    onUpgradeParagon(cid, newParagon)
  else if getDailyDificult(cid) == "challenger" then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, string.." +3 Paragon Level.")
    local newParagonTres = getPlayerResets(cid)+3
    setPlayerResets(cid, newParagonTres)
    onUpgradeParagon(cid, newParagonTres-2)
    onUpgradeParagon(cid, newParagonTres-1)
    onUpgradeParagon(cid, newParagonTres)
  else
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, string.." +1 Paragon Level.")
    local newParagonDois = getPlayerResets(cid)+1
    setPlayerResets(cid, newParagonDois)
    onUpgradeParagon(cid, newParagonDois)
  end
end
      return true
    end
  end

  return false
end

function getDailyTaskList(cid)
  local string = "                                   » Daily Tasks «\n"
  local course = getDailyCourse(cid)
  local isInDl = getPlayerStorageValue(cid, "isInDailyTask")

  if course < 4 and isInDl ~= 1 then
    string = string..getLangString(cid, "\nAvaiable in NPC Fizz.", "\nDisponível no NPC Fizz.")
  
  elseif isInDl == 1 then
    local infos = getDailyTaskInfos(cid)
  if getDailyMonsterCount(cid, true) == infos.count then 
    string = string..getLangString(cid, "\nFinished! Go back and talk to Fizz.", "\nFinalizada! Volte e fale com o NPC Fizz.")..""
  else
    string = string..getLangString(cid, "\nIn progress:", "\nEm progresso:").." ["..getDailyMonsterCount(cid, true).."/"..infos.count.." - "..infos.monster.."]."
  end
  else
    string = string..getLangString(cid, "\nCompleted! Come back tomorrow.", "\nCompletadas! Volte amanhã.")
  end

  string = string.."\n"..getLangString(cid, "\nDailys tasks completed: "..course.."/4.", "\nTasks diárias completadas: "..course.. "/4.")
  --string = string.."\n"..getLangString(cid, "\nCurrent dificult: "..getDailyDificult(cid), "\nDificuldade atual: "..getDailyDificult(cid))..""
  --string = string.."\n\n"..getLangString(cid, "Total Dailys tasks completed: "..getPlayerDailysCompleted(cid), "Total de tasks diárias completadas: "..getPlayerDailysCompleted(cid))

  return string
end