--[[
 * LINKED TASKS - Sistema de Tasks Encadeadas (estilo Rubinot)
 * ------------------------------------------------------------------
 * 5 salas (Sala 1 a Sala 5). Cada sala possui 7 tasks de matar monstros
 * e 1 bau central no meio.
 *
 * COMO FUNCIONA:
 *  - Cada sala tem 7 "displays" (itens no mapa). Clicou no display da
 *    task, ela comeca. Clicou de novo enquanto ATIVA, ela se auto-cancela.
 *  - Ao completar os KILLS, a task fica "pronta para entrega": o player
 *    precisa clicar NOVAMENTE no display para ENTREGAR a task e receber
 *    a recompensa. So apos a entrega a task conta como concluida.
 *  - SALAS SEQUENCIAIS (sequential = true, ex: Sala 1): as tasks so
 *    podem ser feitas em ordem. A task 2 so libera apos ENTREGAR a 1,
 *    e so pode haver UMA task ativa por vez na sala.
 *  - SALAS LIVRES (sequential = false): tasks em qualquer ordem, varias
 *    ativas ao mesmo tempo.
 *  - Ao entregar as 7 tasks da sala, o BAU CENTRAL e liberado e da um
 *    premio aleatorio ao player.
 *  - RECOMPENSAS: ouro (2148/2152/2160) vai direto para o BANCO do
 *    player (convertido em gold). Itens vao direto para a REWARD MAILBOX
 *    do player (item 18358, ao lado do Depot no locker). Experiencia e
 *    aplicada direto.
 *
 * STORAGES (por player - todos automaticos a partir de task.storage):
 *   task.storage      -> status: 0 = nao iniciada, 1 = ativa (matando),
 *                        2 = kills completos (pronta p/ entrega), 3 = entregue
 *   task.storage + 1  -> kills atuais da task
 *   task.storage + 2  -> quantas vezes a task ja foi ENTREGUE
 *   room.chestStorage -> quantas vezes o bau central da sala foi aberto
 *
 * ACTION IDS (registrados em data/actions/actions.xml):
 *   Display da task (sala R, task T) -> 46000 + R*10 + T   (46011 a 46057)
 *   Bau central (sala R)             -> 46100 + R          (46101 a 46105)
 *
 * REWARDS (campo reward da task, lista de {itemId, quantidade}):
 *   itemId = -1  -> entrega 1x Training Wand da classe do player
 *                  (Fire=18337, Water=18336, Air=18338, Earth=18339)
 *   itemId = 2148 -> gold coin
 *   campo exp    -> experiencia aplicada x Rate do servidor (rateExperience)
 *
 * OBS: use apenas caracteres ASCII nos textos (sem acentos) para nao
 * quebrar a exibicao no client.
 *]]

-- ============================================================
-- CONFIGURACAO GERAL
-- ============================================================

linkedTasksConfig = {
  -- true  = o servidor cria os displays e baus no mapa ao ligar (usando as posicoes abaixo)
  -- false = voce coloca os itens manualmente no mapa (RME) com os actionids 46011-46057 e 46101-46105
  autoSpawn = true,

  displayItemId = 1441, -- item usado como display da task (sign)
  chestItemId   = 1740  -- item usado como bau central (chest)
}

-- Training Wand por classe (elemento). IDs: 18336=Water, 18337=Fire, 18338=Air, 18339=Earth
-- Vocations: 1/5 = Fire, 2/6 = Water, 3/7 = Air, 4/8 = Earth, 0 = sem vocacao
linkedTrainingWandByVocation = {
  [0] = 18337,
  [1] = 18337, [5] = 18337,
  [2] = 18336, [6] = 18336,
  [3] = 18338, [7] = 18338,
  [4] = 18339, [8] = 18339
}

