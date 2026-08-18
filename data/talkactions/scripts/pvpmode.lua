local worlds = {
  [WORLDTYPE_OPTIONAL] = "Optional PvP",
  [WORLDTYPE_OPEN] = "Open PvP",
  [WORLDTYPE_HARDCORE] = "Hardcore PvP"
}

local config = {
  delayToUseAgain = 1*12*60*60,
  delayToUseAgainHigh = 7*24*60*60
}

function onSay(cid, words, param, channel)
	if getPlayerStorageValue(cid, "isAvatar") == 1 and getPlayerStorageValue(cid, "canAttackable") ~= 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You cant turn off the PvP mode while you are the Avatar.", "Você não pode desativar o seu modo PvP enquanto é o Avatar."))
		return true
	end
	--[[ if getPlayerLevel(cid) >= 100 and getPlayerStorageValue(cid, "canAttackable") ~= 1 then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You cant turn off the PvP mode anymore. Only players with level under 100 can.", "Você não pode mais desativar o seu modo PvP. Somente jogadores com nível menor que 100 podem desativar."))
		return true
	end ]]
	if getPlayerLevel(cid) < 50 then 
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You can only change your pvp mode when you reach level 50.", "Você só poderá mudar o seu modo de PvP quando atingir o nível 50 ou mais."))
		return true 
	end
	local delay = getPlayerStorageValue(cid, "delayPvpMode")
	if delay >= os.time() then
		doPlayerSendCancel(cid, getLangString(cid, "You need wait "..getSecsString(delay-os.time()).." to change your PvP mode again.", "Você precisa esperar "..getSecsString(delay-os.time()).." para trocar seu modo de PvP novamente."))
		return true
	elseif not getTileInfo(getCreaturePosition(cid)).protection then 
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You can only change your pvp mode in a protection zone. Go back to temple and try again.", "Você não pode mudar o seu modo de PvP fora de uma zona protegida. Volte para o templo e tente novamente."))
		return true 
	elseif getCreatureSkullType(cid) == 4 then		
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "You can only change your pvp mode without red skull.", "Você não pode mudar seu modo de PvP enquanto estiver com red skull."))
		return true 
	else 	
		if getPlayerStorageValue(cid, "canAttackable") ~= 1 then 
			setPlayerStorageValue(cid, "Archangel", 1)
			setPlayerStorageValue(cid, "canAttackable", 1)
			doCreatureSetGuildEmblem(cid, 1)		
			doSendPlayerExtendedOpcode(cid, 91, "inativo")
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "Now you're protected and will not receive or deal any damage on another player.", "Você agora está protegido e não poderá mais receber ou causar dano em outros jogadores."))
			if getPlayerStorageValue(cid, "hasInPotionExp") > os.time() then
				doPlayerSetExperienceRate(cid, 1.2)
			else 
				doPlayerSetExperienceRate(cid, 1)
			end 
		else
			setPlayerStorageValue(cid, "Archangel", 0)
			setPlayerStorageValue(cid, "canAttackable", 0)
			doCreatureSetGuildEmblem(cid, 0)
			doPlayerSetSpecialDescription(cid, "")	
			doSendPlayerExtendedOpcode(cid, 91, "ativo")			
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, getLangString(cid, "Now you can attack and be attacked by another player. You'll receive 40% exp bonus from monsters for of your courage!", "Agora você pode atacar e ser atacado por outros jogadores. Você agora receberá 40% de experiência bônus derrotando monstros devido a sua coragem!"))end 
		    if getPlayerStorageValue(cid, "hasInPotionExp") > os.time() then
				doPlayerSetExperienceRate(cid, 1.5)
			else 
				doPlayerSetExperienceRate(cid, 1.3)
			end 
	end
		if getPlayerLevel(cid) >= 100 then
			setPlayerStorageValue(cid, "delayPvpMode", os.time()+config.delayToUseAgainHigh)
		else
			setPlayerStorageValue(cid, "delayPvpMode", os.time()+config.delayToUseAgain)
		end
		  setCreatureNoMoveTime(cid, 5000)
		  doPlayerSendTextMessage(cid, 22, getLangString(cid, "Leaving the game in 5 seconds...", "Saindo do jogo em 5 segundos..."))
		addEvent(function() if isCreature(cid) then doRemoveCreature(cid) end end, 5000)
  return true
end
