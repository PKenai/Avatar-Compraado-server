PotionCraft = {}
PotionCraft.active = {}

PotionCraft.potions = {
    { id = 7620, name = "Mana Potion", timeSec = 45, timeStr = "45s" },
    { id = 7589, name = "Strong Mana Potion", timeSec = 60, timeStr = "1m" },
    { id = 7590, name = "Great Mana Potion", timeSec = 120, timeStr = "2m" },
    { id = 7618, name = "Health Potion", timeSec = 60, timeStr = "1m" },
    { id = 7588, name = "Strong Health Potion", timeSec = 90, timeStr = "1m 30s" },
    { id = 8473, name = "Great Health Potion", timeSec = 120, timeStr = "2m" }
}

PotionCraft.config = {}
for _, p in ipairs(PotionCraft.potions) do
    PotionCraft.config[p.id] = p
end

function PotionCraft.getOpenPayload()
    local list = {}
    for _, p in ipairs(PotionCraft.potions) do
        local cid = p.id
        local itemType = ItemType(p.id)
        if itemType and not itemType:isNull() then
            cid = itemType:getClientId()
        end
        table.insert(list, {
            id = p.id,
            clientId = cid,
            name = p.name,
            timeSec = p.timeSec,
            timeStr = p.timeStr
        })
    end
    return json.encode({ action = "open", potions = list })
end

function PotionCraft.start(cid, potionId, count)
    if not isPlayer(cid) then return end
    count = math.floor(count)
    if count <= 0 or count > 1000 then
        doPlayerSendCancel(cid, "Quantidade inválida para craft (1 - 1000).")
        return
    end

    local potion = PotionCraft.config[potionId]
    if not potion then
        doPlayerSendCancel(cid, "Poção inválida para craft.")
        return
    end

    if PotionCraft.active[cid] then
        doPlayerSendCancel(cid, "Você já está produzindo poções.")
        return
    end

    local playerPos = getThingPos(cid)
    local totalDurationSec = count * potion.timeSec

    PotionCraft.active[cid] = {
        potionId = potionId,
        totalCount = count,
        doneCount = 0,
        timePerUnit = potion.timeSec,
        startPos = { x = playerPos.x, y = playerPos.y, z = playerPos.z },
        startTime = os.time(),
        nextUnitTime = os.time() + potion.timeSec
    }

    -- Inicia a progressbar com a duracao total em milissegundos
    doCreatureSendProgressbar(cid, totalDurationSec * 1000, true)
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, string.format("Iniciado o craft de %d x %s. Mantenha-se parado durante o processo.", count, potion.name))

    addEvent(PotionCraft.tick, 1000, cid)
end

function PotionCraft.tick(cid)
    if not isPlayer(cid) then
        PotionCraft.active[cid] = nil
        return
    end

    local craft = PotionCraft.active[cid]
    if not craft then return end

    local curPos = getThingPos(cid)
    if curPos.x ~= craft.startPos.x or curPos.y ~= craft.startPos.y or curPos.z ~= craft.startPos.z then
        PotionCraft.cancel(cid, "O craft foi cancelado porque você se moveu!")
        return
    end

    local now = os.time()
    if now >= craft.nextUnitTime then
        craft.doneCount = craft.doneCount + 1
        craft.nextUnitTime = now + craft.timePerUnit

        if craft.doneCount >= craft.totalCount then
            PotionCraft.finish(cid)
            return
        end
    end

    addEvent(PotionCraft.tick, 1000, cid)
end

function PotionCraft.finish(cid)
    local craft = PotionCraft.active[cid]
    if not craft then return end

    local potion = PotionCraft.config[craft.potionId]
    local potionName = potion and potion.name or "Poção"

    doPlayerAddItemToRewardBox(cid, craft.potionId, craft.totalCount)
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string.format("Craft de %d x %s concluído! Os itens foram enviados para seu Reward Mailbox.", craft.totalCount, potionName))

    doCreatureSendProgressbar(cid, 0, true)
    PotionCraft.active[cid] = nil
end

function PotionCraft.cancel(cid, reason)
    local craft = PotionCraft.active[cid]
    if not craft then return end

    doCreatureSendProgressbar(cid, 0, true)

    local potion = PotionCraft.config[craft.potionId]
    local potionName = potion and potion.name or "Poção"

    if craft.doneCount > 0 then
        doPlayerAddItemToRewardBox(cid, craft.potionId, craft.doneCount)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, string.format("%s %d x %s produzidas foram enviadas para seu Reward Mailbox.", reason, craft.doneCount, potionName))
    else
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, reason)
    end

    PotionCraft.active[cid] = nil
end

function PotionCraft.onOpcode(cid, buffer)
    if type(buffer) ~= "string" then return end
    local parts = buffer:explode(">")
    local action = parts[1]

    if action == "craft" then
        local potionId = tonumber(parts[2])
        local count = tonumber(parts[3])
        if potionId and count then
            PotionCraft.start(cid, potionId, count)
        end
    end
end
