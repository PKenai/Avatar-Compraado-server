local spellName = "air trap"
local cf = {segundos = spellsInfo[spellName].segundos}

local trapId = 13025
local time = cf.segundos

function onCastSpell(cid, var)
    if not isPlayer(cid) then
        return false
    end  

    if getSpellCancels(cid, "air") == true then
        return false
    end

    if getPlayerExaust(cid, "air", "trap") == false then
        return false
    end

    if getPlayerHasStun(cid) then
		if getDobrasLevel(cid) >= 17 then
			doPlayerAddExaust(cid, "air", "trap", airExausted.trap-2)
		else
			doPlayerAddExaust(cid, "air", "trap", airExausted.trap)  
		end
        return true
    end

    local posTrap = getCreatureLookPosition(cid)

    if getPlayerCanWalk({player = cid, position = posTrap, checkPZ = true, checkHouse = true, checkWater = true}) then
		if getDobrasLevel(cid) >= 17 then
			doPlayerAddExaust(cid, "air", "trap", airExausted.trap-2)
		else
			doPlayerAddExaust(cid, "air", "trap", airExausted.trap) 
		end
        -- Estagios: mini (<50) arma so' o tile da frente, padrao mantem como
        -- sempre foi e elite (100+) fecha a cruz inteira em volta do alvo.
        -- A armadilha do elite tambem dura mais.
        local positions = {posTrap}
        if isSpellElite(cid) then
            positions = {posTrap,
                {x=posTrap.x+1, y=posTrap.y, z=posTrap.z},
                {x=posTrap.x-1, y=posTrap.y, z=posTrap.z},
                {x=posTrap.x, y=posTrap.y+1, z=posTrap.z},
                {x=posTrap.x, y=posTrap.y-1, z=posTrap.z}}
        end

        local trapTime = spellStageSeconds(cid, time)
        for _, pos in ipairs(positions) do
            if getPlayerCanWalk({player = cid, position = pos, checkPZ = true, checkHouse = true, checkWater = true}) then
                local trap = doCreateItem(trapId, pos)
                if trap then
                    addEvent(removeTileItemById, trapTime*1000, getThingPos(trap), trapId)
                    doSetItemActionId(trap, cid)
                end
            end
        end
        return true
    else
        doPlayerSendCancelEf(cid, "It isn't possible use this fold here.")
        return false
    end  
    return true
end
