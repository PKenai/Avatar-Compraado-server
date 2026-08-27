-- ============================================================================
-- HUNGER ICON LIB - Avatar Server
-- ----------------------------------------------------------------------------
-- Verifica se o player está com fome (food == 0) e envia o ícone
-- correspondente para os spectators via opcode 109.
--
-- Detecta mudanças de estado (fome <-> sem fome) e só envia quando
-- o estado muda, para evitar spam de opcodes.
-- ============================================================================

HUNGER_ICON = {}

HUNGER_ICON.OPCODE = 109
HUNGER_ICON.STORAGE_KEY = 45201  -- para rastrear último estado conhecido

-- Envia o estado do ícone de fome para todos os players próximos
function HUNGER_ICON.broadcastIcon(cid, state)
    if not isCreature(cid) then return end
    local pos = getCreaturePosition(cid)
    if not pos then return end
    local specs = getSpectators(pos, 15, 15)
    local msg = tostring(cid) .. "," .. (state and "1" or "0")
    for _, spec in ipairs(specs) do
        if isPlayer(spec) then
            doSendPlayerExtendedOpcode(spec, HUNGER_ICON.OPCODE, msg)
        end
    end
end

-- Verifica o estado de fome e envia opcode apenas se o estado mudou
function HUNGER_ICON.checkAndUpdate(cid)
    if not isPlayer(cid) then return end

    local food = getPlayerFood(cid)
    local isHungry = (food <= 0)
    local lastState = getPlayerStorageValue(cid, HUNGER_ICON.STORAGE_KEY)

    -- lastState: -1 = nunca Checado, 0 = não fome, 1 = fome
    if isHungry and lastState ~= 1 then
        -- Player ficou com fome agora
        setPlayerStorageValue(cid, HUNGER_ICON.STORAGE_KEY, 1)
        HUNGER_ICON.broadcastIcon(cid, true)
    elseif not isHungry and lastState ~= 0 then
        -- Player comeu e saiu da fome
        setPlayerStorageValue(cid, HUNGER_ICON.STORAGE_KEY, 0)
        HUNGER_ICON.broadcastIcon(cid, false)
    end
end

print(">> Hunger Icon Lib loaded.")
