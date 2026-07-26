local function isWaterHeal(p)
        local m = ""
                m = string.sub(p, 1, 1)
                if m == '"' or m == "" then
                        return true
                end
        return false
end


local function doCalculateEffect(cid, dir)
    local posToEffect = getPositionByDirection(getThingPos(cid), dir)
    doSendMagicEffect(posToEffect, 34, cid)
	if dir == 0 or dir == 2 then
		posToEffect.x = posToEffect.x+1
		doSendMagicEffect(posToEffect, 34, cid)
		posToEffect.x = posToEffect.x-2
		doSendMagicEffect(posToEffect, 34, cid)
	else
		posToEffect.y = posToEffect.y+1
		doSendMagicEffect(posToEffect, 34, cid)
		posToEffect.y = posToEffect.y-2
		doSendMagicEffect(posToEffect, 34, cid)
	end
end


function onSay(cid, words, param, channel)
		if getPlayerLevel(cid) > 1 or getPlayerStorageValue(cid, "tutorialback") == 1 then
			return false
		end
        if not param then
        return false
        end
        if not isWaterHeal(param) then
        return  false
        end
        local mypos = getCreaturePosition(cid)
		
	if getPlayerVocation(cid) ~= 4 then
        doPlayerSendCancel(cid, "Your vocation cannot use this bend.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return true
	elseif getCreatureMana(cid) < 2 then 
		doPlayerSendCancel(cid, "You do not have enough mana.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return true
    end
		
	local posNpc = {x=1130, y=559, z=7}

	if getPlayerStorageValue(cid, "jadissesim") ~= 1 then
		doPlayerSendCancel(cid, "Talk with Kuvira first.")
		return true
	elseif getDistanceBetween(posNpc, mypos) >= 5 then
		doPlayerSendCancel(cid, "Get closer to Kuvira.")
		return true
	end

	doCreatureSay(cid, "Earth Crush", TALKTYPE_ORANGE_1, false, cid)
	doCreatureAddMana(cid, -2, false)
	setPlayerStorageValue(cid, "tutorialback", 1)
	doCalculateEffect(cid, getCreatureLookDirection(cid))
	if isNpc(getTopCreature(posNpc).uid) then
		local mensagem = getLangString(cid, "I see that you already know how to bend the earth. We'll prepare you and teach how to control it with the best benders, be welcome to the tribe! Go back and talk with Sigrid, she'll travel with you to Ba Sing Se. Good luck, "..getCreatureName(cid).."!", "Vejo que já domina bem o elemento terra. Iremos te treinar para aprimorar a sua habilidade de dobra com os melhores, seja bem vindo! Volte e fale com a Sigrid, ele irá te levar para Ba Sing Se. Boa sorte, "..getCreatureName(cid).."!")
		doCreatureSay(getTopCreature(posNpc).uid, mensagem, 5, false, cid)
	end
  return true
end