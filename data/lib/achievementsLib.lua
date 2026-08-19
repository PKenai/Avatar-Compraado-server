--[[
 * Conquistas + Titulos - Lib
 * ------------------------------------------------------------------
 * Sistema de conquistas por player (sem guild) com titulo equipavel.
 * Exibido no client pelo modulo game_achievements (extended opcode 172, JSON).
 *
 * COMO FUNCIONA:
 *  - Cada conquista tem um tipo e um target:
 *      tipo "level"    -> level do player
 *      tipo "kills"    -> total de criaturas derrotadas
 *      tipo "creature" -> kills de UMA criatura especifica (campo `creature`)
 *  - Ao desbloquear, o player pode equipar o titulo (1 por vez).
 *  - O titulo equipado aparece acima do nome do player no client
 *    (creature:setTitle), visivel para TODOS os players.
 *
 * TITULO VISIVEL PARA OUTROS PLAYERS:
 *  - O client detecta quando um player aparece na tela (onAppear) e
 *    envia {action="requestTitle", id=<creatureId>}. O servidor responde
 *    com {action="title", id=<creatureId>, title="..."} via opcode 172.
 *  - Ao equipar/remover o titulo, o servidor faz broadcast para todos
 *    os players na tela (getSpectators).
 *  - No login, o servidor envia os titulos dos players vizinhos como
 *    fallback (caso o onAppear do map description não dispare).
 *
 * STORAGES (por player, string keys - persistem no banco):
 *  - achTotalKills       -> total de criaturas derrotadas
 *  - achCreatureKill_<id> -> kills da criatura da conquista <id>
 *  - achUnlocked_<id>    -> 1 quando a conquista foi desbloqueada
 *  - achEquipped         -> id da conquista cujo título está equipado (-1 = nenhum)
 *
 * OBS: os textos aceitam acentos normalmente (UTF-8 no client), desde que
 * o arquivo esteja salvo em UTF-8.
 *]]

ACHIEVEMENTS_OPCODE = 172

Achievements = Achievements or {}
Achievements.list = Achievements.list or {}

Achievements.storageTotalKills = "achTotalKills"
Achievements.storageEquipped = "achEquipped"

local function storageUnlocked(id)
    return "achUnlocked_" .. id
end

local function storageCreatureKill(id)
    return "achCreatureKill_" .. id
end

