-- ============================================================================
-- spellStages.lua - estagios de evolucao das magias dos players
--
--   Estagio 1 (MINI)  - nivel < 50   : area minima, sem efeitos secundarios
--   Estagio 2 (BASE)  - nivel 50-99  : exatamente o que a magia sempre foi
--   Estagio 3 (ELITE) - nivel 100+   : area maxima + identidade propria
--
-- REGRA DE OURO: o dano NUNCA muda entre estagios. Cada combat de estagio
-- reusa o mesmo callback de dano da magia (as funcoes onGetPlayerMinMaxValues
-- continuam identicas, apenas sao rebindadas em cada combat novo).
--
-- COMO CADA ESTAGIO CRESCE:
--   magias de AREA    : mini perde o anel externo da area, elite ganha um
--                       anel a mais, sempre mantendo o formato da magia
--                       (beam continua beam, cone continua cone)
--   magias de ALVO    : mini e' o golpe seco, elite repete o golpe (eco)
--   nos dois casos o estagio 2 mantem a area/visual de hoje.
--
-- QUEM FAZ O QUE:
--   * a AREA por estagio e' derivada pelo MOTOR (Combat::getStageArea, em
--     sources/combat.cpp). A magia so' precisa ligar com uma linha:
--         setCombatArea(combat, createCombatArea(...))
--         setCombatStageScaling(combat)
--     Rode tools/apply_spell_stages.py para ver quais magias ainda faltam.
--   * o ECO de magia de alvo unico e' feito pelo wrapper de doCombat abaixo,
--     ligado por registerSpellStageEcho(combat).
--   * o SABOR por elemento (slow/efeito) e os estagios escritos a mao usam as
--     funcoes spellStageElite / spellStageFlavor / pickSpellStage.
--
-- Este arquivo e' carregado automaticamente por BaseEvents::loadFromXml, que
-- varre data/spells/lib/ antes de ler data/spells/spells.xml.
-- ============================================================================

SPELL_MINI_LEVEL = 50
SPELL_ELITE_LEVEL = 100

SPELL_STAGE_MINI = 1
SPELL_STAGE_BASE = 2
SPELL_STAGE_ELITE = 3

-- ----------------------------------------------------------------------------
-- Areas dos estagios
-- Formato igual ao usado nas magias: cada linha e' o eixo Y, cada coluna o X,
-- 3 = posicao do conjurador, 1 = tile atingido pelo dano.
-- Sao tabelas proprias (e nao as do spells.lua) para nao depender da ordem em
-- que o loadDirectory carrega os arquivos da pasta lib/.
-- ----------------------------------------------------------------------------

