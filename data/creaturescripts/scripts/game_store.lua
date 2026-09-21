-- ============================================================================
-- GAME STORE (nova loja) - lado servidor
-- ----------------------------------------------------------------------------
-- Portado do pacote "Game Store" (formato TFS 1.x) para a API deste servidor.
-- O protocolo com o client e' o do pacote novo: extended opcode 102 + JSON.
--
-- INSTALACAO (ja feita neste datapack):
--   1. data/creaturescripts/creaturescripts.xml:
--        <event type="extendedopcode" name="GameStoreExtended" event="script"
--               value="game_store.lua"/>
--   2. data/creaturescripts/scripts/loginLogout/login.lua (onLogin):
--        registerCreatureEvent(cid, "GameStoreExtended")
--   3. Client: mods/game_store (mesmo opcode 102).
--
-- CATALOGO
--   As ofertas vem de data/lib/shop_offers.lua - o MESMO arquivo que o BAT
--   (Controles de uso\MARKET\adicionar_loja.bat) gera, entao cadastrar oferta
--   continua sendo pelo BAT. A categoria e' criada na ordem em que a primeira
--   oferta dela aparece no arquivo e herda o icone/descricao daquela oferta.
--
-- CAMPOS ACEITOS EM shop_offers.lua
--   category, type = "item" | "outfit" | "pet", title, cost, class, description
--   type = item   -> itemId, count
--   type = outfit -> outfitMale, outfitFemale, addons
--   type = pet    -> petId (o "id" de data/XML/pets.xml)
--   extras: hideIfOwned = true  (some da loja pra quem ja possui, ex: Camera)
--
-- MONTARIA: o client desta loja sabe desenhar o tipo "mount", mas a montaria
--   deste servidor esta desativada (onMount.lua retorna false), por isso nem o
--   catalogo nem o BAT geram ofertas desse tipo.
--
-- PONTOS: accounts.premium_points (o mesmo saldo do site / da loja antiga).
-- HISTORICO: tabela shop_history (account, player, date, title, cost, details).
-- ============================================================================

local CODE_GAMESTORE = 102
local DONATION_URL = "" -- botao "Get Points" do client abriria este link

local POINTS_REFRESH_TIME = 10 * 1000 -- reenvia o saldo pra quem esta online

local GAME_STORE = nil -- { categories = {...}, offers = { [categoria] = {...} } }

local CAMERA_ITEM = CAMERA_ITEM_ID or 18432
local CAMERA_EQUIP_SLOT = CAMERA_SLOT or 11
local MOMO_ITEM = MOMO_ITEM_ID or 18435
local MOMO_EQUIP_SLOT = MOMO_SLOT or 12

-- ============================================================================
-- Monta a loja a partir de data/lib/shop_offers.lua
-- ============================================================================
function gameStoreInitialize()
    GAME_STORE = {categories = {}, offers = {}}

    if type(ShopOffers) ~= "table" then
        print("[GameStore] ShopOffers nao carregado (data/lib/shop_offers.lua). Loja vazia.")
        return
    end

    for i = 1, #ShopOffers do
        addOfferFromCatalog(ShopOffers[i])
    end
end

-- Converte uma oferta do shop_offers.lua no formato da loja nova.
function addOfferFromCatalog(offer)
    if type(offer) ~= "table" or not offer.category or not offer.title then
        return
    end

    local category = getOrCreateCategory(offer.category, offer)
    if not category then
        return
    end

    local storeOffer = {
        title = offer.title,
        description = offer.description or "",
        price = tonumber(offer.cost) or 0,
        class = offer.class or "all",
        hideIfOwned = offer.hideIfOwned == true
    }

    if offer.type == "pet" then
        local petInfo = getPetInfo(offer.petId)
        if not petInfo then
            print("[GameStore] pet inexistente no pets.xml (petId " .. tostring(offer.petId) .. "): " .. tostring(offer.title))
            return
        end
        storeOffer.type = "pet"
        storeOffer.petId = offer.petId
        -- clientid do pet = sprite usado pelo client (mesmo esquema da loja antiga)
        storeOffer.clientId = petInfo.clientid
    elseif offer.type == "outfit" then
        storeOffer.type = "outfit"
        storeOffer.outfitMale = {
            type = offer.outfitMale or 0,
            addons = offer.addons or 0,
            head = offer.head or 2,
            body = offer.body or 116,
            legs = offer.legs or 114,
            feet = offer.feet or 114,
            mount = offer.mount or 0
        }
        storeOffer.outfitFemale = {
            type = offer.outfitFemale or offer.outfitMale or 0,
            addons = offer.addons or 0,
            head = offer.head or 2,
            body = offer.body or 116,
            legs = offer.legs or 114,
            feet = offer.feet or 114,
            mount = offer.mount or 0
        }
    else
        local itemId = tonumber(offer.itemId) or 0
        if itemId <= 0 then
            return
        end
        storeOffer.type = "item"
        storeOffer.itemId = itemId
        storeOffer.count = tonumber(offer.count) or 1
        local clientId = ItemType(itemId):getClientId()
        storeOffer.clientId = (clientId ~= 0) and clientId or itemId
    end

    -- usa o titulo canonico da categoria (pode ter sido fundida com outra
    -- grafia) pra que a oferta cai no balde certo
    table.insert(GAME_STORE.offers[category.title], storeOffer)
