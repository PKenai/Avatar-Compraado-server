local spellInfos = {
    ["fire"] = 
        {
            {words = "Focus"}, {words = "Lightning"},
            {words = "Bomb"}, {words = "Clock"}, {words = "Thunderbolt"}, {words = "Meteor"},
            {words = "Striker"}, {words = "Overload"}, {words = "Explosion"}, {words = "Voltage"}, {words = "Thunderstorm"}, {words = "Discharge"}, {words = "Conflagration"}
        },

    ["water"] = 
        {
           {words = "BloodControl"},
            {words = "Punch"}, {words = "Dragon"}, {words = "Rain"}, {words = "Bubbles"}, {words = "Protect"},
            {words = "Icebolt"}, {words = "Flow"}, {words = "IceGolem"}, {words = "Tsunami"}, {words = "Clock"}, {words = "Blizzard"}, {words = "BloodBending"}
        },

    ["air"] = 
        {
            {words = "Suffocation"}, {words = "Hurricane"},
            {words = "Tempest"}, {words = "Windblast"}, {words = "Tornado"}, {words = "Barrier"}, {words = "Trap"}, 
            {words = "Doom"}, {words = "Bomb"}, {words = "Windstorm"}, {words = "Stormcall"}, {words = "Vortex"}, {words = "Deflection"}
        },

    ["earth"] = 
        {
           {words = "Control"}, {words = "Leech"},
            {words = "Smash"}, {words = "Ingrain"}, {words = "Fists"}, {words = "Arena"}, {words = "Curse"},
            {words = "Quake"}, {words = "Cataclysm"}, {words = "Aura"}, {words = "Armor"}, {words = "Lavaball"}, {words = "Metalwall"}
        }
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
local talkState = {}

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) 			end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) 		end
function onCreatureSay(cid, type, msg) 		npcHandler:onCreatureSay(cid, type, msg) 	end
function onThink() 							npcHandler:onThink() 						end
function onPlayerEndTrade(cid)				npcHandler:onPlayerEndTrade(cid)			end
function onPlayerCloseChannel(cid)			npcHandler:onPlayerCloseChannel(cid)		end

npcHandler:setMessage(MESSAGE_GREET, "Hello |PLAYERNAME|, do you want to {learn} a fold with me today, or would you like to be {promoted} to a higher rank?")

