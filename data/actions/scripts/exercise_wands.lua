--[[
================================================================================
  VARINHAS DE TREINO (Exercise Wands) — estilo Tibia Global
  Elementos: Água, Fogo, Ar, Terra

  Servidor: TFS 0.4 / 8.60 (API antiga: cid / doPlayer*)
  Local: data/actions/scripts/exercise_wands.lua

  COMO FUNCIONA
  - O jogador usa a varinha em um Exercise Dummy (itens 18334/18335/19336, ou
    criatura chamada "Exercise Dummy").
  - A cada 2s ele "acerta" o dummy: consome 1 carga e ganha progresso de
    magic level (padrão do Tibia Global para varinhas).
  - Quando as cargas acabam, a varinha desintegra.
  - Formula Global: cada carga da 600+ de mana spent COMO SE gastasse 600
    de mana (mana VIRTUAL - o player NAO perde mana), 2s por carga. Acima do
    piso o ganho escala com o requisito do nivel (CONFIG.gainPercent) porque
    a curva deste servidor e 4^ml - com 600 fixo o ml 10+ levaria dias.
  - O idle do jogador e resetado a cada acerto (nao leva kick por inatividade).
  - Andar, deslogar, sair da protection zone ou perder a varinha interrompe
    o treino automaticamente.
  - Treinar num dummy DENTRO de casa dá +10% de eficiência (dummy de casa).
  - A antiga bênção de SKILL da estátua (que acelerava o ML do treino) nao
    existe mais: a aba virou Potions (+15% de cura). O ganho do treino e' a
    formula deste arquivo, e so' ele.

  INSTALAÇÃO
  1) data/actions/actions.xml:
       <action itemid="18336-18339" event="script" value="exercise_wands.lua"/>
  2) data/items/items.xml: adicionar as 4 varinhas (18336-18339) com
       <attribute key="charges" value="3500"/>

  CONTAGEM DE CARGAS NO ICONE (estilo Tibia Global): o servidor envia as
  cargas via extended opcode 0xF8 (canal proprio do otclient, sem tocar no
  protocolo 8.60): [containerId u8 (0xFF = inventario)][index u8][cargas u16].
  O client (modulo game_trainwands) aplica a contagem no item e o icone exibe
  o numero (things.otml marca o item como chargeable). doSendItemUpdate(cid,
  uid) e chamado a cada acerto. Requer SERVIDOR e CLIENT novos juntos.
================================================================================
]]

local CONFIG = {
    interval      = 2000,                  -- ms entre cada acerto no dummy (2s/carga)
    -- Curva do servidor: req(ml) = 1600 * manamultiplier^ml (vocation.cpp
    -- getReqMana). O vocations.xml foi alterado de 4.0 -> 1.1: a curva 4^ml
    -- impossibilita os tempos do dono e transborda uint64 no ml ~27 (req do
    -- ml 27 = 2.9e19 > 1.8e19). Com 1.1 (curva do Global) tudo fica sanavel.
    formulaBase   = 1600,                  -- base da curva (vocation.cpp)
    formulaMagic  = 1.1,                   -- vocations.xml manamultiplier (todas as vocacoes)
    -- Tempo alvo por magic level (spec do dono). O ganho por acerto e
    -- calculado p/ bater exatamente estes tempos:
    --   0-30: 1.7min | 30-40: 3.4 | 40-50: 7.7 | 50-60: 17 | 60-70: 41
    --   70-80: 105.4 | 80-90: 273.4 | 90-100: 707 | 100+: 28490 (~2 anos/50)
    timePerLevel  = {
        { max = 30,  minutes = 1.7 },
        { max = 40,  minutes = 3.4 },
        { max = 50,  minutes = 7.7 },
        { max = 60,  minutes = 17 },
        { max = 70,  minutes = 41 },
        { max = 80,  minutes = 105.4 },
        { max = 90,  minutes = 273.4 },
        { max = 100, minutes = 707 },
        { max = math.huge, minutes = 28490 },
    },
    requirePZ     = true,                  -- exige protection zone para treinar
    houseBonus    = 1.1,                   -- dummy dentro de casa: +10% (1.0 = desliga)
    dummyIds      = {18334, 18335, 19336}, -- ids de ITEM do dummy (19336 = dummy do OTB novo)
    dummyNames    = {"exercise dummy", "dummy"},  -- nomes de CRIATURA do dummy (minusculas)
}

