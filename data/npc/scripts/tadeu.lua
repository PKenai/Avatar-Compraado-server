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

-- === CAPAS (19158 a 19167) ===
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

shopModule:addBuyableItem('capa das nacoes', 1500000, 19167, '')
shopModule:addSellableItem('capa das nacoes', 750000, 19167, '')

-- === CALCAS (19169 a 19178) ===
shopModule:addBuyableItem('calca de viajante', 4000, 19169, '')
shopModule:addSellableItem('calca de viajante', 2000, 19169, '')

shopModule:addBuyableItem('calca reforcada', 12000, 19170, '')
shopModule:addSellableItem('calca reforcada', 6000, 19170, '')

shopModule:addBuyableItem('calca resistente', 28000, 19171, '')
shopModule:addSellableItem('calca resistente', 14000, 19171, '')

shopModule:addBuyableItem('calca aprimorada', 55000, 19172, '')
shopModule:addSellableItem('calca aprimorada', 27500, 19172, '')

shopModule:addBuyableItem('calca nobre', 100000, 19173, '')
shopModule:addSellableItem('calca nobre', 50000, 19173, '')

shopModule:addBuyableItem('calca de protecao', 175000, 19174, '')
shopModule:addSellableItem('calca de protecao', 87500, 19174, '')

shopModule:addBuyableItem('calca majestosa', 300000, 19175, '')
shopModule:addSellableItem('calca majestosa', 150000, 19175, '')

shopModule:addBuyableItem('calca gloriosa', 500000, 19176, '')
shopModule:addSellableItem('calca gloriosa', 250000, 19176, '')

shopModule:addBuyableItem('calca soberana', 800000, 19177, '')
shopModule:addSellableItem('calca soberana', 400000, 19177, '')

shopModule:addBuyableItem('calca das nacoes', 1200000, 19178, '')
shopModule:addSellableItem('calca das nacoes', 600000, 19178, '')

-- === CAPACETES (19180 a 19189) ===
shopModule:addBuyableItem('capacete de viajante', 3500, 19180, '')
shopModule:addSellableItem('capacete de viajante', 1750, 19180, '')

shopModule:addBuyableItem('capacete reforcado', 10000, 19181, '')
shopModule:addSellableItem('capacete reforcado', 5000, 19181, '')

shopModule:addBuyableItem('capacete resistente', 25000, 19182, '')
shopModule:addSellableItem('capacete resistente', 12500, 19182, '')

shopModule:addBuyableItem('capacete aprimorado', 50000, 19183, '')
shopModule:addSellableItem('capacete aprimorado', 25000, 19183, '')

shopModule:addBuyableItem('capacete nobre', 95000, 19184, '')
shopModule:addSellableItem('capacete nobre', 47500, 19184, '')

shopModule:addBuyableItem('capacete de protecao', 165000, 19185, '')
shopModule:addSellableItem('capacete de protecao', 82500, 19185, '')

shopModule:addBuyableItem('capacete majestoso', 280000, 19186, '')
shopModule:addSellableItem('capacete majestoso', 140000, 19186, '')

shopModule:addBuyableItem('capacete glorioso', 475000, 19187, '')
shopModule:addSellableItem('capacete glorioso', 237500, 19187, '')

shopModule:addBuyableItem('capacete soberano', 750000, 19188, '')
shopModule:addSellableItem('capacete soberano', 375000, 19188, '')

shopModule:addBuyableItem('capacete das nacoes', 1100000, 19189, '')
shopModule:addSellableItem('capacete das nacoes', 550000, 19189, '')

-- === BOTAS (19191 a 19200) ===
shopModule:addBuyableItem('bota de viajante', 3000, 19191, '')
shopModule:addSellableItem('bota de viajante', 1500, 19191, '')

shopModule:addBuyableItem('bota reforcada', 9000, 19192, '')
shopModule:addSellableItem('bota reforcada', 4500, 19192, '')

shopModule:addBuyableItem('bota resistente', 22000, 19193, '')
shopModule:addSellableItem('bota resistente', 11000, 19193, '')

shopModule:addBuyableItem('bota aprimorada', 45000, 19194, '')
shopModule:addSellableItem('bota aprimorada', 22500, 19194, '')

shopModule:addBuyableItem('bota nobre', 85000, 19195, '')
shopModule:addSellableItem('bota nobre', 42500, 19195, '')

shopModule:addBuyableItem('bota de protecao', 150000, 19196, '')
shopModule:addSellableItem('bota de protecao', 75000, 19196, '')

shopModule:addBuyableItem('bota majestosa', 250000, 19197, '')
shopModule:addSellableItem('bota majestosa', 125000, 19197, '')

shopModule:addBuyableItem('bota gloriosa', 425000, 19198, '')
shopModule:addSellableItem('bota gloriosa', 212500, 19198, '')

shopModule:addBuyableItem('bota soberana', 680000, 19199, '')
shopModule:addSellableItem('bota soberana', 340000, 19199, '')

shopModule:addBuyableItem('bota das nacoes', 1000000, 19200, '')
shopModule:addSellableItem('bota das nacoes', 500000, 19200, '')

