local events = {"hasImuneable", "onAdvancePoint", "flySystem", "GuildEvents",
                "killTask", "loot", "onMoveItem", "onSee", "deathChecks", "deathGamesCheck", 
                "onDirection", "onTextEdit", "Idle", "Mail", "ReportBug", "SkullCheck", "onAddInjustInPlayer",
                "onGainExp", "castSpell", "onChangeOutfit", "combats", "pushs", "onmount", "prepareCheck", "combatss", "ExtendedOpcode", "onTradeStart", "onjogar", "trainer", "onAttackAvatar", "PartyDamageMeter"}



local premiumoOutfits = {
    ["fire"]   = {51, 52},
    ["water"]  = {47, 48},
    ["air"]    = {49, 50},
    ["earth"]  = {45, 46}
}

local normalOutfits = {
    ["fire"]   = {39, 40},
    ["water"]  = {41, 42},
    ["air"]    = {38, 37},
    ["earth"]  = {43, 44}   
}


function addPremiumOutfit(cid)
    if isPremium(cid) then
        doPlayerAddOutfitId(cid, premiumoOutfits[getPlayerElement(cid)][getPlayerSex(cid)+1], 0)
    end

    doPlayerAddOutfitId(cid, normalOutfits[getPlayerElement(cid)][getPlayerSex(cid)+1], 0)
end

function registerEvents(cid)
    for _, event in pairs(events) do
        registerCreatureEvent(cid, event)
    end
end

function sendBonusExpIfNeed(cid)
   -- if isPremium(cid) then
    --    doPlayerSetExperienceRate(cid, 1.3)
   -- end

    if getPlayerStorageValue(cid, "hasInPotionExp") > os.time() then
        local time = getPlayerStorageValue(cid, "hasInPotionExp")-os.time()
        if getPlayerStorageValue(cid, "Archangel") ~= 1 then
			doPlayerSetExperienceRate(cid, 3.6)
		else
			doPlayerSetExperienceRate(cid, 4.2)
		end
        addEvent(removePotionExp, time*1000, cid)
    end
end

function sendTestEquipamentsIfActive(cid)
    --[[
    if serverInTest then
        if getPlayerStorageValue(cid, "testMoney") == -1 then
            sendBlueMessage(cid, "Aten��o! Servidor em teste, voc� recebeu 1kk e 30 dias de premium account. Qualquer informa��o sobre balanceamento e bugs � util para n�s. Servidor est� com rate 3x.")
            doPlayerAddItem(cid, 2160, 100)
            doPlayerAddPremiumDays(cid, 30)
            setPlayerStorageValue(cid, "testMoney", 1)
        end
    else
        print("MIRTO TIRA ISSO DO LOGIN :D")
    end]]
end

function sendBlessIfActive(cid)
    local bless = getPlayerStorageValue(cid, "blessExp")
    local expLoss = getPlayerStorageValue(cid, "expBeforeDie")-getPlayerExperience(cid)
    local expToWin = expLoss
    local supremeBless = getPlayerStorageValue(cid, "playerWithSupremeBless")

    if bless > 0 then
		if supremeBless > 0 then 
			expToWin = expLoss
		else
			expToWin = (expLoss/2)
		end


        if expToWin > 0 then
            doPlayerAddExperience(cid, math.floor(expToWin))
			if supremeBless > 0 then 
				setPlayerStorageValue(cid, "playerWithSupremeBless", -1)
				local text = getLangString(cid, "You have lost the supreme bless, but all your experience lost has been recovered!", "Voc� acabou de perder a ben��o suprema, entretanto voc� teve toda sua exp perdida recuperada!")
				doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, text)
			else
				local text = getLangString(cid, "You has lost the bless of %s, but half of experience lost has been recovered!", "Voc� acabou de perder a ben��o de %s, entretanto voc� teve metade da exp perdida recuperada.")
				doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string.format(text, getPlayerStorageValue(cid, "blessExpName")))
			end
            setPlayerStorageValue(cid, "blessExp", -1)
        end
    end

    setPlayerHasDeath(cid, "unknow", expToWin, bless > 0)
    setPlayerStorageValue(cid, "expBeforeDie", -1)    
end


local initialItens = {
    normalItens = {
        {itemid=13734, amount=1, slot = CONST_SLOT_FEET},
        {itemid=13733, amount=1, slot = CONST_SLOT_LEGS},
        {itemid=13732, amount=1, slot = CONST_SLOT_ARMOR},
        {itemid=13412, amount=1, slot = CONST_SLOT_RIGHT},
        {itemid=2389, amount=7, slot = CONST_SLOT_LEFT},
        {itemid=1998, amount=1, slot = CONST_SLOT_BACKPACK},
        {itemid=7379, amount=1, slot = CONST_SLOT_BACKPACK},
        {itemid=3963, amount=1, slot = CONST_SLOT_BACKPACK},
        {itemid=2428, amount=1, slot = CONST_SLOT_BACKPACK},
        {itemid=2002, amount=1, slot = CONST_SLOT_BACKPACK},
    },
    vocItens = {
        {{itemid = 13731, amount=1, slot=CONST_SLOT_HEAD} },
        {{itemid = 13731, amount=1, slot=CONST_SLOT_HEAD}, {itemid = 4864, amount=1, slot=CONST_SLOT_AMMO, waterFull = true}, {itemid = 4864, amount=1, slot=CONST_SLOT_BACKPACK, waterFull = true}, {itemid = 4864, amount=1, slot=CONST_SLOT_BACKPACK, waterFull = true}}, 
        {{itemid = 13731, amount=1, slot=CONST_SLOT_HEAD} }, 
        {{itemid = 13731, amount=1, slot=CONST_SLOT_HEAD} },
    },

    slots = {CONST_SLOT_HEAD, CONST_SLOT_NECKLACE, CONST_SLOT_ARMOR, CONST_SLOT_RIGHT, 
             CONST_SLOT_LEFT, CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_RING, CONST_SLOT_AMMO},

    vocOutfits = {
        {383, 388},
        {387, 368},
        {456, 457},
        {384, 371}
    }
}

