-- ============================================================
--  Market / Auction System - SQL Schema (MySQL)
--  Execute this once against the `avatar` database.
--  The server also creates these automatically on startup
--  (see data/globalevents/scripts/market.lua), so this file
--  is only needed for manual / fresh installs.
-- ============================================================

CREATE TABLE IF NOT EXISTS `auction_system` (
  `id` int NOT NULL AUTO_INCREMENT,
  `player` int DEFAULT NULL,
  `item_id` int DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `count` int DEFAULT NULL,
  `desc` varchar(255) DEFAULT NULL,
  `cost` bigint DEFAULT NULL,
  `date` int DEFAULT NULL,
  `expired` smallint DEFAULT NULL,
  `world_id` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `tier` smallint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Tier do item da oferta (0 = item sem tier). Bancos antigos: o servidor adiciona
-- a coluna sozinho no startup (data/globalevents/scripts/market.lua).

-- ------------------------------------------------------------
--  Column used to pay sellers (balance is claimed via
--  data/creaturescripts/scripts/idle.lua marketCheck).
--  If it already exists this ALTER will fail - that is fine.
-- ------------------------------------------------------------
ALTER TABLE `players`
  ADD COLUMN `auction_balance` bigint NOT NULL DEFAULT 0;
