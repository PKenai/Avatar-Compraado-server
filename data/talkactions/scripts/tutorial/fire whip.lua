local function isWaterHeal(p)
        local m = ""
                m = string.sub(p, 1, 1)
                if m == '"' or m == "" then
                        return true
                end
        return false
end

local effects = {
    {eff=103, desl = {x=1,y=0}}, 
    {eff=105, desl = {x=0,y=1}},
    {eff=104, desl = {x=1,y=0}},
    {eff=106, desl = {x=0,y=1}}
}

local function doCalculateEffect(cid, dir)
    local posToEffect = getPositionByDirection(getThingPos(cid), dir)
	local posEff = {x=posToEffect.x+effects[dir+1].desl.x, y=posToEffect.y+effects[dir+1].desl.y, z=posToEffect.z}
    doSendMagicEffect(posEff, effects[dir+1].eff, cid)
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
		
	if getPlayerVocation(cid) ~= 1 then
        doPlayerSendCancel(cid, "Your vocation cannot use this bend.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return true
	elseif getCreatureMana(cid) < 2 then 
		doPlayerSendCancel(cid, "You do not have enough mana.")
        doSendMagicEffect(mypos, CONST_ME_POFF)
        return true
    end
	
	local posNpc = {x=1247, y=741, z=6}

	if getPlayerStorageValue(cid, "jadissesim") ~= 1 then
		doPlayerSendCancel(cid, "Talk with Izumi first.")
		return true
	elseif getDistanceBetween(posNpc, mypos) >= 5 then
		doPlayerSendCancel(cid, "Get closer to Izumi.")
		return true
	end

	doCreatureSay(cid, "Fire Whip", TALKTYPE_ORANGE_1, false, cid)
	doCreatureAddMana(cid, -2, false)
	setPlayerStorageValue(cid, "tutorialback", 1)
	doCalculateEffect(cid, getCreatureLookDirection(cid))
	if isNpc(getTopCreature(posNpc).uid) then
		local mensagem = getLangString(cid, "I see that you already know how to bend the fire. We'll prepare you and teach how to control it with the best benders, be welcome to the nation! Go back and talk with Rolf, he'll travel with you to the Fire Nation Capital. Good luck, "..getCreatureName(cid).."!", "Vejo que já domina bem o elemento fogo. Iremos te treinar para aprimorar a sua habilidade de dobra com os melhores, seja bem vindo! Volte e fale com o Rolf, ele irá te levar para a Fire Nation Capital. Boa sorte, "..getCreatureName(cid).."!")
		doCreatureSay(getTopCreature(posNpc).uid, mensagem, 5, false, cid)
	end
  return true
end