-- Cada varinha: itemid -> configuração
-- skill: "magic" (magic level) | "sword" | "axe" | "club" | "distance" | "shielding" | "fist"
-- value: usado APENAS por skills FISICAS (tries por acerto). Magic usa a
-- tabela CONFIG.timePerLevel (o ganho e calculado p/ bater os tempos do dono)
local WANDS = {
    -- Efeitos custom do client (os padroes 12/14/15 nao renderizam em algumas):
    -- Ar = 77 (NEWVIII) | Agua = 87 (NEWXVIII) | Terra = 94 (NEWXXV) | Fogo = 15 (padrao, funciona)
    [18336] = { name = "Water Training Wand", skill = "magic", value = 600, effect = CONST_ME_NEWXVIII },
    [18337] = { name = "Fire Training Wand",  skill = "magic", value = 600, effect = CONST_ME_HITBYFIRE },
    [18338] = { name = "Air Training Wand",   skill = "magic", value = 600, effect = CONST_ME_NEWVIII },
    [18339] = { name = "Earth Training Wand", skill = "magic", value = 600, effect = CONST_ME_NEWXXV },
    [18341] = { name = "Treino elemental",    skill = "magic", value = 600, effect = CONST_ME_MAGIC_BLUE },
}

local SKILL_TYPES = {
    magic     = { name = "magic level" },
    sword     = { id = SKILL_SWORD,     name = "sword" },
    axe       = { id = SKILL_AXE,       name = "axe" },
    club      = { id = SKILL_CLUB,      name = "club" },
    distance  = { id = SKILL_DISTANCE,  name = "distance" },
    shielding = { id = SKILL_SHIELD,    name = "shielding" },
    fist      = { id = SKILL_FIST,      name = "fist" },
}

local training = {}  -- cid -> dados do treino ativo

local function isDummy(uid, itemid)
    if isCreature(uid) then
        local name = getCreatureName(uid)
        if name then
            name = string.lower(name)
            for _, n in ipairs(CONFIG.dummyNames) do
                if name == n then
                    return true
                end
            end
        end
        return false
    end
    for _, id in ipairs(CONFIG.dummyIds) do
        if itemid == id then
            return true
        end
    end
    return false
end

local function findInContainer(container, itemid)
    local size = getContainerSize(container)
    for slot = 0, size - 1 do
        local it = getContainerItem(container, slot)
        if it and it.uid > 0 then
            if it.itemid == itemid then
                return it
            elseif isContainer(it.uid) then
                local found = findInContainer(it.uid, itemid)
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

local function findWand(cid, itemid)
    -- TFS 0.4: slots 1-10 (HEAD..AMMO). As constantes SLOT_* NAO existem
    -- neste fork (os scripts usam CONST_SLOT_* definidos nos libs, ou numeros)
    -- entao usamos numeros direto para nao depender de lib nenhuma.
    for slot = 1, 10 do
        local it = getPlayerSlotItem(cid, slot)
        if it and it.uid > 0 then
            if it.itemid == itemid then
                return it
            elseif isContainer(it.uid) then
                local found = findInContainer(it.uid, itemid)
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

local function stopTraining(cid, msg)
    if training[cid] then
        training[cid] = nil
        if msg and isPlayer(cid) then
            doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, msg)
        end
    end
end

local function dummyStillThere(t)
    if t.dummyCreature then
        return isCreature(t.dummyUid)
    end
    local dummyItem = getTileItemById(t.dummyPos, t.dummyItemId)
    return dummyItem and dummyItem.uid > 0
end

