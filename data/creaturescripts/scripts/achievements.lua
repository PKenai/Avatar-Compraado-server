--[[
 * Conquistas + Titulos - Server side
 * Client: modules/game_achievements (opcode 172, JSON)
 *
 * Eventos registrados em data/creaturescripts/creaturescripts.xml:
 *   - type="kill"           -> name="AchievementsKill"
 *   - type="advance"        -> name="AchievementsAdvance"
 *   - type="extendedopcode" -> name="AchievementsOpcode"
 * E registrados por player no login (loginLogout/login.lua).
 *
 * Protocolo (opcode 172, JSON):
 *   client -> server: {action="request"} / {action="equip", id=N}
 *                     / {action="unequip"}
 *                     / {action="requestTitle", id=<creatureId>}
 *   server -> client: {action="achievements", equipped=id, list={...}}
 *                     {action="title", id=<creatureId>, title="..."}
 *                     (o client pede quando um player aparece na tela;
 *                      o servidor tambem faz broadcast no equip/unequip)
]]

-- A lib e idempotente e e auto-carregada em todos os estados Lua (data/lib).
dofile(getDataDir() .. "lib/achievementsLib.lua")

function onKill(cid, target, lastHit)
    if not isPlayer(cid) then
        return true
    end

    if not isMonster(target) then
        return true
    end

    -- summons nao contam
    if isSummon(target) then
        return true
    end

    Achievements.onKill(cid, target)
    return true
end

function onAdvance(cid, skill, oldLevel, newLevel)
    -- SKILL__LEVEL = 8 (level up). Tambem aceita 8 puro se a constante faltar.
    if (skill == SKILL__LEVEL or skill == 8) and newLevel > oldLevel then
        Achievements.onAdvance(cid)
    end
    return true
end

function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= ACHIEVEMENTS_OPCODE then
        return true
    end

    local status, jsonData = pcall(function() return json.decode(buffer) end)
    if not status or not jsonData or type(jsonData) ~= "table" then
        return true
    end

    if jsonData.action == "request" then
        Achievements.sendData(cid)
    elseif jsonData.action == "equip" then
        Achievements.equip(cid, tonumber(jsonData.id) or 0)
    elseif jsonData.action == "unequip" then
        Achievements.unequip(cid)
    elseif jsonData.action == "requestTitle" then
        local targetId = tonumber(jsonData.id) or 0
        local target = Achievements.getPlayerById(targetId)
        if target and target ~= cid and isPlayer(target) then
            Achievements.sendTitleTo(cid, target)
        end
    end

    return true
end
