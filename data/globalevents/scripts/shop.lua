-- ### CONFIG ###
-- message send to player by script "type" (types you can check in "global.lua")
SHOP_MSG_TYPE = 19
-- time (in seconds) between connections to SQL database by shop script
SQL_interval = 30
-- ### END OF CONFIG ###

local function addSecondItem(itemtogive_id, itemtogive_count)
        local new_item = doCreateItemEx(itemtogive_id, itemtogive_count)
        doPlayerAddItemEx(cid, new_item)
end

function onThink(interval, lastExecution)
    local result_plr = db.getResult("SELECT * FROM z_ots_comunication WHERE `type` = 'login';")
    if(result_plr:getID() ~= -1) then
        while(true) do
            id = tonumber(result_plr:getDataInt("id"))
            action = tostring(result_plr:getDataString("action"))
            delete = tonumber(result_plr:getDataInt("delete_it"))
            cid = getCreatureByName(tostring(result_plr:getDataString("name")))
            if isPlayer(cid) == TRUE then
                local itemtogive_id = tonumber(result_plr:getDataInt("param1"))
                local itemtogive_count = tonumber(result_plr:getDataInt("param2"))
                local container_id = tonumber(result_plr:getDataInt("param3"))
                local container_count = tonumber(result_plr:getDataInt("param4"))
                local add_item_type = tostring(result_plr:getDataString("param5"))
                local add_item_name = tostring(result_plr:getDataString("param6"))
                local itemtogive2_id = tonumber(result_plr:getDataInt("param8"))
                local itemtogive3_id = tonumber(result_plr:getDataInt("param10"))
                if itemtogive2_id and type(itemtogive2_id) == "number" and itemtogive2_id > 0 then
                    addSecondItem(itemtogive2_id, tonumber(result_plr:getDataInt("param9")))
                end
                if itemtogive3_id and type(itemtogive3_id) == "number" and itemtogive3_id > 0 then
                    addSecondItem(itemtogive3_id, tonumber(result_plr:getDataInt("param11")))
                end



                if(add_item_type == 'montarias') then
                    if not canPlayerRideMount(cid, itemtogive_id) then
                        doPlayerAddMount(cid, itemtogive_id)
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'Você recebeu do Shop Online a montaria: ('.. add_item_name ..').')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                    else
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online tentou enviar para você a montaria: ('.. add_item_name ..'). Entretanto, esse character já possui essa montaria.')
                        local oldPrice = tonumber(result_plr:getDataInt("param7"))
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, oldPrice .. ' Elemental Coins foram devolvidos para a sua conta.')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                        db.executeQuery("UPDATE accounts SET premium_points = '".. getPlayerCoins(cid) + oldPrice .."' where name = '" .. getPlayerAccount(cid) .. "'")
                end
                    return TRUE
                end


                if(add_item_type == 'outfits') then
                    if not canPlayerWearOutfitId(cid, itemtogive_id, 3) and (getPlayerVocation(cid) == 1) then
                        doPlayerAddOutfitId(cid, itemtogive_id, 3)
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'Você recebeu do Shop Online o outfit: ('.. add_item_name ..').')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                    else
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online tentou enviar para você o outfit: ('.. add_item_name ..'). Entretanto, esse character já possui esse outfit, ou você está tentando comprar um outfit de outra vocação (o que não é permitido).')
                        local oldPrice = tonumber(result_plr:getDataInt("param7"))
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, oldPrice .. ' Elemental Coins foram devolvidos para a sua conta.')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                        db.executeQuery("UPDATE accounts SET premium_points = '".. getPlayerCoins(cid) + oldPrice .."' where name = '" .. getPlayerAccount(cid) .. "'")
                end
                    return TRUE
                end

                if(add_item_type == 'outfitsw') then
                    if not canPlayerWearOutfitId(cid, itemtogive_id, 3) and (getPlayerVocation(cid) == 2) then
                        doPlayerAddOutfitId(cid, itemtogive_id, 3)
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'Você recebeu do Shop Online o outfit: ('.. add_item_name ..').')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                    else
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online tentou enviar para você o outfit: ('.. add_item_name ..'). Entretanto, esse character já possui esse outfit, ou você está tentando comprar um outfit de outra vocação (o que não é permitido).')
                        local oldPrice = tonumber(result_plr:getDataInt("param7"))
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, oldPrice .. ' Elemental Coins foram devolvidos para a sua conta.')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                        db.executeQuery("UPDATE accounts SET premium_points = '".. getPlayerCoins(cid) + oldPrice .."' where name = '" .. getPlayerAccount(cid) .. "'")
                end
                    return TRUE
                end

                if(add_item_type == 'outfitsa') then
                    if not canPlayerWearOutfitId(cid, itemtogive_id, 3) and (getPlayerVocation(cid) == 3) then
                        doPlayerAddOutfitId(cid, itemtogive_id, 3)
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'Você recebeu do Shop Online o outfit: ('.. add_item_name ..').')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                    else
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online tentou enviar para você o outfit: ('.. add_item_name ..'). Entretanto, esse character já possui esse outfit, ou você está tentando comprar um outfit de outra vocação (o que não é permitido).')
                        local oldPrice = tonumber(result_plr:getDataInt("param7"))
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, oldPrice .. ' Elemental Coins foram devolvidos para a sua conta.')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                        db.executeQuery("UPDATE accounts SET premium_points = '".. getPlayerCoins(cid) + oldPrice .."' where name = '" .. getPlayerAccount(cid) .. "'")
                end
                    return TRUE
                end

                if(add_item_type == 'outfitse') then
                    if not canPlayerWearOutfitId(cid, itemtogive_id, 3) and (getPlayerVocation(cid) == 4) then
                        doPlayerAddOutfitId(cid, itemtogive_id, 3)
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'Você recebeu do Shop Online o outfit: ('.. add_item_name ..').')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                    else
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online tentou enviar para você o outfit: ('.. add_item_name ..'). Entretanto, esse character já possui esse outfit, ou você está tentando comprar um outfit de outra vocação (o que não é permitido).')
                        local oldPrice = tonumber(result_plr:getDataInt("param7"))
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, oldPrice .. ' Elemental Coins foram devolvidos para a sua conta.')
                        db.query("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.query("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                        db.executeQuery("UPDATE accounts SET premium_points = '".. getPlayerCoins(cid) + oldPrice .."' where name = '" .. getPlayerAccount(cid) .. "'")
                end
                    return TRUE
                end



                local received_item = 0
                local full_weight = 0
                if add_item_type == 'container' then
                    container_weight = getItemWeightById(container_id, 1)
                    if isItemRune(itemtogive_id) == TRUE then
                        items_weight = container_count * getItemWeightById(itemtogive_id, 1)
                    else
                        items_weight = container_count * getItemWeightById(itemtogive_id, itemtogive_count)
                    end
                    full_weight = items_weight + container_weight
                else
                    full_weight = getItemWeightById(itemtogive_id, itemtogive_count)
                    if isItemRune(itemtogive_id) == TRUE then
                        full_weight = getItemWeightById(itemtogive_id, 1)
                    else
                        full_weight = getItemWeightById(itemtogive_id, itemtogive_count)
                    end
                end
                local free_cap = getPlayerFreeCap(cid)
                if full_weight <= free_cap then
                    if add_item_type == 'container' then
                        local new_container = doCreateItemEx(container_id, 1)
                        local iter = 0
                        while iter ~= container_count do
                            doAddContainerItem(new_container, itemtogive_id, itemtogive_count)
                            iter = iter + 1
                        end
                        received_item = doPlayerAddItemEx(cid, new_container)
                    else
                        local new_item = doCreateItemEx(itemtogive_id, itemtogive_count)
                        received_item = doPlayerAddItemEx(cid, new_item)
                    end
                    if received_item == RETURNVALUE_NOERROR then
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'Você recebeu do Shop Online o item: ('.. add_item_name ..').')
                        db.executeQuery("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id .. ";")
                        db.executeQuery("UPDATE `z_shop_history_item` SET `trans_state`='realized', `trans_real`=" .. os.time() .. " WHERE id = " .. id .. ";")
                    else
                        doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online está tentando enviar para você o item: ('.. add_item_name ..'). Por favor, verifique se você possui espaço suficiente em sua mochila ou capacidade necessária para recebê-lo. Tentaremos enviar novamente o item em '.. SQL_interval ..' segundos.')
                    end
                else
                    doPlayerSendTextMessage(cid, SHOP_MSG_TYPE, 'O Shop Online está tentando enviar para você o item: ('.. add_item_name ..'). Por favor, verifique se você possui espaço suficiente em sua mochila ou capacidade necessária para recebê-lo. Tentaremos enviar novamente o item em '.. SQL_interval ..' segundos.')
                end
            end
            if not(result_plr:next()) then
                break
            end
        end
        result_plr:free()
    end
    return TRUE
end