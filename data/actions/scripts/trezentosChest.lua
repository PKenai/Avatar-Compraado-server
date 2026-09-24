local bosses = {"Tyrn", "Moohtant", "Demodras", "Lava Golem"}

local function checkBossAlive()
local specs = getSpectators({x=1212, y=1053, z=7}, 15, 15)
	if specs and #specs > 0 then 
		for i = 1, #specs do 
			if isMonster(specs[i]) and isInArray(bosses, getCreatureName(specs[i])) then 
				return true
			end 
		end 
	end 
	return false
end 

-- NAO entrega mais arma classica (mitologic flail/sword/axe/crossbow).
-- Arma classica tem ataque E defesa: daria o bonus de ataque nas magias
-- (sources/player.cpp) junto com o corte de defesa no PvP
-- (sources/combat.cpp) - os dois lados do see-saw ao mesmo tempo.

function onUse(cid, item, fromPosition, itemEx, toPosition)
	if checkBossAlive() then 	
		doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Você precisa derrotar os 4 bosses presentes na sala.")
		return true
	elseif getPlayerStorageValue(cid, "90520") == 1 then 	
		doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Você já pegou esta recompensa.")
	else	
		setPlayerStorageValue(cid, "90520", 1)
		doSendMagicEffect(getThingPos(cid), 29)
	end 
		doTeleportThing(cid, {x=1138, y=1047, z=7})
		doSendMagicEffect({x=1138, y=1047, z=7}, CONST_ME_TELEPORT)
    return true
end