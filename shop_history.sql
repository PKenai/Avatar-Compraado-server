-- Tabela obrigatoria para o sistema game_shop (client/server).
-- Rode este script no banco do servidor (avatar) antes de usar a loja.

CREATE TABLE IF NOT EXISTS `shop_history` (
  `id` int(11) NOT NULL,
  `account` int(11) NOT NULL,
  `player` int(11) NOT NULL,
  `date` datetime NOT NULL,
  `title` varchar(100) NOT NULL,
  `cost` int(11) NOT NULL,
  `details` varchar(500) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `shop_history`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `shop_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
