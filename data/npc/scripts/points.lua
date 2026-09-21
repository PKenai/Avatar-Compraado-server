local npcGen = newNpc("npcPoints")

npcGen:addOptionInNpc("stats", {"You can change your points for MANA, HEALTH, BEND LEVEL or DODGE.", "You can change your points for MANA, HEALTH, BEND LEVEL or DODGE."})
npcGen:addOptionInNpc("help", {"I don't need your help, thanks.", "I don't need your help, thanks."})
npcGen:addOptionInNpc("job", {"I work with stats, I sell stats to you be more strong.", "I work with stats, I sell stats to you be more strong."})


npcGen:setFuncStart(function(cid)
    local elementPlayer, playerPos, lang = getPlayerElement(cid), getThingPos(cid), getLang(cid)

    if elementPlayer == nil then
        npcGen:say("Sorry "..getCreatureName(cid)..", I can't talk to you while you are an Avatar.", "Sorry "..getCreatureName(cid)..", I can't talk to you while you are an Avatar.", lang)
        return false
    end

    npcGen:say("Hello "..getCreatureName(cid).."! Do you want to change your points for STATS, want to change STONES for points or you want to see your BALANCE?", "Hello "..getCreatureName(cid).."! Do you want to change your points for STATS, want to change STONES for points or you want to see your BALANCE?", lang)
    return true
end)

