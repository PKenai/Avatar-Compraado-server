dofile(getDataDir().."actions/scripts/quests/poi/const.lua")

local monster = {
    pos = {x=685,y=487,z=10},
    monsterName = "Supreme Abadeer"
}

local used = false

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if not used then
        used = true

        doCreateMonster(monster.monsterName, monster.pos, nil, true)
        doSendMagicEffect(monster.pos, 10)
        doTransformLever(item)

        return true
    end

    return false
end