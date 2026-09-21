local npcGen = newNpc("NpcRecepconistFire")
local storageRegister = 8934

npcGen:setHiMsg("Hello %s, Welcome to trainer room of Air Academy, I can help you with REGISTERs.", "Hello %s, Welcome to trainer room of Air Academy, I can help you with REGISTERs.")
npcGen:addOptionInNpc("job", {"I'm the receptionist at this academy, my job is to be very polite to all customers.", "I'm the receptionist at this academy, my job is to be very polite to all customers."})
npcGen:addOptionInNpc("help", {"I have a loooot of work, but I don't need help, ty.", "I have a loooot of work, but I don't need help, ty."})
npcGen:needPremium(true)

function onCreatureSay(cid, type, msg)
    local msg = msg:lower()
    npcGen:onSay(cid, type, msg, 
    function(stage)
        if stage == 1 then
            if msgcontains(msg, "register") or msgcontains(msg, "registro") then
                if getPlayerStorageValue(cid, storageRegister) == -1 then
                    npcGen:say("Huum, you are a new here, to enter in the Academy, you need only a once payment, so you can enter in academy when you want, it's costs 5.000 gold coins, you want to join?", "Huum, you are a new here, to enter in the Academy, you need only a once payment, so you can enter in academy when you want, it's costs 5.000 gold coins, you want to join?")
                    npcGen:setStage(2)
                else
                    npcGen:say("Let's me see... You was already registered in academy, enter and enjoy!", "Let's me see... You was already registered in academy, enter and enjoy!")
                end
            end

        elseif stage == 2 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                if getPlayerStorageValue(cid, storageRegister) == -1 then
                    if doPlayerRemoveMoney(cid, 5000) then
                        npcGen:say("CONGRATULATIONS! Now you are a member of Air Academy, enjoy it.", "CONGRATULATIONS! Now you are a member of Air Academy, enjoy it.")
                        setPlayerStorageValue(cid, storageRegister, 1)
                    else
                        npcGen:say("Sorry sir, you don't have money for it, please come back when you have the money.", "Sorry sir, you don't have money for it, please come back when you have the money.")
                    end
                else
                    npcGen:say("Sorry sir but you was already registered in academy, enter and enjoy!", "Sorry sir but you was already registered in academy, enter and enjoy!")
                end
            else
                npcGen:say("Ok, I think...", "Ok, I think...") 
            end
            npcGen:setStage(1)
        end
        return true
    end)
end

function onThink()
    npcGen:onThink(false)
end

function onCreatureDisappear(cid, pos)
    npcGen:onDisappear(cid, pos)
end