end

-- Chave de comparacao das categorias: "Outfit", "outfits" e " Outfits "
-- viram a MESMA aba (antes uma letra/caixa diferente criava uma aba nova).
function normalizeCategoryKey(title)
    local key = string.lower(tostring(title))
    key = string.gsub(key, "^%s+", "")
    key = string.gsub(key, "%s+$", "")
    return key
end

-- Cria a categoria (na ordem do arquivo) e define icone/descricao pela
-- primeira oferta cadastrada nela.
function getOrCreateCategory(title, offer)
    if type(title) ~= "string" or title == "" then
        return nil
    end

    local key = normalizeCategoryKey(title)
    for i = 1, #GAME_STORE.categories do
        if GAME_STORE.categories[i].key == key then
            return GAME_STORE.categories[i]
        end
    end

    if not GAME_STORE.offers[title] then
        GAME_STORE.offers[title] = {}
    end

    local iconType, iconData = "sprite", 0
    if offer.type == "outfit" then
        iconType, iconData = "outfit", {
            type = offer.outfitMale or 0,
            addons = offer.addons or 0,
            head = 2,
            body = 116,
            legs = 114,
            feet = 114,
            mount = 0
        }
    elseif offer.type == "pet" then
        local petInfo = getPetInfo(offer.petId)
        if petInfo then
            iconType, iconData = "outfit", {type = petInfo.clientid, addons = 0, head = 0, body = 0, legs = 0, feet = 0, mount = 0}
        end
    elseif offer.itemId then
        local clientId = ItemType(offer.itemId):getClientId()
        iconType, iconData = "item", ((clientId ~= 0) and clientId or offer.itemId)
    end

    local category = {
        title = title,
        key = key,
        description = offer.categoryDescription or "Ofertas da loja.",
        iconType = iconType,
        iconData = iconData
    }
    table.insert(GAME_STORE.categories, category)
    return category
end

-- ============================================================================
-- Envio de dados pro client (fetchBase / fetchOffers / points / history / msg)
-- ============================================================================
function gameStoreFetch(player)
    local sex = getPlayerSex(player)
    local element = getPlayerElement(player) or "all"

    local categories = {}
    for i = 1, #GAME_STORE.categories do
        table.insert(categories, GAME_STORE.categories[i])
    end

    sendStore(player, {action = "fetchBase", data = {categories = categories, url = DONATION_URL}})

    -- Sempre manda TODAS as categorias (mesmo sem oferta visivel pro player):
    -- o client usa a primeira pra montar a grade de ofertas.
    for i = 1, #GAME_STORE.categories do
        local title = GAME_STORE.categories[i].title
        local offers = {}

        for j = 1, #GAME_STORE.offers[title] do
            local offer = GAME_STORE.offers[title][j]
            if offerVisibleFor(player, offer, element, sex) then
                table.insert(offers, buildClientOffer(offer, sex))
            end
        end

        sendStore(player, {action = "fetchOffers", data = {category = title, offers = offers}})
    end

    gameStoreUpdatePoints(player)
    gameStoreUpdateHistory(player)
end

