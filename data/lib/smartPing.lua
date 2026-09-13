-- ============================================================================
-- Smart Ping (server) - marcacao de localizacao para a party (opcode 100)
-- ----------------------------------------------------------------------------
-- Fluxo completo:
--   1. jogador da middle click no mapa   -> actions? nao: cliente manda "x,y,z"
--   2. este arquivo valida, aplica cooldown e repassa para a party
--   3. quem clicou ja ve o efeito desenhado pelo proprio cliente
--      (g_map.addEffect em modules/game_ping/ping.lua), entao o servidor NAO
--      reenvia o efeito para ele - senao apareceria efeito dobrado.
--
-- O handler do opcode 100 fica no dispatcher central
-- (creaturescripts/scripts/opcode.lua), igual pesca (103), crafting (106),
-- cooking (107) e companhia. NUNCA registre um segundo CreatureEvent de
-- extended opcode so para isso, ele so duplicaria o trabalho.
-- ============================================================================

local PING_OPCODE = 100        -- tem que ser o mesmo de modules/game_ping/ping.lua

-- O client desenha o effect pelo id cru que chega no pacote, e o
-- ProtocolGame::AddMagicEffect escreve (type + 1) na rede. Como quem clica ve o
-- effect 56 desenhado localmente pelo client (Effect:setId em ping.lua), o server
-- tem que mandar 55 para o pacote carregar 56 - assim quem recebe ve exatamente o
-- mesmo efeito de quem clicou. Se mudar o id no client, mude aqui junto.
local PING_EFFECT_CLIENT = 56  -- o id que o client desenha
local PING_EFFECT = PING_EFFECT_CLIENT - 1 -- o que vai no pacote (server soma 1)
local PING_COOLDOWN = 1        -- segundos entre dois pings do mesmo jogador
local STORAGE_COOLDOWN = 45000 -- storage do cooldown (mude se conflitar)

SmartPing = {}

-- "1234,5678,7" -> {x=1234, y=5678, z=7} / nil se o pacote estiver malformado
local function parsePosition(buffer)
  if type(buffer) ~= "string" or #buffer == 0 then
    return nil
  end

  local parts = buffer:explode(",")
  if #parts ~= 3 then
    return nil
  end

  local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
  if not x or not y or not z then
    return nil
  end

  -- Posicao fora do mapa: pacote forjado, nao vale a pena confiar
  if x < 0 or y < 0 or z < 0 or z > 15 then
    return nil
  end

  return {x = x, y = y, z = z}
end

function SmartPing.onOpcode(cid, buffer)
  if not isPlayer(cid) then
    return false
  end

  local position = parsePosition(buffer)
  if not position then
    return false
  end

  local members = getPartyMembers(cid)
  if type(members) ~= "table" then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_SMALL, "You need to be in a party to use ping.")
    return true
  end

  local now = os.time()
  local lastPing = tonumber(getPlayerStorageValue(cid, STORAGE_COOLDOWN)) or -1
  if now - lastPing < PING_COOLDOWN then
    return true -- ainda em cooldown: ignora sem falar nada
  end

  setPlayerStorageValue(cid, STORAGE_COOLDOWN, now)

  local author = getCreatureName(cid)
  for _, member in ipairs(members) do
    if isPlayer(member) then
      if member ~= cid then
        doSendMagicEffect(position, PING_EFFECT, member)
      end

      doPlayerSendTextMessage(member, MESSAGE_EVENT_ADVANCE, author .. " marked this location!")
    end
  end

  return true
end
