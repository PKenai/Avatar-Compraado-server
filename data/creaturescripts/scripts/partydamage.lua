-- Party Damage Meter - Server side
-- Tracks damage dealt by party members and sends it to the client via extended opcode 115
-- Fires on the TARGET of the damage (statschange), attributing it to the attacker's party

g_partyDamage = g_partyDamage or {}

local OPCODE = 115

local function getPartyLeader(cid)
    -- getPlayerParty returns the leader's cid or nil
    return getPlayerParty(cid)
end

local function getPartyMembersCids(leaderCid)
    -- getPartyMembers returns a table of member cids (including the leader)
    return getPartyMembers(leaderCid)
end

local function buildDamageString(leaderCid)
    local data = g_partyDamage[leaderCid]
    if not data then return "" end
    local buf = ""
    for name, damage in pairs(data) do
        if buf ~= "" then buf = buf .. "," end
        buf = buf .. name .. ":" .. damage
    end
    return buf
end

local function broadcastPartyDamage(leaderCid)
    local buf = buildDamageString(leaderCid)
    if buf == "" then return end
    local members = getPartyMembersCids(leaderCid)
    if not members then return end
    for _, member in ipairs(members) do
        doSendPlayerExtendedOpcode(member, OPCODE, buf)
    end
end

local function addDamage(cid, amount)
    if amount <= 0 then return end
    local leaderCid = getPartyLeader(cid)
    if not leaderCid then return end
    if not g_partyDamage[leaderCid] then g_partyDamage[leaderCid] = {} end
    local name = getCreatureName(cid)
    g_partyDamage[leaderCid][name] = (g_partyDamage[leaderCid][name] or 0) + amount
    broadcastPartyDamage(leaderCid)
end

-- cid = who took the damage, attacker = who dealt it
function onStatsChange(cid, attacker, type, combat, value)
    if type ~= STATSCHANGE_HEALTHLOSS then return true end
    if not isCreature(attacker) then return true end
    local damage = math.abs(value or 0)
    if damage <= 0 then return true end

    -- Direct player attack
    if isPlayer(attacker) then
        addDamage(attacker, damage)
        return true
    end

    -- Summon attack -> credit the master
    local master = getCreatureMaster(attacker)
    if master and isPlayer(master) then
        addDamage(master, damage)
    end

    return true
end

-- Register damage tracking on every monster that spawns (covers summons too)
function onSpawn(cid)
    if isMonster(cid) then
        registerCreatureEvent(cid, "PartyDamageMeter")
    end
    return true
end

-- Called from logout.lua to free memory when the party leader logs out
function partyDamageCleanup(cid)
    local leaderCid = getPartyLeader(cid)
    -- Only the leader owns the data; a regular member logging out must not wipe the party's meter
    if leaderCid == cid and g_partyDamage[leaderCid] then
        g_partyDamage[leaderCid] = nil
    end
end

-- Called from opcode.lua when the client sends opcode 115 ("request" / "reset")
function partyDamageOnOpcode(cid, buffer)
    if buffer == "reset" then
        local leaderCid = getPartyLeader(cid)
        if leaderCid then
            g_partyDamage[leaderCid] = {}
            local members = getPartyMembersCids(leaderCid)
            if members then
                for _, member in ipairs(members) do
                    doSendPlayerExtendedOpcode(member, OPCODE, "reset")
                end
            end
        end
        return true
    end

    -- "request" -> send current data to this player
    local leaderCid = getPartyLeader(cid)
    if not leaderCid then
        doSendPlayerExtendedOpcode(cid, OPCODE, "reset")
        return true
    end
    local buf = buildDamageString(leaderCid)
    if buf == "" then buf = "reset" end
    doSendPlayerExtendedOpcode(cid, OPCODE, buf)
    return true
end
