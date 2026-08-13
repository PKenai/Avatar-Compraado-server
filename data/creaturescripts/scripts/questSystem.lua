--[[
 * Quest System - Server side
 * Client: modules/game_quests (quest log oficial do Avatar)
 *
 * Eventos registrados em data/creaturescripts/creaturescripts.xml:
 *   - type="kill"          -> name="QuestKill"      (contagem de kills)
 *   - type="extendedopcode" -> name="QuestsOpcode"  (pedidos da janela)
 * E registrados por player no login (loginLogout/login.lua).
 *
 * Protocolo (opcode 0xF0, JSON):
 *   client -> server: {action="requestQuestList"} / {action="requestQuestDetails", questId=N}
 *   server -> client: {action="questList", quests={...}} / {action="questDetails", quest={...}}
 *
 * IMPORTANTE: neste TFS cada tipo de evento roda em um estado Lua SEPARADO
 * (creaturescripts, globalevents e NPCs tem lua_State proprios). O startup
 * (questSystemInit.lua) carrega as quests no estado dos globalevents; sem o
 * qsLoadQuestsFromXML() abaixo, o onKill/onExtendedOpcode veria
 * QuestSystem.quests vazio -> quest log sem quests e kills sem contar.
]]

-- A lib e idempotente: pode ser dofilada aqui e no startup sem perder as quests.
dofile(getDataDir() .. "lib/questSystemLib.lua")
qsLoadQuestsFromXML()
print("[QuestSystem] creaturescript state: " .. #QuestSystem.quests .. " quests carregadas")

-- ============================================================
-- CONTAGEM DE KILLS (type="kill")
-- ============================================================
function onKill(cid, target, lastHit)
    -- mortes sem player (ambiente/efeitos) nao contam
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

    local monsterName = string.lower(getCreatureName(target))
    qsOnKillMonster(cid, monsterName)

    -- Aliases (ex: Ogre Mutiny - 3 monstros contam para a mesma missao)
    if monsterName == "ogre berserker" or monsterName == "ogre magician" then
        qsOnKillMonster(cid, "ogre")
    end

    return true
end

-- ============================================================
-- OPCODE 0xF0 (type="extendedopcode")
-- ============================================================
function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= QUEST_SYSTEM_OPCODE then
        return true
    end

    local status, jsonData = pcall(function() return json.decode(buffer) end)
    if not status or not jsonData or type(jsonData) ~= "table" then
        return true
    end

    if jsonData.action == "requestQuestList" then
        qsSendQuestList(cid)
    elseif jsonData.action == "requestQuestDetails" then
        local questId = tonumber(jsonData.questId) or 0
        if questId > 0 then
            qsSendQuestDetails(cid, questId)
        end
    end

    return true
end
