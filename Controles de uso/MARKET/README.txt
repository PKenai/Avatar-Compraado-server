========================================
  MARKET - gerenciar ofertas na loja (game_shop)
========================================

COMO USAR
---------
1. Dê dois cliques em  adicionar_loja.bat
2. Escolha o que fazer:
     [I] Item    -> adiciona um item
     [O] Outfit  -> adiciona um outfit
     [R] Remover -> remove ofertas existentes
     [S] Sair
3. Adicionar:
     Classe   -> T = todas / W = water / F = fire / A = air / E = earth
     Valor    -> preco em premium_points (pontos da conta)
     Categoria-> se digitar uma categoria nova, ela sera criada na loja
     Descricao-> opcional (Enter usa o padrao)
4. Remover:
     O BAT lista as ofertas numeradas (1, 2, 3...).
     Digite os numeros das ofertas que quer remover:
       - separados por espaco ou virgula:  2 5 7   ou   2,5,7
       - faixas:                            1-3
       - misturado:                         1-3 6 9
     Confirme com [S] para remover.
     Um backup do arquivo e salvo como shop_offers.lua.bak antes de remover.
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
- O remover funciona linha a linha: cada oferta deve estar em UMA unica linha
  (formato gerado pelo BAT). Ofertas escritas a mao em varias linhas nao sao
  reconhecidas pela listagem.
