function onTarget(cid, target)
	local cast = db.getResult("SELECT `broadcasting` FROM `players` WHERE `id` = " .. getPlayerGUID(cid) .. ";")
	if(cast:getDataInt("broadcasting") > 0) and (getCreatureName(target) == "Target") then
		sendBlueMessage(cid, getLangString(cid, "You cannot start your training with the cast on.", "Você não pode começar o seu treinamento com o cast ligado."))
    	return false
   	elseif
   		isMonster(target) and getCreatureName(target) == "Target" and not exhaustion.check(cid, "trainerflood") then
		sendBlueMessage(cid, getLangString(cid, "You started your training! You'll not be kicked for inactivity for 8 hours starting now. Every 5 minutes of training, you will gain 1 minute of stamina.", "Você começou seu treinamento! Enquanto estiver treinando, você não será removido por inatividade (pelas primeiras 8 horas a partir de agora). A cada 5 minutos de treinamento, você ganhará 1 minuto de stamina."))
		setPlayerStorageValue(cid, "entrouTrainers", os.time())
		exhaustion.set(cid, "trainerflood", 600)
	end
return true
end