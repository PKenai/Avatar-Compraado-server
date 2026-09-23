local slots = {
	[1] = 13401,
	[4] = 13402,
	[5] = 13405,
	[7] = 13403,
	[8] = 13404,
}


local function getMatchSet(cid)
	for i,v in pairs (slots) do
		if not (getPlayerSlotItem(cid, i).itemid == v) then
			return false
		end
	end
	return true
end

local slots2 = {
	[1] = 13416,
	[4] = 13418,
	[5] = 13415,
	[7] = 13417,
	[8] = 12930,
}


local function getMatchSet2(cid)
	for i,v in pairs (slots2) do
		if not (getPlayerSlotItem(cid, i).itemid == v) then
			return false
		end
	end
	return true
end

function onStatsChange(cid, attacker,type,	combat,	value)
	if not isCreature(attacker) then return true end

	if isPlayer(attacker) then
		porcentagem = 10
	else
		porcentagem = 20
	end
	if getMatchSet(cid) or getMatchSet2(cid) then		
		-- Dano gerado por script (outro handler): nao refletir de novo.
		-- Ver data/lib/combatRecursionGuard.lua.
		if (combat == STATSCHANGE_HEALTHLOSS) and not CombatRecursionGuard.isInside() then
			local damage = math.ceil((value/100)*porcentagem)
			doSendAnimatedText(getThingPos(attacker), damage,143)
			CombatRecursionGuard.run(doCreatureAddHealth, attacker, -damage)
			doPlayerSendTextMessage(cid,MESSAGE_EVENT_DEFAULT,"You reflected "..damage.." by damage from a " .. getCreatureName(attacker) .. ".")
		end
	end
	return true
end

