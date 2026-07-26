local percentShare = 0.1
local maxDistance = 20

function onGainExp(cid, experience)
    local party = getPlayerParty(cid)
    local currentPos = getThingPos(cid)
    local toDoExp = {}


    if party then
        local members = getPartyMembers(cid)

        for _, pid in pairs(members) do
            if pid ~= cid then
                if getDistanceBetween(currentPos, getThingPos(pid)) <= maxDistance then
                    table.insert(toDoExp, pid)
                end
            end
        end
    end

    if #toDoExp > 0 then
        for x = 1, #toDoExp do
            local currentExp = experience*percentShare/#toDoExp
			if #toDoExp == 3 then 
				currentExp = currentExp*4
			elseif #toDoExp >= 4 then 
				currentExp = currentExp*6
			end 

          --  if isPremium(toDoExp[x]) then
           --     currentExp = currentExp+(currentExp*0.1)
            --end

            doPlayerAddExp(toDoExp[x], currentExp)
            doSendAnimatedText(getThingPos(toDoExp[x]), math.ceil(currentExp), 215)
        end
    end

  return true
end