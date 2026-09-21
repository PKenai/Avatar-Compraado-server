-- ============================================================================
-- PIX (doacao / Buy Coins) - tabela de pedidos
-- ----------------------------------------------------------------------------
-- Rode este arquivo no banco do servidor (o mesmo do avatar.sql):
--   mysql -u USUARIO -p NOMEDOBANCO < pix_orders.sql
-- ou cole no phpMyAdmin/HeidiSQL.
--
-- O script do servidor (data/creaturescripts/scripts/game_pix.lua) usa esta
-- tabela para tudo: cria o pedido como 'pending', o gateway/staff marca como
-- 'paid' e a varredura do servidor credita os coins e muda para 'delivered'.
--
-- status: pending -> paid -> delivered   |   canceled / expired
-- ============================================================================

CREATE TABLE IF NOT EXISTS `pix_orders` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `txid` VARCHAR(32) NOT NULL,
    `account_id` INT NOT NULL,
    `player_id` INT NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `payer_name` VARCHAR(255) NOT NULL,
    `value_cents` INT NOT NULL,
    `coins` INT NOT NULL,
    `payload` TEXT NOT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'pending',
    `gateway_id` VARCHAR(64) NULL,
    `created` DATETIME NOT NULL,
    `paid_at` DATETIME NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `txid` (`txid`),
    KEY `status` (`status`),
    KEY `account_id` (`account_id`),
    KEY `created` (`created`)
) ENGINE = InnoDB;

-- Marcar um pedido como pago na mao (o servidor credita em ate 20 segundos).
-- ATENCAO: o SQL nao confere o valor recebido - confira no extrato antes:
--   UPDATE `pix_orders` SET `status` = 'paid' WHERE `txid` = 'PIX123456789';
--
-- Preferindo o comando do jogo (esse confere o valor):
--   !pixconfirm PIX123456789 50.00
--
-- Conferir o que foi creditado:
--   SELECT `txid`, `player_name`, `value_cents`, `coins`, `status`, `created`, `paid_at`
--   FROM `pix_orders` ORDER BY `id` DESC LIMIT 20;
