-- ============================================================================
-- NOMANA ICON LIB - Avatar Server
-- ----------------------------------------------------------------------------
-- Verifica se o player está com mana abaixo de 20% e envia o ícone
-- correspondente para os spectators via opcode 110.
--
-- Detecta mudanças de estado e só envia quando o estado muda.
-- ============================================================================

NOMANA_ICON = {}

NOMANA_ICON.OPCODE = 110
NOMANA_ICON.STORAGE_KEY = 45202  -- para rastrear último estado conhecido
NOMANA_ICON.THRESHOLD = 20       -- percentual de mana para ativar

-- Envia o estado do ícone para todos os players próximos
function NOMANA_ICON.broadcastIcon(cid, state)
    if not isCreature(cid) then return end
    local pos = getCreaturePosition(cid)
    if not pos then return end
    local specs = getSpectators(pos, 15, 15)
    local msg = tostring(cid) .. "," .. (state and "1" or "0")
    for _, spec in ipairs(specs) do
        if isPlayer(spec) then
            doSendPlayerExtendedOpcode(spec, NOMANA_ICON.OPCODE, msg)
        end
    end
end

-- Verifica o estado de mana e envia opcode apenas se o estado mudou
function NOMANA_ICON.checkAndUpdate(cid)
    if not isPlayer(cid) then return end

    local maxMana = getCreatureMaxMana(cid)
    if maxMana <= 0 then return end

    local mana = getCreatureMana(cid)
    local manaPercent = math.floor((mana / maxMana) * 100)
    local isNoMana = (manaPercent < NOMANA_ICON.THRESHOLD)
    local lastState = getPlayerStorageValue(cid, NOMANA_ICON.STORAGE_KEY)

    -- lastState: -1 = nunca Checado, 0 = tem mana, 1 = sem mana
    if isNoMana and lastState ~= 1 then
        setPlayerStorageValue(cid, NOMANA_ICON.STORAGE_KEY, 1)
        NOMANA_ICON.broadcastIcon(cid, true)
    elseif not isNoMana and lastState ~= 0 then
        setPlayerStorageValue(cid, NOMANA_ICON.STORAGE_KEY, 0)
        NOMANA_ICON.broadcastIcon(cid, false)
    end
end

print(">> NoMana Icon Lib loaded.")