function sendInitialItens(cid)
    local playerVoc = getPlayerVocation(cid)

    if playerVoc == 0 then
        return true
    end

    if getPlayerStorageValue(cid, "playerHasGetInitialItens") == 1 then
        return true
    end

    --doPlayerAddOutfit(cid, initialItens.vocOutfits[playerVoc][getPlayerSex(cid)+1], 0)


    for x = 1, #initialItens.slots do
        local possibleItemInSlot = getPlayerSlotItem(cid, initialItens.slots[x]).uid
        if possibleItemInSlot > 0 then
            doRemoveItem(possibleItemInSlot)
        end
    end

    for x = 1, #initialItens.normalItens do
        doPlayerAddItem(cid, initialItens.normalItens[x].itemid, initialItens.normalItens[x].amount, false, initialItens.normalItens[x].slot)
    end

    for x = 1, #initialItens.vocItens[playerVoc] do
        local itemUid = doPlayerAddItem(cid, initialItens.vocItens[playerVoc][x].itemid, initialItens.vocItens[playerVoc][x].amount, false, initialItens.vocItens[playerVoc][x].slot)
        setItemWaterFullByBorean(itemUid, initialItens.vocItens[playerVoc][x].waterFull)
    end
    setPlayerStorageValue(cid, "playerHasGetInitialItens", 1)

end

function sendAllCheckFunctions(cid)
    sendInitialItens(cid)
    sendBackupToPlayer(cid)
    setPlayerStorageValue(cid, "getAwnserAntiBot", -1) --antiBot System
    setPlayerStorageValue(cid, "currentCid", cid)
end



function sendOutfitToNormal(cid)
    local playerVoc = getPlayerVocation(cid)

    if playerVoc == 0 then
        return true
    end

    --doCreatureChangeOutfit(cid, {lookType=initialItens.vocOutfits[playerVoc][getPlayerSex(cid)+1]})
end




--funcs de reset, retiradas--
local function returnStatsPoints(cid)
    local playerElement = getPlayerElement(cid)
    local pointsUsed = (getPointsWasted(cid, "health")+getPointsWasted(cid, "mana")+getPointsWasted(cid, "bend")+getPointsWasted(cid, "dodge"))+getPlayerElementPoints(cid, playerElement)

    --[[for x = 1, 120 do
        if getPlayerStorageValue(cid, "onGainPointsLv"..x) == 1 then
            pointsLevel = pointsLevel+1
        end
    end--]]

    local pointsLevel = getPlayerLevel(cid)-1
    local totalPoints = pointsLevel+getPointsUsedInSkill(cid, "stones")

    if totalPoints ~= pointsUsed then
        if getPlayerStorageValue(cid, "hasResetedBug2") == -1 then
            local msg = {en = "", pt = ""}

            if pointsUsed < totalPoints then
                msg.en = "BUG Correct: "..(totalPoints-pointsUsed).." elemental points returned to you, use in NPC Sthuart."
                msg.pt = "Corre��o BUG: "..(totalPoints-pointsUsed).." ponto(s) elementa(is) foram devolvidos � voc�, use no NPC Sthuart." 
                doPlayerSetElementPoints(cid, playerElement, getPlayerElementPoints(cid, playerElement)+(totalPoints-pointsUsed))
            else
                msg.en = "BUG Correct: All your stats have been reset, please go to NPC Sthuart for redistribute it."
                msg.pt = "Corre��o BUG: Todos seus stats foram resetados, por favor v� at� o NPC Sthuart para redistribuir."

                setPlayerMagLevel(cid, 10)

                setCreatureMaxHealth(cid, getCreatureMaxHealth(cid)-getPointsUsedInSkill(cid, "health"))
                setCreatureMaxMana(cid, getCreatureMaxMana(cid)-getPointsUsedInSkill(cid, "mana"))
                doCreatureAddHealth(cid, -getCreatureHealth(cid)+getCreatureMaxHealth(cid))
                doCreatureAddMana(cid, -getCreatureMana(cid)+getCreatureMaxMana(cid))

                setPlayerStorageValue(cid, "getPointsInDodge", -1)
                setPlayerStorageValue(cid, "getPointsInHealth", -1)
                setPlayerStorageValue(cid, "getPointsInMana", -1)
                setPlayerStorageValue(cid, "getPointsInBendLevel", -1)

                doPlayerSetElementPoints(cid, playerElement, totalPoints)
            end

            doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, getLangString(cid, msg.en, msg.pt))
            setPlayerStorageValue(cid, "hasResetedBug2", 1)
        end
    end
end 