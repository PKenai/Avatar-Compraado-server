-- Fire Wave: cone na direcao que o player olha (norte, sul, leste, oeste),
-- 4 direcoes apenas. Mesmo dano do antigo Fire Whip: a chave "fire whip" em
-- spellsInfo (atk 115), fireExausted e o sistema de level da magia
-- (levelFireWhip / expFireWhip) continuam valendo; mudaram so' a area e o
-- efeito.
local spellName = "fire whip"
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

-- O callback de dano e' resolvido pelo NOME: o motor le o global homonimo no
-- momento do bind e o consome, entao a funcao precisa ser redefinida antes de
-- cada setCombatCallback.
local function createWaveCombat(area, multipler)
    local combat = createCombatObject()
    setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
    setCombatParam(combat, COMBAT_PARAM_EFFECT, WAVE_EFFECT)
    setCombatArea(combat, area)

    --focus ready--
    function onGetPlayerMinMaxValues(cid, level, magLevel)
        local min = (level*2)+(magLevel/3)*2
        local max = (level*2.5)+(magLevel/3)*3
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

local combatWave = createWaveCombat(areaWave, 1)
local combatWaveFocus = createWaveCombat(areaWave, 2)
local combatWaveBig = createWaveCombat(areaWaveBig, 1)
local combatWaveBigFocus = createWaveCombat(areaWaveBig, 2)

local function getWaveCombats(cid)
    if getPlayerLevel(cid) >= WAVE_LEVEL then
        return combatWaveBigFocus, combatWaveBig
    end
    return combatWaveFocus, combatWave
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

    if getPlayerOverPower(cid, "fire", true, true) then
        workAllCdAndAndPrevCd(cid, "fire", "whip", nil, 1)
        return doCombat(cid, focusCombat, var)
    end

    return doCombat(cid, waveCombat, var)
end
