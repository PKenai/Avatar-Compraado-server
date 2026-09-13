--[[
 * Quest System - Lib (port do SakkenOT, adaptado para o TFS do Avatar)
 * ------------------------------------------------------------------
 * Sistema de quests com progresso por kills, exibido no client pelo
 * modulo game_quests (extended opcode 0xF0, JSON).
 *
 * COMO FUNCIONA:
 *  - As quests sao definidas em data/questSystem/quests.xml (carregadas no startup).
 *  - A quest aparece no quest log do client quando o storage de inicio
 *    (startstorageid) e >= startstoragevalue. Para iniciar uma quest,
 *    o NPC deve chamar: qsStartQuest(cid, questId, npcName)
 *  - Missoes com <monster> contam kills automaticamente (evento type="kill").
 *    Cada kill envia progresso atualizado pro client em tempo real.
 *  - Para concluir uma missao no NPC: qsCompleteMission(cid, questId, missionId, npcName)
 *  - Recompensas de missao sao apenas informativas no quest log; a entrega
 *    real (itens/exp) fica a cargo do script do NPC.
 *
 * STORAGES (por player):
 *  - quest.startstorageid          -> status de inicio da quest
 *  - mission.storageid             -> status da missao (startvalue..endvalue)
 *  - mission.progressstorageid     -> kills acumulados da missao (padrao)
 *  - monster.storageid             -> kills por monstro (se especificado no XML)
 *  - fallback: MISSION_PROGRESS_TRACKING_BASE + questId*100 + missionId
 *
 * OBS: os textos podem usar acentuacao normal (UTF-8) — o client renderiza
 * corretamente. Evite apenas bytes invalidos de UTF-8.
 *]]

-- ============================================================
-- CONFIGURACAO
-- ============================================================

-- Opcode do protocolo de quests (client: modules/game_quests)
QUEST_SYSTEM_OPCODE = 0xF0

-- Base para rastrear kills quando a missao nao define progressstorageid
-- nem storageid nos monstros. Range usado: 50000+ (livre neste servidor).
MISSION_PROGRESS_TRACKING_BASE = 50000

QUEST_STATUS = {
    NOT_STARTED = 0,
    IN_PROGRESS = 1,
    COMPLETED = 2
}

MISSION_STATUS = {
    NOT_STARTED = 0,
    IN_PROGRESS = 1,
    COMPLETED = 2
}

-- Carregado 2x (globalevent + creaturescript); nunca pode resetar as quests.
QuestSystem = QuestSystem or {}
QuestSystem.quests = QuestSystem.quests or {}

-- ============================================================
-- HELPERS
-- ============================================================

function QuestSystem.getQuest(id)
    for _, quest in ipairs(QuestSystem.quests) do
        if quest.id == id then
            return quest
        end
    end
    return nil
end

-- ItemType com protecao: ids invalidos nao podem derrubar o server.
local function safeItemType(id)
    local ok, it = pcall(ItemType, id)
    if ok and it then
        return it
    end
    return nil
end

local function itemClientId(serverId)
    local it = safeItemType(serverId)
    if it then
        local ok, cid = pcall(function() return it:getClientId() end)
        if ok and cid then
            return cid
        end
    end
    return serverId
end

local function itemField(it, field)
    if not it then return 0 end
    local ok, value = pcall(function() return it[field](it) end)
    if ok and value then
        return value
    end
    return 0
end

-- ============================================================
-- CARGA DO XML (data/questSystem/quests.xml)
-- ============================================================

