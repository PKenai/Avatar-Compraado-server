========================================
  MARKET - adicionar ofertas na loja (game_shop)
========================================

COMO USAR
---------
1. Dê dois cliques em  adicionar_loja.bat
2. Escolha o que adicionar:
     [I] Item    -> digite o ID do item (server), nome e quantidade
     [O] Outfit  -> digite os IDs dos outfits masculino/feminino (e addons 0-3)
     [S] Sair
3. Informe:
     Classe   -> T = todas / W = water / F = fire / A = air / E = earth
     Valor    -> preco em premium_points (pontos da conta)
     Categoria-> se digitar uma categoria nova, ela sera criada na loja
     Descricao-> opcional (Enter usa o padrao)
4. Pode adicionar quantas ofertas quiser na mesma sessao.
5. Ao terminar, REINICIE O SERVIDOR para as ofertas aparecerem.

ONDE FICAM AS OFERTAS
---------------------
Cada oferta e gravada em:  data\lib\shop_offers.lua
Voce pode editar esse arquivo na mao tambem (mesmo formato).

EXEMPLOS DE LINHA
-----------------
Item:   table.insert(ShopOffers, { category = "Itens", type = "item", title = "Crystal Coin", itemId = 2160, count = 1, cost = 1, class = "all", description = "1 crystal coin." })

Outfit: table.insert(ShopOffers, { category = "Outfits", type = "outfit", title = "Warrior Outfit", outfitMale = 128, outfitFemale = 136, addons = 3, cost = 10, class = "all", description = "Outfit completo com addons." })

OBS
---
- O ID do item deve ser o ID usado pelo SERVIDOR (nao o do client).
- A classe filtra quem pode ver/comprar a oferta (elemento do personagem).
