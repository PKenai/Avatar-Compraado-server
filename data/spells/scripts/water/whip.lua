-- Water Whip: e' o MESMO cone da Fire Wave do Fire Bender (fire/wave.lua),
-- so' que mais fraco. Mesmo formato de area, mesmos estagios (mini/base/elite)
-- e mesmo "focus" (dano dobrado quando o jogador esta em OverPower).
--
-- Diferencas em relacao a Fire Wave:
--   * elemento: agua (COMBAT_DROWNDAMAGE) em vez de fogo
--   * dano: DAMAGE_SCALE (80%) do dano que a Fire Wave faz
--
-- O atk da propria magia (spellsInfo["water whip"]) continua existindo para as
-- outras magias que o leem (whip man.lua, sistemas de dobra), mas o dano deste
-- cast e' derivado da Fire Wave de proposito: assim "menos dano que ela" segue
-- valendo mesmo se a Fire Wave for rebalanceada.
local spellName = "water whip"
local cf = {atk = spellsInfo[spellName].atk}

-- Atk usado pela Fire Wave do Fire Bender (o fallback e' o atk do proprio
-- Water Whip, caso a entrada da Fire Wave deixe de existir no spellsInfo).
local fireWaveAtk = (spellsInfo["fire whip"] and spellsInfo["fire whip"].atk) or cf.atk

-- Fracao do dano da Fire Wave que o Water Whip causa. 0.8 = 20% menos.
local DAMAGE_SCALE = 0.8

-- Efeito em cada SQM atingido pelo cone.
local WAVE_EFFECT = 398

-- Level 1 ao 49: 1 tile na frente e 3 nas duas fileiras seguintes.
local AREA_WAVE = {
    {1, 1, 1},
    {1, 1, 1},
    {0, 3, 0}
}

-- Level 50 em diante: AREA_WAVE4 do lib, 1 tile na frente, 3, 3 e 5 na ponta.
local AREA_WAVE_BIG = AREA_WAVE4

-- Level 100 em diante (ELITE): o cone abre num leque de 5 fileiras.
local AREA_WAVE_ELITE = AREA_STAGE_ELITE_CONE

-- O callback de dano e' resolvido pelo NOME: o motor le o global homonimo no
-- momento do bind e o consome, entao a funcao precisa ser redefinida antes de
-- cada setCombatCallback.
local function createWaveCombat(area, multipler)
    local combat = createCombatObject()
    setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_DROWNDAMAGE)
    setCombatParam(combat, COMBAT_PARAM_EFFECT, WAVE_EFFECT)
    setCombatArea(combat, area)

    --focus ready--
    function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
        local min = (level*2)+((level * 0.5)/3)*2
        local max = (level*2.5)+((level * 0.5)/3)*3
        local m = multipler * DAMAGE_SCALE
        if getPlayerInWaterWithUnderwater(cid) then
            m = m*0.5
        end
        local dano = math.random(min, max) + math.random(8, 16)
        if fireWaveAtk and type(fireWaveAtk) == "number" then
            dano = dano * (fireWaveAtk/100)
            dano = dano+1
        end
        dano = remakeValue(2, dano, cid)
        return -dano*m, -dano*m
    end

    setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
    return combat
end

local areaWave = createCombatArea(AREA_WAVE)
local areaWaveBig = createCombatArea(AREA_WAVE_BIG)
local areaWaveElite = createCombatArea(AREA_WAVE_ELITE)

-- Estagio 1 (mini, <50)   : o cone curto
-- Estagio 2 (50-99)       : AREA_WAVE4, o cone grande
-- Estagio 3 (elite, 100+) : o leque de 5 fileiras
local combatWave = createWaveCombat(areaWave, 1)
local combatWaveFocus = createWaveCombat(areaWave, 2)
local combatWaveBig = createWaveCombat(areaWaveBig, 1)
local combatWaveBigFocus = createWaveCombat(areaWaveBig, 2)
local combatWaveElite = createWaveCombat(areaWaveElite, 1)
local combatWaveEliteFocus = createWaveCombat(areaWaveElite, 2)

local function getWaveCombats(cid)
    local stage = getSpellStage(cid)
    if stage == SPELL_STAGE_ELITE then
        return combatWaveEliteFocus, combatWaveElite
    elseif stage == SPELL_STAGE_MINI then
        return combatWaveFocus, combatWave
    end
    return combatWaveBigFocus, combatWaveBig
end

-- O summon "water whip man" continua acompanhando a dobra: ao ver o storage
-- "executarWhip" ligado no mestre, ele casta a versao dele da magia.
local function testWaterMan(cid)
    local summons = getCreatureSummons(cid)
    if not summons or #summons == 0 then
        return false
    end
    setPlayerStorageValue(summons[1], "executarWhip", 1)
end

function onCastSpell(cid, var)
    local focusCombat, waveCombat = getWaveCombats(cid)

    if getSpellCancels(cid, "water") == true then
        return false
    end
    if getPlayerExaust(cid, "water", "whip", waterExausted.whip) == false then
        return false
    end
    if not canUseWaterSpell(cid, 1, 3, false) then
        return false
    end

    workAllCdAndAndPrevCd(cid, "water", "whip", nil, 1)
    doPlayerAddExaust(cid, "water", "whip", waterExausted.whip)
    if getPlayerHasStun(cid) then
        return true
    end

    testWaterMan(cid)

    -- Estagio 3 (100+): a agua sobe no conjurador antes do cone abrir
    if isSpellElite(cid) then
        doSendMagicEffect(getThingPos(cid), 53)
    end

    if getPlayerOverPower(cid, "water", true, true) then
        return doCombat(cid, focusCombat, var)
    end

    return doCombat(cid, waveCombat, var)
end