function offerVisibleFor(player, offer, element, sex)
    if offer.class ~= "all" and offer.class ~= element then
        return false
    end

    if offer.type == "outfit" then
        local lookType = (sex == PLAYERSEX_FEMALE and offer.outfitFemale or offer.outfitMale).type
        return lookType <= 0 or canPlayerWearOutfit(player, lookType, 0) ~= true
    elseif offer.type == "pet" then
        return doPlayerHasPet(player, offer.petId) ~= true
    elseif offer.type == "item" and offer.hideIfOwned then
        if offer.itemId == MOMO_ITEM then
            local slotItem = getPlayerSlotItem(player, MOMO_EQUIP_SLOT)
            return not (slotItem and slotItem.itemid == MOMO_ITEM)
        end
        return true
    end

    return true
end

function buildClientOffer(offer, sex)
    local data = {
        type = offer.type,
        title = offer.title,
        description = offer.description,
        price = offer.price
    }

    if offer.count then
        data.count = offer.count
    end
    if offer.clientId then
        data.clientId = offer.clientId
    end
    if offer.petId then
        data.petId = offer.petId
    end
    if offer.type == "outfit" then
        data.outfit = (sex == PLAYERSEX_FEMALE) and offer.outfitFemale or offer.outfitMale
    end

    return data
end

function gameStoreUpdatePoints(player)
    sendStore(player, {action = "points", data = getStorePoints(player)})
end

function gameStoreUpdateHistory(player)
    local history = {}
    local resultId = db.storeQuery(
        "SELECT `date`, `title`, `cost`, `details` FROM `shop_history` WHERE `account` = " ..
            getPlayerAccountId(player) .. " ORDER BY `id` DESC LIMIT 30"
    )

    if resultId ~= false then
        repeat
            local desc = "Bought " .. result.getDataString(resultId, "title")
            desc = desc .. " on " .. result.getDataString(resultId, "date")
            desc = desc .. " for " .. result.getDataInt(resultId, "cost") .. " points."
            table.insert(history, desc)
        until not result.next(resultId)
        result.free(resultId)
    end

    sendStore(player, {action = "history", data = history})
end

function sendStore(player, payload)
    if not isPlayer(player) then
        return
    end
    local ok, buffer = pcall(json.encode, payload)
    if ok and buffer then
        doSendPlayerExtendedOpcode(player, CODE_GAMESTORE, buffer)
    end
end

function storeErrorMsg(player, msg)
    sendStore(player, {action = "msg", data = {type = "error", msg = msg}})
end

function storeInfoMsg(player, msg, close)
    sendStore(player, {action = "msg", data = {type = "info", msg = msg, close = close == true}})
end

-- ============================================================================
-- Saldo / compra
-- ============================================================================
function getStorePoints(player)
    local points = 0
    local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. getPlayerAccountId(player))
    if resultId ~= false then
        points = result.getDataInt(resultId, "premium_points")
        result.free(resultId)
    end
    return points
end

function gameStorePurchase(player, offer)
    return doPurchase(player, player, offer, false)
end

function gameStorePurchaseGift(player, offer)
    if not offer.target or offer.target == "" then
        return storeErrorMsg(player, "Target player not found!")
    end

    local target = getPlayerByName(offer.target)
    if not target or not isPlayer(target) then
        return storeErrorMsg(player, "Target player not found!")
    end

    return doPurchase(player, target, offer, true)
end

-- payer = quem paga ; receiver = quem recebe a oferta (gift)
function doPurchase(payer, receiver, requested, isGift)
    if type(requested) ~= "table" or not requested.category then
        return storeErrorMsg(payer, "Invalid offer.")
    end

    local offers = GAME_STORE.offers[requested.category]
    if not offers then
        return storeErrorMsg(payer, "Something went wrong, try again or contact server admin [#1]!")
    end

    for i = 1, #offers do
        local offer = offers[i]
        if offer.title == requested.title and offer.price == requested.price then
            local points = getStorePoints(payer)
            if offer.price > points then
                return storeErrorMsg(payer, "You don't have enough points!")
            end

            local status = giveOffer(receiver, offer)
            if status ~= true then
                return storeErrorMsg(payer, status or "Unknown error")
            end

            db.query(
                "UPDATE `accounts` set `premium_points` = `premium_points` - " .. offer.price ..
                    " WHERE `id` = " .. getPlayerAccountId(payer)
            )
            db.query(
                "INSERT INTO `shop_history` (`account`, `player`, `date`, `title`, `cost`, `details`) VALUES ('" ..
                    getPlayerAccountId(payer) .. "', '" .. getPlayerGUID(receiver) .. "', NOW(), " ..
                    db.escapeString(offer.title) .. ", " .. offer.price .. ", " ..
                    db.escapeString(isGift and ("gift to " .. getCreatureName(receiver)) or json.encode(offer)) .. ")"
            )

            addEvent(gameStoreUpdateHistory, 1000, payer)
            addEvent(gameStoreUpdatePoints, 1000, payer)

            if isGift then
                return storeInfoMsg(payer, "You've bought " .. offer.title .. " for " .. getCreatureName(receiver) .. "!", true)
            end
            return storeInfoMsg(payer, "You've bought " .. offer.title .. "!", true)
        end
    end

    return storeErrorMsg(payer, "Something went wrong, try again or contact server admin [#4]!")
