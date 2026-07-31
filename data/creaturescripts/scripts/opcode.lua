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

-- Temporary: market opcode 230 AVs inside lua51.dll on this VS2022 build.
-- Keep login stable; re-enable after root cause is confirmed.
local MARKET_SAFE_MODE = true

local function marketTrace(msg)
	print("[market] " .. tostring(msg))
	if type(crashLog) == "function" then
		crashLog("[market] " .. tostring(msg))
	end
	local f = io.open("market_trace.log", "a")
	if f then
		f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. tostring(msg) .. "\n")
		f:flush()
		f:close()
	end
end

function onExtendedOpcode(cid, opcode, buffer)
	-- Defensive: bad/partial packets must never take the server down.
	if type(buffer) ~= "string" then
		buffer = ""
	end

	local ok, err = pcall(function()
		if opcode == opcodeMarket then
			marketTrace("enter buffer=" .. buffer)
			if MARKET_SAFE_MODE then
				-- Empty list only — no DB / getItemInfo / table.tostring of offers.
				marketTrace("safe-mode send empty")
				doSendPlayerExtendedOpcode(cid, opcodeMarket, "create>0>{}")
				marketTrace("safe-mode done")
				return
			end
			local parts = buffer:explode(">")
			local action = parts[1]
			local result = tonumber(parts[2])
			marketTrace("action=" .. tostring(action) .. " pag=" .. tostring(result))
			if ( action == "refresh" ) then
			  Market.sendOfferOtclient(cid, 1)
			elseif ( action == "getOffer" ) then
			  Market.sendOfferOtclient(cid, result or 1)
			elseif ( action == "details" ) then
			  doSendPlayerExtendedOpcode(cid, Market.opcodes, "details>"..Market.getOfferDescription(result))
			end
			marketTrace("leave ok")
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
