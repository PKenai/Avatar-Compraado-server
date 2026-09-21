local npcGen = newNpc("npcLootSeller")

npcGen:setHiMsg("Hello my dear friend, you want DRINK something?", "Hello my dear friend, you want DRINK something?")
npcGen:addSellableItens("drink")


npcGen:addOptionInNpc("job", {"I work with sale of various types of drinks.", "I work with sale of various types of drinks."})
npcGen:addOptionInNpc("drink", {"Sorry, but all my stock is finished, come back later.", "Sorry, but all my stock is finished, come back later."})
npcGen:addOptionInNpc("beber", {"Sorry, but all my stock is finished, come back later.", "Sorry, but all my stock is finished, come back later."})
npcGen:addOptionInNpc("help", {"I need a new stock of drink, you know someone who sells?", "I need a new stock of drink, you know someone who sells?"})

function onCreatureSay(cid, type, msg)
    local msg = msg:lower()
    npcGen:onSay(cid, type, msg, 
    function(stage)
        if stage == 1 then
            npcGen:loadSellableItens(msg)
        end
        return true
    end)
end

function onThink()
    npcGen:onThink(function(cid)
        if math.random(1, 100) == 1 then
            npcGen:say("Hicks!", "Hicks!")
        end
    end)
end

function onCreatureDisappear(cid, pos)
    npcGen:onDisappear(cid, pos)
end
