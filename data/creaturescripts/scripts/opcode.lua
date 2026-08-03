dofile(getDataDir().."creaturescripts/scripts/creature_manager.lua")

local function changeAutoloot(cid, value)
	if type(value) ~= "string" or (value ~= "false" and value ~= "true") then
		return true
	end
	if value == "true" then
		setPlayerStorageValue(cid, "autolootdesativo", 0)
	else
		setPlayerStorageValue(cid, "autolootdesativo", 1)
	end
end

local opcodeMarket = 230
local opcodeReward = 247

function onExtendedOpcode(cid, opcode, buffer)
	-- Defensive: bad/partial packets must never take the server down.
	if type(buffer) ~= "string" then
		buffer = ""
	end

	local ok, err = pcall(function()
		if opcode == opcodeMarket then
			local parts = buffer:explode(">")
			local action = parts[1]

			if ( action == "refresh" ) then
				Market.sendOfferOtclient(cid, 1, nil, parts[2] or "all")
			elseif ( action == "getOffer" ) then
				Market.sendOfferOtclient(cid, tonumber(parts[2]) or 1, nil, parts[3] or "all")
			elseif ( action == "search" ) then
				local term = parts[2] or ""
				local pag  = tonumber(parts[3]) or 1
				Market.sendSearchOtclient(cid, term, pag, parts[4] or "all")
			elseif ( action == "details" ) then
				doSendPlayerExtendedOpcode(cid, Market.opcodes, "details>"..Market.getOfferDescription(tonumber(parts[2])))
			end
		elseif opcode == 40 then
			if getPlayerLevel(cid) < 20 or getPlayerStorageValue(cid, "canAttackable") == 1 then 
				doSendPlayerExtendedOpcode(cid, 91, "inativo")
			else 
				doSendPlayerExtendedOpcode(cid, 91, "ativo")
			end
			doSendPlayerExtendedOpcode(cid, 40, getAtributosString(cid))
		elseif opcode == opcodeReward then
			if ( buffer == "send" ) then
				Reward.sendRewards(cid)
			elseif ( buffer == "get" ) then
				Reward.getReward(cid)
			elseif ( buffer == "date" ) then
				Reward.sendRewards(cid)
			end
		elseif opcode == 115 then
			-- Party Damage Meter (DPS) - request/reset
			if type(partyDamageOnOpcode) == "function" then
				partyDamageOnOpcode(cid, buffer)
			end
		elseif opcode == 116 then
			-- Magic Meter - damage per spell, request/reset (meter always counts)
			if type(magicMeterOnOpcode) == "function" then
				magicMeterOnOpcode(cid, buffer)
			end
		elseif opcode == 131 then
			changeAutoloot(cid, buffer)
		elseif opcode == 210 then
			-- Water Heal target: client envia o nome do player antes de castar
			if type(buffer) == "string" and #buffer > 0 then
				local target = getPlayerByNameWildcard(buffer)
				if target and isPlayer(target) then
					setPlayerStorageValue(cid, 87654, target)
				end
			end
		elseif opcode == 6 then
			-- MapShader / Appa flight fade sync from client
			if appaFlightOnFadeDone and (buffer == "fade_out_done" or buffer == "exit_fade_done" or buffer == "fade_in_done") then
				appaFlightOnFadeDone(cid, buffer)
			end
		elseif opcode == 135 then
			-- Farm System (Creature Manager)
			if type(handleFarmOpcode) == "function" then
				handleFarmOpcode(cid, buffer)
			end
		elseif opcode > 0 and opcode < 4 then
			local handler = onReceiveOpCode and onReceiveOpCode[opcode]
			if type(handler) == "function" then
				handler(cid, opcode, buffer)
			end
		end
	end)

	if not ok then
		print(string.format("[opcode.lua] error opcode=%s buffer=%s err=%s", tostring(opcode), tostring(buffer), tostring(err)))
	end
	return true
end
