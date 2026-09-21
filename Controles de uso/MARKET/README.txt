========================================
  MARKET - gerenciar ofertas da loja (game_store) e doacoes via Pix
========================================

COMO USAR
---------
1. Dê dois cliques em  adicionar_loja.bat
2. Escolha o que fazer:
     [I] Item    -> adiciona um item
     [O] Outfit  -> adiciona um outfit
     [P] Pet     -> adiciona um pet (lido de data\XML\pets.xml)
     [R] Remover -> remove ofertas existentes
     [S] Sair
3. Adicionar:
     Classe   -> T = todas / W = water / F = fire / A = air / E = earth
     Valor    -> preco em premium_points (pontos da conta)
     Categoria-> se digitar uma categoria nova, ela sera criada na loja
     Descricao-> opcional (Enter usa o padrao)

     OUTFIT: a categoria NAO e' perguntada. Outfit novo entra direto na
     aba "Outfits" da loja (e' o unico lugar onde outfit aparece).

     PET: a categoria tambem NAO e' perguntada (entra direto na aba "Pets").
     O BAT lista os pets definidos em data\XML\pets.xml (os comentados
     aparecem como comentario no XML e ficam de fora) e voce escolhe pelo
     numero. O nome vira o titulo da oferta na loja (pode ser trocado).

     Se em vez do numero voce digitar N, ele CADASTRA um pet novo no
     pets.xml: pergunta o clientid (o sprite do client), o nome e se exige
     premium. O id e' escolhido sozinho (o primeiro livre) e a linha
     <pet ... /> e' inserida antes de </pets>, preservando todos os
     comentarios do arquivo. Um backup e' salvo em pets.xml.bak antes de
     gravar, e o cadastro e' abortado se o XML fosse ficar invalido.
     Depois de cadastrar, use /reload pets no jogo (ou reinicie o servidor)
     para o pet existir - senao ele ate aparece na loja, mas nao funciona.
     Se o PowerShell nao estiver disponivel, ele mostra o XML e pede o petId.
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

Pet:    table.insert(ShopOffers, { category = "Pets", type = "pet", title = "Air nomad hamster", petId = 1, cost = 15, class = "all", description = "Um pet que segue voce para todo lado." })

OBS
---
- O ID do item deve ser o ID usado pelo SERVIDOR (nao o do client).
- O "petId" e' o campo "id" do pet em data\XML\pets.xml (o "clientid" do
  mesmo arquivo e' o sprite do client, e' o que aparece na pre-visualizacao).
  Pet que nao existe no pets.xml nao aparece nem funciona no jogo.
- Ao cadastrar um pet novo, o id escolhido automaticamente leva em conta
  tambem os pets comentados no XML. Assim, se voce descomentar um deles
  depois, nenhum id vai colidir.
- O clientid precisa existir no client. Sprite que nao existe faz o pet
  ser criado no servidor mas nao desenhar nada na tela.
- Recarregar os pets sem reiniciar o servidor: /reload pets no jogo.
- A classe filtra quem pode ver/comprar a oferta (elemento do personagem).
- O remover funciona linha a linha: cada oferta deve estar em UMA unica linha
  (formato gerado pelo BAT). Ofertas escritas a mao em varias linhas nao sao
  reconhecidas pela listagem.

================================================================================
PIX (botao "Buy Coins" da loja)
================================================================================
Arquivos desta pasta:
  pix_orders.sql        -> tabela de pedidos do Pix (rode uma vez no banco)
  pix_mercadopago.php   -> ponte OPCIONAL com o Mercado Pago (hospede no site;
                           e' onde entra o access token, no marcador
                           "COLOQUE A API DO MERCADO PAGO AQUI")

Configuracao minima (sem gateway, ja funciona):
  1. data/creaturescripts/scripts/game_pix.lua -> PIX_KEY (sua chave Pix),
     PIX_RECEIVER_NAME e PIX_CITY (nome e cidade do recebedor, sem acento).
  2. Rode o pix_orders.sql no banco do servidor.
  3. Reinicie o servidor: a janela do Pix aparece no botao "Doar via Pix"
     (menu da direita) e no botao "Buy Coins" da loja.

Com gateway (credito automatico):
  1. Hospede o pix_mercadopago.php junto do seu site e preencha o banco e o
     access token do Mercado Pago no proprio arquivo (marcador explicito).
  2. Aponte PIX_GATEWAY_URL no game_pix.lua para esse arquivo.
  3. No jogo, a janela do Pix passa a mostrar o botao que abre a pagina de
     pagamento; o pagamento confirmado entra sozinho na conta.

Comandos da staff (access 5):
  !pixpending                     lista os pedidos pendentes (txid, valor, minutos)
  !pixconfirm <txid> <valor>      credita o pedido - o valor digitado tem que
                                  bater com o valor do pedido (protecao contra
                                  comprovante repetido/valor menor)

Notas de seguranca:
  - Nenhuma mensagem do client marca um pedido como pago: quem credita sempre
    parte de um pedido com status 'paid' no banco (webhook, !pixconfirm ou SQL).
  - Cada conta so' tem UM Pix aberto por vez e so' gera outro a cada 10s
    (anti-spam). O client tambem so' consulta o proprio txid, 1x a cada 3s.
  - Sem gateway (modo local) o QR e' um Pix estatico e o banco nao amarra o
    txid ao pagamento: por isso o !pixconfirm exige o valor conferido no
    extrato. Com o pix_mercadopago.php configurado isso vira automatico.

Onde os coins saem dos itens comprados: accounts.premium_points (o mesmo saldo
usado pela loja e pelo site).
