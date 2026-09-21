-- ============================================================================
-- Fishing System (server) - resultado do minigame de pesca (opcode 103)
-- ----------------------------------------------------------------------------
-- Fluxo completo:
--   1. jogador usa a vara na agua     -> actions/scripts/fishing_rod.lua
--   2. servidor manda {action="open"} -> cliente abre a barra e a mira
--   3. jogador aperta espaco na hora  -> cliente manda {action="fish"}
--   4. este arquivo sorteia o peixe   -> {action="result"}
--   5. cliente fecha a janela         -> cliente manda {action="cancel"}
--
-- O QUE SAI NO ANZOL vem de FishSystem.rollFish (data/lib/fishSystem.lua):
-- quanto maior o ID do peixe, mais dificil. Skill de fishing baixa nem ve
-- os peixes grandes - por isso pescar e' a "carreira" da pessoa.
--
-- O handler do opcode 103 fica no dispatcher central
-- (creaturescripts/scripts/opcode.lua) - NUNCA registre um segundo
-- CreatureEvent chamado "ExtendedOpcode", ele seria ignorado.
-- ============================================================================

if type(json) ~= "table" then
  dofile(getDataDir() .. "lib/json.lua")
end

if type(FishSystem) ~= "table" then
  dofile(getDataDir() .. "lib/fishSystem.lua")
end

local FISHING_OPCODE = 103

-- Storages do sistema. Mude aqui se conflitarem com o seu servidor
-- (os mesmos numeros aparecem em actions/scripts/fishing_rod.lua).
local STORAGE_ACTIVE  = 47013   -- 1 = pescando agora
local STORAGE_WATER_X = 47015
local STORAGE_WATER_Y = 47016
local STORAGE_WATER_Z = 47017

local WORM_ID = 3976    -- worm (isca, gasta 1 por tentativa)

-- Efeitos do acerto.
local EFFECT_CATCH_WATER  = 152   -- na agua
local EFFECT_CATCH_PLAYER = 204   -- no jogador

-- Quantos "skill tries" cada peixe vale. Peixe maior = mais XP de fishing,
-- mas ainda devagar de proposito (a pessoa joga o dia todo pra subir).
local function fishingTries(fish)
  local t = 1
  if fish.tier >= 2 then t = 2 end
  if fish.tier >= 3 then t = 3 end
  if fish.tier >= 4 then t = 4 end
  if fish.tier >= 5 then t = 6 end
  return t
end

FishingSystem = {}

local function limparEstado(cid)
	setPlayerStorageValue(cid, STORAGE_ACTIVE, -1)
	setPlayerStorageValue(cid, STORAGE_WATER_X, -1)
	setPlayerStorageValue(cid, STORAGE_WATER_Y, -1)
	setPlayerStorageValue(cid, STORAGE_WATER_Z, -1)
end

local function responder(cid, dados)
	dados.action = "result"
	-- A HUD mostra quantos worms sobraram, entao o numero viaja em toda
	-- resposta -- e o que mantem o medalhao certo sem o cliente adivinhar.
	dados.worms = getPlayerItemCount(cid, WORM_ID)
	-- Mandar a skill junto deixa a HUD/barra mostrar o progresso sem precisar
	-- de outro opcode.
	dados.fishing = FishSystem.getFishingLevel(cid)
	doSendPlayerExtendedOpcode(cid, FISHING_OPCODE, json.encode(dados))
end

local function pescar(cid, acertou)
	-- Nao esta pescando: pacote atrasado ou forjado, ignora.
	if getPlayerStorageValue(cid, STORAGE_ACTIVE) ~= 1 then
		return
	end

	-- Sem isca acaba a pescaria na hora. `stop` faz o cliente fechar a janela
	-- em vez de esperar as tentativas restantes.
	if getPlayerItemCount(cid, WORM_ID) <= 0 then
		limparEstado(cid)
		responder(cid, {success = false, stop = true,
		               message = "You ran out of worms."})
		return
	end

	doPlayerRemoveItem(cid, WORM_ID, 1)

	-- Errou a mira: gastou a isca e pronto.
	if not acertou then
		responder(cid, {success = false, message = "The fish got away."})
		return
	end

	-- Acertou: sorteia o peixe conforme a skill de fishing.
	local fish = FishSystem.rollFish(cid)
	local adicionou = doPlayerAddItem(cid, fish.id, 1)

	-- Mochila cheia: devolve a isca em vez de cobrar por um peixe que o
	-- jogador nao recebeu.
	if adicionou < 1 then
		doPlayerAddItem(cid, WORM_ID, 1)
		responder(cid, {success = false,
		               message = "You have no room for the fish."})
		return
	end

	-- Skill de pesca so sobe em fisgada boa.
	doPlayerAddSkillTry(cid, SKILL_FISHING, fishingTries(fish))

	local x = tonumber(getPlayerStorageValue(cid, STORAGE_WATER_X)) or -1
	local y = tonumber(getPlayerStorageValue(cid, STORAGE_WATER_Y)) or -1
	local z = tonumber(getPlayerStorageValue(cid, STORAGE_WATER_Z)) or -1
	if x > 0 and y > 0 then
		doSendMagicEffect({x = x, y = y, z = z}, EFFECT_CATCH_WATER)
	end
	doSendMagicEffect(getCreaturePosition(cid), EFFECT_CATCH_PLAYER)

	-- Peixe lendario: avisa todo mundo (sensacao de conquista).
	if fish.tier >= 5 then
		doBroadcastMessage(getPlayerName(cid) .. " pescou um " .. fish.name .. "!", MESSAGE_STATUS_WARNING)
	end

	responder(cid, {success = true, tier = fish.tier, itemId = fish.id,
	                message = "You caught a " .. fish.name .. "!"})
end

-- Cliente mandou {action="fish", success=true/false} a cada tentativa.
function FishingSystem.onFish(cid, acertou)
	pescar(cid, acertou)
end

-- Cliente mandou {action="cancel"} (ESC / andou / acabaram as tentativas):
-- limpa o estado pra poder pescar de novo e para o efeito na agua.
function FishingSystem.onCancel(cid)
	if getPlayerStorageValue(cid, STORAGE_ACTIVE) == 1 then
		limparEstado(cid)
	end
end

-- Chame no logout (loginLogout/logout.lua): sem isso, deslogar no meio da
-- pescaria deixaria o jogador "pescando" pra sempre ao relogar.
function FishingSystem.onLogout(cid)
	limparEstado(cid)
end