-- ============================================================
-- SALAS (AJUSTE AQUI AS POSICOES DO SEU MAPA!)
-- ------------------------------------------------------------------
-- displayPos: posicao do PRIMEIRO display. Os outros 6 sao criados em
--             sequencia no eixo X usando displaySpacing (ou pode passar
--             uma lista com as 7 posicoes exatas).
-- chestPos:   posicao do bau central.
-- Deixe x = 0 para nao criar (e coloque o item manualmente no RME).
--
-- OBS: cada sala deve ter monstros UNICOS (nao repita o mesmo monstro
-- em 2 tasks da mesma sala, senao so a primeira task contara kills).
-- ============================================================

linkedTasksRooms = {
  ------------------------------------------------------------------
  -- SALA 1 - SEQUENCIAL (so libera a proxima task apos concluir a anterior)
  ------------------------------------------------------------------
  [1] = {
    name = "Sala 1",
    sequential     = true,                -- tasks em ordem obrigatoria, 1 ativa por vez
    displayPos     = {x = 0, y = 0, z = 7}, -- <-- posicao do 1o display
    displaySpacing = 2,
    chestPos       = {x = 0, y = 0, z = 7}, -- <-- posicao do bau central
    chestStorage    = 45501,  -- storage do bau (quantas vezes abriu)
    chestRepeatable = true,   -- pode abrir mais de uma vez?
    chestMaxOpens   = 5,      -- se repetivel, quantas vezes
    chestExp        = 2000,   -- exp extra ao abrir o bau (x Rate)
    chestRewards = {          -- premios aleatorios (sorteia 1 grupo)
      {{2148, 10000}},
      {{2148, 25000}},
      {{2148, 50000}},
      {{2148, 100000}},
      {{2148, 250000}}
    },
    tasks = {
      {name = "Cacador de Rotworms",     storage = 45001, monster = "Rotworm",        amount = 250,  reward = {{2148, 20000}}, exp = 10000,  repeatable = true, maxRepeats = 2},
      {name = "Cacador de Anoes",        storage = 45006, monster = "Enslaved Dwarf", amount = 300,  reward = {{-1, 1}}},
      {name = "Cacador de Elfos",        storage = 45011, monster = "Elf",            amount = 500,  reward = {{2148, 30000}}, exp = 25000},
      {name = "Cacador de Ciclopes",     storage = 45016, monsters = {"Cyclops", "Cyclops Smith", "Cyclops Drone"}, amount = 1000, reward = {{2148, 60000}}, exp = 35000},
      {name = "Cacador de Terror Birds", storage = 45021, monster = "Terror Bird",    amount = 500,  reward = {{2148, 40000}}, exp = 70000,  repeatable = true, maxRepeats = 2},
      {name = "Cacador de Gargoyles",    storage = 45026, monster = "Gargoyle",       amount = 1000, reward = {{-1, 1}}},
      {name = "Cacador de Destroyers",   storage = 45031, monster = "Destroyer",      amount = 1500, reward = {},            exp = 800000, repeatable = true, maxRepeats = 2}
    }
  },

  ------------------------------------------------------------------
  -- SALA 2 - nivel 20-40
  ------------------------------------------------------------------
  [2] = {
    name = "Sala 2",
    displayPos     = {x = 0, y = 0, z = 7},
    displaySpacing = 2,
    chestPos       = {x = 0, y = 0, z = 7},
    chestStorage   = 45502,
    chestRepeatable = true,
    chestMaxOpens   = 5,
    chestExp        = 5000,
    chestRewards = {
      {{2160, 3}, {2195, 2}},
      {{2152, 50000}},
      {{2160, 6}, {2466, 1}},          -- golden armor
      {{2152, 75000}},
      {{2160, 10}}
    },
    tasks = {
      {name = "Cacador de Minotauros",   storage = 45036, monster = "Minotaur",      amount = 40, reward = {{2152, 8000}},  exp = 2500, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Elfos",        storage = 45041, monster = "Elf",           amount = 40, reward = {{2152, 8000}},  exp = 2500, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Ghouls",       storage = 45046, monster = "Ghoul",         amount = 40, reward = {{2152, 9000}},  exp = 3000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Berserkers",   storage = 45051, monster = "Orc Berserker", amount = 45, reward = {{2152, 10000}}, exp = 3500, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Terror Birds", storage = 45056, monster = "Terror Bird",   amount = 45, reward = {{2152, 12000}}, exp = 4000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Ferreiros",    storage = 45061, monster = "Cyclops Smith", amount = 50, reward = {{2152, 15000}}, exp = 5000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Diabos de Fogo", storage = 45066, monster = "Fire Devil",  amount = 50, reward = {{2152, 18000}}, exp = 6000, repeatable = true, maxRepeats = 3}
    }
  },

  ------------------------------------------------------------------
  -- SALA 3 - nivel 40-70
  ------------------------------------------------------------------
  [3] = {
    name = "Sala 3",
    displayPos     = {x = 0, y = 0, z = 7},
    displaySpacing = 2,
    chestPos       = {x = 0, y = 0, z = 7},
    chestStorage   = 45503,
    chestRepeatable = true,
    chestMaxOpens   = 4,
    chestExp        = 15000,
    chestRewards = {
      {{2160, 8}, {2435, 1}},          -- dwarven axe
      {{2152, 120000}},
      {{2160, 12}, {7386, 1}},         -- mercenary sword
      {{2160, 15}, {2536, 1}},         -- medusa shield
      {{2160, 25}}
    },
    tasks = {
      {name = "Cacador de Esqueletos Demoniacos", storage = 45071, monster = "Demon Skeleton", amount = 60, reward = {{2152, 20000}}, exp = 8000,  repeatable = true, maxRepeats = 3},
      {name = "Cacador de Filhotes de Dragao",    storage = 45076, monster = "Dragon Hatchling", amount = 60, reward = {{2152, 25000}}, exp = 10000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Necromantes",           storage = 45081, monster = "Necromancer",     amount = 60, reward = {{2152, 25000}}, exp = 10000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Feiticeiros",           storage = 45086, monster = "Warlock",         amount = 70, reward = {{2152, 30000}}, exp = 12000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Hidras",                storage = 45091, monster = "Hydra",           amount = 70, reward = {{2152, 35000}}, exp = 15000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Behemoths",             storage = 45096, monster = "Behemoth",        amount = 60, reward = {{2152, 35000}}, exp = 15000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Dragoes",               storage = 45101, monster = "Dragon",          amount = 70, reward = {{2152, 40000}}, exp = 18000, repeatable = true, maxRepeats = 3}
    }
  },

  ------------------------------------------------------------------
  -- SALA 4 - nivel 70-120
  ------------------------------------------------------------------
  [4] = {
    name = "Sala 4",
    displayPos     = {x = 0, y = 0, z = 7},
    displaySpacing = 2,
    chestPos       = {x = 0, y = 0, z = 7},
    chestStorage   = 45504,
    chestRepeatable = true,
    chestMaxOpens   = 4,
    chestExp        = 30000,
    chestRewards = {
      {{2160, 15}, {2498, 1}},         -- royal helmet
      {{2160, 20}, {7388, 1}},         -- vile axe
      {{2160, 25}, {13630, 1}},        -- frozen helmet
      {{2160, 30}, {13637, 1}},        -- dominant chest
      {{2160, 50}}
    },
    tasks = {
      {name = "Cacador de Dragoes Mortos-Vivos", storage = 45106, monster = "Undead Dragon", amount = 70, reward = {{2152, 50000}}, exp = 25000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Dragoes de Gelo",      storage = 45111, monster = "Frost Dragon",  amount = 80, reward = {{2152, 55000}}, exp = 28000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Lordes Dragoes",       storage = 45116, monster = "Dragon Lord",   amount = 80, reward = {{2152, 60000}}, exp = 30000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Medusas",              storage = 45121, monster = "Medusa",        amount = 80, reward = {{2152, 65000}}, exp = 35000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Serpentes",            storage = 45126, monster = "Serpent Spawn", amount = 80, reward = {{2152, 65000}}, exp = 35000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Wyrms",                storage = 45131, monster = "Wyrm",          amount = 80, reward = {{2152, 70000}}, exp = 40000, repeatable = true, maxRepeats = 3},
      {name = "Cacador de Feiticeiros Sombrios", storage = 45136, monster = "Dark Warlock",  amount = 70, reward = {{2152, 75000}}, exp = 45000, repeatable = true, maxRepeats = 3}
    }
  },

  ------------------------------------------------------------------
  -- SALA 5 - nivel 120+ (a mais dificil)
  ------------------------------------------------------------------
  [5] = {
    name = "Sala 5",
    displayPos     = {x = 0, y = 0, z = 7},
    displaySpacing = 2,
    chestPos       = {x = 0, y = 0, z = 7},
    chestStorage   = 45505,
    chestRepeatable = true,
    chestMaxOpens   = 3,
    chestExp        = 75000,
    chestRewards = {
      {{2160, 30}, {8924, 1}},         -- hellforged axe
      {{2160, 40}, {13632, 1}, {13633, 1}}, -- frozen legs + frozen boots
      {{2160, 50}, {13638, 1}},        -- dominant legs
      {{2160, 75}, {13640, 1}},        -- dominant shield
      {{2160, 100}}
    },
    tasks = {
      {name = "Cacador de Demonios",          storage = 45141, monster = "Demon",          amount = 80, reward = {{2152, 100000}}, exp = 60000, repeatable = false},
      {name = "Cacador de Destruidores",      storage = 45146, monster = "Destroyer",      amount = 60, reward = {{2152, 120000}}, exp = 70000, repeatable = false},
      {name = "Cacador de Grim Reapers",      storage = 45151, monster = "Grim Reaper",    amount = 80, reward = {{2152, 120000}}, exp = 70000, repeatable = false},
      {name = "Cacador de Nightfiends",       storage = 45156, monster = "Nightfiend",     amount = 80, reward = {{2152, 130000}}, exp = 80000, repeatable = false},
      {name = "Cacador de Dragoes Sinistros", storage = 45161, monster = "Ghastly Dragon", amount = 50, reward = {{2152, 150000}}, exp = 90000, repeatable = false},
      {name = "Cacador de Leviatas",          storage = 45166, monster = "Leviathan",      amount = 40, reward = {{2152, 180000}}, exp = 100000, repeatable = false},
      {name = "Cacador de Elder Wyrms",       storage = 45171, monster = "Elder Wyrm",     amount = 50, reward = {{2152, 180000}}, exp = 100000, repeatable = false}
    }
  }
}

-- ============================================================
-- FUNCOES INTERNAS
-- ============================================================

-- retorna o valor de um storage tratando -1 (nao setado) como 0
function linkedStorageValue(cid, storage)
  local v = getPlayerStorageValue(cid, storage)
  if not v or v < 0 then
    return 0
  end
  return v
end

function linkedTaskStatus(cid, task)
  return linkedStorageValue(cid, task.storage)
end

function linkedTaskKills(cid, task)
  return linkedStorageValue(cid, task.storage + 1)
end

function linkedTaskCompletions(cid, task)
  return linkedStorageValue(cid, task.storage + 2)
end

-- nome(s) do monstro da task para mensagens e texto do display
function linkedTaskMonsterLabel(task)
  if task.monsters and type(task.monsters) == "table" and #task.monsters > 0 then
    return table.concat(task.monsters, ", ")
  end
  return task.monster or "?"
end

-- texto do objetivo: "250 Rotworm(s)" ou "1000 de: Cyclops, Cyclops Smith, Cyclops Drone"
function linkedTaskGoalText(task)
  if task.monsters and type(task.monsters) == "table" and #task.monsters > 1 then
    return task.amount .. " de: " .. table.concat(task.monsters, ", ")
  end
  return task.amount .. " " .. (task.monster or "?") .. "(s)"
end

-- a task aceita o monstro morto? (suporta lista de monstros, ex: os 3 ciclopes)
function linkedTaskMatchesMonster(task, monsterName)
  if task.monsters and type(task.monsters) == "table" then
    for i = 1, #task.monsters do
      if string.lower(task.monsters[i]) == monsterName then
        return true
      end
    end
    return false
  end
  return task.monster and string.lower(task.monster) == monsterName
end

-- Training Wand da classe do player (Fire/Water/Air/Earth)
function linkedTrainingWandFor(cid)
  return linkedTrainingWandByVocation[getPlayerVocation(cid)] or 18337
end

-- experiencia aplicando o Rate do servidor (rateExperience em config.lua)
-- NOTA: NAO usar getExperienceStage(level) aqui - isso retorna o multiplicador
-- de stage (ex: 0.08 no level 150), nao o rate do servidor. Usamos
-- getConfigValue("rateExperience") para o "x Rate" pedido pelo dono.
function linkedExpWithRate(cid, amount)
  if not amount or amount <= 0 then
    return 0
  end
  local rate = getConfigValue("rateExperience")
  if not rate or rate <= 0 then
    rate = 1
  end
  return math.floor(amount * rate)
end

-- ============================================================
-- CONTROLE DE TASK
-- ============================================================

function linkedTaskStart(cid, task)
  setPlayerStorageValue(cid, task.storage, 1)
  setPlayerStorageValue(cid, task.storage + 1, 0)
end

function linkedTaskCancel(cid, task)
  setPlayerStorageValue(cid, task.storage, 0)
  setPlayerStorageValue(cid, task.storage + 1, 0)
end

-- moedas que sao DINHEIRO -> vao para o BANCO (valor em gold por unidade)
-- 2148 = gold coin (x1), 2152 = platinum coin (x100), 2160 = crystal coin (x10000)
linkedMoneyItems = {
  [2148] = 1,
  [2152] = 100,
  [2160] = 10000
}

-- entrega itens DIRETAMENTE na REWARD MAILBOX do player (item 18358),
-- que fica ao lado do Depot dentro do locker (4 slots).
-- Precisa do binding C++ doPlayerAddItemToRewardBox (exe recompilado).
-- Fallbacks: deposito (doPlayerAddItemToDepot) e, por ultimo, a mochila.
function linkedGiveItemToDepot(cid, itemId, count)
  if doPlayerAddItemToRewardBox then
    if doPlayerAddItemToRewardBox(cid, itemId, count) then
      return "reward mailbox"
    end
  end
  if doPlayerAddItemToDepot then
    for depotid = 1, 10 do
      if doPlayerAddItemToDepot(cid, depotid, itemId, count) then
        return "deposito"
      end
    end
  end
  doPlayerAddItem(cid, itemId, count)
  return "mochila"
end

-- entrega uma lista de recompensas {itemId, quantidade} e devolve o texto
-- ouro -> banco (doPlayerSetBalance), itens -> reward mailbox, wand (-1) -> reward mailbox
function linkedGiveRewardList(cid, reward)
  local parts = {}
  if reward and type(reward) == "table" and #reward > 0 then
    for i = 1, #reward do
      local itemId = reward[i][1]
      local count = reward[i][2] or 1
      if itemId == -1 then
        itemId = linkedTrainingWandFor(cid)
      end
      local goldPerUnit = linkedMoneyItems[itemId]
      if goldPerUnit then
        local gold = count * goldPerUnit
        doPlayerSetBalance(cid, getPlayerBalance(cid) + gold)
        table.insert(parts, gold .. " de ouro no banco")
      else
        local dest = linkedGiveItemToDepot(cid, itemId, count)
        local destText = "na reward mailbox"
        if dest == "deposito" then
          destText = "no deposito"
        elseif dest == "mochila" then
          destText = "na mochila"
        end
        table.insert(parts, count .. "x " .. getItemNameById(itemId) .. " " .. destText)
      end
    end
  end
  return parts
end

-- entrega a recompensa da task (ouro -> banco, itens -> reward mailbox, exp) e
-- devolve a lista completa como texto
function linkedGiveTaskReward(cid, task)
  local parts = linkedGiveRewardList(cid, task.reward)
  if task.exp and task.exp > 0 then
    local expGain = linkedExpWithRate(cid, task.exp)
    doPlayerAddExperience(cid, expGain)
    table.insert(parts, expGain .. " de experiencia")
  end
  return table.concat(parts, ", ")
end

-- quantas tasks da sala ja foram concluidas (pelo menos 1 vez)
function linkedRoomDoneCount(cid, roomId)
  local room = linkedTasksRooms[roomId]
  if not room then
    return 0
  end
  local count = 0
  for i = 1, #room.tasks do
    if linkedTaskCompletions(cid, room.tasks[i]) >= 1 then
      count = count + 1
    end
  end
  return count
end

-- a sala esta 100% concluida? (bau central liberado)
function linkedRoomIsDone(cid, roomId)
  local room = linkedTasksRooms[roomId]
  if not room then
    return false
  end
  return linkedRoomDoneCount(cid, roomId) >= #room.tasks
end

-- em salas sequenciais, a task so pode ser iniciada se as anteriores
-- foram concluidas e se nao ha outra task ativa na sala.
function linkedCanStartTask(cid, room, taskIndex)
  if room.sequential and taskIndex > 1 then
    local prev = room.tasks[taskIndex - 1]
    if linkedTaskCompletions(cid, prev) < 1 then
      return false, "Complete a task " .. (taskIndex - 1) .. " para liberar esta."
    end
  end

  if room.sequential then
    for j = 1, #room.tasks do
      if j ~= taskIndex and linkedTaskStatus(cid, room.tasks[j]) == 1 then
        return false, "Voce ja tem a Task " .. j .. " ativa nesta sala. Clique no display dela para cancelar ou termine-a primeiro."
      end
    end
  end

  return true
end

-- chama quando a task atinge a quantia de kills (a partir do onKill).
-- A task fica PRONTA PARA ENTREGA (status 2): o player precisa clicar
-- novamente no display para entregar e receber a recompensa.
function linkedTaskReadyToClaim(cid, roomId, task)
  setPlayerStorageValue(cid, task.storage, 2)
  setPlayerStorageValue(cid, task.storage + 1, 0)

  local pos = getCreaturePosition(cid)
  doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Kills completos em: " .. task.name .. "! Clique NOVAMENTE no display para ENTREGAR a task e receber a recompensa.")
  doSendMagicEffect(pos, CONST_ME_MAGIC_BLUE)
  doSendAnimatedText(pos, "Pronto!", 215)
end

-- ENTREGA a task (clique no display com status 2): da a recompensa e
-- incrementa as entregas. Soh aqui a task conta como concluida (progresso
-- da sala / bau central).
function linkedTaskClaim(cid, roomId, task)
  local completions = linkedTaskCompletions(cid, task) + 1
  setPlayerStorageValue(cid, task.storage + 2, completions)

  local maxRepeats = task.maxRepeats or 1
  if not task.repeatable or completions >= maxRepeats then
    setPlayerStorageValue(cid, task.storage, 3) -- entregue, sem mais repeticoes
  else
    setPlayerStorageValue(cid, task.storage, 0) -- repetivel: disponivel para reiniciar
  end

  -- recompensa (ouro -> banco, itens -> deposito, exp) + mensagem
  local rewardList = linkedGiveTaskReward(cid, task)

  local room = linkedTasksRooms[roomId]
  local pos = getCreaturePosition(cid)
  doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Task ENTREGUE: " .. task.name .. "! Voce recebeu: " .. rewardList .. ".")
  doSendMagicEffect(pos, CONST_ME_GIFT_WRAPS)
  doSendAnimatedText(pos, "Entregue!", 215)

  -- libera o bau central se TODAS as tasks da sala forem entregues
  if room and linkedRoomIsDone(cid, roomId) then
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Voce entregou todas as tasks da " .. room.name .. "! O bau central foi LIBERADO, va abri-lo!")
    doSendMagicEffect(pos, CONST_ME_MAGIC_GREEN)
    if room.chestPos and room.chestPos.x and room.chestPos.x > 0 then
      doSendMagicEffect(room.chestPos, CONST_ME_GIFT_WRAPS)
    end
  end
end

-- ============================================================
-- CLIQUE NO DISPLAY DA TASK (inicia / cancela / reinicia)
-- ============================================================

function linkedDisplayClick(cid, roomId, taskIndex)
  local room = linkedTasksRooms[roomId]
  if not room or not room.tasks[taskIndex] then
    doPlayerSendCancel(cid, "Display de task invalido.")
    return
  end

  local task = room.tasks[taskIndex]
  local status = linkedTaskStatus(cid, task)
  local kills = linkedTaskKills(cid, task)
  local completions = linkedTaskCompletions(cid, task)
  local maxRepeats = task.maxRepeats or 1
  local total = #room.tasks
  local pos = getCreaturePosition(cid)

  local info = room.name .. " - Task " .. taskIndex .. " de " .. total .. ": " .. task.name .. " (matar " .. linkedTaskGoalText(task) .. ")."
  local statusMsg = nil

  if status == 1 then
    -- clicou numa task ATIVA -> auto-cancela (zerando o progresso)
    linkedTaskCancel(cid, task)
    statusMsg = "Task CANCELADA: " .. task.name .. ". Todo o progresso foi zerado."
    doSendMagicEffect(pos, CONST_ME_POFF)
  elseif status == 2 then
    -- KILLS COMPLETOS -> clicou de novo -> ENTREGA a task e recebe a recompensa
    linkedTaskClaim(cid, roomId, task)
    statusMsg = "Task ENTREGUE: " .. task.name .. "! Recompensa enviada (ouro ao banco, itens na reward mailbox)."
    doSendMagicEffect(pos, CONST_ME_GIFT_WRAPS)
  elseif status == 3 then
    -- JA ENTREGUE e sem repeticoes disponiveis
    doPlayerSendCancel(cid, "Esta task ja foi entregue" .. (task.repeatable and " (limite de repeticoes atingido)." or " e ela nao e repetivel."))
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, info .. " Status: ENTREGUE.")
    return
  else
    -- verifica as regras de sequencia da sala (ordem obrigatoria / 1 ativa por vez)
    local canStart, reason = linkedCanStartTask(cid, room, taskIndex)
    if not canStart then
      doPlayerSendCancel(cid, reason)
      doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, info)
      return
    end

    -- nao iniciada (0) -> inicia | repetivel ja entregue (status resetado p/ 0) -> reinicia
    linkedTaskStart(cid, task)
    local repeatInfo = ""
    if completions > 0 and status == 0 then
      repeatInfo = " (repeticao " .. (completions + 1) .. "/" .. maxRepeats .. ")"
    end
    statusMsg = "Task INICIADA" .. repeatInfo .. ": mate " .. linkedTaskGoalText(task) .. ". Ao completar os kills, clique novamente no display para ENTREGAR. Clique agora para cancelar."
    doSendMagicEffect(pos, CONST_ME_MAGIC_BLUE)
  end

  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, info)
  if statusMsg then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, statusMsg)
  end

  -- progresso da sala (recalcula DEPOIS do claim, para nao mostrar numero desatualizado)
  local doneCount = linkedRoomDoneCount(cid, roomId)
  local roomLine = room.name .. ": " .. doneCount .. "/" .. total .. " tasks concluidas."
  if doneCount >= total then
    roomLine = roomLine .. " Bau central LIBERADO!"
  else
    roomLine = roomLine .. " Faltam " .. (total - doneCount) .. " task(s) para liberar o bau central."
  end
  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, roomLine)

  -- se cancelou uma task ativa, mostra quanto progresso foi perdido
  if status == 1 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, "Voce tinha " .. kills .. "/" .. linkedTaskGoalText(task) .. " nesta task (progresso zerado).")
  end
