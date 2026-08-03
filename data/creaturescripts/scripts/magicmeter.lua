-- Magic Meter - Server side
-- Tracks how much damage EACH spell dealt and sends it to the client via extended opcode 116.
-- Opcode 116  <->  client module "game_magicmeter"
--
-- The meter ALWAYS counts, even when the client window is closed: every damage event
-- updates the totals and pushes a (throttled) live update to the player, exactly like
-- the Party DPS Meter. The client just renders the window when it is open.
--
-- Protocol (client -> server):
--   request  -> ask for current totals (e.g. on login / when opening the window)
--   reset    -> clear the player's totals
-- Protocol (server -> client):
--   reset
--   SpellName:Damage,SpellName2:Damage2,...
--
-- IMPORTANT: the events defined here (onCastSpell / onStatsChange / onSpawn) share the
-- global Lua state with partydamage.lua and onUseSpell.lua. Each event captures the
-- global function by name AT LOAD TIME, so this file MUST stay loaded AFTER those two
-- (it is registered last in data/creaturescripts/creaturescripts.xml).

g_magicMeter = g_magicMeter or {}
g_magicSpellLog = g_magicSpellLog or {}
g_magicLastPush = g_magicLastPush or {}

local OPCODE = 116
local ATTRIB_WINDOW = 10 -- seconds: damage is attributed to a spell cast within this window
local LOG_SIZE = 5
local PUSH_THROTTLE = 0.1 -- seconds: at most one live push per player per 100ms

-- Prettify spell words ("fire whip" -> "Fire Whip") as a fallback name.
local function prettify(words)
    local result = tostring(words):gsub("^%l", string.upper)
    result = result:gsub(" (%l)", function(c) return " " .. c:upper() end)
    return result
end

-- Sanitize names so the wire format "Name:Damage,Name2:Damage2" can't break.
local function sanitizeName(name)
    return tostring(name):gsub("[:,]", "-")
end

local function getSpellName(words)
    if type(words) ~= "string" or words == "" then
        return "Outros"
    end
    -- getInstantSpellInfo matches against the spell NAME (case-insensitive) and
    -- logs an error if not found; pcall keeps a bad word from ever crashing.
    local ok, info = pcall(getInstantSpellInfo, words)
    if ok and type(info) == "table" and info.name and info.name ~= "" then
        return sanitizeName(info.name)
    end
    return sanitizeName(prettify(words))
end

local function buildMagicString(cid)
    local data = g_magicMeter[cid]
    if not data then return "" end
    local buf = {}
    for name, damage in pairs(data) do
        if damage > 0 then
            table.insert(buf, sanitizeName(name) .. ":" .. damage)
        end
    end
    return table.concat(buf, ",")
end

-- Throttled live push (multi-target AoE spells can otherwise flood the client).
local function pushMagicMeter(cid, force)
    if not force then
        local now = os.clock()
        local last = g_magicLastPush[cid] or 0
        if now - last < PUSH_THROTTLE then
            return
        end
        g_magicLastPush[cid] = now
    end
    local buf = buildMagicString(cid)
    if buf == "" then buf = "reset" end
    doSendPlayerExtendedOpcode(cid, OPCODE, buf)
end

-- castspell event: fired on every player spell cast.
-- IMPORTANT: the `words` parameter can arrive as a NUMBER (the target cid) on the
-- per-creature cast path (BaseSpell::castSpell(creature, target)), and as the spell
-- words on the onPlayerSay path. The C++ CreatureEvent::onCastSpell ALWAYS stores the
-- real spell words in the player storage "currentFold" first, so that is the reliable
-- source of the spell name here (same trick onUseSpell.lua uses).
-- Must always return true so it never blocks the cast.
function onCastSpell(cid, words)
    if not isPlayer(cid) then return true end

    local source = ""
    if type(getCurrentFold) == "function" then
        local ok, fold = pcall(getCurrentFold, cid)
        if ok and type(fold) == "string" and fold ~= "" then
            source = fold
        end
    end
    -- Fallback: the raw words param when it is a real string (onPlayerSay path)
    if source == "" and type(words) == "string" and words ~= "" then
        source = words
    end
    if source == "" then return true end

    if not g_magicSpellLog[cid] then g_magicSpellLog[cid] = {} end
    table.insert(g_magicSpellLog[cid], { name = getSpellName(source), time = os.time() })
    if #g_magicSpellLog[cid] > LOG_SIZE then
        table.remove(g_magicSpellLog[cid], 1)
    end
    return true
end

local function addDamage(cid, amount)
    if amount <= 0 then return end
    if not g_magicMeter[cid] then g_magicMeter[cid] = {} end

    -- Attribute the damage to the most recent spell cast within the window.
    local now = os.time()
    local spellName = "Outros"
    local log = g_magicSpellLog[cid]
    if log then
        for i = #log, 1, -1 do
            if now - log[i].time <= ATTRIB_WINDOW then
                spellName = log[i].name
                break
            end
        end
    end

    -- Fallback: if the log has nothing recent, use the current fold from the storage
    -- (it always holds the words of the last spell cast by the player). NOTE: this can
    -- attribute non-spell damage (weapons/melee) to the last spell cast; acceptable
    -- trade-off so long delayed spell damage (DoTs) still counts toward the right spell.
    if spellName == "Outros" and type(getCurrentFold) == "function" then
        local ok, fold = pcall(getCurrentFold, cid)
        if ok and type(fold) == "string" and fold ~= "" then
            spellName = getSpellName(fold)
        end
    end

    g_magicMeter[cid][spellName] = (g_magicMeter[cid][spellName] or 0) + amount

    -- Always push (throttled) - the meter works even with the window closed.
    pushMagicMeter(cid)
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
        registerCreatureEvent(cid, "MagicMeter")
    end
    return true
end

-- Called from logout.lua to free memory
function magicMeterCleanup(cid)
    g_magicMeter[cid] = nil
    g_magicSpellLog[cid] = nil
    g_magicLastPush[cid] = nil
end

-- Called from opcode.lua when the client sends opcode 116 ("request" / "reset")
function magicMeterOnOpcode(cid, buffer)
    if buffer == "reset" then
        g_magicMeter[cid] = {}
        doSendPlayerExtendedOpcode(cid, OPCODE, "reset")
        return true
    end

    -- "request" -> send current totals (the meter counts regardless of the window)
    pushMagicMeter(cid, true)
    return true
end
