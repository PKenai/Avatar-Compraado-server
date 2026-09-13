-- ============================================================
-- HYDRA ROOM LIB
-- Boss Room: Green Hydra Head + Blue Hydra Head
-- ============================================================

HYDRA_ROOM_FROM   = HYDRA_ROOM_FROM   or {x = 383, y = 434, z = 11}
HYDRA_ROOM_TO     = HYDRA_ROOM_TO     or {x = 444, y = 482, z = 11}
HYDRA_ROOM_CENTER = HYDRA_ROOM_CENTER or {x = 413, y = 458, z = 11}
HYDRA_ROOM_RANGEX = HYDRA_ROOM_RANGEX or 32
HYDRA_ROOM_RANGEY = HYDRA_ROOM_RANGEY or 25

HYDRA_LEVER_ON  = HYDRA_LEVER_ON  or 1946
HYDRA_LEVER_OFF = HYDRA_LEVER_OFF or 1945

HYDRA_ENTRY_TILES = HYDRA_ENTRY_TILES or {
    {x = 492, y = 468, z = 9},
    {x = 495, y = 467, z = 9},
    {x = 497, y = 468, z = 9},
    {x = 496, y = 470, z = 9},
    {x = 492, y = 471, z = 9},
}

HYDRA_TELEPORT_POS = HYDRA_TELEPORT_POS or {x = 404, y = 473, z = 11}
HYDRA_EXIT_POS     = HYDRA_EXIT_POS     or {x = 495, y = 469, z = 9}

HYDRA_CHEST_ITEMID   = 28873
HYDRA_CHEST_ACTIONID = 50021
HYDRA_CHEST_POS      = {x = 401, y = 471, z = 11}

HYDRA_REWARD_PLAT_ITEM  = 2152
HYDRA_REWARD_PLAT_COUNT = 200

HYDRA_LEVER_COOLDOWN_STORAGE = 50020
HYDRA_CHEST_COOLDOWN_STORAGE = 50021
HYDRA_LEVER_COOLDOWN_TIME    = 24 * 3600
HYDRA_CHEST_COOLDOWN_TIME    = 5  * 3600

HYDRA_GREEN_DEATH_ITEMID = 19267
HYDRA_GREEN_DEATH_POS    = {x = 408, y = 460, z = 11}
HYDRA_BLUE_DEATH_ITEMID  = 19273
HYDRA_BLUE_DEATH_POS     = {x = 412, y = 460, z = 11}

hydraRoomState = hydraRoomState or {
    active = false,
    bosses = {
        green = {
            name      = "Green Hydra Head",
            pos       = {x = 408, y = 461, z = 11},
            cid       = nil,
            isDead    = false,
            deathItem = 19267,
            deathPos  = {x = 408, y = 460, z = 11},
        },
        blue = {
            name      = "Blue Hydra Head",
            pos       = {x = 412, y = 460, z = 11},
            cid       = nil,
            isDead    = false,
            deathItem = 19273,
            deathPos  = {x = 412, y = 460, z = 11},
        },
    },
    pulseTimerId   = nil,
    exitTimerId    = nil,  -- timer pos-vitoria (2 min)
    timeoutTimerId = nil,  -- timer de seguranca (30 min)
}

function hydraCountPlayersInRoom()
    local specs = getSpectators(HYDRA_ROOM_CENTER, HYDRA_ROOM_RANGEX, HYDRA_ROOM_RANGEY)
    local count = 0
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isPlayer(specs[i]) then count = count + 1 end
        end
    end
    return count
end

function areAllHydrasDead()
    for _, boss in pairs(hydraRoomState.bosses) do
        if not boss.isDead then return false end
    end
    return true
end

function getHydraKeyByCid(cid)
    for key, boss in pairs(hydraRoomState.bosses) do
        if boss.cid == cid then return key end
    end
    return nil
end

function hydraRoomRemoveChest()
    local item = getTileItemById(HYDRA_CHEST_POS, HYDRA_CHEST_ITEMID)
    if item and item.uid and item.uid > 0 then
        doRemoveItem(item.uid)
        return true
    end
    return false
end

function hydraRoomSpawnChest()
    hydraRoomRemoveChest()
    local chest = doCreateItem(HYDRA_CHEST_ITEMID, 1, HYDRA_CHEST_POS)
    if chest and chest > 0 then
        doSetItemActionId(chest, HYDRA_CHEST_ACTIONID)
        doSendMagicEffect(HYDRA_CHEST_POS, CONST_ME_MAGIC_BLUE)
        return true
    end
    return false
end

function hydraRoomRemoveAllMonsters()
    local specs = getSpectators(HYDRA_ROOM_CENTER, HYDRA_ROOM_RANGEX, HYDRA_ROOM_RANGEY)
    if specs and #specs > 0 then
        for i = 1, #specs do
            if isMonster(specs[i]) then doRemoveCreature(specs[i]) end
        end
    end
end

-- runningEventId: NUNCA parar o evento que esta' rodando agora.
-- O executeTimer do C++ (luascript.cpp) chama o callback e so' depois le' o
-- iterador do evento pra liberar as referencias; o stopEvent apaga essa entrada
-- (luaStopEvent -> erase), entao parar a si mesmo deixa o iterador apontando pra
-- memoria liberada e o server cai com access violation, sem log.
-- Quem roda como timer zera o proprio *TimerId na primeira linha do callback;
-- o parametro aqui e' o cinto de seguranca extra.
function hydraRoomStopTimers(runningEventId)
    hydraRoomState.active = false
    if hydraRoomState.pulseTimerId and hydraRoomState.pulseTimerId ~= runningEventId then
        stopEvent(hydraRoomState.pulseTimerId)
        hydraRoomState.pulseTimerId = nil
    end
    if hydraRoomState.exitTimerId and hydraRoomState.exitTimerId ~= runningEventId then
        stopEvent(hydraRoomState.exitTimerId)
        hydraRoomState.exitTimerId = nil
    end
    if hydraRoomState.timeoutTimerId and hydraRoomState.timeoutTimerId ~= runningEventId then
        stopEvent(hydraRoomState.timeoutTimerId)
        hydraRoomState.timeoutTimerId = nil
    end
    for _, boss in pairs(hydraRoomState.bosses) do
        boss.cid    = nil
        boss.isDead = false
    end
end

function hydraRoomResetAll(runningEventId)
    hydraRoomStopTimers(runningEventId)
    hydraRoomRemoveAllMonsters()
    hydraRoomRemoveChest()
    local gItem = getTileItemById(HYDRA_GREEN_DEATH_POS, HYDRA_GREEN_DEATH_ITEMID)
    if gItem and gItem.uid and gItem.uid > 0 then doRemoveItem(gItem.uid) end
    local bItem = getTileItemById(HYDRA_BLUE_DEATH_POS, HYDRA_BLUE_DEATH_ITEMID)
    if bItem and bItem.uid and bItem.uid > 0 then doRemoveItem(bItem.uid) end
end