end

-- ============================================================
-- BAU CENTRAL (premio aleatorio)
-- ============================================================

function linkedChestOpen(cid, roomId)
  local room = linkedTasksRooms[roomId]
  if not room then
    doPlayerSendCancel(cid, "Bau invalido.")
    return
  end

  local opened = linkedStorageValue(cid, room.chestStorage)
  local maxOpens = room.chestMaxOpens or 1
  local pos = getCreaturePosition(cid)

  -- limites de abertura
  if not room.chestRepeatable and opened >= 1 then
    doPlayerSendCancel(cid, "Voce ja abriu o bau central da " .. room.name .. ".")
    return
  end
  if room.chestRepeatable and opened >= maxOpens then
    doPlayerSendCancel(cid, "Voce ja abriu o bau central da " .. room.name .. " " .. maxOpens .. " vezes.")
    return
  end

  -- todas as tasks precisam estar concluidas
  local doneCount = linkedRoomDoneCount(cid, roomId)
  if doneCount < #room.tasks then
    doPlayerSendCancel(cid, "O bau central esta trancado! Complete todas as tasks da " .. room.name .. " (" .. doneCount .. "/" .. #room.tasks .. " concluidas).")
    return
  end

  -- abriu! sorteia o premio
  setPlayerStorageValue(cid, room.chestStorage, opened + 1)

  local pool = room.chestRewards
  local prize = pool[math.random(1, #pool)]
  -- ouro -> banco, itens -> reward mailbox (mesma logica das tasks)
  local parts = linkedGiveRewardList(cid, prize)
  if room.chestExp and room.chestExp > 0 then
    local expGain = linkedExpWithRate(cid, room.chestExp)
    doPlayerAddExperience(cid, expGain)
    table.insert(parts, expGain .. " de experiencia")
  end

  doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Voce abriu o bau central da " .. room.name .. " e recebeu: " .. table.concat(parts, ", ") .. ".")
  doSendMagicEffect(pos, CONST_ME_GIFT_WRAPS)
  doSendAnimatedText(pos, "Premio!", 215)
end

-- ============================================================
-- SPAWN DOS ITENS NO MAPA (chamado pelo global event onStartup)
-- ============================================================

function linkedDisplayPosition(room, index)
  local base = room.displayPos
  if type(base[1]) == "table" then
    -- lista explicita de posicoes
    return base[index] or base[1]
  end
  local spacing = room.displaySpacing or 2
  return {x = base.x + (index - 1) * spacing, y = base.y, z = base.z}
end

function linkedSpawnItem(pos, itemId, aid, text)
  if not pos or not pos.x or pos.x == 0 then
    return
  end

  local existing = getTileItemById(pos, itemId)
  if existing and existing.uid > 0 then
    -- ja existe um item no lugar: garante o actionid se for nosso (ou sem aid)
    if existing.actionid == 0 or existing.actionid == aid then
      doSetItemActionId(existing.uid, aid)
      if text then
        doSetItemText(existing.uid, text)
      end
    end
    return
  end

  local uid = doCreateItem(itemId, 1, pos)
  if uid and uid > 0 then
    doSetItemActionId(uid, aid)
    if text then
      doSetItemText(uid, text)
    end
  end
end

function spawnLinkedTaskItems()
  if not linkedTasksConfig.autoSpawn then
    return true
  end

  for roomId, room in pairs(linkedTasksRooms) do
    -- displays de task (1 por task da sala)
    for i = 1, #room.tasks do
      local task = room.tasks[i]
      local aid = 46000 + roomId * 10 + i
      local text = room.name .. " - Task " .. i .. ": matar " .. linkedTaskGoalText(task)
      linkedSpawnItem(linkedDisplayPosition(room, i), linkedTasksConfig.displayItemId, aid, text)
    end

    -- bau central
    local chestAid = 46100 + roomId
    local chestText = room.name .. " - BAU CENTRAL (recompensa aleatoria)"
    linkedSpawnItem(room.chestPos, linkedTasksConfig.chestItemId, chestAid, chestText)
  end
  return true
end
