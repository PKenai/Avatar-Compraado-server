--[[
 * Cada dia tem um valor úncio, quando o servidor cai, o dia reseta.
]]--

local dayStorage, yearStorage = "dayId1", "yearId1"

function getDayID()
    local dayId = getStorage("dayId1")
    local yearId = getStorage("yearId1")

    return "dy"..dayId..yearId
end

function setNewDay()
    local dayId = getStorage(dayStorage)
    local yearId = getStorage(yearStorage)


    if dayId >= 365000 or dayId < 1 then
        dayId = 1
        yearId = yearId+1
    else
        dayId = dayId+1
    end

    doSetStorage(dayStorage, dayId)
    doSetStorage(yearStorage, yearId)
end