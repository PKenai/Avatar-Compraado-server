-- ============================================================================
--  Market / Auction System - Talkaction (!offer)
--  Registered in data/talkactions/talkactions.xml
-- ============================================================================

local config = {
    maxOffersPerPlayer = 5,
    -- Preço máximo aceito: 2^53 - 1 (maior inteiro exato em Lua 5.1 /
    -- double). Na prática é "ilimitado" para qualquer economia do jogo.
    maxPrice = 9007199254740991,
    storageExhaustion  = 9999,
    sendOffersOnlyInPZ = true,
    blocked_items = {},
    accepted_items = {11259, 13041, 12686, 12687, 12688, 12689}
}

local idsDoDesc = {
    [11259] = "You see elemental coin.",
    [13041] = "You see premium scroll.",
    [12686] = "You see Fire Stone. This stone is very rare and powerful, handle with extreme care.",
    [12687] = "You see Earth Stone. This stone is very rare and powerful, handle with extreme care.",
    [12688] = "You see Water Stone. This stone is very rare and powerful, handle with extreme care.",
    [12689] = "You see Air Stone. This stone is very rare and powerful, handle with extreme care."
}

local function setExhaustion(uid, time)
    return doCreatureSetStorage(uid, config.storageExhaustion, time + os.time())
end

local function getExhaustion(uid)
    local storage = getCreatureStorage(uid, config.storageExhaustion)
    if storage <= 0 then
        return 0
    end
    return storage - os.time()
end

local function isArmor(itemId)
    local item = getItemInfo(itemId)
    if type(item) ~= "table" then
        return false
    end
    local armorWields = {1, 2, 4, 7, 8, 9}
    return isInArray(armorWields, item.wieldPosition)
end

local function isItemToOffer(itemId)
    -- A regra de "que item pode ser vendido" mora em market_lib.lua
    -- (Market.isSellableItem), a mesma que o crosshair usa pra avisar o jogador
    -- na hora do clique. Aqui so' chamamos ela; o bloco abaixo e' o fallback
    -- caso a lib nao esteja carregada.
    if type(Market) == "table" and type(Market.isSellableItem) == "function" then
        return Market.isSellableItem(itemId)
    end

    local item = getItemInfo(itemId)
    if type(item) ~= "table" then
        return false
    end
    if isInArray(config.accepted_items, itemId) then
        return true
    elseif (tonumber(item.maxItems) or 0) > 0 then
        return false -- container (mochila/baú): iria com o conteúdo dentro
    elseif isItemStackable(itemId) then
        return false
    elseif item.wieldPosition == 1 or item.wieldPosition == 2 or item.wieldPosition == 4 or item.wieldPosition == 7 or item.wieldPosition == 8 or item.wieldPosition == 9 then -- capacete, armadura, bota, calça, anel, amuleto
        return true
    elseif item.weaponType > 0 then -- sword, axe, club, distance, shield, wands, rods, ammunition
        return true
    end
    return false
end

-- ----------------------------------------------------------------------------
--  Helpers: tier, depósito e mensagens
-- ----------------------------------------------------------------------------
local function marketMsg(cid, text)
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, text)
end

local function marketFail(cid, text)
    marketMsg(cid, text)
    doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
end

-- Quantos itens do tipo `itemid` o jogador tem dentro dos depósitos (todos os
-- lockers + reward mailbox, containers aninhados incluidos).
local function depotCountOf(cid, itemid)
    if type(Market) == "table" and type(Market.depotItemCount) == "function" then
        local ok, count = pcall(Market.depotItemCount, cid, itemid)
        if ok then
            return tonumber(count) or 0
        end
    end
    return 0
end

