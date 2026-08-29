-- ============================================================================
-- HEALCUT HOOKS - Avatar Server
-- ----------------------------------------------------------------------------
-- Hooka doTargetCombatHealth e doCreatureAddHealth para reduzir cura
-- quando o debuff Grievous Wounds está ativo no alvo.
--
-- IMPORTANTE: Este script deve ser carregado DEPOIS que healcut_lib.lua
-- e ANTES do sistema de combate principal.
--
-- Instalação: Adicionar dofile() no final de imuneable.lua ou em lib.lua
-- ============================================================================

dofile(getDataDir() .. "lib/custom/healcut_lib.lua")

-- Hook no doTargetCombatHealth (reduz cura aplicada via combate)
local originalDoTargetCombatHealth = doTargetCombatHealth
function doTargetCombatHealth(cid, target, type, min, max, effect, ...)
    -- Só reduz cura (valores positivos = cura)
    if type == COMBAT_HEALING and isCreature(target) and isPlayer(target) then
        if HEALCUT.isActive(target) then
            min = math.floor(min * HEALCUT.REDUCTION_MULT)
            max = math.floor(max * HEALCUT.REDUCTION_MULT)
        end
    end
    return originalDoTargetCombatHealth(cid, target, type, min, max, effect, ...)
end

-- Hook no doCreatureAddHealth (reduz cura direta, ex: poções, regen)
local originalDoCreatureAddHealth = doCreatureAddHealth
function doCreatureAddHealth(cid, health, ...)
    if health and health > 0 and isCreature(cid) and isPlayer(cid) then
        if HEALCUT.isActive(cid) then
            health = math.floor(health * HEALCUT.REDUCTION_MULT)
        end
    end
    return originalDoCreatureAddHealth(cid, health, ...)
end
