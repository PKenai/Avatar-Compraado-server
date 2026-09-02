dofile(getDataDir().."creaturescripts/scripts/creature_manager.lua")

-- Carrega o sistema de crafting server-side (uma vez so)
if not _craftingSystemLoaded and type(CraftingSystem) ~= "table" then
  dofile(getDataDir().."lib/craftingSystem.lua")
  _craftingSystemLoaded = true
end

-- Carrega o tooltip lib (uma vez so)
if not _tooltipLibLoaded and type(TooltipLib) ~= "table" then
  dofile(getDataDir().."lib/tooltipLib.lua")
  _tooltipLibLoaded = true
end

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
local opcodeTutorial = 220
local opcodeDepotSearch = 233
local storageTutorial = 42001

function onExtendedOpcode(cid, opcode, buffer)
	-- Defensive: bad/partial packets must never take the server down.
	if type(buffer) ~= "string" then
		buffer = ""
	end

	local ok, err = pcall(function()
		if opcode == opcodeMarket then
			-- Ignore market requests during the first 5 seconds after login
			local loginTime = getPlayerStorageValue(cid, "timeLogin")
			if type(loginTime) == "number" and loginTime > 0 and os.time() - loginTime < 5 then
				return true
			end
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
		elseif opcode == 212 then
			-- Momo Pouch: get / toggle / setitem (client: modules/game_momo)
			if type(momoHandleOpcode) == "function" then
				momoHandleOpcode(cid, buffer)
			end
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
		elseif opcode == opcodeDepotSearch then
			-- Busca de itens no depósito / pegar item (client: container nativo)
			local parts = buffer:explode(">")
			if parts[1] == "search" and type(DepotSearch) == "table" and type(DepotSearch.search) == "function" then
				DepotSearch.search(cid, parts[2] or "")
			elseif parts[1] == "take" and type(DepotSearch) == "table" and type(DepotSearch.take) == "function" then
				DepotSearch.take(cid, tonumber(parts[2]), tonumber(parts[3]))
			end
		elseif opcode == opcodeTutorial then
			-- Tutorial do primeiro login (client: modules/Game_firstlogin)
			if buffer == "get" then
				local done = getPlayerStorageValue(cid, storageTutorial)
				doSendPlayerExtendedOpcode(cid, opcodeTutorial, done > 0 and "1" or "0")
			elseif buffer == "set" then
				setPlayerStorageValue(cid, storageTutorial, 1)
			elseif buffer == "reset" then
				setPlayerStorageValue(cid, storageTutorial, -1)
			end
		elseif opcode == 215 then
			-- Potion Craft System
			if type(PotionCraft) == "table" and type(PotionCraft.onOpcode) == "function" then
				PotionCraft.onOpcode(cid, buffer)
			end
		elseif opcode == 105 then
			-- Tooltips (game_tooltips)
			print(string.format("[TOOLTIPS] opcode=105 cid=%s buffer=%s", tostring(cid), tostring(buffer)))
			if type(TooltipLib) == "table" and type(TooltipLib.onTooltipRequest) == "function" then
				TooltipLib.onTooltipRequest(cid, buffer)
			else
				print("[TOOLTIPS] ERROR: TooltipLib not loaded")
			end
		elseif opcode == 106 then
			-- Crafting System (game_crafting) - 100% Server-Side
			if type(CraftingSystem) ~= "table" then
				dofile(getDataDir().."lib/craftingSystem.lua")
			end
			if type(CraftingSystem) == "table" then
				-- NPC envia "open>profId" para abrir a janela
				if type(buffer) == "string" and string.sub(buffer, 1, 5) == "open>" then
					local profId = tonumber(string.sub(buffer, 6)) or 1
					CraftingSystem.sendWindow(cid, profId)
				else
					-- Client envia JSON com acao de craft
					CraftingSystem.onOpcode(cid, buffer)
				end
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
