-- ============================================================================
-- Vara de pesca -- usar na agua abre o minigame no cliente.
-- ----------------------------------------------------------------------------
-- Fluxo completo do sistema:
--   1. jogador usa a vara na agua        -> este arquivo
--   2. servidor manda {action="open"}    -> cliente abre a barra e a mira
--   3. jogador aperta espaco na hora     -> cliente manda {action="fish"}
--   4. servidor entrega (ou nao) o peixe -> data/lib/fishingLib.lua (o opcode
--      103 e tratado no dispatcher central creaturescripts/scripts/opcode.lua)
--
-- Os dois lados conversam pelo extended opcode 103.

if type(json) ~= "table" then
  dofile(getDataDir() .. "lib/json.lua")
end

local FISHING_OPCODE = 103

-- Storages usadas pelo sistema. Mude aqui se conflitarem com o seu servidor
-- (os mesmos numeros aparecem em data/lib/fishingLib.lua).
local STORAGE_ACTIVE  = 47013   -- 1 = pescando agora
local STORAGE_WATER_X = 47015
local STORAGE_WATER_Y = 47016
local STORAGE_WATER_Z = 47017

local WORM_ID = 3976    -- worm (a isca)

-- Quantas tentativas o minigame da por lance. Cada tentativa gasta 1 worm.
local ATTEMPTS = 5

-- Efeito que sai na agua enquanto a linha esta lancada.
local WATER_EFFECT = 203
local WATER_EFFECT_INTERVAL = 2000

-- Todo sqm de agua onde da pra pescar. Se o seu mapa usa outros ids de agua,
-- e aqui que eles entram.
local WATER = {
	[4608]=true,[4609]=true,[4610]=true,[4611]=true,[4612]=true,[4613]=true,
	[4614]=true,[4615]=true,[4616]=true,[4617]=true,[4618]=true,[4619]=true,
	[4620]=true,[4621]=true,[4622]=true,[4623]=true,[4624]=true,[4625]=true,
	[4820]=true,[4821]=true,[4822]=true,[4823]=true,[4824]=true,[4825]=true,
	[490]=true,[491]=true,[492]=true,[493]=true,
	[618]=true,[619]=true,[620]=true,[621]=true,[622]=true,[623]=true,
	[624]=true,[625]=true,[626]=true,[627]=true,[628]=true,[629]=true,
	[4664]=true,[4665]=true,[4666]=true,
	[7236]=true,[10499]=true,[3258]=true,
}

-- Efeito piscando na agua enquanto a linha esta lancada. Se re-agenda sozinho
-- e para quando a storage zera (cancel do cliente / logout), entao nao sobra
-- timer rodando depois que o jogador fecha a janela.
local function efeitoNaAgua(cid)
	if getPlayerStorageValue(cid, STORAGE_ACTIVE) ~= 1 then return end

	local x = tonumber(getPlayerStorageValue(cid, STORAGE_WATER_X)) or -1
	local y = tonumber(getPlayerStorageValue(cid, STORAGE_WATER_Y)) or -1
	local z = tonumber(getPlayerStorageValue(cid, STORAGE_WATER_Z)) or -1
	if x > 0 and y > 0 then
		doSendMagicEffect({x = x, y = y, z = z}, WATER_EFFECT)
	end

	addEvent(efeitoNaAgua, WATER_EFFECT_INTERVAL, cid)
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
	-- Alvo tem que ser agua. Devolver false deixa o clique cair no
	-- comportamento padrao do item em vez de "sorry, not possible".
	if not itemEx or not WATER[itemEx.itemid] then
		return false
	end

	if getPlayerStorageValue(cid, STORAGE_ACTIVE) == 1 then
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, "You are already fishing.")
		return true
	end

	if getPlayerItemCount(cid, WORM_ID) <= 0 then
		doPlayerSendCancel(cid, "You need worms to fish.")
		doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
		return true
	end

	-- O resultado do minigame volta como extended opcode no dispatcher
	-- central (opcode.lua). O evento ja e registrado no login, mas garantir
	-- aqui nao custa nada.
	registerCreatureEvent(cid, "ExtendedOpcode")

	setPlayerStorageValue(cid, STORAGE_ACTIVE, 1)
	setPlayerStorageValue(cid, STORAGE_WATER_X, toPosition.x)
	setPlayerStorageValue(cid, STORAGE_WATER_Y, toPosition.y)
	setPlayerStorageValue(cid, STORAGE_WATER_Z, toPosition.z)

	doSendMagicEffect(toPosition, WATER_EFFECT)
	efeitoNaAgua(cid)

	-- wormId vai como CLIENT id: o medalhao da HUD desenha o sprite, e o
	-- cliente so conhece client ids.
	doSendPlayerExtendedOpcode(cid, FISHING_OPCODE, json.encode({
		action  = "open",
		ticks   = ATTEMPTS,
		worms   = getPlayerItemCount(cid, WORM_ID),
		wormId  = getItemInfo(WORM_ID).clientId,
	}))

	return true
end