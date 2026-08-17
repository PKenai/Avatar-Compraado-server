--[[
 * TraidorDeath - conta mortes de Traidores para a quest do NPC Felipinho
 * (massacre da familia do homem que roubou o dinheiro do pirulito).
 *
 * So conta quando o matador esta NA quest (storage "felipinhoQuest" = 1).
 * Ao completar o massacre, avisa o jogador para voltar ao Felipinho.
 *
 * Registrado em data/creaturescripts/creaturescripts.xml (type="death",
 * name="TraidorDeath") e anexado ao monstro via
 * <script><event name="TraidorDeath"/></script>.
]]

local MAX_KILLS = 800
local QUEST_STORAGE = "felipinhoQuest"
local KILLS_STORAGE = "felipinhoKills"

function onDeath(cid, corpse, deathList)
    if not isMonster(cid) then
        return true
    end
    if string.lower(getCreatureName(cid)) ~= "traidor" then
        return true
    end

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
                if getPlayerStorageValue(player, QUEST_STORAGE) == 1 then
                    local kills = getPlayerStorageValue(player, KILLS_STORAGE)
                    if kills < MAX_KILLS then
                        kills = kills + 1
                        setPlayerStorageValue(player, KILLS_STORAGE, kills)
                        if kills >= MAX_KILLS then
                            doPlayerSendTextMessage(player, MESSAGE_EVENT_ADVANCE,
                                "Massacre completo! Volte ao Felipinho e devolva os 100k.")
                        end
                    end
                end
                break
            end
        end
    end

    return true
end
