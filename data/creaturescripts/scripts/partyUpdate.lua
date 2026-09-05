-- ============================================================================
-- PARTY ICON HUD (adaptado para este fork 0.4)
-- ----------------------------------------------------------------------------
-- O codigo original (Canary/TFS 1.x) usava API OO (creature:getName(),
-- Party:onJoin, events.xml) que NAO existe neste motor. Esta versao usa a
-- API deste fork:
--   * getPlayerParty(cid)   -> cid do lider (ou nil se nao esta em party)
--   * getPartyMembers(cid)  -> tabela com os membros + o lider no final
--   * doSendPlayerExtendedOpcode(cid, opcode, buffer) -> envia para o client
--   * json.encode           -> data/lib/json.lua (carregado no initState)
--
-- Protocolo com o client (OTClient, opcode 160):
--   {type="update", player={name, pos}}          -> move o icone do jogador
--   {type="join",   members={{name, vocation, pos}, ...}} -> monta o HUD
--   {type="leave",  name="<nome>"}               -> remove o icone
--
-- O motor nao tem hooks de Party (join/leave/disband), entao:
--   * o LIDER reenvia a lista completa ("join") sempre que a roster muda;
--   * cada jogador guarda a roster que conhece e, ao sair/deslogar, limpa o
--     proprio HUD ("leave" de todos os nomes) para nao sobrar icone;
--   * no disband/logout do lider, os membros sao avisados ("leave").
--   * updates so saem quando o jogador anda (com heartbeat a cada 5 ticks
--     para se recuperar de mensagens perdidas).
-- ============================================================================

local OPCODE_PARTY = 160

-- estado deste script (nao compartilhado entre sistemas; zera no reload)
local lastLeader = {}   -- cid -> lider que o jogador seguia (detecta saida)
local rosterCache = {}  -- cid do lider -> {[membroCid] = true} (p/ avisar no disband)
local myRoster = {}     -- cid -> {[nome] = true} (roster conhecida, p/ limpar o proprio HUD)
local tickCount = {}    -- cid -> contador de ticks (heartbeat)
local lastPos = {}      -- cid -> {x, y, z} (so envia update quando mudou)

local HEARTBEAT_EVERY = 5 -- reenvia a posicao a cada 5 ticks (~5s) mesmo parado

local function safeJson(data)
    local ok, res = pcall(json.encode, data)
    if ok and type(res) == "string" then
        return res
    end
    return nil
end

local function sendOpcode(cid, data)
    if not isPlayer(cid) then
        return
    end
    local payload = safeJson(data)
    if payload then
        doSendPlayerExtendedOpcode(cid, OPCODE_PARTY, payload)
    end
end

-- Limpa o HUD do jogador com a ultima roster que ele conhecia.
local function clearOwnHud(cid)
    local names = myRoster[cid]
    if not names then
        return
    end
    for name in pairs(names) do
        sendOpcode(cid, {type = "leave", name = name})
    end
    myRoster[cid] = nil
end

-- Monta a lista completa (nome, vocacao, pos) e envia para todos do grupo.
local function sendRoster(members)
    local list = {}
    for _, m in ipairs(members) do
        if isPlayer(m) then
            table.insert(list, {
                name = getCreatureName(m),
                vocation = getPlayerVocation(m),
                pos = getThingPos(m)
            })
        end
    end
    local payload = safeJson({type = "join", members = list})
    if not payload then
        return
    end
    for _, m in ipairs(members) do
        if isPlayer(m) then
            doSendPlayerExtendedOpcode(m, OPCODE_PARTY, payload)
        end
    end
end

-- Avisa os membros de um grupo que ele acabou (disband/logout do lider).
local function notifyDisband(leaderCid)
    local prev = rosterCache[leaderCid]
    rosterCache[leaderCid] = nil
    if not prev then
        return
    end
    for m in pairs(prev) do
        if isPlayer(m) and m ~= leaderCid then
            local payload = safeJson({type = "leave", name = getCreatureName(m)})
            if payload then
                doSendPlayerExtendedOpcode(m, OPCODE_PARTY, payload)
            end
        end
    end
end

-- Compara a roster atual com a ultima conhecida do lider; se mudou, reenvia.
local function syncRoster(leader, members)
    local now = {}
    for _, m in ipairs(members) do
        if isPlayer(m) then
            now[m] = true
        end
    end

    local prev = rosterCache[leader]
    local changed = (prev == nil)
    if prev and not changed then
        for m in pairs(prev) do
            if not now[m] then
                changed = true
                break
            end
        end
    end
    if not changed then
        for m in pairs(now) do
            if not prev[m] then
                changed = true
                break
            end
        end
    end

    rosterCache[leader] = now
    if changed then
        sendRoster(members)
    end
end

function onThink(cid, interval)
    if not isPlayer(cid) then
        return true
    end

    local leader = getPlayerParty(cid)

    if not leader then
        -- saiu/desfez o grupo: limpa o proprio HUD por completo
        if lastLeader[cid] then
            lastLeader[cid] = nil
            clearOwnHud(cid)
        end
        -- se era o lider, avisa os membros que o grupo acabou
        notifyDisband(cid)
        tickCount[cid] = nil
        lastPos[cid] = nil
        return true
    end

    lastLeader[cid] = leader

    local members = getPartyMembers(cid)
    if type(members) ~= "table" then
        return true -- corrida: saiu da party no meio do think
    end

    -- so envia a posicao quando mudou (ou no heartbeat periodico)
    local pos = getThingPos(cid)
    local last = lastPos[cid]
    local moved = not last or last.x ~= pos.x or last.y ~= pos.y or last.z ~= pos.z
    lastPos[cid] = pos

    tickCount[cid] = (tickCount[cid] or 0) + 1
    local heartbeat = (tickCount[cid] % HEARTBEAT_EVERY) == 0

    if moved or heartbeat then
        local myData = {name = getCreatureName(cid), pos = pos}
        for _, member in ipairs(members) do
            if isPlayer(member) then
                sendOpcode(member, {type = "update", player = myData})
            end
        end
    end

    -- mantem a propria roster conhecida (para limpar o HUD ao sair)
    local names = {}
    for _, m in ipairs(members) do
        if isPlayer(m) then
            names[getCreatureName(m)] = true
        end
    end
    myRoster[cid] = names

    -- o lider mantem a lista sincronizada (entrada/saida/desbanco)
    if cid == leader then
        syncRoster(leader, members)
    end

    return true
end

function onLogout(cid)
    if not isPlayer(cid) then
        return true
    end
    -- se era lider, o grupo desfaz: avisa os membros restantes
    notifyDisband(cid)
    lastLeader[cid] = nil
    myRoster[cid] = nil
    tickCount[cid] = nil
    lastPos[cid] = nil
    return true
end