--[[
    FIRE VOLTAGE — Rework Épico (Level 130+)
    
    O Pyromancer acumula toda a energia de fogo no corpo e libera em uma explosão
    de ondas de choque concêntricas que se expandem ao redor, fritando tudo no caminho.
    
    Fase 1 (0ms):       Efeito de carga de energia no caster
    Fase 2 (300ms):     Primeira onda — anel raio 0-2
    Fase 3 (600ms):     Segunda onda — anel raio 3-4
    Fase 4 (900ms):     Terceira onda — anel raio 5-6
    Focus:              +3 ondas extras (expansão a raio 8, retorno ao centro e fechamento)
]]--

local spellName = "fire voltage"
local cf = {atk = (spellsInfo[spellName] and spellsInfo[spellName].atk) or 500}

local MyLocal = {}

-- ===== IMUNIDADES E ALVOS VÁLIDOS =====
local skulls = {1, 3, 4, 5, 6}
local function isImune(cid, creature)
    if not isCreature(creature) or not isCreature(cid) then
        return true
    end
    if isNpc(creature) or (isPlayer(creature) and getPlayerAccess(creature) >= 3) then
        return true
    end
    if isMonster(creature) and isSummon(creature) and getCreatureMaster(creature) == cid then
        return true
    end
    if isMonster(creature) or isMonster(cid) then 
        return false 
    end
    if isPlayer(cid) and isPlayer(creature) and (getPlayerStorageValue(cid, "canAttackable") == 1 or getPlayerStorageValue(creature, "canAttackable") == 1) then 
        return true 
    end 
    if isInParty(cid) and isInParty(creature) and getPlayerParty(cid) == getPlayerParty(creature) then
        return true
    end 
    if isInSameGuild(cid, creature) then
        return true
    end
    local modes = getPlayerModes(cid)
    if isInArray(skulls, getCreatureSkullType(creature)) then
        return false
    end
    if isPlayer(cid) and isPlayer(creature) and modes and modes.pvp == 0 then
        return true
    end
    return false
end

-- ===== CÁLCULO DE DANO =====
local function calcDano(cid, isFocus)
    if not isCreature(cid) then return 0 end
    local level = isPlayer(cid) and getPlayerLevel(cid) or 130
    local magLevel = level * 0.5

    local min = (level + ((level * 0.5) / 2) * 5.0) + math.random(40, 60)
    local max = (level + ((level * 0.5) / 2) * 6.5) + math.random(60, 90)

    if getPlayerInWaterWithUnderwater(cid) then
        min = min * 0.5
        max = max * 0.5
    end

    local dano = math.random(min, max)

    if isFocus then
        dano = dano * 2.2
    end

    local atk = cf.atk
    if atk and type(atk) == "number" then
        dano = dano * (atk / 100)
        dano = dano + 1
    end
    dano = remakeValue(1, dano, cid)
    return math.max(1, math.floor(dano))
end

-- ===== POSIÇÕES DO ANEL VISUAL =====
local function getRingPositions(center, minRadius, maxRadius)
    local positions = {}
    for x = center.x - maxRadius, center.x + maxRadius do
        for y = center.y - maxRadius, center.y + maxRadius do
            local dist = math.max(math.abs(x - center.x), math.abs(y - center.y))
            if dist >= minRadius and dist <= maxRadius then
                local pos = {x = x, y = y, z = center.z}
                if hasSqm(pos) and not getTileInfo(pos).protection then
                    table.insert(positions, pos)
                end
            end
        end
    end
    return positions
end

-- ===== BUSCA DE ALVOS NA ÁREA =====
local function getTargetsInArea(cid, center, minR, maxR)
    local targets = {}
    local seen = {}

    -- 1. getSpectators (abrange toda a área da onda)
    local specs = getSpectators(center, maxR, maxR, false)
    if specs then
        for _, spec in ipairs(specs) do
            if isCreature(spec) and spec ~= cid and not isNpc(spec) and not isImune(cid, spec) and not isInPz(spec) then
                local sPos = getCreaturePosition(spec)
                if sPos.z == center.z and not seen[spec] then
                    local dist = math.max(math.abs(sPos.x - center.x), math.abs(sPos.y - center.y))
                    if dist >= minR and dist <= maxR then
                        if dist <= 1 or isSightClear(center, sPos, true) then
                            seen[spec] = true
                            table.insert(targets, spec)
                        end
                    end
                end
            end
        end
    end

    -- 2. Varredura por tile com getTopCreature (garantia para creatures/monsters no mapa)
    for x = center.x - maxR, center.x + maxR do
        for y = center.y - maxR, center.y + maxR do
            local dist = math.max(math.abs(x - center.x), math.abs(y - center.y))
            if dist >= minR and dist <= maxR then
                local pos = {x = x, y = y, z = center.z}
                if hasSqm(pos) and not getTileInfo(pos).protection then
                    local top = getTopCreature(pos).uid
                    if top and top > 0 and isCreature(top) and top ~= cid and not isNpc(top) and not isImune(cid, top) and not isInPz(top) then
                        if not seen[top] and (dist <= 1 or isSightClear(center, pos, true)) then
                            seen[top] = true
                            table.insert(targets, top)
                        end
                    end
                end
            end
        end
    end

    return targets
end

