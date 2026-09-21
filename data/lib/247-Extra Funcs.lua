exhaustion =
{
	check = function (cid, storage)
		-- O valor pode voltar como string (storages com chave string no engine);
		-- comparar string com os.time() estourava "attempt to compare number
		-- with string" a cada onThink. Sempre converte antes de comparar.
		local value = tonumber(getPlayerStorageValue(cid, storage)) or -1
		return value >= os.time()
	end,

	get = function (cid, storage)
		local exhaust = (tonumber(getPlayerStorageValue(cid, storage)) or -1)+1
		if(exhaust > 0) then
			local left = exhaust - os.time()
			if(left >= 0) then
				return left
			end
		end

		return false
	end,

	set = function (cid, storage, time)
                if time > 1 then
				time = time-1
				end
		setPlayerStorageValue(cid, storage, os.time() + time)
	end,
        add = function (cid, storage, addtime)
           if not exhaustion.check(cid, storage) then
           return exhaustion.set(cid, storage, addtime)
           end
           local old = exhaustion.get(cid, storage)
           old = old+addtime
           return exhaustion.set(cid, storage, old)
        end,
	make = function (cid, storage, time)
		local exhaust = exhaustion.get(cid, storage)
		if(not exhaust) then
			exhaustion.set(cid, storage, time)
			return true
		end

		return false
	end
}

function getPlayerCoins(cid)
if not isPlayer(cid) then return false end 
local coins = db.getResult("SELECT `premium_points` FROM `accounts` WHERE `id` = "..getPlayerAccountId(cid)..";")
local result = coins:getDataInt("premium_points")
return result
end

function doSlow(cid, target, value, time, effect)
 local speed = getCreatureSpeed(target)
 if speed < 30 then
  return true
 end
 local newspeed = speed*(1-(value/100))
 if newspeed < 30 then 
  return true
 end
 local perdida = speed - newspeed

 -- PlayerSpeed.tempSlow guarda o valor, GARANTE a devolucao (addEvent +
 -- varredura no onThink) e nunca deixa a velocidade chegar a 0 (speed <= 0
 -- cancela a walk no servidor). O addEvent sozinho era o furo: se o restore
 -- se perdia, o personagem ficava abaixo da base pra sempre - "paralisado"
 -- ate' o relogin.
 if type(time) ~= "number" or time <= 0 then
  time = 3000 -- sem tempo valido o addEvent antigo estourava: usa o padrao
 end

 if type(PlayerSpeed) == "table" and PlayerSpeed.tempSlow then
  PlayerSpeed.tempSlow(target, math.floor(perdida), time)
 else
  doChangeSpeed(target, -perdida)
  addEvent(function()
                if isCreature(target) then
                    doChangeSpeed(target, perdida)
                end
            end, time)
 end

 if effect then 
  local targpos = getThingPos(target)
  doSendMagicEffect({x=targpos.x+1, y=targpos.y+1, z=targpos.z}, effect)
 end 
return true
end

function isInPz(cid)
	local pos = getCreaturePosition(cid)
return getTileInfo(pos).protection
end

function getAtributosString(cid)
local atributosList = {"health", "bend", "speed", "dodge"}
local pendentes = getPlayerStorageValue(cid, "pendentes")
if type(pendentes) ~= "number" or pendentes < 0 then
	pendentes = 0
end
local string = pendentes.. ", 0"
	for i = 1, #atributosList do
		local storageAtributo = atributosList[i] .. "value"
		local valor = getPlayerStorageValue(cid, storageAtributo)
		valor = tonumber(valor) or 0 -- storage string-keyed volta como string apos relog
		if valor < 0 then valor = 0 end -- storage nunca setado volta -1
		string = string.. ", "..valor..""
		-- getCostByValue pode devolver nil em borda (ex: dodge -1); sem o "or"
		-- a concatenacao estourava "attempt to concatenate a nil value" no login.
		local custo = getCostByValue(valor, atributosList[i]) or 99
		string = string.. ", "..custo..""
	end
	return string
end