local dobraAtual = {}
local sequenciaAtual = {}

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end    
	local lang, element = getLang(cid), getPlayerElement(cid)

    if element ~= "air" then
        selfSay(getLangString(cid, "Sorry, i only teaching air benders, the winds will lead you to your mentor.", "Sorry, i only teaching air benders, the winds will lead you to your mentor."), cid)
        return false
    end
	 
    -- Penultima e ultima dobra da lista ensinada (as "ultimates", que pedem
    -- stones e Reset especificos). Calculado da propria lista.
    local totalFolds = #spellInfos[element]
    local PENULT, LAST = totalFolds-1, totalFolds

    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid 
	if not talkState[talkUser] or talkState[talkUser] <= 0 then
		talkState[talkUser] = 1 
	end
    if talkState[talkUser] == 1 then
        if msgcontains(msg, "promote") or msgcontains(msg, "promotion") or msgcontains(msg, "promovido") or msgcontains(msg, "promover") then
			if getPlayerStorageValue(cid, "canPromote") == 1 then
				local nomeByVoc = {"Fire Lord", "Tribal Chief", "Air Monk", "Dai Li"}
				selfSay(getLangString(cid, "I now promote you to "..nomeByVoc[getPlayerVocation(cid)]..". Congratulations and honor your name!", "I now promote you to "..nomeByVoc[getPlayerVocation(cid)]..". Congratulations and honor your name!"), cid)
				doSendMagicEffect(getCreaturePosition(cid), 49)
				talkState[talkUser] = 1 
				setPlayerStorageValue(cid, "canPromote", 2)
				setPlayerStorageValue(cid, "isPromoted", 1)
                setPlayerStorageValue(cid, "90514", 1)
			elseif getPlayerStorageValue(cid, "canPromote") == 2 then
				local nomeByVoc = {"Fire Lord", "Tribal Chief", "Air Monk", "Dai Li"}
				selfSay(getLangString(cid, "You already are a "..nomeByVoc[getPlayerVocation(cid)]..".", "You already are a "..nomeByVoc[getPlayerVocation(cid)].."."), cid)
				talkState[talkUser] = 1 
			else
				selfSay(getLangString(cid, "You need to complete your secret mission first.", "You need to complete your secret mission first."), cid)
				talkState[talkUser] = 1 
			end
        elseif msgcontains(msg, "learn") or msgcontains(msg, "aprender") then
            local list = getListLearnFold(cid, true, true)

            if list ~= "" then
                selfSay(getLangString(cid, "Huuumm, let me see... in this level you can learn: {"..list.."}. Are you interested?", "Huuumm, let me see... in this level you can learn: {"..list.."}. Are you interested?"), cid)
                talkState[talkUser] = 2 
            else
                selfSay(getLangString(cid, "Right now you don't have any fold avaiable to learn.", "Right now you don't have any fold avaiable to learn."), cid)
            end
        end

        return true
        
    elseif talkState[talkUser] == 2 then
        local list = string.explode(getListLearnFold(cid), ",")

    local spells = spellInfos[getPlayerElement(cid)]
    for x = 1, #spells do 
      if spells[x].words:lower() == msg then 
        sequencia = x 
        break;
      end 
    end 
	-- PENULT = penultima dobra da lista (2 stones), LAST = ultima (5 stones)
        for x = 1, #list do
            if msgcontains(msg, list[x]:lower()) then
				if list[x]:lower() == "vortex" or list[x]:lower() == "deflection" then							
					local stones, totaltasks = 2, 100
					sequenciaAtual[cid] = PENULT
					if list[x]:lower() == "deflection" then
                        stones = 5
                        totaltasks = 150
						sequenciaAtual[cid] = LAST
					end
					selfSay(getLangString(cid, "Hmm, the "..getFoldDisplayName(element, list[x]).." bend costs {"..stones.." Air Stones} and require {Reset "..totaltasks.."} or higher to learn, do you have the stones and the required Reset level?", "Hmm, the "..getFoldDisplayName(element, list[x]).." bend costs {"..stones.." Air Stones} and require {Reset "..totaltasks.."} or higher to learn, do you have the stones and the required Reset level?"), cid)			
					dobraAtual[cid] = list[x]
					talkState[talkUser] = 5
					return true
				else
					local current, price = list[x]:lower(), math.ceil(getFoldPrice(cid, list[x]))
					local nextStage = 4
					selfSay(getLangString(cid, "Hmm, the fold "..getFoldDisplayName(element, list[x]).." costs {"..price.."} gold coins or 1 bender scroll to learn, do you wanna pay with {gold} or {bender scroll}?", "Hmm, the fold "..getFoldDisplayName(element, list[x]).." costs {"..price.."} gold coins or 1 bender scroll to learn, do you wanna pay with {gold} or {bender scroll}?"), cid)
					nextStage = 3
					dobraAtual[cid] = list[x]
					talkState[talkUser] = nextStage 
					sequenciaAtual[cid] = 0
					return true
				end
            end
        end
            local list = getListLearnFold(cid, true, true)
			selfSay(getLangString(cid, "Only the folds i said earlier are available for learning. List: {"..list.."}.", "Only the folds i said earlier are available for learning. List: {"..list.."}."), cid)
			talkState[talkUser] = 2 
        return true

    elseif talkState[talkUser] == 3 and sequenciaAtual[cid] ~= PENULT and sequenciaAtual[cid] ~= LAST then
    local msg = string.lower(msg)
        if msgcontains(msg, "gold") or msgcontains(msg, "scroll") or msgcontains(msg, "yes") or msgcontains(msg, "sim") then
			if not msgcontains(msg, "scroll") then 
				msg = "gold"
			end
            local current = dobraAtual[cid]

            local canLearn = canBuyFold(cid, current, msgcontains(msg, "gold") and 1 or 2)

            if canLearn == true then
                selfSay(getLangString(cid, "Congratulations! Use this fold with extreme caution and wisdom.", "Congratulations! Use this fold with extreme caution and wisdom."), cid)
            else
                selfSay(getLangString(cid, canLearn[1], canLearn[2]), cid)
            end
        else
            selfSay(getLangString(cid, "Ok, I think.", "Ok, I think."), cid)
        end

        talkState[talkUser] = 2 
        return true
   elseif talkState[talkUser] == 4 and sequenciaAtual[cid] ~= PENULT and sequenciaAtual[cid] ~= LAST then
    local msg = string.lower(msg)
        if msgcontains(msg, "yes") or msgcontains(msg, "sim") then
            local current = dobraAtual[cid]

            local canLearn = canBuyFold(cid, current, 2)

            if canLearn == true then
                selfSay(getLangString(cid, "Congratulations! Use this fold with extreme caution and wisdom.", "Congratulations! Use this fold with extreme caution and wisdom."), cid)
            else
                selfSay(getLangString(cid, canLearn[1], canLearn[2]), cid)
            end
        else
            selfSay(getLangString(cid, "Ok, I think.", "Ok, I think."), cid)
        end

       talkState[talkUser] = 1 
        return true
   elseif talkState[talkUser] == 5 then
    local msg = string.lower(msg)
        if msgcontains(msg, "yes") or msgcontains(msg, "sim") then
            local current = dobraAtual[cid]
			local sequencia = sequenciaAtual[cid]
            local canLearn = canBuyUltimateFold(cid, current, sequencia)

            if canLearn == true then
                selfSay(getLangString(cid, "Congratulations! Use this fold with extreme caution and wisdom.", "Congratulations! Use this fold with extreme caution and wisdom."), cid)
            else
                selfSay(getLangString(cid, canLearn[1], canLearn[2]), cid)
            end
        else
            selfSay(getLangString(cid, "Ok, I think.", "Ok, I think."), cid)
        end

       talkState[talkUser] = 1 
        return true
    
    end
	return true
end

function onGreet(cid) 
	talkState[cid] = 1 	
	sequenciaAtual[cid] = 0
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:addModule(FocusModule:new())
