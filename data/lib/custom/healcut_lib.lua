-- ============================================================================
-- HEALCUT LIB - Avatar Server
-- ----------------------------------------------------------------------------
-- Biblioteca compartilhada para o sistema de Heal Cut (Grievous Wounds).
-- Reduz cura em 50% quando o debuff está ativo.
-- Será carregada por imuneable.lua (detecção) e por hooks de cura.
-- ============================================================================

HEALCUT = {}

HEALCUT.STORAGE_KEY = 45200
HEALCUT.DURATION = 5          -- segundos
HEALCUT.REDUCTION_MULT = 0.50 -- 50% de redução
HEALCUT.OPCODE = 108

-- Verifica se o player possui o debuff de Grievous Wounds ativo
function HEALCUT.isActive(cid)
    if not isPlayer(cid) then return false end
    return getPlayerStorageValue(cid, HEALCUT.STORAGE_KEY) >= os.time()
end

-- Retorna o multiplicador de cura (0.5 = cura pela metade)
function HEALCUT.getHealMultiplier(cid)
    if HEALCUT.isActive(cid) then
        return HEALCUT.REDUCTION_MULT
    end
    return 1.0
end

-- Envia o estado do ícone para todos os players próximos
function HEALCUT.broadcastIcon(cid, state)
    if not isCreature(cid) then return end
    local pos = getCreaturePosition(cid)
    local specs = getSpectators(pos, 15, 15)
    local msg = tostring(cid) .. "," .. (state and "1" or "0")
    for _, spec in ipairs(specs) do
        if isPlayer(spec) then
            doSendPlayerExtendedOpcode(spec, HEALCUT.OPCODE, msg)
        end
    end
end

-- Aplica o debuff e agenda a limpeza
function HEALCUT.apply(cid)
    setPlayerStorageValue(cid, HEALCUT.STORAGE_KEY, os.time() + HEALCUT.DURATION)
    HEALCUT.broadcastIcon(cid, true)
    addEvent(function(cid)
        if isCreature(cid) then
            if getPlayerStorageValue(cid, HEALCUT.STORAGE_KEY) <= os.time() then
                HEALCUT.broadcastIcon(cid, false)
            end
        end
    end, HEALCUT.DURATION * 1000 + 100, cid)
end