-- Um unico tile (so' quem esta na frente/embaixo do conjurador)
AREA_STAGE_SOLO = { {3} }

-- Flechas / beams (viram um trilho de tiles na direcao olhada)
AREA_STAGE_MINI_BEAM = {
    {1},
    {3}
}

AREA_STAGE_ELITE_BEAM = {
    {1},
    {1},
    {1},
    {1},
    {1},
    {1},
    {3}
}

-- Cones (waves) apontando para o eixo escolhido
AREA_STAGE_MINI_CONE = {
    {1, 1, 1},
    {0, 3, 0}
}

AREA_STAGE_ELITE_CONE = {
    {0, 1, 1, 1, 0},
    {0, 1, 1, 1, 0},
    {0, 1, 1, 1, 0},
    {0, 1, 1, 1, 0},
    {0, 0, 3, 0, 0}
}

-- Areas centradas no conjurador (explosao em volta / aura)
AREA_STAGE_MINI_SELF = { {3} }

-- Cruz: os 4 lados do conjurador, sem as diagonais
AREA_STAGE_MINI_PLUS = {
    {0, 1, 0},
    {1, 3, 1},
    {0, 1, 0}
}

-- Quadrado 5x5 em volta do conjurador (25 tiles)
AREA_STAGE_ELITE_SQUARE = {
    {1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1},
    {1, 1, 3, 1, 1},
    {1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1}
}

AREA_STAGE_ELITE_SELF = {
    {0, 0, 1, 1, 1, 0, 0},
    {0, 1, 1, 1, 1, 1, 0},
    {1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 3, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1},
    {0, 1, 1, 1, 1, 1, 0},
    {0, 0, 1, 1, 1, 0, 0}
}

-- ----------------------------------------------------------------------------
-- Sabor do estagio ELITE por elemento (mantendo a essencia de cada um)
--   fire  : Combustao  - as chamas pegam de novo no alvo
--   water : Correnteza - o alvo fica preso na agua e se arrasta
--   air   : Vendaval   - o vento desestabiliza e empurra o alvo
--   earth : Fissura    - o chao racha e prende o alvo
-- slowPercent / slowTime seguem a assinatura de doSlow(cid, target, %, ms)
-- ----------------------------------------------------------------------------
SPELL_ELITE_FLAVOR = {
    fire  = { name = "Combustao", effect = 5,   slowPercent = 0,  slowTime = 0,    echoDelay = 300, echo = true },
    water = { name = "Correnteza", effect = 53, slowPercent = 35, slowTime = 1500, echoDelay = 300, echo = true },
    air   = { name = "Vendaval",   effect = 76, slowPercent = 25, slowTime = 1200, echoDelay = 250, echo = true },
    earth = { name = "Fissura",    effect = 287, slowPercent = 40, slowTime = 1200, echoDelay = 300, echo = true }
}

-- ----------------------------------------------------------------------------
-- Nivel -> estagio
-- ----------------------------------------------------------------------------
function getSpellStage(cid)
    -- Monstros e summons nao tem estagio: continuam exatamente como sempre
    -- foram, senao as magias de monstro herdariam a area elite.
    if not isPlayer(cid) then
        return SPELL_STAGE_BASE
    end

    local level = getPlayerLevel(cid)
    if level >= SPELL_ELITE_LEVEL then
        return SPELL_STAGE_ELITE
    elseif level >= SPELL_MINI_LEVEL then
        return SPELL_STAGE_BASE
    end
    return SPELL_STAGE_MINI
end

function isSpellMini(cid)
    return getSpellStage(cid) == SPELL_STAGE_MINI
end

function isSpellElite(cid)
    return getSpellStage(cid) == SPELL_STAGE_ELITE
end

function getSpellStageName(stage)
    if stage == SPELL_STAGE_ELITE then return "elite" end
    if stage == SPELL_STAGE_MINI then return "mini" end
    return "estagio 2"
end

-- Escolhe qualquer coisa por estagio (combat, area, numero...)
-- Ex: local combat = pickSpellStage(cid, combatMini, combat, combatElite)
function pickSpellStage(cid, mini, base, elite)
    local stage = getSpellStage(cid)
    if stage == SPELL_STAGE_ELITE then
        return elite
    elseif stage == SPELL_STAGE_MINI then
        return mini
    end
    return base
end

-- ============================================================================
-- Segundo golpe do estagio ELITE
-- Agenda (delay ms) uma segunda aplicacao do combat. Nao faz nada antes do
-- nivel 100, entao pode ser chamada livremente nas magias.
--   cid      : conjurador
--   var      : o mesmo variant usado no doCombat principal
--   combats  : um combat ou uma lista deles (sorteia um, igual o resto do datapack)
--   delay    : ms do eco (default 300)
-- ============================================================================
function spellStageEcho(cid, var, combats, delay)
    if not isSpellElite(cid) then
        return false
    end

    local combat = combats
    if type(combats) == "table" then
        combat = combats[math.random(1, #combats)]
    end
    if not combat then
        return false
    end

    addEvent(function()
        if not isCreature(cid) or isInPz(cid) then
            return false
        end

        -- alvo unico: se morreu ou entrou em pz, o eco nao sai
        if type(var) == "number" then
            local target = variantToNumber(var)
            if not target or target <= 0 or not isCreature(target) or isInPz(target) then
                return false
            end
        end

        return doCombat(cid, combat, var)
    end, delay or 300)

    return true
end

-- ============================================================================
-- Sabor do estagio ELITE aplicado no alvo
-- Slow + efeito extra, so' para quem esta no nivel 100+.
--   element : "fire" | "water" | "air" | "earth"
-- ============================================================================
function spellStageFlavor(cid, element, target)
    if not isSpellElite(cid) or not isCreature(target) then
        return false
    end

    local flavor = SPELL_ELITE_FLAVOR[element]
    if not flavor then
        return false
    end

    if flavor.effect and flavor.effect > 0 then
        doSendMagicEffect(getThingPos(target), flavor.effect)
    end

    if flavor.slowPercent > 0 and flavor.slowTime > 0 then
        doSlow(cid, target, flavor.slowPercent, flavor.slowTime)
    end

    return true
end

-- ============================================================================
-- Pacote completo do estagio ELITE, para resolver em uma linha so' na magia.
--   cid     : conjurador
--   element : "fire" | "water" | "air" | "earth"
--   var     : variant do doCombat principal
--   combats : combat (ou lista) que faz o segundo golpe. Use nil nas magias de
--             AREA, para nao dobrar o dano em varios alvos de uma vez; nelas o
--             elite fica com a area grande + o sabor do elemento.
--   target  : criatura alvo (0/nil quando a magia e' de area)
--   delay   : sobrescreve o tempo do eco, quando a magia ja' tem um golpe
--             extra proprio (ex: o sistema de dobras) e precisa de espaco
-- ============================================================================
function spellStageElite(cid, element, var, combats, target, delay)
    if not isSpellElite(cid) then
        return false
    end

    local flavor = SPELL_ELITE_FLAVOR[element]

    if combats then
        spellStageEcho(cid, var, combats, delay or (flavor and flavor.echoDelay) or 300)
    end

    if target and isCreature(target) then
        spellStageFlavor(cid, element, target)
    end

    return true
end

-- ============================================================================
-- Efeito visual por estagio: no mini a magia aparece "pequena", no elite
-- aparece carregada. Util quando a magia tem efeito secundario de impacto.
-- ============================================================================
function spellStageEffect(cid, effMini, effBase, effElite)
    return pickSpellStage(cid, effMini, effBase, effElite)
end

-- ============================================================================
-- ESCALA POR ESTAGIO - para as magias que nao tem area de dano
-- (cura, duracao, velocidade, numero de ondas/hits, tempo de efeito)
--
-- Sempre multiplicam um valor BASE da propria magia, entao o estagio 2 (50-99)
-- continua sendo exatamente o valor de hoje.
--
--   Mini (<50)  : 0.6x - 0.75x
--   Padrao(50-99): 1x
--   Elite (100+) : 1.5x - 2x
-- ============================================================================
SPELL_STAGE_MINI_FACTOR = 0.6
SPELL_STAGE_ELITE_FACTOR = 1.6

function spellStageScale(cid, base, miniFactor, eliteFactor)
    local stage = getSpellStage(cid)
    if stage == SPELL_STAGE_ELITE then
        return base * (eliteFactor or SPELL_STAGE_ELITE_FACTOR)
    elseif stage == SPELL_STAGE_MINI then
        return base * (miniFactor or SPELL_STAGE_MINI_FACTOR)
    end
    return base
end

-- Cura: 60% no mini, 160% no elite
function spellStageHeal(cid, base)
    return math.floor(spellStageScale(cid, base, 0.6, 1.6))
end

-- Duracao em milissegundos: 60% no mini, 160% no elite
function spellStageDuration(cid, ms)
    return math.floor(spellStageScale(cid, ms, 0.6, 1.6))
end

-- Duracao em segundos (os scripts usam bastante cf.segundos)
function spellStageSeconds(cid, seconds)
    return math.max(1, math.floor(spellStageScale(cid, seconds, 0.6, 1.6)))
end

-- Numero de ondas / hits / ticks: -1 no mini, +1 no elite (nunca abaixo de 1)
function spellStageCount(cid, base)
    local stage = getSpellStage(cid)
    if stage == SPELL_STAGE_ELITE then
        return base + 1
    elseif stage == SPELL_STAGE_MINI then
        return math.max(1, base - 1)
    end
    return base
end

-- Velocidade/incremento por tick: 75% no mini, 150% no elite
function spellStageSpeed(cid, base)
    return math.floor(spellStageScale(cid, base, 0.75, 1.5))
end

-- ============================================================================
-- REGISTRO AUTOMATICO DOS ESTAGIOS
--
-- Em vez de reescrever o onCastSpell de cada magia (sao ~90 scripts), a magia
-- apenas registra os combats de mini/elite assim que sao criados:
--
--     registerSpellStageCombats(combat, combatMini, combatElite)
--     registerSpellStageEcho(combat)   -- magia de alvo unico
--
-- O wrapper abaixo e' quem escolhe o estagio no momento do cast. O ganho e'
-- que TODO o resto da magia (checks, dobras, efeitos) continua intacto, e o
-- dano nem e' tocado: os combats de estagio sao clones do original.
-- ============================================================================

SPELL_STAGE_COMBATS = {}
SPELL_STAGE_ECHO = {}

function registerSpellStageCombats(base, mini, elite)
    if base and mini and elite then
        SPELL_STAGE_COMBATS[base] = { mini = mini, elite = elite }
    end
    return base
end

function registerSpellStageEcho(base)
    if base then
        SPELL_STAGE_ECHO[base] = true
    end
    return base
end

-- doCombat original (guardado antes de qualquer sombra)
local spellStageRawDoCombat = doCombat

function doCombat(cid, combat, var, ...)
    local baseCombat = combat

    local family = SPELL_STAGE_COMBATS[combat]
    if family then
        combat = pickSpellStage(cid, family.mini, combat, family.elite)
    end

    local result = spellStageRawDoCombat(cid, combat, var, ...)

    -- Estagio 3 em magia de alvo unico: o golpe ecoa (2 vezes o dano)
    if SPELL_STAGE_ECHO[baseCombat] and isSpellElite(cid) and type(var) == "number" then
        addEvent(function()
            if not isCreature(cid) or isInPz(cid) then
                return false
            end
            local target = variantToNumber(var)
            if not target or target <= 0 or not isCreature(target) or isInPz(target) then
                return false
            end
            return spellStageRawDoCombat(cid, combat, var)
        end, 300)
    end

    return result
end