-- NOTA: funcoes do loop de treino sao GLOBAIS (com prefixo pra nao colidir
-- com outros scripts) — o fork deste TFS 0.4 recusa callback LOCAL no
-- addEvent (todos os scripts do servidor usam globais ou anonimas).
function exerciseWandsHit(cid, t)
    if isPlayer(cid) then
        local pos = getCreaturePosition(cid)
        if getDistanceBetween(pos, t.dummyPos) > 1 then
            stopTraining(cid, "You are too far away and stop training.")
            return
        end
    end
    local wand = findWand(cid, t.itemid)
    if not wand then
        stopTraining(cid, "You no longer have your training wand.")
        return
    end

    local charges = getItemAttribute(wand.uid, "charges")
    if not charges then
        -- sem atributo "charges" no items.xml: NAO destrói o item, só avisa
        stopTraining(cid, "Your training wand has no charges. (missing 'charges' in items.xml?)")
        return
    end
    if charges <= 0 then
        doRemoveItem(wand.uid, 1)
        stopTraining(cid, "Your training wand has run out of charges.")
        return
    end

    -- Formula estilo Tibia Global: cada carga conta COMO SE gastasse 600 de
    -- mana (mana VIRTUAL) - o player NAO perde mana de verdade. O magic level
    -- sobe proporcionalmente via doPlayerAddSpentMana logo abaixo.

    -- Reseta o timer de idle (idle.lua derruba quem fica parado em
    -- idleKickTime = 14 min) - sem isso o treino automatico desloga.
    doPlayerSetIdleTime(cid, 0)

    doItemSetAttribute(wand.uid, "charges", charges - 1)

    -- Empurra a contagem atualizada pro client em tempo real (extensao na source:
    -- o icone da varinha mostra as cargas restantes, estilo Tibia Global).
    if doSendItemUpdate then
        doSendItemUpdate(cid, wand.uid)
    end

    local st = SKILL_TYPES[t.skill] or SKILL_TYPES.magic
    local amount
    if st.id then
        amount = math.floor(t.value * t.bonus)
        doPlayerAddSkillTry(cid, st.id, amount)
    else
        -- IMPORTANTE: aqui a formula JA' calcula o mana exato que o nivel pede,
        -- Passamos useMultiplier=false pro addManaSpent NAO multiplicar o mana
        -- por (rates * RATE_MAGIC) — senao o mana vira 0 e o magic level nao sobe.
        -- Magic: o ganho por acerto e CALCULADO p/ cada nivel levar o tempo
        -- da tabela CONFIG.timePerLevel (spec do dono), sobre a curva do
        -- servidor req(ml) = 1600 * 1.1^ml (vocations.xml manamultiplier=1.1).
        -- 30 acertos/minuto (2s por acerto): gain = req / (minutos * 30).
        -- useMultiplier=false: rateMagic=0.0 do config.lua zeraria o ganho.
        local ml = getPlayerMagLevel(cid, true) -- raw (sem modificadores), como o servidor usa
        local minutes = 1.7
        for _, band in ipairs(CONFIG.timePerLevel) do
            if ml < band.max then
                minutes = band.minutes
                break
            end
        end
        local nextReq = CONFIG.formulaBase * (CONFIG.formulaMagic ^ ml)
        amount = math.floor(nextReq / (minutes * 30) * t.bonus)
        if amount < 1 then
            amount = 1
        end
        doPlayerAddSpentMana(cid, amount, false)
    end

    if t.effect then
        doSendMagicEffect(t.dummyPos, t.effect)
    end

    if charges - 1 <= 0 then
        doRemoveItem(wand.uid, 1)
        stopTraining(cid, "Your training wand has run out of charges.")
        return
    end

    -- callback ANONIMO (padrao do fullPotion.lua: addEvent(function() ... end, ms))
    -- com cid via closure, para nao depender da passagem de parametros do fork
    addEvent(function() exerciseWandsTick(cid) end, CONFIG.interval)
end

function exerciseWandsTick(cid)
    local t = training[cid]
    if not t then
        return
    end

    if not isPlayer(cid) then
        training[cid] = nil -- deslogou: o loop se cancela sozinho
        return
    end

    local pos = getCreaturePosition(cid)
    if pos.x ~= t.startPos.x or pos.y ~= t.startPos.y or pos.z ~= t.startPos.z then
        stopTraining(cid, "You move and stop training.")
        return
    end

    if not dummyStillThere(t) then
        stopTraining(cid, "You stop training.")
        return
    end

    if getDistanceBetween(pos, t.dummyPos) > 1 then
        stopTraining(cid, "You are too far away and stop training.")
        return
    end

    if CONFIG.requirePZ and not getTileInfo(pos).protection then
        stopTraining(cid, "You must stay in a protection zone to keep training.")
        return
    end

    exerciseWandsHit(cid, t)
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
    local cfg = WANDS[item.itemid]
    if not cfg then
        return false
    end

    if not isDummy(itemEx.uid, itemEx.itemid) then
        doPlayerSendCancel(cid, "You can only use your training wand on an Exercise Dummy.")
        return true
    end

    local pos = getCreaturePosition(cid)
    local dummyPos = getThingPosition(itemEx.uid)
    if getDistanceBetween(pos, dummyPos) > 1 then
        doPlayerSendCancel(cid, "Move closer to the dummy to start training.")
        return true
    end

    if CONFIG.requirePZ and not getTileInfo(pos).protection then
        doPlayerSendCancel(cid, "You can only train in a protection zone.")
        return true
    end

    if training[cid] then
        doPlayerSendCancel(cid, "You are already training.")
        return true
    end

    local bonus = 1.0
    if CONFIG.houseBonus > 1.0 and getTileInfo(dummyPos).house then
        bonus = CONFIG.houseBonus
    end

    training[cid] = {
        itemid        = item.itemid,
        dummyUid      = itemEx.uid,
        dummyItemId   = itemEx.itemid,
        dummyCreature = isCreature(itemEx.uid),
        dummyPos      = dummyPos,
        startPos      = pos,
        skill         = cfg.skill,
        value         = cfg.value,
        effect        = cfg.effect,
        bonus         = bonus,
    }

    local st = SKILL_TYPES[cfg.skill] or SKILL_TYPES.magic
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You start training your " .. st.name .. " on the Exercise Dummy.")
    exerciseWandsHit(cid, training[cid])
    return true
end
