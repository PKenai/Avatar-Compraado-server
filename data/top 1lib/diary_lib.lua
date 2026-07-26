function getDay()
  return tonumber(os.date('%d'))
end

function getMonth()
  return tonumber(os.date('%m'))
end

function getYear()
  return tonumber(os.date('%Y'))
end

function isLeapYear(year)
  return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

function getQtdDayOfMonth(month, year)
  local day = 31
  if ( month == 2 ) then
    day = isLeapYear(year) and 29 or 28
  elseif ( month == 4 or month == 6 or month == 9 or month == 11 ) then
    day = day - 1    
  end
  return day
end

local msgBr = "[Daily Reward] Você recebeu 1x %s como recompensa por ficar 1 hora online."
local msgEn = "[Daily Reward] You have received 1x %s as a reward for staying 1 hour online."

local msgBr1 = "[Daily Reward] Você recebeu 15k (15.000 gps) como recompensa por ficar 1 hora online."
local msgBr2 = "[Daily Reward] Você recebeu 10k (10.000 gps) como recompensa por ficar 1 hora online."
local msgBr3 = "[Daily Reward] Você recebeu 5k (5.000 gps) como recompensa por ficar 1 hora online."
local msgBr4 = "[Daily Reward] Você recebeu 2x %s como recompensa por ficar 1 hora online."

local msgEn1 = "[Daily Reward] You have received 15k (15.000 gps) as a reward for staying 1 hour online."
local msgEn2 = "[Daily Reward] You have received 10k (10.000 gps) as a reward for staying 1 hour online."
local msgEn3 = "[Daily Reward] You have received 5k (5.000 gps) as a reward for staying 1 hour online."
local msgEn4 = "[Daily Reward] You have received 2x %s as a reward for staying 1 hour online."

Reward = {

	opcodes = 247,
	timeOn  = 1*60*60, -- Tempo online. ( 3*60*60 equivale a 3 horas )

	rewards_one = { 2160, 2152, 2148, 2173, 18099, 18100, 18101, 18102 }, -- Premios.
	rewards_two = { 11322, 6500, 11334, 2177, 11325, 12409, 10531, 12447 }, -- Premios.
	rewards_three = { 12466, 13848, 18115, 12828, 11259, 13375, 12753, 18057, 12754, 12831 }, -- Premios.
	
	storage = { 
	  timer = 9740,
	  month = 9741, 
	  day   = 9700
	},
	
	sendDate = function(cid)
	  doSendPlayerExtendedOpcode(cid, Reward.opcodes, "date>"..getDay()..">"..getMonth()..">"..getYear())
	end,

	setTime = function(cid)
	  setPlayerStorageValue(cid, Reward.storage.timer, os.time())
	end,

	getTime = function(cid)
	  return os.time() - getPlayerStorageValue(cid, Reward.storage.timer)
	end,
	
	getReward = function(cid)
	  local day = Reward.storage.day + getDay()
	  if ( getPlayerStorageValue(cid, day) == 0 and Reward.getTime(cid) >= Reward.timeOn ) then
		local chance = math.random(1, 100)
		local item
		if ( chance <= 70 ) then
		  item = Reward.rewards_one[math.random(#Reward.rewards_one)]
		elseif ( chance <= 90 ) then
		  item = Reward.rewards_two[math.random(#Reward.rewards_two)]
		else
		  item = Reward.rewards_three[math.random(#Reward.rewards_three)]
		end
		if item == 2160 then
			doPlayerAddItem(cid, 2160)
			doPlayerAddItem(cid, 2152, 50)
			setPlayerStorageValue(cid, day, 1)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, msgEn1:format(getItemInfo(item).name), msgBr1:format(getItemInfo(item).name)))
			return true
		elseif item == 2152 then
			doPlayerAddItem(cid, 2160)
			setPlayerStorageValue(cid, day, 1)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, msgEn2:format(getItemInfo(item).name), msgBr2:format(getItemInfo(item).name)))
			return true
		elseif item == 2148 then
			doPlayerAddItem(cid, 2152, 50)
			setPlayerStorageValue(cid, day, 1)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, msgEn3:format(getItemInfo(item).name), msgBr3:format(getItemInfo(item).name)))
			return true
		elseif item == 11259 then
			doPlayerAddItem(cid, 11259, 2)
			setPlayerStorageValue(cid, day, 1)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, msgEn4:format(getItemInfo(item).name), msgBr4:format(getItemInfo(item).name)))
			return true
		end
		doPlayerAddItem(cid, item) 
	    setPlayerStorageValue(cid, day, 1)	     
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, getLangString(cid, msgEn:format(getItemInfo(item).name), msgBr:format(getItemInfo(item).name)))
	  end
	end,
	
	resetRewards = function(cid)
	  for i = 1, getQtdDayOfMonth(getMonth(), getYear()) do
		setPlayerStorageValue(cid, Reward.storage.day+i, 0)
	  end
	end,
	
	sendRewards = function(cid)
	  local day   = ''
		
	  if ( getMonth() ~= getPlayerStorageValue(cid, Reward.storage.month) ) then
	    Reward.resetRewards(cid)
		setPlayerStorageValue(cid, Reward.storage.month, getMonth())								
	  end

	  for i = 1, getDay() do 
		day = day..getPlayerStorageValue(cid, Reward.storage.day+i)..'-'
	  end
	
	  Reward.sendDate(cid)
	  doSendPlayerExtendedOpcode(cid, Reward.opcodes, "daily>"..day)
	end

}