-- ===== EXPLOSÃO DA ONDA =====
local function doWaveExplosion(cid, center, visualMinR, visualMaxR, isFocus, hitMinR)
    if not isCreature(cid) then return end

    -- Visual dos anéis de fogo
    local poses = getRingPositions(center, visualMinR, visualMaxR)
    for _, pos in ipairs(poses) do
        if isSightClear(center, pos, true) then
            doSendDistanceShoot(center, pos, CONST_ANI_FIRE)
        end
        addEvent(doSendMagicEffect, 80, pos, CONST_ME_HITBYFIRE)
        addEvent(doSendMagicEffect, 160, pos, CONST_ME_FIREAREA)
    end

    -- Dano em todas as criaturas na área da expansão
    local damageMinR = hitMinR or 0
    local targets = getTargetsInArea(cid, center, damageMinR, visualMaxR)
    for _, target in ipairs(targets) do
        local dano = calcDano(cid, isFocus)
        addEvent(function()
            if isCreature(cid) and isCreature(target) and not isInPz(target) then
                doTargetCombatHealth(cid, target, COMBAT_FIREDAMAGE, -dano, -dano, CONST_ME_HITBYFIRE)
            end
        end, 100)
    end
end

-- Efeitos de faíscas em 8 direções
local directions8 = {
    {x= 0, y=-1}, {x= 1, y=-1}, {x= 1, y= 0}, {x= 1, y= 1},
    {x= 0, y= 1}, {x=-1, y= 1}, {x=-1, y= 0}, {x=-1, y=-1},
}

local function doSparkBurst(cid, center, isFocus)
    if not isCreature(cid) then return end
    local reach = isFocus and 6 or 4
    for _, dir in ipairs(directions8) do
        local toPos = {x = center.x + (dir.x * reach), y = center.y + (dir.y * reach), z = center.z}
        if hasSqm(toPos) then
            doSendDistanceShoot(center, toPos, CONST_ANI_REDSTAR)
            addEvent(doSendDistanceShoot, 60, center, toPos, CONST_ANI_FIRE)
        end
    end
end

-- ===== SEQUÊNCIA PRINCIPAL =====
local function executeVoltage(cid, center, isFocus)
    if not isCreature(cid) or isInPz(cid) then return end

    -- Fase 1: Carga de energia no caster
    doSendMagicEffect(center, CONST_ME_ENERGYHIT)
    doSendMagicEffect(center, CONST_ME_YELLOWENERGY)
    doSendMagicEffect(center, CONST_ME_FIREAREA)

    -- Fase 2: Onda 1 — raio 0-2
    addEvent(function()
        if not isCreature(cid) then return end
        doSendMagicEffect(center, CONST_ME_EXPLOSIONHIT)
        doSparkBurst(cid, center, isFocus)
        doWaveExplosion(cid, center, 0, 2, isFocus, 0)
    end, 300)

    -- Fase 3: Onda 2 — raio 3-4 (atinge quem estiver até raio 4)
    addEvent(function()
        if not isCreature(cid) then return end
        doSendMagicEffect(center, CONST_ME_BIGCLOUDS)
        doWaveExplosion(cid, center, 3, 4, isFocus, 0)
    end, 600)

    -- Fase 4: Onda 3 — raio 5-6 (atinge quem estiver até raio 6)
    addEvent(function()
        if not isCreature(cid) then return end
        doSendMagicEffect(center, CONST_ME_HITBYFIRE)
        doWaveExplosion(cid, center, 5, 6, isFocus, 0)
    end, 900)

    -- Focus: ondas extras épicas
    if isFocus then
        -- Onda 4: expansão máxima raio 7-8
        addEvent(function()
            if not isCreature(cid) then return end
            doWaveExplosion(cid, center, 7, 8, true, 0)
        end, 1200)

        -- Onda 5: contração / nova detonação no centro (raio 0-3)
        addEvent(function()
            if not isCreature(cid) then return end
            doSendMagicEffect(center, CONST_ME_EXPLOSIONAREA)
            doWaveExplosion(cid, center, 0, 3, true, 0)
        end, 1500)

        -- Onda 6: cataclismo final (raio 0-6)
        addEvent(function()
            if not isCreature(cid) then return end
            doSendMagicEffect(center, CONST_ME_POFF)
            doSparkBurst(cid, center, true)
            doWaveExplosion(cid, center, 0, 6, true, 0)
        end, 1900)
    end
end

-- ===== CAST PRINCIPAL =====
function onCastSpell(cid, var)
    if getSpellCancels(cid, "fire") == true then
        return false
    end

    if getTileInfo(getCreaturePosition(cid)).optional or isInWarGround(cid) then
        doPlayerSendCancelEf(cid, "You can't use this fold here.")
        return false
    end

    if MyLocal[cid] ~= nil then
        doPlayerSendCancelEf(cid, "You're already channeling Voltage.")
        return false
    end

    if getPlayerExaust(cid, "fire", "voltage", fireExausted.voltage) == false then
        return false
    end

    if getPlayerHasStun(cid) then
        workAllCdAndAndPrevCd(cid, "fire", "voltage", nil, 1)
        doPlayerAddExaust(cid, "fire", "voltage", fireExausted.voltage)
        return true
    end

    local isFocus = getPlayerOverPower(cid, "fire", true, true)
    local center = getCreaturePosition(cid)

    if getTileInfo(center).protection then
        doPlayerSendCancelEf(cid, "You can't use this fold here.")
        return false
    end

    MyLocal[cid] = true

    executeVoltage(cid, center, isFocus)

    local duration = isFocus and 2200 or 1100
    addEvent(function()
        MyLocal[cid] = nil
    end, duration)

    doPlayerAddExaust(cid, "fire", "voltage", fireExausted.voltage)
    workAllCdAndAndPrevCd(cid, "fire", "voltage", nil, 1)
    return true
end