function onCreatureSay(cid, type, msg)
    local msg = msg:lower()
    npcGen:onSay(cid, type, msg, 
    function(stage)
        local elementPlayer = getPlayerElement(cid)

        if stage == 1 then
            if msgcontains(msg, "balance") or msgcontains(msg, "saldo") then
                npcGen:say("Now you balance are "..getPlayerElementPoints(cid, elementPlayer).." point(s).", "Now you balance are "..getPlayerElementPoints(cid, elementPlayer).." point(s).", cid)
            
            elseif msgcontains(msg, "stones") then
                local number = npcGen:setStorage("numberStones", npcGen:getNumberMsg(msg))
                npcGen:say("You want to change "..number.." "..elementPlayer.." stone(s) for "..number.." point(s)?", "You want to change "..number.." "..elementPlayer.." stone(s) for "..number.." point(s)?")
                npcGen:setStage(2)

            elseif msgcontains(msg, "mana") then
                local number = npcGen:setStorage("numberMana", npcGen:getNumberMsg(msg))
                local cost = getPriceOffNumber(cid, "mana", number)
                npcGen:say("I add +"..5*number.." of your total mana (+"..number.." attribute(s) in mana) for "..cost.." point(s), are you interested?", "I add +"..5*number.." of your total mana (+"..number.." attribute(s) in mana) for "..cost.." point(s), are you interested?")
                npcGen:setStage(3)

            elseif msgcontains(msg, "health") then
                local number = npcGen:setStorage("numberHealth", npcGen:getNumberMsg(msg))
                local cost = getPriceOffNumber(cid, "health", number)
                npcGen:say("I add +"..20*number.." of your total health (+"..number.." attributes in health) for "..cost.." point(s), are you interested?", "I add +"..20*number.." of your total health (+"..number.." attributes in health) for "..cost.." point(s), are you interested?")
                npcGen:setStage(4)

            elseif msgcontains(msg, "bend") then
                local number = npcGen:setStorage("numberBend", npcGen:getNumberMsg(msg))
                local cost = getPriceOffNumber(cid, "bend", number)
                npcGen:say("I add +"..1*number.." to your bend level (+"..number.." attributes in bend level) for "..cost.." point(s), are you interested?", "I add +"..1*number.." to your bend level (+"..number.." attributes in bend level) for "..cost.." point(s), are you interested?")
                npcGen:setStage(5)

            elseif msgcontains(msg, "dodge") then
                local number = npcGen:setStorage("numberDodge", npcGen:getNumberMsg(msg, 15))
                local cost = getPriceOffNumber(cid, "dodge", number)

                if getPointsUsedInSkill(cid, "dodge")+number > 15 then
                    npcGen:say("You can't add +"..number.." point(s) in dodge, because the max allowed are 15%, you already have "..getPointsUsedInSkill(cid, "dodge").."%.", "You can't add +"..number.." point(s) in dodge, because the max allowed are 15%, you already have "..getPointsUsedInSkill(cid, "dodge").."%.")
                else
                    npcGen:say("I add +"..1*number.."% to your dodge ability (+"..number.." attributes in dodge ability) for "..cost.." point(s), are you interested?", "I add +"..1*number.."% to your dodge ability (+"..number.." attributes in dodge ability) for "..cost.." point(s), are you interested?")
                    npcGen:setStage(6)
                end 
            end

        elseif stage == 2 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                local number = npcGen:numberValid(npcGen:getStorage("numberStones"))
                if doPlayerRemoveItem(cid, getStoneItemId(elementPlayer), number) then
                    doPlayerSetElementPoints(cid, elementPlayer, getPlayerElementPoints(cid, elementPlayer)+number)
                    addPointsInSkill(cid, "stones", 1*number)
                    npcGen:say("Ok, thanks for change with me, now you have "..getPlayerElementPoints(cid, elementPlayer).." "..elementPlayer.." point(s).", "Ok, thanks for change with me, now you have "..getPlayerElementPoints(cid, elementPlayer).." "..elementPlayer.." point(s).")
                else
                    npcGen:say("You don't have "..number.." "..elementPlayer.." stone(s) to change with me.", "You don't have "..number.." "..elementPlayer.." stone(s) to change with me.")
                end
            else
                npcGen:say("Ok, I think...", "Ok, I think...")
            end
            npcGen:setStage(1)

        elseif stage == 3 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                local number = npcGen:numberValid(npcGen:getStorage("numberMana"))
                local price = getPriceOffNumber(cid, "mana", number)

                if getPlayerElementPoints(cid, elementPlayer) >= price then
                    npcGen:say("Excellent choice! Here is +"..5*number.." added to your total mana.", "Excellent choice! Here is +"..5*number.." added to your total mana.")
                    addPointsInSkill(cid, "mana", 5*number)
                    setCreatureMaxMana(cid, getCreatureMaxMana(cid)+(5*number))
                    doCreatureAddMana(cid, 5*number)
                    doPlayerSetElementPoints(cid, elementPlayer, getPlayerElementPoints(cid, elementPlayer)-price)
                else
                    npcGen:say("You don't have "..price.." point(s) for buy this mana.", "You don't have "..price.." point(s) for buy this mana.")
                end
            else
                npcGen:say("Ok, I think...", "Ok, I think...")
            end
            npcGen:setStage(1)

        elseif stage == 4 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                local number = npcGen:numberValid(npcGen:getStorage("numberHealth"))
                local price = getPriceOffNumber(cid, "health", number)
                if getPlayerElementPoints(cid, elementPlayer) >= price then
                    npcGen:say("Excellent choice! Here is +"..20*number.." added to your total health.", "Excellent choice! Here is +"..20*number.." added to your total health.")
                    addPointsInSkill(cid, "health", 20*number)
                    setCreatureMaxHealth(cid, getCreatureMaxHealth(cid, true)+(20*number))
                    doCreatureAddHealth(cid, 20*number)
                    doPlayerSetElementPoints(cid, elementPlayer, getPlayerElementPoints(cid, elementPlayer)-price)
                else
                    npcGen:say("You don't have "..price.." point(s) for buy this health.", "You don't have "..price.." point(s) for buy this health.")
                end
            else
                npcGen:say("Ok, I think...", "Ok, I think...")  
            end
            npcGen:setStage(1)

        elseif stage == 5 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                local number = npcGen:numberValid(npcGen:getStorage("numberBend"))
                local price = getPriceOffNumber(cid, "bend", number)
                if getPlayerElementPoints(cid, elementPlayer) >= price then
                    npcGen:say("Excellent choice! Here is +"..1*number.." added to your bend level.", "Excellent choice! Here is +"..1*number.." added to your bend level.")
                    addPointsInSkill(cid, "bend", 1*number)
                    doPlayerAddMagicLevel(cid, number)
                    doPlayerSetElementPoints(cid, elementPlayer, getPlayerElementPoints(cid, elementPlayer)-price)
                else
                    npcGen:say("You don't have "..price.." point(s) for buy this bend level.", "You don't have "..price.." point(s) for buy this bend level.")
                end
            else
                npcGen:say("Ok, I think...", "Ok, I think...")  
            end
            npcGen:setStage(1)

        elseif stage == 6 then
            if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                local number = npcGen:numberValid(npcGen:getStorage("numberDodge"))
                local price = getPriceOffNumber(cid, "dodge", number)

                if getPointsUsedInSkill(cid, "dodge")+number > 15 then
                    npcGen:say("You can't add +"..number.." point(s) in dodge, because the max allowed are 15%, you already have "..getPointsUsedInSkill(cid, "dodge").."%.", "You can't add +"..number.." point(s) in dodge, because the max allowed are 15%, you already have "..getPointsUsedInSkill(cid, "dodge").."%.")
                else
                    if getPlayerElementPoints(cid, elementPlayer) >= price then
                        npcGen:say("Excellent choice! Here is +"..1*number.." added to your dodge ability.", "Excellent choice! Here is +"..1*number.." added to your dodge ability.")
                        addPointsInSkill(cid, "dodge", 1*number)
                        doPlayerSetElementPoints(cid, elementPlayer, getPlayerElementPoints(cid, elementPlayer)-price)
                    else
                        npcGen:say("You don't have "..price.." point(s) for buy this dodge.", "You don't have "..price.." point(s) for buy this dodge.")
                    end
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
    npcGen:onThink()
end

function onCreatureDisappear(cid, pos)
    npcGen:onDisappear(cid, pos)
end