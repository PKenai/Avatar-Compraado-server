-- !outfit <lookType>[, addons[, head body legs feet]]
-- Veste a outfit pelo lookType (o ID da outfit no .dat/.spr do client), sem
-- passar pela janela de outfits. Mount, wings, aura, shader e as cores atuais
-- sao mantidos quando nao sao informados.
--
--   !outfit 1020                  -> troca so a outfit
--   !outfit 1020 3                -> outfit + addons
--   !outfit 1020 3 78 68 58 76    -> outfit + addons + head/body/legs/feet
--
-- Jogador so veste o que ja possui (mesma checagem da janela de outfits).
-- Staff (access >= MIN_ACCESS_STAFF) pode testar qualquer lookType do client.

local MIN_ACCESS_STAFF = 5
local MAX_LOOKTYPE = 65535
local MESSAGE_TYPE = MESSAGE_STATUS_CONSOLE_BLUE

local function sendMessage(cid, text)
  doPlayerSendTextMessage(cid, MESSAGE_TYPE, text)
end

local function usage(cid)
  sendMessage(cid, "Usage: !outfit <lookType>[, addons[, head body legs feet]]")
  sendMessage(cid, "Example: !outfit 1020 3    |    !outfit 136 3 78 68 58 76")
end

-- Aceita "1020 3" ou "1020,3" ou "1020, 3, 78, 68"; devolve nil se algum
-- token nao for um numero inteiro positivo.
local function parseNumbers(param)
  local values = {}
  for token in string.gmatch(param, "[^%s,;]+") do
    local value = tonumber(token)
    if not value or value ~= math.floor(value) or value < 0 then
      return nil
    end

    values[#values + 1] = value
  end

  return values
end

function onSay(cid, words, param, channel)
  local values = parseNumbers(param or "")
  if not values or #values < 1 or #values > 6 then
    usage(cid)
    return true
  end

  local lookType = values[1]
  if lookType < 1 or lookType > MAX_LOOKTYPE then
    sendMessage(cid, "Invalid lookType: " .. lookType .. " (use 1 to " .. MAX_LOOKTYPE .. ").")
    return true
  end

  local addons = values[2]
  if addons and addons > 3 then
    sendMessage(cid, "Invalid addons: " .. addons .. " (use 0 to 3).")
    return true
  end

  for index = 3, #values do
    if values[index] > 255 then
      sendMessage(cid, "Invalid color: " .. values[index] .. " (use 0 to 255).")
      return true
    end
  end

  if getPlayerAccess(cid) < MIN_ACCESS_STAFF then
    if not canPlayerWearOutfit(cid, lookType) then
      sendMessage(cid, "You do not own the outfit " .. lookType .. ".")
      return true
    end

    if addons and addons > 0 and not canPlayerWearOutfit(cid, lookType, addons) then
      sendMessage(cid, "You do not own the addons of the outfit " .. lookType .. ".")
      return true
    end
  end

  local outfit = getCreatureOutfit(cid)
  if not outfit then
    sendMessage(cid, "You cannot change your outfit right now.")
    return true
  end

  outfit.lookType = lookType
  outfit.lookTypeEx = 0

  if addons then
    outfit.lookAddons = addons
  end

  if values[3] then outfit.lookHead = values[3] end
  if values[4] then outfit.lookBody = values[4] end
  if values[5] then outfit.lookLegs = values[5] end
  if values[6] then outfit.lookFeet = values[6] end

  doCreatureChangeOutfit(cid, outfit)
  sendMessage(cid, "Outfit changed to lookType " .. lookType .. ".")
  return true
end
