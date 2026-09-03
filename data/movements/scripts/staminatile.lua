STAMINA_TIME = 5 * 60 * 1000
STAMINA_ADD = 1

staminaTileEvents = staminaTileEvents or {}

local function staminaTick(cid)
    if isPlayer(cid) then
        doPlayerAddStamina(cid, STAMINA_ADD)
        staminaTileEvents[cid] = addEvent(staminaTick, STAMINA_TIME, cid)
    else
        staminaTileEvents[cid] = nil
    end
end

function onStepIn(cid, item, position, fromPosition, pos)
    if isPlayer(cid) then
        if staminaTileEvents[cid] then
            stopEvent(staminaTileEvents[cid])
        end
        staminaTileEvents[cid] = addEvent(staminaTick, STAMINA_TIME, cid)
    end
    return true
end

function onStepOut(cid, item, position, fromPosition)
    if isPlayer(cid) then
        if staminaTileEvents[cid] then
            stopEvent(staminaTileEvents[cid])
            staminaTileEvents[cid] = nil
        end
    end
    return true
end