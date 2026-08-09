-- ============================================================================
-- OFERTAS DA LOJA (game_shop)
-- ----------------------------------------------------------------------------
-- Este arquivo e a "fonte da verdade" das ofertas. Ele e lido pelo
-- data/creaturescripts/scripts/shop.lua sempre que um player abre a loja.
--
-- Voce pode editar na mao ou usar o BAT:  Controles de uso\MARKET\adicionar_loja.bat
--
-- Campos de cada oferta:
--   category    = nome da categoria (se nao existir, a loja cria)
--   type        = "item" ou "outfit"
--   title       = nome exibido na loja
--   cost        = preco em premium_points
--   class       = "all" | "fire" | "water" | "air" | "earth"  (elemento/classe)
--   description = texto exibido ao clicar em "i" na oferta
--
--   Para ITEM:   itemId = id do item (server), count = quantidade
--   Para OUTFIT: outfitMale = id do outfit masculino, outfitFemale = id do
--                feminino, addons = 0 a 3
-- ============================================================================

ShopOffers = ShopOffers or {}

-- Categoria: Items
table.insert(ShopOffers, { category = "Items", type = "item", title = "Crystal Coin", itemId = 2160, count = 1, cost = 1, class = "all", description = "You will receive 1 crystal coins." })
table.insert(ShopOffers, { category = "Items", type = "item", title = "Demon Helmet", itemId = 2493, count = 1, cost = 11, class = "all", description = "A very rare helmet." })

-- Categoria: Outfits
table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Warrior Outfit", outfitMale = 128, outfitFemale = 136, addons = 3, cost = 10, class = "all", description = "Full Warrior Outfit with addons." })
table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Summoner Outfit", outfitMale = 133, outfitFemale = 138, addons = 3, cost = 15, class = "all", description = "Full Summoner Outfit with addons." })
table.insert(ShopOffers, { category = "Others", type = "item", title = "Camera", itemId = 18432, count = 1, cost = 25, class = "all", description = "Use it to turn on or off your channel." })