function qsLoadQuestsFromXML()
    if #QuestSystem.quests > 0 then
        return true
    end

    local xmlFile = io.open(getDataDir() .. "questSystem/quests.xml", "r")
    if not xmlFile then
        print("[QuestSystem] Error: quests.xml not found")
        return false
    end

    local content = xmlFile:read("*all")
    xmlFile:close()

    for questBlock in content:gmatch('<quest (.-)</quest>') do
        local questHeader = questBlock:match('^([^>]*)>')
        local questName = questHeader:match('name="([^"]+)"')

        if questName then
            local questId = tonumber(questHeader:match('id="(%d+)"')) or (#QuestSystem.quests + 1)
            local lookType = tonumber(questHeader:match('looktype="(%d+)"') or 0)
            local lookTypeEx = tonumber(questHeader:match('looktypeex="(%d+)"') or 0)
            local startStorageId = tonumber(questHeader:match('startstorageid="(%d+)"'))
            local startStorageValue = tonumber(questHeader:match('startstoragevalue="([%-]?%d+)"'))

            local quest = {
                id = questId,
                name = questName,
                lookType = lookType,
                lookTypeEx = lookTypeEx,
                description = "",
                startStorageId = startStorageId,
                startStorageValue = startStorageValue,
                missions = {}
            }

            local questDesc = questBlock:match('<description>([^<]+)</description>')
            if questDesc then
                quest.description = questDesc
            end

            for missionBlock in questBlock:gmatch('<mission (.-)</mission>') do
                local missionHeader = missionBlock:match('^([^>]*)>')
                local missionName = missionHeader:match('name="([^"]+)"')

                if missionName then
                    local missionId = #quest.missions + 1
                    local storageId = tonumber(missionHeader:match('storageid="(%d+)"'))
                    local progressStorageId = tonumber(missionHeader:match('progressstorageid="(%d+)"'))
                    local startValue = tonumber(missionHeader:match('startvalue="([%-]?%d+)"'))
                    local endValue = tonumber(missionHeader:match('endvalue="([%-]?%d+)"'))
                    local maxProgressOverride = tonumber(missionHeader:match('maxprogress="(%d+)"'))

                    local mission = {
                        id = missionId,
                        name = missionName,
                        description = missionBlock:match('<description>([^<]+)</description>') or "",
                        storageId = storageId,
                        progressStorageId = progressStorageId,
                        startValue = startValue,
                        endValue = endValue,
                        maxProgressOverride = maxProgressOverride,
                        rewards = {},
                        monsters = {},
                        items = {}
                    }

                    for itemId, count in missionBlock:gmatch('<reward id="(%d+)"[^>]*count="(%d+)"') do
                        table.insert(mission.rewards, {id = tonumber(itemId), count = tonumber(count)})
                    end

                    for monsterTag in missionBlock:gmatch('<monster (.-)/>') do
                        local mName = monsterTag:match('name="([^"]+)"')
                        local mCount = tonumber(monsterTag:match('count="(%d+)"') or 0)
                        local mStorageId = tonumber(monsterTag:match('storageid="(%d+)"'))
                        local mOutfit = tonumber(monsterTag:match('outfit="(%d+)"') or 0)

                        if mName and mCount then
                            table.insert(mission.monsters, {
                                name = mName,
                                count = mCount,
                                storageId = mStorageId,
                                outfit = mOutfit
                            })
                        end
                    end

                    table.insert(quest.missions, mission)
                end
            end

            table.insert(QuestSystem.quests, quest)
        end
    end

    return true
end

-- ============================================================
-- STATUS
-- ============================================================

function qsIsQuestStarted(cid, questId)
    local quest = QuestSystem.getQuest(questId)
    if not quest then return false end

    if quest.startStorageId and quest.startStorageValue then
        local currentValue = tonumber(getPlayerStorageValue(cid, quest.startStorageId)) or -1
        return currentValue >= quest.startStorageValue
    end

    return false
end

function qsIsMissionStarted(cid, questId, missionId)
    local quest = QuestSystem.getQuest(questId)
    if not quest then return false end

    local mission = quest.missions[missionId]
    if not mission then return false end

    if mission.storageId and mission.startValue then
        local currentValue = tonumber(getPlayerStorageValue(cid, mission.storageId)) or -1
        return currentValue >= mission.startValue
    end

    return false
end

function qsIsMissionCompleted(cid, questId, missionId)
    local quest = QuestSystem.getQuest(questId)
    if not quest then return false end

    local mission = quest.missions[missionId]
    if not mission then return false end

    if mission.storageId and mission.endValue then
        local currentValue = tonumber(getPlayerStorageValue(cid, mission.storageId)) or -1
        return currentValue >= mission.endValue
    end

    return false
end

function qsGetMissionStatus(cid, questId, missionId)
    if qsIsMissionCompleted(cid, questId, missionId) then
        return MISSION_STATUS.COMPLETED
    elseif qsIsMissionStarted(cid, questId, missionId) then
        return MISSION_STATUS.IN_PROGRESS
    else
        return MISSION_STATUS.NOT_STARTED
    end
end

function qsGetQuestStatus(cid, questId)
    local quest = QuestSystem.getQuest(questId)
    if not quest then
        return QUEST_STATUS.NOT_STARTED
    end

    if not qsIsQuestStarted(cid, questId) then
        return QUEST_STATUS.NOT_STARTED
    end

    local allCompleted = true
    for _, mission in ipairs(quest.missions) do
        if not qsIsMissionCompleted(cid, questId, mission.id) then
            allCompleted = false
            break
        end
    end

    return allCompleted and QUEST_STATUS.COMPLETED or QUEST_STATUS.IN_PROGRESS
end

-- ============================================================
-- PROGRESSO DE KILLS
-- ============================================================

function qsGetMissionProgress(cid, questId, missionId)
    -- Blindagem: ids invalidos nunca podem derrubar o envio do quest log
    questId = tonumber(questId) or 0
    missionId = tonumber(missionId) or 0

    local quest = QuestSystem.getQuest(questId)
    if not quest then return 0 end

    local mission = quest.missions[missionId]
    if not mission then return 0 end

    -- Se a missao tem monstros com storageId, soma o progresso deles
    local totalProgress = 0
    local hasMonsterStorages = false
    for _, monster in ipairs(mission.monsters) do
        if monster.storageId then
            local sv = tonumber(getPlayerStorageValue(cid, monster.storageId)) or -1
            totalProgress = totalProgress + math.min(monster.count, math.max(0, sv))
            hasMonsterStorages = true
        end
    end

    if hasMonsterStorages then
        return totalProgress
    end

    -- Usa o storage custom de tracking ou o fallback padrao
    local trackingStorage = mission.progressStorageId or (MISSION_PROGRESS_TRACKING_BASE + (questId * 100) + missionId)
    local sv = tonumber(getPlayerStorageValue(cid, trackingStorage)) or -1
    return math.max(0, sv)
end

function qsSetMissionProgress(cid, questId, missionId, progress)
    questId = tonumber(questId) or 0
    missionId = tonumber(missionId) or 0

    local quest = QuestSystem.getQuest(questId)
    if not quest then return end

    local mission = quest.missions[missionId]
    if not mission then return end

    local trackingStorage = mission.progressStorageId or (MISSION_PROGRESS_TRACKING_BASE + (questId * 100) + missionId)
    setPlayerStorageValue(cid, trackingStorage, progress)
end

function qsOnKillMonster(cid, monsterName)
    if type(monsterName) ~= "string" or monsterName == "" then return end
    monsterName = monsterName:lower()

    for _, quest in ipairs(QuestSystem.quests) do
        local killOk, killErr = pcall(function()
            if qsIsQuestStarted(cid, quest.id) then
                for _, mission in ipairs(quest.missions) do
                    if not qsIsMissionCompleted(cid, quest.id, mission.id or 0) then
                        for _, monster in ipairs(mission.monsters) do
                            if monster.name:lower() == monsterName then
                                -- Rastreamento por monstro (storageId no XML)
                                if monster.storageId then
                                    local mProgress = math.max(0, tonumber(getPlayerStorageValue(cid, monster.storageId)) or -1)
                                    if mProgress < monster.count then
                                        setPlayerStorageValue(cid, monster.storageId, mProgress + 1)
                                    end
                                else
                                    -- Rastreamento padrao da missao
                                    local progress = qsGetMissionProgress(cid, quest.id, mission.id or 0)
                                    progress = progress + 1
                                    qsSetMissionProgress(cid, quest.id, mission.id or 0, progress)
                                end

                                -- Checa se a missao completou
                                local totalRequired = 0
                                for _, m in ipairs(mission.monsters) do
                                    totalRequired = totalRequired + m.count
                                end

                                local totalProgress = qsGetMissionProgress(cid, quest.id, mission.id or 0)

                                if totalProgress >= totalRequired then
                                    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Task finished! Talk to the NPC to receive your reward.")
                                else
                                    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest progress: " .. totalProgress .. "/" .. totalRequired .. " " .. monster.name)
                                end

                                qsSendQuestList(cid)
                                qsSendQuestDetails(cid, quest.id)
                            end
                        end
                    end
                end
            end
        end)
        if not killOk then
            print("[QuestSystem] Erro no kill handler da quest '" .. tostring(quest.name) .. "' (id " .. tostring(quest.id) .. "): " .. tostring(killErr))
        end
    end
end

-- ============================================================
-- API PARA NPCS (iniciar / concluir / progresso)
-- ============================================================

function qsStartQuest(cid, questId, npcName, skipSound)
    local quest = QuestSystem.getQuest(questId)
    if not quest then return end

    if quest.startStorageId and quest.startStorageValue then
        setPlayerStorageValue(cid, quest.startStorageId, quest.startStorageValue)
    end

    -- Inicializa apenas a primeira missao (evita spoilers)
    local firstMission = quest.missions[1]
    if firstMission and firstMission.storageId and firstMission.startValue then
        setPlayerStorageValue(cid, firstMission.storageId, firstMission.startValue)
    end

    -- Efeito visual ao iniciar a quest
    local pos = getCreaturePosition(cid)
    if pos then
        doSendMagicEffect(pos, 199)
    end

    qsSendQuestList(cid)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Quest started: " .. quest.name)

    -- Notificacao (client: modules/game_notification, opcode 201)
    if npcName then
        local notificationData = {
            title = quest.name,
            message = "Nova missão: " .. firstMission.name .. "!",
            color = "#FFA500",
            duration = 5000
        }

        if not skipSound then
            notificationData.soundType = "start"
            notificationData.npcName = npcName
        end

        doSendPlayerExtendedOpcode(cid, 201, json.encode(notificationData))
    end
end

function qsCompleteMission(cid, questId, missionId, npcName, skipSound)
    local quest = QuestSystem.getQuest(questId)
    if not quest then return end

    local mission = quest.missions[missionId]
    if not mission then return end

    -- Marca a missao como concluida (endValue)
    if mission.storageId and mission.endValue then
        setPlayerStorageValue(cid, mission.storageId, mission.endValue)
    end

    -- Inicia automaticamente a proxima missao se existir
    local nextMission = quest.missions[missionId + 1]
    if nextMission then
        if not qsIsMissionStarted(cid, questId, nextMission.id) and not qsIsMissionCompleted(cid, questId, nextMission.id) then
            if nextMission.storageId and nextMission.startValue then
                setPlayerStorageValue(cid, nextMission.storageId, nextMission.startValue)
            end
        end
    end

    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Mission completed: " .. mission.name)

    -- Notificacao (client: modules/game_notification, opcode 201)
    if npcName then
        local notificationData = {
            title = quest.name,
            message = "Missão concluida: " .. mission.name .. "!",
            color = "#00FF00",
            duration = 5000
        }

        if not skipSound then
            notificationData.soundType = "end"
            notificationData.npcName = npcName
        end

        doSendPlayerExtendedOpcode(cid, 201, json.encode(notificationData))
    end

    qsSendQuestList(cid)
end

-- ============================================================
-- ENVIO AO CLIENT (opcode 0xF0)
-- ============================================================

function qsSendQuestDetails(cid, questId)
    local quest = QuestSystem.getQuest(questId)
    if not quest then return end

    local questData = {
        id = quest.id,
        name = quest.name,
        status = qsGetQuestStatus(cid, quest.id),
        missions = {}
    }

    local showNext = true
    local detailsOk, detailsErr = pcall(function()
        for _, mission in ipairs(quest.missions) do
            local missionStatus = qsGetMissionStatus(cid, quest.id, mission.id or 0)
            local isStartedOrDone = (missionStatus ~= MISSION_STATUS.NOT_STARTED)

            -- Mostra apenas missoes ja iniciadas/concluidas ou a proxima disponivel
            if isStartedOrDone or showNext then
                local maxProgress = 0
                for _, monster in ipairs(mission.monsters) do
                    maxProgress = maxProgress + monster.count
                end
                if maxProgress == 0 then
                    maxProgress = mission.maxProgressOverride or 1
                end

                local rewardsData = {}
                if questData.status == QUEST_STATUS.COMPLETED then
                    for _, reward in ipairs(mission.rewards) do
                        local clientId = itemClientId(reward.id)
                        local name = "Unknown Item"
                        local it = safeItemType(reward.id)
                        if it then
                            local okName, itemName = pcall(function() return it:getName() end)
                            if okName and itemName and itemName ~= "" then
                                name = itemName
                            end
                        end

                        -- Tooltip detalhado com atributos
                        local tooltip = name
                        if it then
                            local armor = itemField(it, "getArmor")
                            local attack = itemField(it, "getAttack")
                            local defense = itemField(it, "getDefense")
                            local weight = itemField(it, "getWeight")

                            if armor > 0 then tooltip = tooltip .. "\nArmor: " .. armor end
                            if attack > 0 then tooltip = tooltip .. "\nAttack: " .. attack end
                            if defense > 0 then tooltip = tooltip .. "\nDefense: " .. defense end
                            if weight > 0 then tooltip = tooltip .. "\nWeight: " .. (weight / 100) .. " oz" end
                        end

                        table.insert(rewardsData, {id = clientId, count = reward.count, name = tooltip})
                    end
                end

                local monstersData = {}
                for _, monster in ipairs(mission.monsters) do
                    table.insert(monstersData, {
                        name = monster.name,
                        count = monster.count,
                        outfit = monster.outfit or 0,
                        progress = monster.storageId and math.max(0, tonumber(getPlayerStorageValue(cid, monster.storageId)) or -1) or 0
                    })
                end

                table.insert(questData.missions, {
                    id = mission.id,
                    name = mission.name,
                    description = mission.description,
                    status = missionStatus,
                    completed = qsIsMissionCompleted(cid, quest.id, mission.id or 0),
                    progress = math.min(qsGetMissionProgress(cid, quest.id, mission.id or 0), maxProgress),
                    maxProgress = maxProgress,
                    rewards = rewardsData,
                    monsters = monstersData
                })
            end

            -- Se a missao atual nao esta completa, para de mostrar as proximas
            if missionStatus ~= MISSION_STATUS.COMPLETED then
                showNext = false
            end
        end
    end)
    if not detailsOk then
        print("[QuestSystem] Erro ao enviar detalhes da quest '" .. tostring(quest.name) .. "' (id " .. tostring(quest.id) .. "): " .. tostring(detailsErr))
    end

    local payload = {
        action = "questDetails",
        quest = questData
    }

    doSendPlayerExtendedOpcode(cid, QUEST_SYSTEM_OPCODE, json.encode(payload))
end

function qsSendQuestList(cid)
    local questsData = {}
    for _, quest in ipairs(QuestSystem.quests) do
        -- Uma quest com dados quebrados NAO pode apagar o quest log inteiro:
        -- isola a montagem de cada quest; as saudaveis continuam aparecendo.
        local listOk, listErr = pcall(function()
            local status = qsGetQuestStatus(cid, quest.id or 0)
            if status ~= QUEST_STATUS.NOT_STARTED then
                local visibleMissionCount = 0
                local completedMissions = 0
                local totalProgress = 0
                local totalMax = 0
                local showNext = true

                for _, mission in ipairs(quest.missions) do
                    local mStatus = qsGetMissionStatus(cid, quest.id or 0, mission.id or 0)
                    local isStartedOrDone = (mStatus ~= MISSION_STATUS.NOT_STARTED)

                    if isStartedOrDone or showNext then
                        visibleMissionCount = visibleMissionCount + 1
                        if mStatus == MISSION_STATUS.COMPLETED then
                            completedMissions = completedMissions + 1
                        end

                        -- Progresso de kills: soma missao a missao
                        local maxProgress = 0
                        for _, monster in ipairs(mission.monsters) do
                            maxProgress = maxProgress + monster.count
                        end
                        if maxProgress == 0 then
                            maxProgress = mission.maxProgressOverride or 1
                        end

                        local missionProgress = 0
                        if mStatus == MISSION_STATUS.COMPLETED then
                            missionProgress = maxProgress
                        else
                            missionProgress = math.min(qsGetMissionProgress(cid, tonumber(quest.id) or 0, tonumber(mission.id) or 0), maxProgress)
                        end

                        totalMax = totalMax + maxProgress
                        totalProgress = totalProgress + missionProgress
                    end

                    if mStatus ~= MISSION_STATUS.COMPLETED then
                        showNext = false
                    end
                end

                table.insert(questsData, {
                    id = quest.id,
                    name = quest.name,
                    lookType = quest.lookType or 0,
                    lookTypeEx = quest.lookTypeEx > 0 and itemClientId(quest.lookTypeEx) or 0,
                    description = quest.description or "",
                    status = status,
                    missionCount = visibleMissionCount,
                    completedMissions = completedMissions,
                    progress = totalProgress,
                    maxProgress = totalMax
                })
            end
        end)
        if not listOk then
            print("[QuestSystem] Erro ao montar quest '" .. tostring(quest.name) .. "' (id " .. tostring(quest.id) .. "): " .. tostring(listErr))
        end
    end

    local payload = {
        action = "questList",
        quests = questsData
    }

    doSendPlayerExtendedOpcode(cid, QUEST_SYSTEM_OPCODE, json.encode(payload))
end
