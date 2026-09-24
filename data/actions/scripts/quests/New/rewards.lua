-- Armas classicas (ogre axe 13456 e hive sword 12864) sairam do sorteio: elas
-- tem ataque E defesa e furariam o see-saw ataque/defesa (ver sources/combat.cpp).
local rewards = {12949, 12880, 12916, 12927, 12804, 12859}
 
 
local function doPlayerAddRandomReward(cid, items)
        if type(items) ~= "table" then return false end
       
        local ite = math.random(1, #items)
        for i,v in pairs (items) do
                if i == ite then
                        doPlayerAddItem(cid, v)
                        return true
                end
        end
        return false
end
 
function onUse(cid, item, fromPosition, itemEx, toPosition)
        if getPlayerLevel(cid) < 45 then
                return doPlayerSendCancel(cid, getLangString(cid, "Not enough level.", "Você não tem level suficiente."))
        end
        local stor = getPlayerStorageValue(cid, item.actionid)
        if stor == -1 then
                doPlayerAddRandomReward(cid, rewards)
                setPlayerStorageValue(cid, item.actionid, 1)
                return doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, getLangString(cid, "You have found an item.", "Você encontrou um item."))
        else
                return doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, getLangString(cid, "The chest is empty.", "Esse chest está vazio."))
        end
        return true
end