-- Itens que saíram do depósito para serem vendidos voltam pro depósito quando
-- alguma verificação posterior falha (nunca ficam presos nem duplicados).
local function giveBackToDepot(cid, itemid, count)
    count = tonumber(count) or 0
    if count <= 0 then
        return true
    end

    if type(doPlayerAddItemToDepot) == "function" then
        for depotid = 1, 10 do
            if doPlayerAddItemToDepot(cid, depotid, itemid, count) then
                return true
            end
        end
    end

    -- último recurso: mochila (o item continuava sendo do jogador)
    return doPlayerAddItem(cid, itemid, count) ~= nil
end

-- Entrega um item do market pro jogador com o tier certo. O atributo precisa
-- estar setado ANTES do item chegar ao client, senão o sprite vai sem o shader
-- do tier (por isso criar -> setar -> adicionar, e não o contrário).
local function giveMarketItem(cid, itemid, count, tier)
    count = tonumber(count) or 1
    tier = tonumber(tier) or 0
    if tier < 0 or tier > 10 then
        tier = 0
    end

    if type(doCreateItemEx) ~= "function" or type(doPlayerAddItemEx) ~= "function" then
        return doPlayerAddItem(cid, itemid, count)
    end

    local uid = doCreateItemEx(itemid, count)
    if not uid or uid == 0 or uid == false then
        return doPlayerAddItem(cid, itemid, count)
    end

    if tier > 0 and type(doItemSetAttribute) == "function" then
        pcall(doItemSetAttribute, uid, "tier", tier)
    end

    -- doPlayerAddItemEx devolve o ReturnValue (RET_NOERROR = 0 neste server).
    -- Em caso de falha o item desanexado é liberado no fim do script, então
    -- aqui basta dizer ao chamador que não deu.
    local ret = doPlayerAddItemEx(cid, uid, false)
    if ret == true or (type(ret) == "number" and ret == 0) then
        return uid
    end

    return nil
end

-- Tier do item que está sendo anunciado (0 = item sem tier).
local function itemTierOf(uid)
    if not uid or uid <= 0 then
        return 0
    end
    local tier = tonumber(getItemAttribute(uid, "tier")) or 0
    if tier < 0 or tier > 10 then
        tier = 0
    end
    return tier
end

