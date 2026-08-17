--[[
 * RogerioLoot - drop condicional da Foto (18877) da quest "As Fotos de Rogerio"
 * -----------------------------------------------------------------------------
 * A foto so cai no corpo da Mordecasca da terra quando o matador esta com a
 * quest ativa (storage 49200 = 1). Fora da quest, NAO droppa.
 *
 * POR QUE ASSIM: o evento de morte (onDeath) roda ANTES do loot normal cair
 * no corpo, entao aqui nos ADICIONAMOS a foto no corpo quando o jogador esta
 * na quest. Por isso o item NAO fica no <loot> do monstro no XML.
 *
 * Evento registrado em data/creaturescripts/creaturescripts.xml (type="death")
 * e anexado ao monstro via <script><event name="RogerioLoot"/></script>.
 *]]

local PHOTO_ITEM = 18877
local QUEST_STORAGE = 49200   -- 1 = quest em andamento (data/questSystem/quests.xml)
local DROP_ODDS = 300         -- 1 foto a cada ~300 Mordecascas mortas (media)

function onDeath(cid, corpse, deathList)
    if not isMonster(cid) then
        return true
    end
    if string.lower(getCreatureName(cid)) ~= "mordecasca da terra" then
        return true
    end

    -- procura o player que matou (ou o dono do summon)
    local killer = nil
    for i = 1, #deathList do
        local k = deathList[i]
        if type(k) == "number" then
            if isPlayer(k) then
                killer = k
                break
            elseif isCreature(k) then
                local master = getCreatureMaster(k)
                if master and master ~= 0 and isPlayer(master) then
                    killer = master
                    break
                end
            end
        end
    end

    -- so droppa se o matador estiver na quest (1 foto a cada ~DROP_ODDS kills)
    if killer and getPlayerStorageValue(killer, QUEST_STORAGE) >= 1 then
        if math.random(1, DROP_ODDS) == 1 then
            doAddContainerItem(corpse.uid, PHOTO_ITEM, 1)
        end
    end

    return true
end
