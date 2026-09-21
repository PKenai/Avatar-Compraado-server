-- Water IceSpikes: uma CORRENTE de gelo no padrao do "Light Chain" (Gesior).
--
-- Como funciona:
--   1. a magia acha a primeira criatura. Nao precisa de alvo marcado: ela varre
--      ao redor do conjurador (CHAIN_SEARCH_RANGE SQM) e pega a mais proxima.
--      Se o jogador tiver um alvo marcado, esse tem PRIORIDADE (ate
--      CHAIN_TARGET_RANGE SQM);
--   2. acertou a criatura, a corrente SALTA para a proxima: o alvo seguinte tem
--      que estar a no maximo CHAIN_HOP_RANGE SQM do anterior, e o salto leva
--      CHAIN_HOP_DELAY ms (200ms, o mesmo ritmo do Light Chain original);
--   3. no maximo CHAIN_MAX_TARGETS criaturas sao atingidas por cast, cada uma
--      no maximo UMA vez, sempre levando o dano de sempre (com o congelamento/
--      empurrao de sempre);
--   4. junto de cada criatura atingida vem o RESPINGO do Light Chain: tudo que
--      estiver a CHAIN_SPLASH_RANGE SQM dela leva CHAIN_SPLASH_SCALE do dano
--      (1/4), sem congelamento/empurrao. O proximo alvo da corrente fica de
--      fora do respingo para nao levar dano duas vezes.
--
-- Nada aqui prende o servidor: cada salto e' um addEvent com isCreature checado,
-- entao morrer no meio da corrente nao deixa evento orfao.
--
-- Referencia: "Light Chain" da Gesior Noob-spells collection (OTLand) - a
-- funcionalidade foi trazida de la; efeito e dano continuam os do IceSpikes.
local spellName = "water icespikes"
local cf = {atk = spellsInfo[spellName].atk}

-- ---------------------------------------------------------------------------
-- Ajustes da corrente
-- ---------------------------------------------------------------------------
local CHAIN_EFFECT      = 289 -- efeito da corrente: vale acertando e no respingo
local CHAIN_MAX_TARGETS = 5   -- criaturas atingidas por cast
local CHAIN_HOP_RANGE   = 6   -- SQM no maximo entre uma criatura e a proxima
                              -- (o Light Chain original usa 3; aqui ficou 6 a
                              -- pedido do dono do servidor)
local CHAIN_SEARCH_RANGE = 6  -- SQM ao redor do conjurador (sem alvo marcado)
local CHAIN_TARGET_RANGE = 6  -- SQM no maximo para o alvo marcado (prioridade)
local CHAIN_HOP_DELAY   = 200 -- ms entre um salto e o proximo
local CHAIN_SPLASH_RANGE = 1  -- SQM ao redor da criatura atingida que levam o respingo
local CHAIN_SPLASH_SCALE = 0.25 -- respingo = 1/4 do dano principal

-- ---------------------------------------------------------------------------
-- Alvos validos (mesmas regras que o resto do datapack: sem aliado, sem
-- propria summon, sem NPC, sem gente em protection zone)
-- ---------------------------------------------------------------------------
local function isInPvpZone(cid)
    local pos = getCreaturePosition(cid)
    if not pos then
        return false
    end
    return getTileInfo(pos).hardcore
end

local function isInSameGuild(cid, target)
    if isPlayer(target) and not (isInPvpZone(target) and not castleWar.isOnCastle(target)) then
        local cidGuild = getPlayerGuildId(cid)
        if cidGuild > 0 and cidGuild == getPlayerGuildId(target) then
            return true
        end
    end
    return false
end

local function isFriendly(cid, target)
    if isPlayer(target) and target == cid then
        return true
    end
    if isInSameGuild(cid, target) then
        return true
    end
    if isPlayer(target) and isPlayer(cid) and isInParty(target) and isInParty(cid) and getPlayerParty(cid) == getPlayerParty(target) then
        return true
    end
    if isSummon(target) and getCreatureMaster(target) == cid then
        return true
    end
    return isSameWarTeam(cid, target)
