dofile(getDataDir().."actions/scripts/quests/resetquest/const.lua")

local canEnter = true
local playersIn = {} --players q estão dentro
local firstMonstersSummoned = false

local function canEnterInResetQuest(cid)
    if getPlayerStorageValue(cid, "canStartResetQuest") == 1 and getPlayerStorageValue(cid, "hasCompletedResetQuest") == -1 then
        return true
    end

    return false
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if not canEnter then
        return true
    end

    if playersIn[cid] then
        canEnter = false
        setCreatureNoMoveTime(cid, 500)
        doTransformItem(item.uid, 1226)
        doTeleportThing(cid, toPosition, true)

        addEvent(function(cid, toPosition)
            doTeleportThing(cid, {x=toPosition.x,y=toPosition.y-1,z=toPosition.z})
            canEnter = true
        end, 500, cid, toPosition)

        playersIn[cid] = nil
        setPlayerStorageValue(cid, "hasActiveInQuest", -1)
        return true
    end


    if canEnterInResetQuest(cid) then
        local isOpen = getStorage("resetQuestClosed") == -1

        if not isOpen then
            doPlayerSendCancel(cid, getLangString(cid, "You can't enter here now, wait the global save.", "Você não pode entrar aqui agora, espere o global save."))
            return true
        end

        if not firstMonstersSummoned then
            for x = 1, #firstMonsters do
                local monster = doCreateMonster(firstMonsters[x].name, firstMonsters[x], nil, true)
                doCreatureSetDropLoot(monster, false)
            end

            firstMonstersSummoned = true
        end


        registerPlayerInQuest(
            {
                player = cid, 
                posExit = getThingPos(cid), 
                globalStorage = "resetQuest",
                cantUseSpells = cantUseSpells,
            }
        )

        playersIn[cid] = true
        canEnter = false
        setCreatureNoMoveTime(cid, 500)
        doTransformItem(item.uid, 1226)
        doTeleportThing(cid, toPosition, true)
        sendBlueMessage(cid, getLangString(cid, "Attention: If you do logout inside, you will be teleported to exit.", "Atenção: Caso você deslogue dentro da quest, você será teleportado para fora."))

        addEvent(valid(function(cid, toPosition)
            clearAllItems(cid)
            doTeleportThing(cid, {x=toPosition.x,y=toPosition.y+1,z=toPosition.z})
            canEnter = true
        end), 500, cid, toPosition)

    else
        doPlayerSendCancel(cid, getLangString(cid, "You can't enter here, please speak with NPC Isolde.", "Você não pode entrar aqui, porfavor fale com o NPC Isolde."))
    end

    return true
end