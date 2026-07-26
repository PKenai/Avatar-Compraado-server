STAMINA_TIME = 5 * 60 * 1000
STAMINA_ADD = 1

function event(cid)
    if isPlayer(cid) then
        doPlayerAddStamina(cid, STAMINA_ADD)
        eventCheck = addEvent(event, STAMINA_TIME, cid)
    end
end

function onStepIn(cid, item, position, fromPosition, pos)
    if isPlayer(cid) then
    eventCheck = addEvent(event, STAMINA_TIME, cid)
    end
    return true
end

function onStepOut(cid, item, position, fromPosition)
    if isPlayer(cid) then
        stopEvent(eventCheck)
    end
    return true
end