end

-- Pet fantasma (data/XML/pets.xml): e' um monstro sem master e o engine nao
-- expoe o flag Creature::isPet() para o Lua. A unica marca visivel e' o nome,
-- que sai do proprio pets.xml - a lista e' montada uma vez e fica em cache.
local petNames = nil
local function isPetCreature(target)
    if petNames == nil then
        petNames = {}
        for id = 1, 255 do
            local info = getPetInfo(id)
            if info and info.name then
                petNames[string.lower(info.name)] = true
            end
        end
    end
    local name = getCreatureName(target)
    return (name ~= nil and petNames[string.lower(name)]) or false
end

local function isValidTarget(cid, target, hitList, fromPos)
    if not isCreature(target) or target == cid then
        return false
    end
    if isNpc(target) or isInPz(target) then
        return false
    end
    if isPetCreature(target) then
        return false
    end
    if getCreatureHealth(target) <= 0 then
        return false
    end
    if hitList[target] then
        return false
    end
    if isFriendly(cid, target) then
        return false
    end
    local pos = getThingPos(target)
    return pos.z == fromPos.z
end

local function findFirstTarget(cid)
    local myPos = getThingPos(cid)

    -- 1) PRIORIDADE: o alvo que o jogador ja' marcou, se estiver ao alcance
    local current = getCreatureTarget(cid)
    if current and current > 0 then
        local pos = getThingPos(current)
        if isValidTarget(cid, current, {}, myPos)
            and getDistanceBetween(myPos, pos) <= CHAIN_TARGET_RANGE
            and isSightClear(myPos, pos, true) then
            return current
        end
    end

    -- 2) sem alvo marcado: a criatura mais proxima ao redor do conjurador
    local specs = getSpectators(myPos, CHAIN_SEARCH_RANGE, CHAIN_SEARCH_RANGE, false)
    if not specs then
        return nil
    end

    local best, bestDist = nil, nil
    for _, spec in ipairs(specs) do
        if isValidTarget(cid, spec, {}, myPos) then
            local pos = getThingPos(spec)
            local dist = getDistanceBetween(myPos, pos)
            if dist > 0 and dist <= CHAIN_SEARCH_RANGE and isSightClear(myPos, pos, true) then
                if not bestDist or dist < bestDist then
                    best, bestDist = spec, dist
                end
            end
        end
    end
    return best
end

local function findNextTarget(cid, fromPos, hitList)
    local specs = getSpectators(fromPos, CHAIN_HOP_RANGE, CHAIN_HOP_RANGE, false)
    if not specs then
        return nil
    end

    local best, bestDist = nil, nil
    for _, spec in ipairs(specs) do
        if isValidTarget(cid, spec, hitList, fromPos) then
            local pos = getThingPos(spec)
            local dist = getDistanceBetween(fromPos, pos)
            if dist > 0 and dist <= CHAIN_HOP_RANGE and isSightClear(fromPos, pos, true) then
                if not bestDist or dist < bestDist then
                    best, bestDist = spec, dist
                end
            end
        end
    end
    return best
end

-- ---------------------------------------------------------------------------
-- Dano da corrente (mesma formula de sempre) + congelamento/empurrao
-- ---------------------------------------------------------------------------
local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_DROWNDAMAGE)

-- respingo do Light Chain: mesmo dano, sem congelamento/empurrao
local combatSplash = createCombatObject()
setCombatParam(combatSplash, COMBAT_PARAM_TYPE, COMBAT_DROWNDAMAGE)

function onGetPlayerMinMaxValues(cid, level, magLevel)
    local min = (level+(magLevel/2)*4.1)+math.random(3, 7)
    local max = (level+(magLevel/2)*5.3)+math.random(7, 15)
    local dano = math.random(min, max)
    local atk = cf.atk
    if atk and type(atk) == "number" then
        dano = dano * (atk/100)
        dano = dano+1
    end
    dano = remakeValue(2, dano, cid)
    return -dano, -dano
