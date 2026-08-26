-- ============================================================================
-- OFERTAS DA LOJA (game_shop)
-- ----------------------------------------------------------------------------
-- Este arquivo e a "fonte da verdade" das ofertas. Ele e lido pelo
-- data/creaturescripts/scripts/store.lua sempre que um player abre a loja.
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

-- Categoria: Use
table.insert(ShopOffers, { category = "Use", type = "item", title = "Pergaminho da experiência", itemId = 18867, count = 1, cost = 10, class = "all", description = "Aumenta seu ganho de experiência por 45 minutos!" })
table.insert(ShopOffers, { category = "Use", type = "item", title = "Pergaminho da benção", itemId = 18866, count = 1, cost = 5, class = "all", description = "Concede a benção: perca 50% menos experiência na próxima morte." })
table.insert(ShopOffers, { category = "Use", type = "item", title = "Pergaminho do despertar", itemId = 18865, count = 1, cost = 15, class = "all", description = "Desperta o estado Avatar por 5 minutos." })

-- Categoria: Outfits
table.insert(ShopOffers, { category = "Others", type = "item", title = "Camera", itemId = 18432, count = 1, cost = 25, class = "all", description = "Use it to turn on or off your channel." })
table.insert(ShopOffers, { category = "Others", type = "item", title = "Momo Pouch", itemId = 18435, count = 1, cost = 25, class = "all", hideIfOwned = true, description = "A special pouch that can only be equipped in its own slot." })
table.insert(ShopOffers, { category = "Outfit", type = "outfit", title = "Water avatar state", outfitMale = 1222, outfitFemale = 1222, addons = 0, cost = 10, class = "water", description = "Feel the avatar state" })
table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Earth avatar state", outfitMale = 1223, outfitFemale = 1223, addons = 0, cost = 10, class = "earth", description = "Feel the earth avatar state" })
table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Fire avatar state", outfitMale = 1225, outfitFemale = 1225, addons = 0, cost = 10, class = "fire", description = "Feel the fire avatar state" })
table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Air avatar state", outfitMale = 1226, outfitFemale = 1226, addons = 0, cost = 10, class = "air", description = "Feel the air avatar state" })
table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Full Avatar State", outfitMale = 1224, outfitFemale = 1224, addons = 0, cost = 100, class = "all", description = "Feel the power of becoming an true avatar" })
table.insert(ShopOffers, { category = "Others", type = "item", title = "Bender Scroll", itemId = 13848, count = 1, cost = 2, class = "all", description = "Entregue a um mestre de dobra para aprender a dobra desejada" })
table.insert(ShopOffers, { category = "Others", type = "item", title = "Agua milagrosa do oasis", itemId = 18999, count = 1, cost = 35, class = "water", description = "Uma fonte infinita de agua para dobradores. Nunca seca!" })
