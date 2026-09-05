-- Koin - vendedor de varinhas de treino
-- Abre a janela de trade (como o Kurt) e cobra 5x Moeda Avatar (18340) por varinha.

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)

local COIN_AVATAR = 18340   -- Moeda Avatar
local COST = 5              -- Moedas Avatar por varinha
local WAND_CHARGES = 3500   -- cargas de cada varinha

function onCreatureAppear(cid)          npcHandler:onCreatureAppear(cid)        end
function onCreatureDisappear(cid)       npcHandler:onCreatureDisappear(cid)     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg) end
function onThink()                      npcHandler:onThink()                    end
function onPlayerEndTrade(cid)          npcHandler:onPlayerEndTrade(cid)        end
function onPlayerCloseChannel(cid)      npcHandler:onPlayerCloseChannel(cid)    end
npcHandler:setMessage(MESSAGE_GREET, "")

-- ShopModule registra a palavra-chave de trade ("trade"/"oferta") e abre a janela.
local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

-- Itens da janela de trade (subType = cargas; pagamento custom abaixo).
npcHandler.shopItems[18336] = {buyPrice = COST, sellPrice = -1, subType = 1, realName = 'Water Training Wand'}
npcHandler.shopItems[18337] = {buyPrice = COST, sellPrice = -1, subType = 1, realName = 'Fire Training Wand'}
npcHandler.shopItems[18338] = {buyPrice = COST, sellPrice = -1, subType = 1, realName = 'Air Training Wand'}
npcHandler.shopItems[18339] = {buyPrice = COST, sellPrice = -1, subType = 1, realName = 'Earth Training Wand'}

-- Pagamento em Moeda Avatar (18340) em vez de gold. Retorna false para
-- impedir o ShopModule de cobrar gold.
function onBuy(cid, itemid, subType, amount, ignoreCap, inBackpacks)
  amount = amount or 1
  local totalCost = COST * amount

  if getPlayerItemCount(cid, COIN_AVATAR) < totalCost then
    doPlayerSendCancel(cid, "You need "..totalCost.." Moedas Avatar to buy that.")
    return false
  end

  local backpack = 1988
  local a, b = doNpcSellItem(cid, itemid, amount, WAND_CHARGES, ignoreCap, inBackpacks, backpack)
  if a < amount then
    doPlayerSendCancel(cid, "You do not have enough space.")
    return false
  end

  doPlayerRemoveItem(cid, COIN_AVATAR, totalCost)
  doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "You bought "..amount.." "..getItemNameById(itemid).." for "..totalCost.." Moedas Avatar.")
  return false
end
npcHandler:setCallback(CALLBACK_ONBUY, onBuy)

-- Koin não compra itens de volta.
function onSell(cid, itemid, subType, amount, ignoreCap, inBackpacks)
  doPlayerSendCancel(cid, "I do not buy items.")
  return false
end
npcHandler:setCallback(CALLBACK_ONSELL, onSell)

function creatureSayCallback(cid, type, msg)
  if not npcHandler:isFocused(cid) then
    return false
  end
  msg = msg:lower()

  if msgcontains(msg, "wand") or msgcontains(msg, "varinha") or msgcontains(msg, "moeda") or msgcontains(msg, "coin") then
    selfSay("Say {trade} to see my training wands!", cid)
    return true
  end

  return true
end

function onGreet(cid)
  selfSay("Hello "..getCreatureName(cid).."! I sell {training wands} for 5 {Moeda Avatar} each. Say {trade} to see my offers!", cid)
  return true
end

npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