-- Definições: id, tipo (level/kills/creature), target, nome, título, descrição
-- Para tipo "creature", o campo `creature` e o nome da criatura (minusculo).
local defs = {
    { id = 1,  type = "level", target = 10,    name = "Atingiu level 10",             title = "Iniciante em ação",     description = "Alcance o level 10." },
    { id = 2,  type = "level", target = 25,    name = "Atingiu level 25",             title = "Aventureiro promissor",  description = "Alcance o level 25." },
    { id = 3,  type = "level", target = 50,    name = "Atingiu level 50",             title = "Herói em ascensão",      description = "Alcance o level 50." },
    { id = 4,  type = "level", target = 100,   name = "Atingiu level 100",            title = "Lenda viva",             description = "Alcance o level 100." },
    { id = 5,  type = "level", target = 200,   name = "Atingiu level 200",            title = "Semideus",               description = "Alcance o level 200." },
    { id = 6,  type = "kills", target = 10,    name = "Derrotou 10 criaturas",        title = "Caçador iniciante",      description = "Derrote 10 criaturas." },
    { id = 7,  type = "kills", target = 100,   name = "Derrotou 100 criaturas",       title = "Caçador experiente",     description = "Derrote 100 criaturas." },
    { id = 8,  type = "kills", target = 1000,  name = "Derrotou 1.000 criaturas",     title = "Exterminador",           description = "Derrote 1.000 criaturas." },
    { id = 9,  type = "kills", target = 5000,  name = "Derrotou 5.000 criaturas",     title = "Lenda do massacre",      description = "Derrote 5.000 criaturas." },
    { id = 10, type = "kills", target = 10000, name = "Derrotou 10.000 criaturas",    title = "Deus da guerra",         description = "Derrote 10.000 criaturas." },
    -- Matar criatura especifica (zoeiras)
    { id = 11, type = "creature", creature = "pica-pau da terra", target = 500, name = "Derrotou 500 pica-paus da terra", title = "Caçador de paus",       description = "Derrote 500 pica-paus da terra." },
    { id = 13, type = "creature", creature = "cockroach",         target = 300, name = "Derrotou 300 baratas",            title = "Inseticida humano",      description = "Derrote 300 baratas." },
    { id = 14, type = "creature", creature = "chicken",           target = 200, name = "Derrotou 200 galinhas",           title = "Nuggets de frango",      description = "Derrote 200 galinhas." },
    { id = 17, type = "creature", creature = "tarantula de pedra", target = 500, name = "Derrotou 500 tarântulas de pedra", title = "Amigo do Homem-Aranha", description = "Derrote 500 tarântulas de pedra." },
    { id = 18, type = "creature", creature = "defensor da montanha", target = 1, name = "Derrotou o Defensor da montanha", title = "Alpinista", description = "Derrote o Defensor da montanha." },
    { id = 19, type = "creature", creature = "traidor", target = 2000, name = "Derrotou 2.000 Traidores", title = "Fiel", description = "Derrote 2.000 Traidores." },
    -- Quest: desbloqueada manualmente pelo NPC (a criatura e o nome do NPC da
    -- quest, nunca e matavel, entao o onKill nunca dispara sozinho).
    { id = 20, type = "creature", creature = "coelho da margarida", target = 1, name = "Resgatou o Coelho da Margarida", title = "Amigo dos animais", description = "Complete a quest O Coelho da Margarida." },
    { id = 21, type = "creature", creature = "urso feroz", target = 150, name = "Derrotou 150 ursos ferozes", title = "Abraça urso", description = "Derrote 150 ursos ferozes." },
    -- Quest: desbloqueada manualmente pelo NPC (criatura sentinela, nunca matavel)
    { id = 22, type = "creature", creature = "rafinha", target = 1, name = "Pescou o anel do Rafinha", title = "Pescador nato", description = "Complete a quest O Anel do Rafinha." },
    -- Quest: desbloqueada manualmente pelo NPC (repolhos sao itens, nao criaturas)
    { id = 23, type = "creature", creature = "senhor dos repolhos", target = 1, name = "Recuperou os 50 repolhos", title = "Repolhudo", description = "Complete a quest Os Repolhos Roubados e recupere todos os 50 repolhos." },
}

for _, def in ipairs(defs) do
    Achievements.list[def.id] = def
end

function Achievements.getProgress(cid, id)
    local def = Achievements.list[id]
    if not def then
        return 0
    end

    if def.type == "level" then
        return getPlayerLevel(cid)
    end

    local storageKey
    if def.type == "creature" then
        storageKey = storageCreatureKill(id)
    else
        storageKey = Achievements.storageTotalKills
    end

    local value = getPlayerStorageValue(cid, storageKey)
    if type(value) ~= "number" or value < 0 then
        return 0
    end
    return value
end

function Achievements.isUnlocked(cid, id)
    return getPlayerStorageValue(cid, storageUnlocked(id)) == 1
end

function Achievements.getEquippedId(cid)
    return getPlayerStorageValue(cid, Achievements.storageEquipped)
end

-- Retorna o texto do titulo equipado (ou nil se nao tiver nenhum)
function Achievements.getEquippedTitle(cid)
    if not isPlayer(cid) then
        return nil
    end

    local equippedId = Achievements.getEquippedId(cid)
    if type(equippedId) ~= "number" or equippedId < 1 then
        return nil
    end

    local def = Achievements.list[equippedId]
    if not def then
        return nil
    end

    return def.title
end

-- Checa e desbloqueia a conquista se o progresso atingiu o target
function Achievements.check(cid, id)
    local def = Achievements.list[id]
    if not def then
        return
    end

    if Achievements.isUnlocked(cid, id) then
        return
    end

    if Achievements.getProgress(cid, id) < def.target then
        return
    end

    setPlayerStorageValue(cid, storageUnlocked(id), 1)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Conquista desbloqueada: " .. def.name .. "! Titulo: " .. def.title .. " (abra Conquistas na topbar para equipar).")
    Achievements.sendData(cid)
end

function Achievements.checkType(cid, achType)
    for id, def in pairs(Achievements.list) do
        if def.type == achType then
            Achievements.check(cid, id)
        end
    end
end

