--[[
 * DefensorMontanha - comportamentos ao morrer do "Defensor da montanha":
 *   * marca o matador com storage "aianoKill" (quest do NPC Aiano)
 *   * o item 1290 na posicao {x=640, y=441, z=5} some por 5 minutos
 *   * (o Set da Montanha 13401-13405 cai pelo <loot> do monstro, 1% cada)
 *
 * O titulo "Alpinista" e desbloqueado pelo sistema de conquistas
 * (achievementsLib.lua, conquista id 18 - matar o Defensor da montanha 1x).
 *
 * Registrado em data/creaturescripts/creaturescripts.xml (type="death") e
 * anexado ao monstro via <script><event name="DefensorMontanha"/></script>.
]]

local ITEM_BARREIRA = 1290
local BARREIRA_POS = {x = 640, y = 441, z = 5}
local BARREIRA_TIME = 5 * 60 * 1000

local timerAtivo = false

local function respawnBarreira()
    doCreateItem(ITEM_BARREIRA, 1, {x = BARREIRA_POS.x, y = BARREIRA_POS.y, z = BARREIRA_POS.z})
    timerAtivo = false
end

function onDeath(cid, corpse, deathList)
    if not isMonster(cid) then
        return true
    end
    if string.lower(getCreatureName(cid)) ~= "defensor da montanha" then
        return true
    end

    -- 1) marca o matador para a quest do Aiano (storage "aianoKill")
    for i = 1, #deathList do
        local k = deathList[i]
        if type(k) == "number" then
            local player = nil
            if isPlayer(k) then
                player = k
            elseif isCreature(k) then
                local master = getCreatureMaster(k)
                if master and master ~= 0 and isPlayer(master) then
                    player = master
                end
            end
            if player then
                setPlayerStorageValue(player, "aianoKill", 1)
                -- progresso do quest log (quest id 22, missao 1): 1/1 ao matar
                if getPlayerStorageValue(player, "aianoQuest") == 1 then
                    setPlayerStorageValue(player, 49221, 1)
                end
                break
            end
        end
    end

    -- 2) barreira some por 5 minutos (nao duplica se ja estiver fora)
    if not timerAtivo then
        if removeTileItemById(BARREIRA_POS, ITEM_BARREIRA) then
            timerAtivo = true
            addEvent(respawnBarreira, BARREIRA_TIME)
        end
    end

    return true
end
