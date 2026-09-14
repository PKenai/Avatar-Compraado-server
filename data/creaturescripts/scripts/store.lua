-- ============================================================================
-- GAME STORE (server side) — adaptado para o Avatar (API TFS 0.4-style)
-- ----------------------------------------------------------------------------
-- Evento: <event type="extendedopcode" name="Store" event="script" value="store.lua"/>
-- Registro no login: registerCreatureEvent(cid, "Store")
--
-- As ofertas ficam em data/lib/shop_offers.lua (use o BAT de MARKET para
-- adicionar itens/outfits sem editar codigo).
--
-- Outfits que o player ja possui nao aparecem na lista (evita comprar duas
-- vezes o mesmo outfit). Itens podem ser comprados quantas vezes quiser.
-- ============================================================================

local SHOP_EXTENDED_OPCODE = 205
local CAMERA_OPCODE = 206
local SHOP_CALLBACKS = {}
local SHOP_CATEGORIES = nil
local SHOP_BUY_URL = ""
local SHOP_AD = nil
local MAX_PACKET_SIZE = 9000

-- Monta as categorias a partir do data/lib/shop_offers.lua, filtrando as
-- ofertas pela classe (elemento) do player.
function initShop(player)
    SHOP_CATEGORIES = {}
    SHOP_CALLBACKS = {}

    local pSex = getPlayerSex(player)
    local element = getPlayerElement(player) or "all"
    local categoriesByName = {}

    for _, offer in ipairs(ShopOffers or {}) do
        local offerClass = offer.class or "all"
        if offerClass == "all" or offerClass == element then
            -- outfits que o player ja possui ficam escondidos da Store;
            -- ofertas com hideIfOwned (ex: Momo Pouch) somem para quem ja tem o item
            local hide = (offer.type == "outfit" and playerOwnsOfferOutfit(player, offer, pSex))
                or (offer.type == "item" and offer.hideIfOwned and playerOwnsMomo(player))
                or (offer.type == "pet" and doPlayerHasPet(player, offer.petId) == true)
            if not hide then
                local catIndex = categoriesByName[offer.category]
                if not catIndex then
                    table.insert(SHOP_CATEGORIES, {type = offer.type, name = offer.category, offers = {}})
                    table.insert(SHOP_CALLBACKS, {})
                    catIndex = #SHOP_CATEGORIES
                    categoriesByName[offer.category] = catIndex
                end
                addOffer(SHOP_CATEGORIES[catIndex], SHOP_CALLBACKS[catIndex], offer, pSex)
            end
        end
    end
end

-- Retorna true se o player ja pode vestir o outfit da oferta (lookType do sexo dele).
function playerOwnsOfferOutfit(player, offer, pSex)
    local lookType = (pSex == PLAYERSEX_FEMALE and offer.outfitFemale) or offer.outfitMale
    if not lookType or lookType <= 0 then
        return false
    end
    return canPlayerWearOutfit(player, lookType, 0) == true
end

-- Converte uma oferta do shop_offers.lua no formato enviado ao client.
function addOffer(category, callbacks, offer, pSex)
    if offer.type == "pet" then
        -- Pet fantasma: a oferta mostra o preview da criatura (clientid do
        -- pets.xml) e a compra apenas da a posse do pet ao player.
        local petInfo = getPetInfo(offer.petId)
        if not petInfo then
            return
        end
        local pet = {
            type = petInfo.clientid,
            addons = 0,
            head = 0,
            body = 0,
            legs = 0,
            feet = 0,
            mount = 0
        }
        table.insert(category.offers, {cost = offer.cost, type = "pet", pet = pet, petId = offer.petId, title = offer.title, description = offer.description or ""})
        table.insert(callbacks, defaultPetBuyAction)
    elseif offer.type == "outfit" then
        local outfitType = (pSex == PLAYERSEX_FEMALE and offer.outfitFemale) or offer.outfitMale
        local outfit = {
            type = outfitType or 0,
            addons = offer.addons or 0,
            head = offer.head or 2,
            body = offer.body or 116,
            legs = offer.legs or 114,
            feet = offer.feet or 114,
            mount = offer.mount or 0
        }
        table.insert(category.offers, {cost = offer.cost, type = "outfit", outfit = outfit, title = offer.title, description = offer.description or ""})
        table.insert(callbacks, defaultOutfitBuyAction)
    else
        local itemId = offer.itemId
        local clientId = ItemType(itemId):getClientId()
        if clientId == 0 then clientId = itemId end
        table.insert(category.offers, {cost = offer.cost, type = "item", item = clientId, itemId = itemId, count = offer.count or 1, title = offer.title, description = offer.description or ""})
        table.insert(callbacks, defaultItemBuyAction)
    end
