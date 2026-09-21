local npcGen = newNpc("simpleBoatNpc")

npcGen:setHiMsg("Hello %s. I can take you around the continent, do you want see my ROUTES?", "Hello %s. I can take you around the continent, do you want see my ROUTES?")
npcGen:needPremium(true)
npcGen:setRoutes("simpleBoat")

npcGen:addOptionInNpc("help", {"I don't need your help, thank you.", "I don't need your help, thank you."})

function onCreatureSay(cid, type, msg)
    local msg = msg:lower()
    npcGen:onSay(cid, type, msg, 
    function(stage)
        if stage == 1 then
            if msgcontains(msg, "routes") or msgcontains(msg, "offer") then
                if npcGen:isPlayerStageFree() then
                    npcGen:say("I can take you to: "..npcGen:getRoutesString()..".", "I can take you to: "..npcGen:getRoutesString()..".")
                    return true
                end
            end
            npcGen:loadShipRoutes(msg)
        end
        return true
    end)
end

function onThink()
    npcGen:onThink()
end

function onCreatureDisappear(cid, pos)
    npcGen:onDisappear(cid, pos)
end