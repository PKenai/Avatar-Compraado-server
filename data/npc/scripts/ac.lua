local npcGen = newNpc("Gaige")
 
npcGen:setHiMsg("Hello %s, I can give you the archangel blessing.", "Hello %s, I can give you the archangel blessing.")
npcGen:needPremium(false)
-- local function finishArchangel(cid)
--  return isCreature(cid) and setPlayerStorageValue(cid, "canAttackable", -1) and  doPlayerSetSpecialDescription(cid, text)
--end 
function onCreatureSay(cid, type, msg)
    local msg = msg:lower()    
    npcGen:onSay(cid, type, msg,
    function(stage)
		if getCreatureSkullType(cid) == 4 then  
			npcGen:say("I don't talk with killers.", "I don't talk with killers.")
			return false 
		end 
		if not isInPz(cid) and (isPlayerPzLocked(cid) or getCreatureCondition(cid, CONDITION_INFIGHT)) then
			npcGen:say("I can't talk to you right now.", "I can't talk to you right now.") 
			return false
		end
        if stage == 1 then
			if getPlayerStorageValue(cid, "extraArchangel") ~= 1 then 
				setPlayerStorageValue(cid, "extraArchangel", 1)
				setPlayerStorageValue(cid, "Archangel_Start", os.time()-1)
			end 
        --    if msgcontains(msg, "trade") or msgcontains(msg, "exchange") or msgcontains(msg, "trocar") or msgcontains(msg, "troco") then
        --                        npcGen:say("You want to exchange their event tokens for elemental coins or archangel blessing?", "You want to exchange their event tokens for elemental coins or archangel blessing?")
        --                        npcGen:setStage(2)          
        --    end
 
       -- elseif stage == 2 then
        --                if msgcontains(msg, "coins") or msgcontains(msg, "elemental") or msgcontains(msg, "elemental coins") then
         --                       npcGen:setStage(3)
          --                      npcGen:say("Each elemental coin costs 10 event tokens. How much elemental coins do you want to buy?", "Each elemental coin costs 10 event tokens. How much elemental coins do you want to buy?")
                                
                        if msgcontains(msg, "blessing") or msgcontains(msg, "archangel") or msgcontains(msg, "yes") then
                                npcGen:say("Would you like to get the blessing of the archangel (non-pvp) for 4 hours? (You can only get once between 20 hours).", "Would you like to get the blessing of the archangel (non-pvp) for 4 hours? (You can only get once between 20 hours).")
                                npcGen:setStage(4)
                        end
                                
      --[[          elseif stage == 3 then
            if tonumber(msg) and tonumber(msg) >= 1 then              
                                npcGen:say("Do you want trade "..(tonumber(msg)*10).." tokens for "..(tonumber(msg)).." elemental coin?", "Do you want trade "..(tonumber(msg)*10).." tokens for "..(tonumber(msg)).." elemental coin?")
                                npcGen:setStage(10 + tonumber(msg))                            
                        else
                                npcGen:say("It's not a valid number.", "It's not a valid number.")
                        end    
                       ]]
                elseif stage == 4 then
                        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
                                if getPlayerStorageValue(cid, "canAttackable") == 1 then
                                        npcGen:say("You already have this blessing.", "You already have this blessing.")
                                elseif exhaustion.check(cid, "Archangel_Start") then
                                        local segundos = exhaustion.get(cid, "Archangel_Start")
                                        local minutos = segundos/60 
                                        local horas = minutos/60
                                        minutos = math.ceil(minutos)
                                        horas = math.ceil(horas)
                                        local strEN = "You've got your blessing recently, come back in"
                                        if horas > 0 then 
                                            strEN = strEN .. " " .. horas .. " hour(s)."
                                        elseif minutos > 0 then 
                                            strEN = strEN .. " " .. minutos .. " minute(s)."
                                        else
                                            strEN = strEN .. " " .. segundos .. " second(s)."
                                        end 
                                        npcGen:say(strEN, strEN)
                             --   elseif doPlayerRemoveItem(cid, 6527, 2) then
								else
                                        setPlayerStorageValue(cid, "canAttackable", 1)
										doCreatureSetGuildEmblem(cid, 1)
                                        exhaustion.set(cid, "Archangel_Start", 60 * 60 * 20)
                                        exhaustion.set(cid, "Archangel", 60 * 60 * 4)
                                        doPlayerSave(cid)
                                        npcGen:setStage(1)
                                        npcGen:say("Now you're blessed and can not be attacked(or attack) other players.", "Now you're blessed and can not be attacked(or attack) other players.")
                                        doSendMagicEffect(getCreaturePosition(cid), 49)
                                        addEvent(function()
                                                if isCreature(cid) then
                                                  setPlayerStorageValue(cid, "canAttackable", -1)
                                                  doPlayerSetSpecialDescription(cid, "")
												  doCreatureSetGuildEmblem(cid, 0)
                                                end
                                        end, 60 * 60 * 4 * 1000)
                               -- else
                                --        npcGen:say("You don't have enough event tokens", "VocÃª nÃ£o tem event tokens suficiente.")
                                 --       npcGen:setStage(1)
                                end
                        end
            --[[    elseif stage >= 10 then
                        if msgcontains(msg, "yes") or msgcontains(msg, "yes") then
								if (stage-10) >= 1 then 
									if doPlayerRemoveItem(cid, 6527,  (stage - 10)*10) then
                                        npcGen:say("Did you get your coins elemental.", "VocÃª recebeu suas elemental coins.")
                                        db.executeQuery("UPDATE accounts SET premium_points = premium_points + " .. stage - 10 .. " where name = '" .. getPlayerAccount(cid) .. "'")
                                        npcGen:setStage(1)
									else
                                        npcGen:say("You don't have that much event tokens.", "VocÃª nÃ£o tem essa quantidade de event tokens.")
                                        npcGen:setStage(1)
									end
								else 
									npcGen:say("Invalid amount of coins.", "Invalid amount of coins.")
								end
                        else	
                                npcGen:setStage(1)
                        end]]
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