function onSay(cid, words, param, channel)
    if (param == '') then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Comando inválido.")
        doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
        return true
    elseif config.sendOffersOnlyInPZ and not getTilePzInfo(getPlayerPosition(cid)) then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você necessita estar em área PZ para utilizar o market.")
        doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
        return true
    elseif getExhaustion(cid) > 0 then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você está exhausted.")
        doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
        return true
    end

    local word = string.explode(param, ",")
    if word[1] == "add" then
        if not word[2] or not word[3] or not word[4] then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] É necessário informar todos os dados.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        local itemCount = tonumber(word[3])
        local itemValue = tonumber(word[4])
        if (not itemCount or not itemValue) or (itemCount < 1 or itemValue < 1) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Insira valores válidos.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif #tostring(itemCount) > 3 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Esta quantidade está acima do limite.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif itemCount > 100 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você não pode vender mais do que 100 itens.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif itemValue > config.maxPrice then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Este preço está acima do limite.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif itemValue < 1000 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Este preço está abaixo do limite.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        setExhaustion(cid, 3)

        local resultId = db.getResult("SELECT `id` FROM `auction_system` WHERE `player` = " .. getPlayerGUID(cid) .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
        if (resultId:getID() ~= -1) then
            if resultId:getRows(true) >= config.maxOffersPerPlayer then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Desculpe, você não pode adicionar mais ofertas (máximo de " .. config.maxOffersPerPlayer .. " ofertas por personagem).")
                doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
                return true
            end
        end

        -- Nome -> id pelo helper do market: ele apara espaco sobrando (o
        -- jogador escreve "magic sword , 1, 2000") e chama getItemIdByName()
        -- com o report de erro desligado, senao um nome inexistente imprime um
        -- bloco [Error - ...] no console a cada tentativa. O fallback mantem o
        -- talkaction funcionando mesmo se a lib do market nao estiver carregada.
        local itemId
        if type(Market) == "table" and type(Market.getItemIdByName) == "function" then
            itemId = Market.getItemIdByName(word[2])
        else
            errors(false)
            itemId = getItemIdByName(word[2])
            errors(true)
        end
        itemCount = math.floor(itemCount)
        if not itemId then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Não existe item com este nome.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif isInArray(config.blocked_items, itemId) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Este item não pode ser vendido no market.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif not isItemToOffer(itemId) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Este item não pode ser vendido no market.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif itemCount > 1 and not isItemStackable(itemId) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Este tipo de item só pode ser anunciado com a quantidade limitada a 1.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        -- ====================================================================
        --  VERIFICAÇÃO DE POSSE
        --  O cliente só manda nome/quantidade: quem decide se o item é mesmo do
        --  jogador é o servidor, e a checagem é repetida antes e depois de cada
        --  remoção. Item do chão, de baú no chão, de container aberto de outro
        --  jogador ou de um amigo NÃO passa daqui, e nada é removido antes de
        --  todas as checagens passarem (nada de item duplicado).
        -- ====================================================================
        if type(Market) == "table" and type(Market.ensureSchema) == "function" then
            Market.ensureSchema()
        end

        local invCount = getPlayerItemCount(cid, itemId)
        local depotCount = depotCountOf(cid, itemId)
        local missing = itemCount - invCount

        -- 1ª checagem: tem que ter na mochila e/ou no depósito
        if (invCount + depotCount) < itemCount then
            marketFail(cid, "[MARKET] Desculpe, você não tem este item ou a quantia deste item.")
            return true
        end

        -- 2ª checagem: o que está só no depósito é trazido pra mochila com o
        -- mesmo helper da busca do depósito...
        local depotTaken = 0
        if missing > 0 then
            depotTaken = tonumber(takePlayerDepotItem(cid, itemId, missing)) or 0
            if depotTaken < missing then
                giveBackToDepot(cid, itemId, depotTaken)
                marketFail(cid, "[MARKET] Desculpe, você não tem este item ou a quantia deste item.")
                return true
            end
        end

        -- ...e a posse é conferida de novo, agora com o item na mochila
        if getPlayerItemCount(cid, itemId) < itemCount then
            giveBackToDepot(cid, itemId, depotTaken)
            marketFail(cid, "[MARKET] Desculpe, você não tem este item ou a quantia deste item.")
            return true
        end

        local theItem = getPlayerItemById(cid, true, itemId)
        if not theItem or not theItem.uid or theItem.uid <= 0 then
            giveBackToDepot(cid, itemId, depotTaken)
            marketFail(cid, "[MARKET] Desculpe, você não tem este item.")
            return true
        end

        local elementalRuneType = getItemAttribute(theItem.uid, 'elementalrunetype')
        local elementalRuneCharges = getItemAttribute(theItem.uid, 'elementalrunecharges')
        if elementalRuneType and elementalRuneType >= 1 and (isArmor(theItem.itemid) or (elementalRuneCharges and elementalRuneCharges > 0)) then
            giveBackToDepot(cid, itemId, depotTaken)
            marketFail(cid, "[MARKET] Você não pode colocar um item encantado no market.")
            return true
        end

        -- 3ª checagem: o item achado tem mesmo que ser do jogador (se o
        -- getPlayerItemById trouxe algo de outro lugar, o uid some e o
        -- getThing falha aqui).
        if not getThing(theItem.uid) then
            giveBackToDepot(cid, itemId, depotTaken)
            marketFail(cid, "[MARKET] Desculpe, você não tem este item.")
            return true
        end

        -- tier do item (0 = sem tier): precisa ser lido AGORA, antes da remoção
        local tier = itemTierOf(theItem.uid)

        local theDesc = idsDoDesc[itemId] or ""
        if theDesc == "" and theItem.type == 0 then
            doItemSetAttribute(theItem.uid, "description", getItemDescriptionsById(itemId).description)
            theDesc = "You see " .. getItemDescr(theItem.uid)
        end

        -- 4ª checagem: remove e confere o que sobrou na mochila
        local beforeCount = getPlayerItemCount(cid, itemId)
        local removed
        if itemCount == 1 then
            removed = doRemoveItem(theItem.uid, 1)
        else
            removed = doPlayerRemoveItem(cid, itemId, itemCount)
        end

        if not removed or getPlayerItemCount(cid, itemId) > (beforeCount - itemCount) then
            giveBackToDepot(cid, itemId, depotTaken)
            marketFail(cid, "[MARKET] Desculpe, você não tem este item ou a quantia deste item.")
            return true
        end

        local itemName = string.lower(getItemNameById(itemId))
        itemValue = math.floor(itemValue)
        local q = db.escapeString
        -- NOTE: db.escapeString ALREADY wraps the value in single quotes
        -- (see DatabaseMySQL::escapeString) - do NOT add quotes here.
        local inserted = db.executeQuery(
            "INSERT INTO `auction_system` (`player`, `item_name`, `item_id`, `count`, `desc`, `cost`, `date`, `expired`, `world_id`, `tier`) VALUES (" ..
            getPlayerGUID(cid) .. ", " .. q(itemName) .. ", " .. itemId .. ", " .. itemCount .. ", " .. q(theDesc) .. ", " .. string.format("%.0f", itemValue) .. ", " .. os.time() .. ", 0, " .. getConfigValue('worldId') .. ", " .. tier .. ");"
        )

        -- Última checagem: se o INSERT falhou, o item NÃO fica perdido - mas só
        -- devolve depois de confirmar que a oferta realmente não entrou (um
        -- retorno falso com a linha gravada duplicaria o item).
        if not inserted then
            local check = db.getResult("SELECT `id` FROM `auction_system` WHERE `player` = " .. getPlayerGUID(cid) .. " AND `item_id` = " .. itemId .. " AND `cost` = " .. string.format("%.0f", itemValue) .. " AND `world_id` = " .. getConfigValue('worldId') .. " ORDER BY `id` DESC LIMIT 1;")
            local rowExists = check and check:getID() ~= -1
            if check and rowExists then
                check:free()
            end

            if not rowExists then
                giveMarketItem(cid, itemId, itemCount, tier)
                marketFail(cid, "[MARKET] Falha ao registrar a oferta. O item voltou pra sua mochila.")
                return true
            end
        end

        local tierText = tier > 0 and (" [Tier " .. tier .. "]") or ""
        marketMsg(cid, "[MARKET] Você adicionou " .. itemCount .. " " .. itemName .. tierText .. " por " .. string.format("%.0f", itemValue) .. " gold coins nas ofertas de venda do market.")

        return true

    elseif word[1] == "buy" then
        if not word[2] then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Digite o ID da oferta que deseja comprar.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        local id = tonumber(word[2])
        if not id then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você não digitou um número válido para o ID da oferta.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        setExhaustion(cid, 3)

        local resultId = db.getResult("SELECT * FROM `auction_system` WHERE `id` = " .. id .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
        if resultId:getID() == -1 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] ID da oferta incorreto.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        local expired = resultId:getDataInt("expired")
        local playerId = resultId:getDataInt("player")
        local playerName = getPlayerNameByGUID(playerId)
        local itemValue = resultId:getDataLong("cost")
        local itemId = resultId:getDataInt("item_id")
        local itemCount = resultId:getDataInt("count")
        local itemName = resultId:getDataString("item_name")
        local itemTier = tonumber(resultId:getDataInt("tier")) or 0
        resultId:free()

        if expired == 1 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Esta oferta já expirou.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif getPlayerName(cid) == playerName then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você não pode comprar seus próprios itens.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif getPlayerMoney(cid) < itemValue then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você não possui dinheiro suficiente.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif getPlayerFreeCap(cid) < getItemWeightById(itemId, itemCount) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você está tentando comprar o item " .. itemName .. " de " .. getItemWeightById(itemId, itemCount) .. " de cap, você possui apenas " .. getPlayerFreeCap(cid) .. " de cap. disponível. Coloque alguns itens em seu depot ou em sua house, e tente refazer a compra.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        elseif not doPlayerRemoveMoney(cid, itemValue) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você não possui dinheiro suficiente.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        else
            -- o item volta com o tier que foi anunciado (giveMarketItem seta o
            -- atributo antes de o client receber o item, senão o sprite ficaria
            -- sem o shader do tier)
            local delivered = 0
            if isItemStackable(itemId) then
                if giveMarketItem(cid, itemId, itemCount, itemTier) then
                    delivered = itemCount
                end
            else
                -- itens não-stackáveis só podem ser anunciados com quantidade 1
                for i = 1, itemCount do
                    if giveMarketItem(cid, itemId, 1, itemTier) then
                        delivered = delivered + 1
                    else
                        break
                    end
                end
            end

            if delivered == 0 then
                -- nada foi entregue: devolve o dinheiro e a oferta continua no ar
                doPlayerAddMoney(cid, itemValue)
                marketFail(cid, "[MARKET] Você não tem espaço na mochila. A compra foi cancelada e o dinheiro devolvido.")
                return true
            end

            db.executeQuery("DELETE FROM `auction_system` WHERE `id` = " .. id .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você comprou " .. itemCount .. " " .. itemName .. " por " .. string.format("%.0f", itemValue) .. " gps!")
            db.executeQuery("UPDATE `players` SET `auction_balance` = `auction_balance` + " .. string.format("%.0f", itemValue) .. " WHERE `id` = " .. playerId .. ";")
        end

        return true

    elseif word[1] == "remove" then
        if not word[2] then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Digite o ID da oferta que quer remover.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        local id = tonumber(word[2])
        if not id then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você não digitou um número válido para o ID da oferta.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            return true
        end

        setExhaustion(cid, 3)

        local resultId = db.getResult("SELECT * FROM `auction_system` WHERE `id` = " .. id .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
        if (resultId:getID() == -1) then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] ID da oferta incorreto.")
            return true
        end

        local playerId = resultId:getDataInt("player")
        local itemId = resultId:getDataInt("item_id")
        local itemCount = resultId:getDataInt("count")
        local itemName = resultId:getDataString("item_name")
        local itemTier = tonumber(resultId:getDataInt("tier")) or 0
        resultId:free()

        if getPlayerGUID(cid) == playerId then
            if getPlayerFreeCap(cid) < getItemWeightById(itemId, itemCount) then
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Você está tentando retirar o item " .. itemName .. " de " .. getItemWeightById(itemId, itemCount) .. " de capacidade e você tem " .. getPlayerFreeCap(cid) .. " de capacidade disponível. Coloque alguns itens em seu depot ou em sua house, e tente remover a oferta.")
                doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
            else
                -- entrega antes de apagar a oferta: se não houver espaço, a oferta
                -- continua no ar (o item nunca é perdido nem duplicado)
                local delivered = 1
                if isItemStackable(itemId) then
                    if not giveMarketItem(cid, itemId, itemCount, itemTier) then
                        delivered = 0
                    end
                else
                    for i = 1, itemCount do
                        if not giveMarketItem(cid, itemId, 1, itemTier) then
                            delivered = 0
                            break
                        end
                    end
                end

                if delivered == 0 then
                    marketFail(cid, "[MARKET] Você não tem espaço na mochila para receber o item. A oferta continua no market.")
                    return true
                end

                db.executeQuery("DELETE FROM `auction_system` WHERE `id` = " .. id .. " AND `world_id` = " .. getConfigValue('worldId') .. ";")
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Sua oferta foi removida do market.")
            end
        else
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[MARKET] Esta oferta não pertence a você.")
            doSendMagicEffect(getPlayerPosition(cid), CONST_ME_POFF)
        end
    end
    return true
end
