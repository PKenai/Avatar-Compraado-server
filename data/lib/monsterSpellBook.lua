--[[
  monsterSpellBook.lua - as spells assinatura dos monstros.

  Chave = nome do monstro (como esta' no XML dele). Toda spell daqui
  usa o mesmo motor (data/spells/scripts/monster/monsterSpell.lua), que
  descobre a spell pelo nome de quem esta' conjurando.

  shape: blast | burst | nova | wave | beam | breath | rain
  O dano nao esta aqui: ele vem do <attack min max> no XML do monstro.
  Gerado por tools/gen_monster_spells.py - mudar aqui a mao se perde.
]]

monsterSpellBook = {
  ["Ba Sing Se Lion"] = {
    spell = "Ba Sing Se Roar", element = "fire", shape = "nova", radius = 3
  },
  ["Black Panther"] = {
    spell = "Panther Pounce", element = "physical", shape = "burst", radius = 2
  },
  ["Blue Hydra Head"] = {
    spell = "Blue Hydra Storm", element = "energy", shape = "rain", radius = 2, count = 7
  },
  ["Cemetery Worm"] = {
    spell = "Grave Burrow", element = "poison", shape = "burst", radius = 1, cond = "poison"
  },
  ["Cockroach"] = {
    spell = "Carapace Scuttle", element = "earth", shape = "nova", radius = 1
  },
  ["Desert Crocodile"] = {
    spell = "Sandwater Ambush", element = "water", shape = "breath", length = 4, width = 0
  },
  ["Earth Beetle"] = {
    spell = "Beetle Tremor", element = "earth", shape = "nova", radius = 1
  },
  ["Earth Ladybug"] = {
    spell = "Ladybug Quake", element = "earth", shape = "wave", length = 3, width = 1
  },
  ["Earth Mordecai"] = {
    spell = "Mordecai's Landslide", element = "earth", shape = "breath", length = 4, width = 0
  },
  ["Earth Woodpecker"] = {
    spell = "Stone Peck", element = "physical", shape = "beam", length = 4, width = 0
  },
  ["Elephant"] = {
    spell = "Tusk Stampede", element = "physical", shape = "wave", length = 4, width = 1
  },
  ["Fierce Bear"] = {
    spell = "Bear Maul", element = "physical", shape = "breath", length = 2, width = 0
  },
  ["Forbidden Folds Book"] = {
    spell = "Forbidden Chapter", element = "death", shape = "rain", radius = 2, count = 6, cond = "curse"
  },
  ["Giant Cricket"] = {
    spell = "Chirp Screech", element = "physical", shape = "nova", radius = 2
  },
  ["Giant Snail"] = {
    spell = "Slime Trail", element = "poison", shape = "beam", length = 3, width = 0, cond = "poison"
  },
  ["Gleaming Beetle"] = {
    spell = "Gleam Flash", element = "energy", shape = "nova", radius = 2
  },
  ["Green Hydra Head"] = {
    spell = "Green Hydra Spores", element = "poison", shape = "nova", radius = 3, cond = "corrode"
  },
  ["Guardian Beetle"] = {
    spell = "Guardian's Tremor", element = "earth", shape = "nova", radius = 3
  },
  ["Hermit Crab"] = {
    spell = "Shell Smash", element = "physical", shape = "burst", radius = 1
  },
  ["Hippo"] = {
    spell = "River Crush", element = "physical", shape = "nova", radius = 2
  },
  ["Hopper"] = {
    spell = "Hopper Cyclone", element = "air", shape = "nova", radius = 3
  },
  ["Jaguar"] = {
    spell = "Jaguar Maul", element = "physical", shape = "burst", radius = 1
  },
  ["Momo"] = {
    spell = "Little Fury", element = "physical", shape = "blast"
  },
  ["Mountain Defender"] = {
    spell = "Mountain Slam", element = "earth", shape = "nova", radius = 3
  },
  ["Mud Bee"] = {
    spell = "Mud Swarm", element = "poison", shape = "rain", radius = 2, count = 6, cond = "poison"
  },
  ["Mud Man"] = {
    spell = "Mud Grasp", element = "earth", shape = "burst", radius = 2
  },
  ["Rock-Eating Cockroach"] = {
    spell = "Rock Crunch", element = "physical", shape = "burst", radius = 2
  },
  ["Sea Iguana"] = {
    spell = "Tidal Snap", element = "water", shape = "wave", length = 4, width = 1
  },
  ["Steel Shell Centipede"] = {
    spell = "Steel Coil", element = "physical", shape = "wave", length = 3, width = 1
  },
  ["Stone Tarantula"] = {
    spell = "Venom Web", element = "poison", shape = "nova", radius = 2, cond = "poison"
  },
  ["Stone-Spitting Spider"] = {
    spell = "Stone Spit", element = "earth", shape = "blast"
  },
  ["Swamp Man Arm"] = {
    spell = "Swamp Slam", element = "physical", shape = "wave", length = 3, width = 1
  },
  ["Swamp Man Head"] = {
    spell = "Swamp Miasma", element = "poison", shape = "nova", radius = 3, cond = "poison"
  },
  ["Swamp Monster"] = {
    spell = "Swamp Devour", element = "poison", shape = "breath", length = 4, width = 0, cond = "poison"
  },
  ["Swamp Tentacles"] = {
    spell = "Tentacle Drag", element = "water", shape = "beam", length = 3, width = 0
  },
  ["Traitor"] = {
    spell = "Backstab Dust", element = "earth", shape = "blast"
  },
  ["Trenix"] = {
    spell = "Trenix Inferno", element = "fire", shape = "breath", length = 4, width = 0, cond = "burn"
  },
  ["Uncontrolled Knowledge"] = {
    spell = "Whispered Madness", element = "death", shape = "nova", radius = 3, cond = "curse"
  },
  ["Vacaceronte"] = {
    spell = "Charging Horns", element = "physical", shape = "beam", length = 5, width = 0
  },
  ["Vulture Bee"] = {
    spell = "Carrion Sting", element = "poison", shape = "rain", radius = 2, count = 6, cond = "poison"
  },
  ["Warm Cape Crab"] = {
    spell = "Scalding Tide", element = "water", shape = "nova", radius = 2
  },
  ["White Scarab"] = {
    spell = "Sacred Sandstorm", element = "earth", shape = "rain", radius = 3, count = 8
  },
}
