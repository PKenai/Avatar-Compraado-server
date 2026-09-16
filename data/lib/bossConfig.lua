--[[
 * bossConfig.lua -- GERADO AUTOMATICAMENTE por tools/generate_bosses.py
 *
 * Tabela de ligacao do sistema ALPHA:
 *   [nome do monstro] = {
 *       boss     = nome do monstro ALPHA correspondente
 *       material = item de craft que o monstro droppa (pode ser nil)
 *       glove    = luva completa que o boss pode droppar (4%)
 *       kills    = meta de kills da task diaria (max 1000)
 *   }
 *
 * Nao edite a mao: rode `python tools/generate_bosses.py`.
]]

BossConfig = BossConfig or {}

BossConfig.prefix = 'ALPHA '

BossConfig.gloveChance = 5000
BossConfig.gloveChancePercent = 4.00  -- % efetiva com rateLoot=0.10
BossConfig.crystalChance = 100000 -- 100000 = sempre dropa (1 a 3 moedas)
BossConfig.crystalCountmax = 3
BossConfig.tileItemId = 19333
BossConfig.tileItemId2 = 19334
BossConfig.tileActionId = 50030

BossConfig.monsters = {
  ["Ba Sing Se Lion"] = { boss = "ALPHA Ba Sing Se Lion", material = 19121, glove = 19120, kills = 324, experience = 2500 },
  ["Black Panther"] = { boss = "ALPHA Black Panther", material = 19147, glove = 19146, kills = 675, experience = 13000 },
  ["Blue Hydra Head"] = { boss = "ALPHA Blue Hydra Head", material = nil, glove = nil, kills = 1000, experience = 50000 },
  ["Cemetery Worm"] = { boss = "ALPHA Cemetery Worm", material = 19103, glove = 19102, kills = 240, experience = 1200 },
  ["Cockroach"] = { boss = "ALPHA Cockroach", material = 19099, glove = 19098, kills = 170, experience = 475 },
  ["Desert Crocodile"] = { boss = "ALPHA Desert Crocodile", material = nil, glove = nil, kills = 1000, experience = 36500 },
  ["Earth Beetle"] = { boss = "ALPHA Earth Beetle", material = 19101, glove = 19100, kills = 222, experience = 980 },
  ["Earth Ladybug"] = { boss = "ALPHA Earth Ladybug", material = 19107, glove = 19106, kills = 226, experience = 1025 },
  ["Earth Mordecai"] = { boss = "ALPHA Earth Mordecai", material = 19135, glove = 19134, kills = 418, experience = 4500 },
  ["Earth Woodpecker"] = { boss = "ALPHA Earth Woodpecker", material = 19129, glove = 19128, kills = 374, experience = 3500 },
  ["Elephant"] = { boss = "ALPHA Elephant", material = 19127, glove = 19126, kills = 360, experience = 3200 },
  ["Fierce Bear"] = { boss = "ALPHA Fierce Bear", material = 19109, glove = 19108, kills = 269, experience = 1600 },
  ["Forbidden Folds Book"] = { boss = "ALPHA Forbidden Folds Book", material = 19153, glove = 19152, kills = 900, experience = 24000 },
  ["Giant Cricket"] = { boss = "ALPHA Giant Cricket", material = 19131, glove = 19130, kills = 457, experience = 5500 },
  ["Giant Snail"] = { boss = "ALPHA Giant Snail", material = 19125, glove = 19124, kills = 457, experience = 5500 },
  ["Gleaming Beetle"] = { boss = "ALPHA Gleaming Beetle", material = 19119, glove = 19118, kills = 307, experience = 2200 },
  ["Green Hydra Head"] = { boss = "ALPHA Green Hydra Head", material = nil, glove = nil, kills = 1000, experience = 50000 },
  ["Guardian Beetle"] = { boss = "ALPHA Guardian Beetle", material = nil, glove = nil, kills = 50, experience = 0 },
  ["Hermit Crab"] = { boss = "ALPHA Hermit Crab", material = 19143, glove = 19142, kills = 430, experience = 4800 },
  ["Hippo"] = { boss = "ALPHA Hippo", material = nil, glove = nil, kills = 283, experience = 1800 },
  ["Hopper"] = { boss = "ALPHA Hopper", material = nil, glove = nil, kills = 1000, experience = 34300 },
  ["Jaguar"] = { boss = "ALPHA Jaguar", material = 19141, glove = 19140, kills = 541, experience = 8000 },
  ["Mountain Defender"] = { boss = "ALPHA Mountain Defender", material = nil, glove = nil, kills = 50, experience = 0 },
  ["Mud Bee"] = { boss = "ALPHA Mud Bee", material = 19113, glove = 19112, kills = 250, experience = 1325 },
  ["Mud Man"] = { boss = "ALPHA Mud Man", material = 19117, glove = 19116, kills = 289, experience = 1900 },
  ["Rock-Eating Cockroach"] = { boss = "ALPHA Rock-Eating Cockroach", material = 19151, glove = 19150, kills = 826, experience = 20000 },
  ["Sea Iguana"] = { boss = "ALPHA Sea Iguana", material = 19139, glove = 19138, kills = 786, experience = 18000 },
  ["Steel Shell Centipede"] = { boss = "ALPHA Steel Shell Centipede", material = 19123, glove = 19122, kills = 340, experience = 2800 },
  ["Stone Tarantula"] = { boss = "ALPHA Stone Tarantula", material = 19115, glove = 19114, kills = 300, experience = 2075 },
  ["Stone-Spitting Spider"] = { boss = "ALPHA Stone-Spitting Spider", material = 19111, glove = 19110, kills = 350, experience = 3000 },
  ["Swamp Man Arm"] = { boss = "ALPHA Swamp Man Arm", material = nil, glove = nil, kills = 475, experience = 6000 },
  ["Swamp Man Head"] = { boss = "ALPHA Swamp Man Head", material = nil, glove = nil, kills = 598, experience = 10000 },
  ["Swamp Monster"] = { boss = "ALPHA Swamp Monster", material = nil, glove = nil, kills = 598, experience = 10000 },
  ["Swamp Tentacles"] = { boss = "ALPHA Swamp Tentacles", material = nil, glove = nil, kills = 223, experience = 1000 },
  ["Traitor"] = { boss = "ALPHA Traitor", material = 19137, glove = 19136, kills = 453, experience = 5400 },
  ["Trenix"] = { boss = "ALPHA Trenix", material = nil, glove = nil, kills = 968, experience = 28000 },
  ["Uncontrolled Knowledge"] = { boss = "ALPHA Uncontrolled Knowledge", material = 19145, glove = 19144, kills = 625, experience = 11000 },
  ["Vacaceronte"] = { boss = "ALPHA Vacaceronte", material = nil, glove = nil, kills = 651, experience = 12000 },
  ["Vulture Bee"] = { boss = "ALPHA Vulture Bee", material = 19133, glove = 19132, kills = 388, experience = 3800 },
  ["Warm Cape Crab"] = { boss = "ALPHA Warm Cape Crab", material = 19105, glove = 19104, kills = 374, experience = 3500 },
  ["White Scarab"] = { boss = "ALPHA White Scarab", material = nil, glove = nil, kills = 968, experience = 28000 },
}

-- Criaturas que NAO entram no sorteio da task diaria (andar de evento/quest).
BossConfig.dailyExcluded = {
  ["Blue Hydra Head"] = true,
  ["Green Hydra Head"] = true,
  ["Guardian Beetle"] = true,
  ["Mountain Defender"] = true,
  ["Swamp Man Arm"] = true,
  ["Swamp Man Head"] = true,
  ["Swamp Monster"] = true,
  ["Swamp Tentacles"] = true,
}
