-- Fire Wave: cone na direcao que o player olha (norte, sul, leste, oeste),
-- 4 direcoes apenas. O atk vem da chave "fire wave" em spellsInfo (nome da
-- magia; a antiga chave "fire whip" foi removida). O id interno "whip" segue
-- valendo: fireExausted.whip, o CD da spellbar (199-ServerToDll.lua, "firewhip")
-- e o sistema de level da magia (levelFireWhip / expFireWhip).
local spellName = "fire wave"
local cf = {atk = spellsInfo[spellName].atk}

-- Efeito 36 em cada SQM atingido pelo cone: COMBAT_PARAM_EFFECT manda um
-- efeito por tile da area (Combat::combatTileEffects).
local WAVE_EFFECT = 36

-- A partir deste level o cone vai ate 5 tiles de largura.
local WAVE_LEVEL = 50

-- Level 1 ao 49: 1 tile na frente e 3 nas duas fileiras seguintes.
local AREA_WAVE = {
    {1, 1, 1},
    {1, 1, 1},
    {0, 3, 0}
}

-- Level 50 em diante: AREA_WAVE4 do lib, 1 tile na frente, 3, 3 e 5 na ponta.
local AREA_WAVE_BIG = AREA_WAVE4

-- Level 100 em diante (ELITE): o cone abre num leque de 5 fileiras.
-- Areas de estagio vindas do lib/spellStages.lua
local AREA_WAVE_ELITE = AREA_STAGE_ELITE_CONE

-- O callback de dano e' resolvido pelo NOME: o motor le o global homonimo no
-- momento do bind e o consome, entao a funcao precisa ser redefinida antes de
-- cada setCombatCallback.
local function createWaveCombat(area, multipler)
    local combat = createCombatObject()
    setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
    setCombatParam(combat, COMBAT_PARAM_EFFECT, WAVE_EFFECT)
    setCombatArea(combat, area)

    --focus ready--
    function onGetPlayerMinMaxValues(cid, level, magLevelUnused)
        local min = (level*2)+((level * 0.5)/3)*2
        local max = (level*2.5)+((level * 0.5)/3)*3
        local m = multipler
        if getPlayerInWaterWithUnderwater(cid) then
            m = m*0.5
        end
        local dano = math.random(min, max) + math.random(8, 16)
        local atk = cf.atk
        if atk and type(atk) == "number" then
            dano = dano * (atk/100)
            dano = dano+1
        end
        dano = remakeValue(1, dano, cid)
        return -dano*m, -dano*m
    end

    setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
    return combat
end

local areaWave = createCombatArea(AREA_WAVE)
local areaWaveBig = createCombatArea(AREA_WAVE_BIG)
local areaWaveElite = createCombatArea(AREA_WAVE_ELITE)

-- Estagio 1 (mini, <50)   : o cone curto de sempre
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

function onCastSpell(cid, var)
    local focusCombat, waveCombat = getWaveCombats(cid)

    if getSpellCancels(cid, "fire") == true then
        return false
    end
    if doPlayerAddExaust(cid, "fire", "whip", fireExausted.whip) == false then
        return false
    end
    if getPlayerHasStun(cid) then
        workAllCdAndAndPrevCd(cid, "fire", "whip", nil, 1)
        return true
    end

    -- Estagio 3 (100+): as chamas sobem no conjurador antes do cone abrir
    local eliteFlourish = isSpellElite(cid)
    if eliteFlourish then
        doSendMagicEffect(getThingPos(cid), 5)
    end

    if getPlayerOverPower(cid, "fire", true, true) then
        workAllCdAndAndPrevCd(cid, "fire", "whip", nil, 1)
        return doCombat(cid, focusCombat, var)
    end

    return doCombat(cid, waveCombat, var)
end
