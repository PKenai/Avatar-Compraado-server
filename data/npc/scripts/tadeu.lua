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
	selfSay("Hello "..getCreatureName(cid).."! How can i help you? Do you want to see my {offers}?", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, onGreet)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())

-- === CAPES (19158 to 19167) ===
shopModule:addBuyableItem("Traveler's Cape", 5000, 19158, '')
shopModule:addSellableItem("Traveler's Cape", 2500, 19158, '')

shopModule:addBuyableItem("Reinforced Cape", 15000, 19159, '')
shopModule:addSellableItem("Reinforced Cape", 7500, 19159, '')

shopModule:addBuyableItem("Tough Cape", 35000, 19160, '')
shopModule:addSellableItem("Tough Cape", 17500, 19160, '')

shopModule:addBuyableItem("Improved Cape", 70000, 19161, '')
shopModule:addSellableItem("Improved Cape", 35000, 19161, '')

shopModule:addBuyableItem("Noble Cape", 130000, 19162, '')
shopModule:addSellableItem("Noble Cape", 65000, 19162, '')

shopModule:addBuyableItem("Protective Cape", 220000, 19163, '')
shopModule:addSellableItem("Protective Cape", 110000, 19163, '')

shopModule:addBuyableItem("Majestic Cape", 380000, 19164, '')
shopModule:addSellableItem("Majestic Cape", 190000, 19164, '')

shopModule:addBuyableItem("Glorious Cape", 650000, 19165, '')
shopModule:addSellableItem("Glorious Cape", 325000, 19165, '')

shopModule:addBuyableItem("Sovereign Cape", 1000000, 19166, '')
shopModule:addSellableItem("Sovereign Cape", 500000, 19166, '')

shopModule:addBuyableItem("Nations Cape", 1500000, 19167, '')
shopModule:addSellableItem("Nations Cape", 750000, 19167, '')

-- === PANTS (19169 to 19178) ===
shopModule:addBuyableItem("Traveler's Pants", 4000, 19169, '')
shopModule:addSellableItem("Traveler's Pants", 2000, 19169, '')

shopModule:addBuyableItem("Reinforced Pants", 12000, 19170, '')
shopModule:addSellableItem("Reinforced Pants", 6000, 19170, '')

shopModule:addBuyableItem("Tough Pants", 28000, 19171, '')
shopModule:addSellableItem("Tough Pants", 14000, 19171, '')

shopModule:addBuyableItem("Improved Pants", 55000, 19172, '')
shopModule:addSellableItem("Improved Pants", 27500, 19172, '')

shopModule:addBuyableItem("Noble Pants", 100000, 19173, '')
shopModule:addSellableItem("Noble Pants", 50000, 19173, '')

shopModule:addBuyableItem("Protective Pants", 175000, 19174, '')
shopModule:addSellableItem("Protective Pants", 87500, 19174, '')

shopModule:addBuyableItem("Majestic Pants", 300000, 19175, '')
shopModule:addSellableItem("Majestic Pants", 150000, 19175, '')

shopModule:addBuyableItem("Glorious Pants", 500000, 19176, '')
shopModule:addSellableItem("Glorious Pants", 250000, 19176, '')

shopModule:addBuyableItem("Sovereign Pants", 800000, 19177, '')
shopModule:addSellableItem("Sovereign Pants", 400000, 19177, '')

shopModule:addBuyableItem("Nations Pants", 1200000, 19178, '')
shopModule:addSellableItem("Nations Pants", 600000, 19178, '')

-- === HELMETS (19180 to 19189) ===
shopModule:addBuyableItem("Traveler's Helmet", 3500, 19180, '')
shopModule:addSellableItem("Traveler's Helmet", 1750, 19180, '')

shopModule:addBuyableItem("Reinforced Helmet", 10000, 19181, '')
shopModule:addSellableItem("Reinforced Helmet", 5000, 19181, '')

shopModule:addBuyableItem("Tough Helmet", 25000, 19182, '')
shopModule:addSellableItem("Tough Helmet", 12500, 19182, '')

shopModule:addBuyableItem("Improved Helmet", 50000, 19183, '')
shopModule:addSellableItem("Improved Helmet", 25000, 19183, '')

shopModule:addBuyableItem("Noble Helmet", 95000, 19184, '')
shopModule:addSellableItem("Noble Helmet", 47500, 19184, '')

shopModule:addBuyableItem("Protective Helmet", 165000, 19185, '')
shopModule:addSellableItem("Protective Helmet", 82500, 19185, '')

shopModule:addBuyableItem("Majestic Helmet", 280000, 19186, '')
shopModule:addSellableItem("Majestic Helmet", 140000, 19186, '')

shopModule:addBuyableItem("Glorious Helmet", 475000, 19187, '')
shopModule:addSellableItem("Glorious Helmet", 237500, 19187, '')

shopModule:addBuyableItem("Sovereign Helmet", 750000, 19188, '')
shopModule:addSellableItem("Sovereign Helmet", 375000, 19188, '')

shopModule:addBuyableItem("Nations Helmet", 1100000, 19189, '')
shopModule:addSellableItem("Nations Helmet", 550000, 19189, '')

-- === BOOTS (19191 to 19200) ===
shopModule:addBuyableItem("Traveler's Boots", 3000, 19191, '')
shopModule:addSellableItem("Traveler's Boots", 1500, 19191, '')

shopModule:addBuyableItem("Reinforced Boots", 9000, 19192, '')
shopModule:addSellableItem("Reinforced Boots", 4500, 19192, '')

shopModule:addBuyableItem("Tough Boots", 22000, 19193, '')
shopModule:addSellableItem("Tough Boots", 11000, 19193, '')

shopModule:addBuyableItem("Improved Boots", 45000, 19194, '')
shopModule:addSellableItem("Improved Boots", 22500, 19194, '')

shopModule:addBuyableItem("Noble Boots", 85000, 19195, '')
shopModule:addSellableItem("Noble Boots", 42500, 19195, '')

shopModule:addBuyableItem("Protective Boots", 150000, 19196, '')
shopModule:addSellableItem("Protective Boots", 75000, 19196, '')

shopModule:addBuyableItem("Majestic Boots", 250000, 19197, '')
shopModule:addSellableItem("Majestic Boots", 125000, 19197, '')

shopModule:addBuyableItem("Glorious Boots", 425000, 19198, '')
shopModule:addSellableItem("Glorious Boots", 212500, 19198, '')

shopModule:addBuyableItem("Sovereign Boots", 680000, 19199, '')
shopModule:addSellableItem("Sovereign Boots", 340000, 19199, '')

shopModule:addBuyableItem("Nations Boots", 1000000, 19200, '')
shopModule:addSellableItem("Nations Boots", 500000, 19200, '')