end
setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")

function onGetChainSplashMinMaxValues(cid, level, magLevel)
    local min = (level+(magLevel/2)*4.1)+math.random(3, 7)
    local max = (level+(magLevel/2)*5.3)+math.random(7, 15)
    local dano = math.random(min, max)
    local atk = cf.atk
    if atk and type(atk) == "number" then
        dano = dano * (atk/100)
        dano = dano+1
    end
    dano = remakeValue(2, dano, cid) * CHAIN_SPLASH_SCALE
    return -dano, -dano
end
setCombatCallback(combatSplash, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetChainSplashMinMaxValues")

function onTargetCreature(cid, target)
    if isNpc(target) then
        return false
    end
    if getPlayerStorageValue(target, "playerOnAir") == 1 then
        doPushCreature(target, math.random(0, 3), 1, 500, false, true)
    elseif math.random(1, 100) >= 70 then
        doFrozzenCreature(target, 2000)
    end
end
setCombatCallback(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

-- ---------------------------------------------------------------------------
-- A corrente em si
-- ---------------------------------------------------------------------------
local iceChainHit

-- Respingo: quem estiver em volta da criatura atingida leva 1/4 do dano.
-- "skip" e' o proximo alvo da corrente - ele vai levar o dano cheio no proximo
-- salto, entao nao entra aqui.
local function iceChainSplash(cid, fromPos, hitList, skip)
    local specs = getSpectators(fromPos, CHAIN_SPLASH_RANGE, CHAIN_SPLASH_RANGE, false)
    if not specs then
        return
    end

    for _, spec in ipairs(specs) do
        if spec ~= skip and isValidTarget(cid, spec, hitList, fromPos) then
            local pos = getThingPos(spec)
            local dist = getDistanceBetween(fromPos, pos)
            if dist > 0 and dist <= CHAIN_SPLASH_RANGE then
                doSendMagicEffect(pos, CHAIN_EFFECT)
                doCombat(cid, combatSplash, {type=2, pos=pos})
            end
        end
    end
end

-- Atingiu a criatura: aplica o dano, o respingo e agenda o proximo salto.
iceChainHit = function(cid, target, hitList, hits)
    if not isCreature(cid) or not isCreature(target) then
        return
    end

    hitList[target] = true
    hits = hits + 1

    local targetPos = getThingPos(target)
    doSendMagicEffect(targetPos, CHAIN_EFFECT)
    doCombat(cid, combat, {type=2, pos=targetPos})

    -- proxima criatura: uma vez cada, no maximo CHAIN_MAX_TARGETS por cast
    local nextTarget = nil
    if hits < CHAIN_MAX_TARGETS then
        nextTarget = findNextTarget(cid, targetPos, hitList)
    end

    iceChainSplash(cid, targetPos, hitList, nextTarget)

    if nextTarget then
        addEvent(function()
            if isCreature(cid) then
                iceChainHit(cid, nextTarget, hitList, hits)
            end
        end, CHAIN_HOP_DELAY)
    end
end

function onCastSpell(cid, var)
    if getSpellCancels(cid, "water") == true then
        return false
    end
    if getPlayerExaust(cid, "water", "iceSpikes") == false then
        return false
    end

    -- procura o alvo antes de gastar a agua: um cast sem alvo nao consome nada
    local target = findFirstTarget(cid)
    if not target then
        doPlayerSendCancelEf(cid, getLangString(cid, "No target for the ice chain.", "Nenhum alvo para a corrente de gelo."))
        return false
    end

    if not canUseWaterSpell(cid, 1, 3, false) then
        return false
    end

    if getDobrasLevel(cid) >= 5 then
        doPlayerAddExaust(cid, "water", "iceSpikes", waterExausted.iceSpikes-3)
    else
        doPlayerAddExaust(cid, "water", "iceSpikes", waterExausted.iceSpikes)
    end

    if getPlayerHasStun(cid) then
        return true
    end

    iceChainHit(cid, target, {}, 0)
    return true
end
