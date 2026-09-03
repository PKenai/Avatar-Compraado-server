--[[
 * BossRoomPantano - Evento ao morrer do "Monstro do pantano":
 *   * Remove todos os tentaculos da sala
 *   * Para os timers de cura e manutencao
 *   * Apos 1 minuto, teleporta todos os players para fora
 *   * Reseta a alavanca
 *
 * Limites da sala: {x=120, y=1924, z=7} ate {x=177, y=1968, z=7}
 * Saida: {x=799, y=519, z=6}
 *
 * Registrado em data/creaturescripts/creaturescripts.xml (type="death") e
 * anexado ao monstro via <script><event name="BossRoomPantano"/></script>.
 * Depende das funcoes globais bossRoomStopTimers() e bossRoomRemoveTentacles()
 * definidas em data/actions/scripts/bossRoom.lua.
]]

-- ============================================================
-- Configuracao (usa constantes globais do bossRoomLib.lua)
-- ============================================================
local CLEANUP_DELAY = 60 * 1000  -- 1 minuto

-- ============================================================
-- Reseta a alavanca
-- ============================================================
local function resetLever()
    for i = 1, #ENTRY_TILES do
        local pos = ENTRY_TILES[i]
        local item = getTileItemById(pos, LEVER_ON)
        if item and item.uid and item.uid > 0 then
            doTransformItem(item.uid, LEVER_OFF)
            return true
        end
    end
    local searchPos = {x = 808, y = 519, z = 5}
    local item = getTileItemById(searchPos, LEVER_ON)
    if item and item.uid and item.uid > 0 then
        doTransformItem(item.uid, LEVER_OFF)
        return true
    end
    return false
end

-- ============================================================
-- Teleporta todos os players da sala do boss para fora
-- ============================================================
local function teleportPlayersOut()
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)

    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                doTeleportThing(specs[i], EXIT_POS)
                doSendMagicEffect(EXIT_POS, CONST_ME_TELEPORT)
                doPlayerSendTextMessage(specs[i], MESSAGE_EVENT_ADVANCE,
                    "Boss derrotado! Voces foram teleportados para fora.")
            end
        end
    end

    -- Reseta a alavanca
    resetLever()
end

-- ============================================================
-- onDeath
-- ============================================================
function onDeath(cid, corpse, deathList)
    if not isMonster(cid) then
        return true
    end

    if getCreatureName(cid) ~= BOSS_NAME then
        return true
    end

    -- 1) Remove todos os tentaculos da sala
    bossRoomRemoveTentacles()

    -- 2) Para os timers de cura e manutencao
    bossRoomStopTimers()

    -- 3) Avisa que o boss foi derrotado
    local specs = getSpectators(ROOM_CENTER, ROOM_RANGEX, ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then
                doPlayerSendTextMessage(specs[i], MESSAGE_EVENT_ADVANCE,
                    "O Monstro do Pantano foi derrotado! Saindo em 1 minuto...")
            end
        end
    end

    -- 4) Agenda o teleporte para fora apos 1 minuto
    addEvent(teleportPlayersOut, CLEANUP_DELAY)

    return true
end