end

-- Entrega a oferta (mesmas regras da loja antiga).
function giveOffer(cid, offer)
    if offer.type == "item" then
        return giveItem(cid, offer)
    elseif offer.type == "outfit" then
        return giveOutfit(cid, offer)
    elseif offer.type == "pet" then
        return givePet(cid, offer)
    end
    return "Invalid offer type."
end

function giveItem(cid, offer)
    -- Camera / Momo Pouch vao direto pro slot proprio (nao pro backpack)
    if offer.itemId == CAMERA_ITEM or offer.itemId == MOMO_ITEM then
        local slot = (offer.itemId == CAMERA_ITEM) and CAMERA_EQUIP_SLOT or MOMO_EQUIP_SLOT
        local slotItem = getPlayerSlotItem(cid, slot)
        if slotItem and slotItem.itemid ~= 0 then
            return "You already have this item equipped."
        end
        if doPlayerAddItem(cid, offer.itemId, offer.count or 1, false, 1, slot) then
            return true
        end
        return "Could not equip the item."
    end

    if getPlayerFreeCap(cid) < getItemWeightById(offer.itemId, offer.count or 1) then
        return "You don't have enough capacity."
    end

    -- canDropOnMap = false: item comprado nao cai no chao se o inventario encher
    if doPlayerAddItem(cid, offer.itemId, offer.count or 1, false) then
        return true
    end
    return "Your inventory is full."
end

function giveOutfit(cid, offer)
    local lookType = (getPlayerSex(cid) == PLAYERSEX_FEMALE) and offer.outfitFemale or offer.outfitMale
    if lookType.type <= 0 then
        return "Invalid outfit."
    end

    if canPlayerWearOutfit(cid, lookType.type, lookType.addons or 0) == true then
        return "You already have this outfit."
    end

    if not doPlayerAddOutfit(cid, lookType.type, lookType.addons or 0) then
        return "Could not add the outfit to your character. Please contact a staff member."
    end

    local other = (getPlayerSex(cid) == PLAYERSEX_FEMALE) and offer.outfitMale or offer.outfitFemale
    if other and other.type > 0 then
        doPlayerAddOutfit(cid, other.type, other.addons or 0)
    end
    return true
end

function givePet(cid, offer)
    if not offer.petId then
        return "Invalid pet offer."
    end

    if doPlayerHasPet(cid, offer.petId) == true then
        return "You already own this pet."
    end

    if not doPlayerAddPet(cid, offer.petId) then
        return "Could not add the pet to your character. Please contact a staff member."
    end

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
        "Voce comprou o pet: (" .. tostring(offer.title) .. "). Botao direito em voce mesmo -> Pet para escolher.")
    return true
end

-- ============================================================================
-- Opcode + manutencao do saldo
-- ============================================================================
function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= CODE_GAMESTORE then
        return false
    end

    if not GAME_STORE then
        gameStoreInitialize()
        addEvent(refreshPlayersPoints, POINTS_REFRESH_TIME)
    end

    if type(buffer) ~= "string" or buffer == "" then
        return false
    end

    local status, json_data = pcall(json.decode, buffer)
    if not status or type(json_data) ~= "table" then
        return false
    end

    local action, data = json_data.action, json_data.data
    if not action or type(data) ~= "table" and action ~= "fetch" then
        return false
    end

    if action == "fetch" then
        gameStoreFetch(cid)
    elseif action == "purchase" then
        gameStorePurchase(cid, data)
    elseif action == "gift" then
        gameStorePurchaseGift(cid, data)
    end

    return true
end

function refreshPlayersPoints()
    for _, cid in ipairs(getPlayersOnline()) do
        if isPlayer(cid) then
            gameStoreUpdatePoints(cid)
        end
    end
    addEvent(refreshPlayersPoints, POINTS_REFRESH_TIME)
end
