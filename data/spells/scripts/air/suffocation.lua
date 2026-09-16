local spellName = "air suffocation"
local cf = {atk = spellsInfo[spellName].atk, segundos = spellsInfo[spellName].segundos}

local MyLocal = {}
MyLocal.fireId = 13025
MyLocal.totalTime = cf.segundos
MyLocal.players = {}

-- Avatar: a magia inteira solta UM unico efeito, este (visual novo).
local SUFFOCATION_EFFECT = 392

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_AIRDAMAGE)

function onGetPlayerMinMaxValues(cid, level, magLevel)
    local min = (level+(magLevel/3)*3.3)+math.random(5, 10)
    local max = (level+(magLevel/3)*3.7)+math.random(10, 15)

	local dano = math.random(min, max)
	local atk = cf.atk
	if atk and type(atk) == "number" then 
		dano = dano * (atk/100)
		dano = dano+1
	end
	dano = remakeAirEarth(cid, dano)
    return -dano, -dano
end
setCombatCallback(combat, CALLBACK_PARAM_LEVELMAGICVALUE, "onGetPlayerMinMaxValues")
registerSpellStageEcho(combat)

local function sendFiresAround(cid)
    local playerPos = getCreaturePosition(cid)
    local poses = {{x=playerPos.x+1,y=playerPos.y,z=playerPos.z}, {x=playerPos.x-1,y=playerPos.y,z=playerPos.z},
                   {x=playerPos.x,y=playerPos.y+1,z=playerPos.z}, {x=playerPos.x,y=playerPos.y-1,z=playerPos.z},
                   {x=playerPos.x+1,y=playerPos.y-1,z=playerPos.z}, {x=playerPos.x+1,y=playerPos.y+1,z=playerPos.z},
                   {x=playerPos.x-1,y=playerPos.y+1,z=playerPos.z}, {x=playerPos.x-1,y=playerPos.y-1,z=playerPos.z}}
    for x = 1, #poses do
        local item = doCreateItem(MyLocal.fireId, poses[x])
        addEvent(removeTileItemById, MyLocal.totalTime*1000, getThingPos(item), MyLocal.fireId)
    end
end

local function sendDistanceEffect(cid, finish, target)
    if isCreature(cid) and isCreature(target) and not isInPz(cid) and not isInPz(target) then
        -- Avatar: o visual antigo (distance shoot 41 a cada tick + 211 no final)
        -- saiu; agora so' existe o efeito 392 mandado uma vez, no cast.
        local mypos = getCreaturePosition(cid)
		doSlow(cid, target, 10, 750)
		doCombat(cid, combat, numberToVariant(target))
        
        if finish then
            MyLocal.players[cid] = nil
            if isCreature(target) then
                local posTarget = getCreaturePosition(target)
               -- if getDistanceBetween(playerPos, posTarget) > 7 then
                --    doPlayerSendCancelEf(cid, "The target is too far, the fold was failed.")
                 --   return true
                --end
                setCreatureNoMoveTime(target, MyLocal.totalTime*1000, MyLocal.totalTime*500)
				if isPlayer(target) then 
					exhaustion.set(target, "stopDashs", 2) 
				end 
                --sendFiresAround(target)
            else
                doPlayerSendCancelEf(cid, "The target is gone, the fold was failed.")
                return true
            end
        end
    end
end

local AIR_FLOAT_OPCODE = 114

local function sendFloatToTarget(target, duration)
    local specs = getSpectators(getCreaturePosition(target), 12, 12)
    if specs then
        local payload = "float|" .. target .. "|" .. duration
        for _, spec in ipairs(specs) do
            if isPlayer(spec) then
                doSendPlayerExtendedOpcode(spec, AIR_FLOAT_OPCODE, payload)
            end
        end
    end
end

local function sendStopFloatToTarget(target)
    if not isCreature(target) then return end
    local specs = getSpectators(getCreaturePosition(target), 12, 12)
    if specs then
        local payload = "stopfloat|" .. target
        for _, spec in ipairs(specs) do
            if isPlayer(spec) then
                doSendPlayerExtendedOpcode(spec, AIR_FLOAT_OPCODE, payload)
            end
        end
    end
end

function onCastSpell(cid, var)
    if getSpellCancels(cid, "air") == true then
        return false
    end
  --  if MyLocal.players[cid] == nil then
        if getPlayerExaust(cid, "air", "suffocation") == false then
            return false
        end

            MyLocal.players[cid] = nil

        if cantReceiveDisable(cid, getCreatureTarget(cid)) then
            return false
        end

        if getPlayerHasStun(cid) then
			if getDobrasLevel(cid) >= 11 then
				doPlayerAddExaust(cid, "air", "suffocation", airExausted.suffocation-7)
			else
				doPlayerAddExaust(cid, "air", "suffocation", airExausted.suffocation)
			end
            return true
        end

        local target = getCreatureTarget(cid)
        local totalDuration = 150 * 18  -- 18 ticks * 150ms = 2700ms

        -- Trava o movimento do alvo desde o início
        doCreatureSetMoveImmuneTime(target, totalDuration + 200)

        -- Levita o alvo durante todo o tempo de dano
        sendFloatToTarget(target, totalDuration + 200)

        -- Interrompe a levitação ao fim do dano
        addEvent(sendStopFloatToTarget, totalDuration + 200, target)

        MyLocal.players[cid] = true

        -- Avatar: unico efeito da magia (392), no alvo
        if isCreature(target) then
            doSendMagicEffect(getCreaturePosition(target), SUFFOCATION_EFFECT)
        end

        for x = 1, 18 do
            addEvent(sendDistanceEffect, 150*x, cid, x == 18, target)
        end
        workAllCdAndAndPrevCd(cid, "air", "suffocation", nil, 1)

			if getDobrasLevel(cid) >= 11 then
				doPlayerAddExaust(cid, "air", "suffocation", airExausted.suffocation-7)
			else
				doPlayerAddExaust(cid, "air", "suffocation", airExausted.suffocation)
			end
        return true
    --else
     --   doPlayerSendCancelEf(cid, "You're already using this fold.")
      --  return false
    --end
end