function getCostByValue(value, att)
	if not tonumber(value) then 
		print("[Alerta] getCostByValue retornando 99 em algum caso errado")
		return 99
	end
	if att == "health" or att == "speed" then 
		if value <= 15 then
			return 1
		elseif value <= 25 then
			return 2
		elseif value <= 40 then
			return 3
		elseif value <= 50 then
			return 4
		elseif value <= 85 then
			return 5
		else
			return 8
		end
	elseif att == "bend" then 
	    if value >= 0 and value <= 19 then
			return 1
		elseif value >= 20 and value <= 29 then
			return 2
		elseif value >= 30 and value <= 49 then
			return 4
		elseif value >= 50 and value <= 59 then
			return 7
		elseif value >= 60 and value <= 69 then
			return 10
		elseif value >= 70 then
			return 15
		end
	elseif att == "dodge" then 
		-- +1 para pegar o custo do PROXIMO ponto. Valor -1 (storage ausente)
		-- virava indice 0 em dodgeValues, ou seja nil: quem concatenasse isso
		-- quebrava. Indice fora de 1..#dodgeValues agora cai no 99 explicito.
		value = math.floor(tonumber(value) or 0)+1
		local dodgeValues = {1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 10}
		if value >= 1 and value <= 15 then
			return dodgeValues[value]
		else
			return 99
		end
	end 
		print("[Alerta] getCostByValue retornando 99 em algum caso errado")
	return 99
end 

function doPlayerCancelFollow(cid)
	return true 
end 

function adjustDirection(dir)
local finaldir = dir-1
if finaldir == -1 then 
return 3
elseif finaldir == 4 then 
return 0
end 
return finaldir
end 
function returnPositionByCoord(pos, linha, coluna, dir)
return getPosByDir(getPosByDir(pos, dir, 6-linha), adjustDirection(dir), 6-coluna)
end
function changeOrNot(change, value, compr)
if change then 
return (compr-value)
end
return 0
end
function getPositionsByTable(pos, tabela, dir, compr, tabelas)
	local poses = {}
	for i = 1, tabelas do
	table.insert(poses, {})
	end
	local linhas = #tabela
	local changelinhas, changecolunas = false, false
	if linhas <= compr then 
		changelinhas = true 
	end 

	for i = 1, linhas do 
		local colunas = #tabela[i]
		if colunas <= compr then 
			changecolunas = true 
		end 
		for j = 1, colunas do
			if tabela[i][j] > 0 then 
				local posf = returnPositionByCoord({x=pos.x, y=pos.y, z=pos.z}, i+(changeOrNot(changelinhas, linhas, compr)), j+(changeOrNot(changecolunas, colunas, compr)), dir)
				table.insert(poses[tabela[i][j]], posf)
			end 
		end
	end
	return poses
end

function getRealMaxHp(cid)
local base = 110
local fromLevel = getPlayerLevel(cid)*30
local vitality = tonumber(getPlayerStorageValue(cid, "healthvalue")) or 0
if vitality <= 0 then vitality = 0 end
local fromVit = vitality*50
local fromCrystal = getPlayerStorageValue(cid, "pointsUsedInLifeCrystal")
if fromCrystal <= 0 then 
	fromCrystal = 0
end

return base + fromLevel + fromVit + fromCrystal
end

function getRealMaxMana(cid)
local base = 95
local fromLevel = getPlayerLevel(cid)*5
local vitality = tonumber(getPlayerStorageValue(cid, "speedvalue")) or 0
if vitality <= 0 then vitality = 0 end
local fromVit = vitality*20

return base + fromLevel + fromVit
end

-- ============================================================
-- applyFloat(cid, duration)
-- Faz a criatura 'cid' flutuar visivelmente por 'duration' ms
-- no client de todos os jogadores que estiverem no range.
-- Opcode 114 = game_specialfx no Avatar Client
-- ============================================================
local SPECIALFX_OPCODE = 114

function applyFloat(cid, duration)
    if not isCreature(cid) then return end
    duration = duration or 5000

    local targetId = getCreatureId and getCreatureId(cid) or cid
    local pos = getCreaturePosition(cid)
    if not pos then return end

    local specs = getSpectators(pos, false, true, 10, 10, 8, 8)
    if not specs then return end

    for _, spec in ipairs(specs) do
        if isPlayer(spec) then
            doSendPlayerExtendedOpcode(spec, SPECIALFX_OPCODE, "float|" .. targetId .. "|" .. duration)
        end
    end
end

function stopFloat(cid)
    if not isCreature(cid) then return end

    local targetId = getCreatureId and getCreatureId(cid) or cid
    local pos = getCreaturePosition(cid)
    if not pos then return end

    local specs = getSpectators(pos, false, true, 10, 10, 8, 8)
    if not specs then return end

    for _, spec in ipairs(specs) do
        if isPlayer(spec) then
            doSendPlayerExtendedOpcode(spec, SPECIALFX_OPCODE, "stopfloat|" .. targetId)
        end
    end
end