-- Chamado em cada kill de monstro (target = criatura derrotada)
function Achievements.onKill(cid, target)
    if not isPlayer(cid) then
        return
    end

    -- total de kills
    local kills = getPlayerStorageValue(cid, Achievements.storageTotalKills)
    if type(kills) ~= "number" or kills < 0 then
        kills = 0
    end
    setPlayerStorageValue(cid, Achievements.storageTotalKills, kills + 1)
    Achievements.checkType(cid, "kills")

    -- kills de criatura especifica
    if not isCreature(target) then
        return
    end

    local creatureName = string.lower(getCreatureName(target))
    for id, def in pairs(Achievements.list) do
        if def.type == "creature" and def.creature == creatureName then
            local count = getPlayerStorageValue(cid, storageCreatureKill(id))
            if type(count) ~= "number" or count < 0 then
                count = 0
            end
            setPlayerStorageValue(cid, storageCreatureKill(id), count + 1)
            Achievements.check(cid, id)
        end
    end
end

-- Chamado no onAdvance (level up)
function Achievements.onAdvance(cid)
    if not isPlayer(cid) then
        return
    end

    Achievements.checkType(cid, "level")
end

-- Chamado no login (players que ja estao acima do target ganham retroativamente)
-- Obs: conquistas de criatura especifica nao sao retroativas (nao ha historico
-- de kills por criatura), entao so level e kills sao checados aqui.
function Achievements.onLogin(cid)
    if not isPlayer(cid) then
        return
    end

    Achievements.checkType(cid, "level")
    Achievements.checkType(cid, "kills")
    Achievements.sendData(cid)
    Achievements.sendNearbyTitles(cid)
end

function Achievements.equip(cid, id)
    local def = Achievements.list[id]
    if not def then
        return
    end

    if not Achievements.isUnlocked(cid, id) then
        doPlayerSendCancel(cid, "Você ainda não desbloqueou essa conquista.")
        return
    end

    setPlayerStorageValue(cid, Achievements.storageEquipped, id)
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Titulo equipado: " .. def.title)
    Achievements.sendData(cid)
    Achievements.broadcastTitle(cid)
end

function Achievements.unequip(cid)
    setPlayerStorageValue(cid, Achievements.storageEquipped, -1)
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Titulo removido.")
    Achievements.sendData(cid)
    Achievements.broadcastTitle(cid)
end

function Achievements.sendData(cid)
    if not isPlayer(cid) then
        return
    end

    local ids = {}
    for id in pairs(Achievements.list) do
        table.insert(ids, id)
    end
    table.sort(ids)

    local list = {}
    for _, id in ipairs(ids) do
        local def = Achievements.list[id]
        table.insert(list, {
            id = id,
            name = def.name,
            title = def.title,
            description = def.description,
            progress = Achievements.getProgress(cid, id),
            target = def.target,
            unlocked = Achievements.isUnlocked(cid, id)
        })
    end

    local payload = {
        action = "achievements",
        equipped = Achievements.getEquippedId(cid),
        list = list
    }

    doSendPlayerExtendedOpcode(cid, ACHIEVEMENTS_OPCODE, json.encode(payload))
end

-- Procura um player online pelo id de criatura (cid)
function Achievements.getPlayerById(id)
    for _, pid in ipairs(getPlayersOnline()) do
        if pid == id then
            return pid
        end
    end
    return nil
end

-- Envia o titulo do targetCid para o viewerCid (via extended opcode 172)
function Achievements.sendTitleTo(viewerCid, targetCid)
    if not isPlayer(viewerCid) or not isPlayer(targetCid) then
        return
    end

    local payload = {
        action = "title",
        id = targetCid,
        title = Achievements.getEquippedTitle(targetCid) or ""
    }

    doSendPlayerExtendedOpcode(viewerCid, ACHIEVEMENTS_OPCODE, json.encode(payload))
end

-- Envia o titulo do cid para todos os players na tela dele (apos equipar/remover)
function Achievements.broadcastTitle(cid)
    if not isPlayer(cid) then
        return
    end

    local spectators = getSpectators(getCreaturePosition(cid), 15, 15)
    for _, viewer in ipairs(spectators) do
        if viewer ~= cid and isPlayer(viewer) then
            Achievements.sendTitleTo(viewer, cid)
        end
    end
end

-- Login: envia os titulos de todos os players vizinhos como fallback
-- (o client normalmente pede via onAppear; isso cobre o map description)
function Achievements.sendNearbyTitles(cid)
    if not isPlayer(cid) then
        return
    end

    local spectators = getSpectators(getCreaturePosition(cid), 15, 15)
    for _, target in ipairs(spectators) do
        if target ~= cid and isPlayer(target) then
            Achievements.sendTitleTo(cid, target)
        end
    end
end
