local npcGen = newNpc("zukoBoatNpc")

--npcGen:setHiMsg("Hello %s. My service is expensive, but they are unbelievable routes to amazing places, you want see the ROUTES?", "Hello %s. My service is expensive, but they are unbelievable routes to amazing places, you want see the ROUTES?")
npcGen:needPremium(true)
npcGen:setRoutes("zukoBoat")

npcGen:addOptionInNpc("help", {"I don't need your help, thank you.", "I don't need your help, thank you."})


npcGen:setFuncStart(function(cid)
    local name = getCreatureName(cid)
        npcGen:say("Hello "..name..". My service is expensive, but they are unbelievable routes to amazing places, you want see the ROUTES?", "Hello "..name..". My service is expensive, but they are unbelievable routes to amazing places, you want see the ROUTES?", getLang(cid))
        return true
    end)

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