end

function sendMessage(player, title, msg, forceStatus)
    sendJSON(player, "message", {title = title, msg = msg}, forceStatus)
end

function getPoints(player)
    local points = 0
    local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. getPlayerAccountId(player))
    if resultId ~= false then
        points = result.getDataInt(resultId, "premium_points")
        result.free(resultId)
    end
    return points
end

function getStatus(player)
    return { ad = SHOP_AD, points = getPoints(player), buyUrl = SHOP_BUY_URL }
end

function sendJSON(player, action, data, forceStatus)
    local status = nil
    if not getPlayerStorageValue(player, 1150001) or getPlayerStorageValue(player, 1150001) + 10 < os.time() or forceStatus then
        status = getStatus(player)
    end
    setPlayerStorageValue(player, 1150001, os.time())

    local buffer = json.encode({action = action, data = data, status = status})
    local s = {}
    for i = 1, #buffer, MAX_PACKET_SIZE do s[#s + 1] = buffer:sub(i, i + MAX_PACKET_SIZE - 1) end

    if #s == 1 then
        doSendPlayerExtendedOpcode(player, SHOP_EXTENDED_OPCODE, s[1])
    else
        doSendPlayerExtendedOpcode(player, SHOP_EXTENDED_OPCODE, "S" .. s[1])
        for i = 2, #s - 1 do doSendPlayerExtendedOpcode(player, SHOP_EXTENDED_OPCODE, "P" .. s[i]) end
        doSendPlayerExtendedOpcode(player, SHOP_EXTENDED_OPCODE, "E" .. s[#s])
    end
end

function onExtendedOpcode(cid, opcode, buffer)
    if opcode == CAMERA_OPCODE then
        return handleCameraOpcode(cid, buffer)
    end

    if opcode ~= SHOP_EXTENDED_OPCODE then return false end

    if type(buffer) ~= "string" or buffer == "" then return false end

    local status, json_data = pcall(function() return json.decode(buffer) end)
    if not status or not json_data then return false end

    local action = json_data['action']
    local data = json_data['data']

    if action == 'init' then
        initShop(cid)
        sendJSON(cid, "categories", SHOP_CATEGORIES)
        doSendPlayerExtendedOpcode(cid, SHOP_EXTENDED_OPCODE, '{"action": "balance", "data": ' .. getPlayerBankBalance(cid) .. '}')
    elseif action == 'buy' then
        processBuy(cid, data)
    elseif action == "fetchHistory" then
        sendHistory(cid)
    end
    return true
end

function handleCameraOpcode(cid, buffer)
    if type(buffer) ~= "string" or buffer == "" then return false end

    local status, json_data = pcall(function() return json.decode(buffer) end)
    if not status or not json_data then return false end

    local data = json_data['data']
    local cmd = type(data) == "table" and data['cmd'] or nil

    if cmd == 'toggle' then
        cameraToggle(cid)
    elseif cmd == 'off' then
        cameraOff(cid)
    end
    return true
end

function processBuy(cid, data)
    if type(data) ~= "table" then return sendMessage(cid, "Error!", "Invalid offer") end
    local categoryId = tonumber(data["category"])
    local offerId = tonumber(data["offer"])

    if not SHOP_CATEGORIES or not SHOP_CATEGORIES[categoryId] or not SHOP_CATEGORIES[categoryId]['offers'][offerId] then
        return sendMessage(cid, "Error!", "Invalid offer")
    end

    local offer = SHOP_CATEGORIES[categoryId]['offers'][offerId]
    local callback = SHOP_CALLBACKS[categoryId][offerId]
    local points = getPoints(cid)

    if offer['cost'] > points then
        return sendMessage(cid, "Error!", "You don't have enough points!", true)
    end

    local status = callback(cid, offer)
    if status == true then
        db.query("UPDATE `accounts` set `premium_points` = `premium_points` - " .. offer['cost'] .. " WHERE `id` = " .. getPlayerAccountId(cid))
        db.query("INSERT INTO `shop_history` (`account`, `player`, `date`, `title`, `cost`, `details`) VALUES ('" .. getPlayerAccountId(cid) .. "', '" .. getPlayerGUID(cid) .. "', NOW(), " .. db.escapeString(offer['title']) .. ", " .. db.escapeString(offer['cost']) .. ", " .. db.escapeString(json.encode(offer)) .. ")")
        return sendMessage(cid, "Success!", "You bought " .. offer['title'] .. "!", true)
    end
    sendMessage(cid, "Error!", status or "Unknown error")
end

function sendHistory(cid)
    local history = {}
    local resultId = db.storeQuery("SELECT `date`, `title`, `cost` FROM `shop_history` WHERE `account` = " .. getPlayerAccountId(cid) .. " ORDER BY `id` DESC LIMIT 20")

    if resultId ~= false then
        repeat
            table.insert(history, {
                date = result.getDataString(resultId, "date"),
                item = result.getDataString(resultId, "title"),
                cost = result.getDataInt(resultId, "cost")
            })
        until not result.next(resultId)
        result.free(resultId)
    end
    sendJSON(cid, "history", history)
end

function defaultItemBuyAction(cid, offer)
    if offer.itemId == CAMERA_ITEM_ID then
        local slotItem = getPlayerSlotItem(cid, CAMERA_SLOT)
        if slotItem and slotItem.itemid ~= 0 then
            return "You already have a Camera equipped."
        end
        local ok = doPlayerAddItem(cid, offer.itemId, offer.count or 1, false, 1, CAMERA_SLOT)
        if ok then
            return true
        end
        return "Could not equip the Camera."
    end
    if offer.itemId == MOMO_ITEM_ID then
        local slotItem = getPlayerSlotItem(cid, MOMO_SLOT)
        if slotItem and slotItem.itemid ~= 0 then
            return "You already have a Momo Pouch equipped."
        end
        local ok = doPlayerAddItem(cid, offer.itemId, offer.count or 1, false, 1, MOMO_SLOT)
        if ok then
            return true
        end
        return "Could not equip the Momo Pouch."
    end
    if getPlayerFreeCap(cid) < getItemWeightById(offer.itemId, offer.count) then
        return "You don't have enough capacity."
    end
    -- canDropOnMap = false: itens comprados NUNCA caem no chao nem entram no Momo Pouch
    -- (o pouch so recebe loot de monstro). Se o inventario estiver cheio, a compra falha.
    local ok = doPlayerAddItem(cid, offer.itemId, offer.count, false)
    if ok then
        return true
    end
    return "Your inventory is full."
end

function defaultPetBuyAction(cid, offer)
    if not offer.petId then
        return "Invalid pet offer."
    end

    if doPlayerHasPet(cid, offer.petId) == true then
        return "You already own this pet."
    end

    if not doPlayerAddPet(cid, offer.petId) then
        return "Could not add the pet to your character. Please contact a staff member."
    end

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Voce comprou o pet: (" .. tostring(offer.title) .. "). Botao direito em voce mesmo -> Pet para escolher.")
    return true
end

function defaultOutfitBuyAction(cid, offer)
    local outfit = offer.outfit
    if outfit.type > 0 then
        -- adiciona pelo lookType (doPlayerAddOutfit); se o lookType nao estiver
        -- registrado no outfits.xml a compra falha e os pontos nao sao debitados
        local added = doPlayerAddOutfit(cid, outfit.type, outfit.addons or 0)
        if not added then
            return "Could not add the outfit to your character. Please contact a staff member."
        end
    end
    if outfit.mount and outfit.mount > 0 then doPlayerAddMount(cid, outfit.mount) end
    return true
end
