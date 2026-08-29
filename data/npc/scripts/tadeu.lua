local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
npcHandler.talkRadius = 4
NpcSystem.parseParameters(npcHandler)
local talkState = {}

function onCreatureAppear(cid)        npcHandler:onCreatureAppear(cid)      end
function onCreatureDisappear(cid)       npcHandler:onCreatureDisappear(cid)     end
function onCreatureSay(cid, type, msg)    npcHandler:onCreatureSay(cid, type, msg)  end
function onThink()              npcHandler:onThink()            end
function onPlayerEndTrade(cid)        npcHandler:onPlayerEndTrade(cid)      end
function onPlayerCloseChannel(cid)      npcHandler:onPlayerCloseChannel(cid)    end
npcHandler:setMessage(MESSAGE_GREET, "")

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end
	return true
end

function onGreet(cid) 
	selfSay(getLangString(cid, "Hello "..getCreatureName(cid).."! How can i help you? Do you want to see my {offers}?", "Olá "..getCreatureName(cid).."! Você deseja ver minhas {ofertas}?"), cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())

-- === CAPAS (19158 a 19166) ===
shopModule:addBuyableItem('capa de viajante', 5000, 19158, '')
shopModule:addSellableItem('capa de viajante', 2500, 19158, '')

shopModule:addBuyableItem('capa reforcada', 15000, 19159, '')
shopModule:addSellableItem('capa reforcada', 7500, 19159, '')

shopModule:addBuyableItem('capa resistente', 35000, 19160, '')
shopModule:addSellableItem('capa resistente', 17500, 19160, '')

shopModule:addBuyableItem('capa aprimorada', 70000, 19161, '')
shopModule:addSellableItem('capa aprimorada', 35000, 19161, '')

shopModule:addBuyableItem('capa nobre', 130000, 19162, '')
shopModule:addSellableItem('capa nobre', 65000, 19162, '')

shopModule:addBuyableItem('capa de protecao', 220000, 19163, '')
shopModule:addSellableItem('capa de protecao', 110000, 19163, '')

shopModule:addBuyableItem('capa majestosa', 380000, 19164, '')
shopModule:addSellableItem('capa majestosa', 190000, 19164, '')

shopModule:addBuyableItem('capa gloriosa', 650000, 19165, '')
shopModule:addSellableItem('capa gloriosa', 325000, 19165, '')

shopModule:addBuyableItem('capa soberana', 1000000, 19166, '')
shopModule:addSellableItem('capa soberana', 500000, 19166, '')
