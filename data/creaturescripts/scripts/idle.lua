local config = {
  idleWarning = getConfigValue('idleWarningTime'),
  idleKick = getConfigValue('idleKickTime')
}

local makers = {"Coriel"}

function anotherDir(dir)
if dir >= 2 then 
	return math.random(0, 1)
else 
	return math.random(2, 3)
end 
end 

function checkExpRates(cid)
local cast = db.getResult("SELECT `broadcasting` FROM `players` WHERE `id` = " .. getPlayerGUID(cid) .. ";")
local expF = 1 -- se nao tiver nenhum bonus vai ser 1x, logo, nao sera modificado
local onlineCount = #getPlayersOnline()
	if onlineCount >= 400 then
		expF = expF+0.5
	end
	if onlineCount >= 300 then
		expF = expF+0.4
	end
	if onlineCount >= 200 then
		expF = expF+0.3
	end
	if onlineCount >= 100 then
		expF = expF+0.2
	end
	if onlineCount >= 40 then
		expF = expF+0.1
	end
    if(cast:getDataInt("broadcasting") == 1) then
    	expF = expF+0.05
   	end
	if getPlayerPremiumDays(cid) > 0 then -- Se tem premium account 15% mais xp
		expF = expF+0.15
	end
	if getPlayerStorageValue(cid, "hasInPotionExp") > os.time() then -- Se tem pot exp 20% mais xp
		expF = expF+0.2
	end
	if getPlayerStamina(cid) >= 2400 then  -- Se tem stamina 40+ 20% mais xp
		expF = expF + 0.2
	end 
	if getPlayerGuildName(cid) == getStorage(391893) then -- se é da guild dominante +15% xp
		expF = expF+0.15
	end
	if (getCreatureSkullType(cid) == SKULL_RED) then
		expF = expF/2
	end
	doPlayerSetExperienceRate(cid, expF) -- atualiza pro combo final
end 

function tryAntibotSystem(cid)
	if not tonumber(getPlayerStorageValue(cid, "horarioBot")) then
		setPlayerStorageValue(cid, "horarioBot", 0)
	end
	local lastTime = tonumber(getPlayerStorageValue(cid, "horarioBot"))
	if os.time()-900 > lastTime and not exhaustion.check(cid, "checkcooldownBot") then -- ja faz 30m desde o ultimo verifyBot e ja passou o cooldown de re-check 
		verifyBot(cid)
	end
end

local function marketCheck(cid)
    local balance = db.getResult("SELECT `auction_balance` FROM `players` WHERE `id` = " .. getPlayerGUID(cid) .. ";")
    if(balance:getDataInt("auction_balance") < 1) then
        balance:free()
        return true
   end
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Você recebeu " .. balance:getDataInt("auction_balance") .. " gold coins por ter vendido algum item no mercado!")
   doPlayerAddMoney(cid, balance:getDataInt("auction_balance"))
    db.executeQuery("UPDATE `players` SET `auction_balance` = '0' WHERE `id` = " .. getPlayerGUID(cid) .. ";")
    balance:free()
end

function onThink(cid, interval)
if not exhaustion.check(cid, "marketCheck") then 
	exhaustion.set(cid, "marketCheck", 15)
	marketCheck(cid)
	--local target = getCreatureTarget(cid)
	--if math.random(1, 400) >= 390 and isCreature(target) and isMonster(target) and not isSummon(target) and getCreatureName(target) ~= "Target" and getPlayerLevel(cid) >= 30 then
	--	tryAntibotSystem(cid)
	--end
end 
  checkExpRates(cid)
  if(getTileInfo(getCreaturePosition(cid)).noLogout or getCreatureNoMove(cid) or
    getPlayerCustomFlagValue(cid, PLAYERCUSTOMFLAG_ALLOWIDLE)) then
    return true
  end
	local testPos = getCreaturePosition(cid)
  if testPos.x >= 442 and testPos.y >= 88 and testPos.z == 8 and testPos.x <= 449 and testPos.y <= 94 then 
		--doPlayerResetIdleTime(cid)
		return true
end

  local idleTime = getPlayerIdleTime(cid) + interval
  doPlayerSetIdleTime(cid, idleTime)
  if(config.idleKick > 0 and idleTime > config.idleKick) then
	if isCreature(getCreatureTarget(cid)) and getCreatureName(getCreatureTarget(cid)) == "Target" and os.time() - 28800 < getPlayerStorageValue(cid, "entrouTrainers") then
		doPlayerResetIdleTime(cid)
	elseif getPlayerStorageValue(cid, "ativoBot") == 1 then
		doPlayerResetIdleTime(cid)
	else 
		doRemoveCreature(cid)
	end 
  elseif(config.idleWarning > 0 and idleTime == config.idleWarning) then
  	if isCreature(getCreatureTarget(cid)) and getCreatureName(getCreatureTarget(cid)) == "Target" and os.time() - 28800 < getPlayerStorageValue(cid, "entrouTrainers") then
		doPlayerResetIdleTime(cid)
		return true
	end
    local message = getLangString(cid, "There was no variation in your behaviour for " .. math.ceil(config.idleWarning / 60000) .. " minutes", "Seu character não teve nenhuma variação de movimento nos últimos "..math.ceil(config.idleWarning / 60000).." minutos")
    if(config.idleKick > 0) then
      message = message .. getLangString(cid, ". You will be disconnected in ", ". Você será desconectado em ")
      local diff = math.ceil((config.idleWarning - config.idleKick) / 60000)
      if(diff > 1) then
        message = message .. diff .. getLangString(cid, " minutes", " minutos")
      else
        message = message .. getLangString(cid, "one minute", "um minuto")
      end

      message = message .. getLangString(cid, " if you don't move", " se você não se movimentar")
    end

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, message..".")
  end

  return true
end