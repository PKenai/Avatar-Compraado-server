local itemIdShow = 1921

function onAdvance(cid, skill, oldLevel, newLevel)
	-- SKILL__LEVEL = 8 (level up). Also accept raw 8 if constant is missing.
	if (skill == SKILL__LEVEL or skill == 8) and newLevel > oldLevel then
		if getPlayerStorageValue(cid, "getTurnMsgPoints") ~= 1 then
			local string = getLangString(cid, "Congratulations! You have gained element points.\nYou can use these element points for change with more stats as Bend Level, Speed, Hitpoints and Dodge Chance. Type CTRL + E.", "Parabens! Voce ganhou pontos.\nVoce pode utilizar esses pontos para trocar por stats como Bend Level, Mana, Health e Speed. Use CTRL + E.")
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string)
			setPlayerStorageValue(cid, "getTurnMsgPoints", 1)
		elseif newLevel >= 50 and getPlayerStorageValue(cid, "pvpLevelMessage") ~= 1 then
			setPlayerStorageValue(cid, "pvpLevelMessage", 1)
			local string = getLangString(cid, "Congratulations! You have reached level 50.\nYou are now blessed and will not lose items until your next death.\nYou can now attack others players of level 50 or higher.", "Parabens! Voce alcancou o nivel 50.\nSeu personagem foi abencoado e nao perdera nenhum item em sua proxima morte.\nAgora voce pode atacar e ser atacado por outros jogadores de nivel 50 ou superior, mas existe penalidades (skull system).")
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, string)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, "Now you'll lose your backpack on death (you can use an amulet of loss or buy blessing to prevent this). If you die while you're red skulled, you'll lose all your items (there's no prevent for that).", "Agora voce podera perder sua backpack em uma eventual morte (seja para monstro ou para um jogador, caso nao esteja utilizando amulet of loss ou nao esteja abencoado para prevenir). Caso morra estando com red skull (adquirido apos matar muitos jogadores injustificadamente), perdera todos os itens, sem direito a prevencao."))
			setPlayerStorageValue(cid, "playerWithBless", 1)
			setPlayerStorageValue(cid, "blessExpName", "Sony")
		end

		doCreatureAddHealth(cid, getCreatureMaxHealth(cid) - getCreatureHealth(cid))
		doCreatureAddMana(cid, getCreatureMaxMana(cid) - getCreatureMana(cid))
		local posicao = getThingPos(cid)
		doSendMagicEffect({x = posicao.x + 1, y = posicao.y + 1, z = posicao.z}, 166)

		-- 1 attribute point per level gained
		local lastAwarded = getPlayerStorageValue(cid, 188100)
		if type(lastAwarded) ~= "number" or lastAwarded < 0 then
			lastAwarded = oldLevel
		end

		if lastAwarded < newLevel then
			local gained = newLevel - lastAwarded
			local pendentes = getPlayerStorageValue(cid, "pendentes")
			if type(pendentes) ~= "number" or pendentes < 0 then
				pendentes = 0
			end
			pendentes = pendentes + gained
			setPlayerStorageValue(cid, "pendentes", pendentes)
			setPlayerStorageValue(cid, 188100, newLevel)
			doSendPlayerExtendedOpcode(cid, 41, tostring(pendentes))
			if getAtributosString then
				doSendPlayerExtendedOpcode(cid, 40, getAtributosString(cid))
			end
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Voce ganhou " .. gained .. " attribute point(s). Total pendente: " .. pendentes .. ".")
		end

		addNewTasks(cid, newLevel)
	end

	return true
end
