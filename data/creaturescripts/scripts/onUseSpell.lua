local errorMsg = {
    ["fire"] = {"Before you need learn this fold.", "Você ainda não aprendeu a usar essa dobra."},
    ["air"] = {"Before you need learn this fold.", "Você ainda não aprendeu a usar essa dobra."},
    ["earth"] = {"Before you need learn this fold.", "Você ainda não aprendeu a usar essa dobra."},
    ["water"] = {"Before you need learn this fold.", "Você ainda não aprendeu a usar essa dobra."}
}

function onCastSpell(cid, words)
    if getPlayerGroupId(cid) >= 5 then
        return true
    end
    local words = getCurrentFold(cid)
	if string.lower(words) == "water mregen" then 
		words = "water regen"
	end 
    local spellInfo, playerLevel = getInstantSpellInfo(words), getPlayerLevel(cid)
    local element = getPlayerElement(cid)

    if getPlayerStorageValue(cid, "hasActiveInQuest") == 1 then
        for x = 1, 20 do
            local currentSpell = getPlayerStorageValue(cid, "canUseSpell"..x)
            
            if not (currentSpell == -1) then
                if words == currentSpell then
                    doPlayerSendCancel(cid, getLangString(cid, "You cannot use this fold here.", "Você não pode usar essa dobra aqui."))
                    return false
                end
            else
                break
            end
        end
    end

    if spellInfo.level > 46 then
        if playerLevel >= spellInfo.level then
            if not hasFoldIsBuy(cid, words) then
                doPlayerSendCancel(cid, getLangString(cid, "Before you need learn this fold.", "Você ainda não aprendeu a usar essa dobra."))
                local errorMsg = errorMsg[element]

                sendBlueMessage(cid, getLangString(cid, errorMsg[1], errorMsg[2]))
                doSendMagicEffect(getCreaturePosition(cid), 2)
                return false
            end
        end
    end
  
    return true
end

--em construcao :D