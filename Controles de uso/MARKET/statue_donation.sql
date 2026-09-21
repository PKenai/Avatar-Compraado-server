-- ============================================================================
--  STATUE DONATION - tabela de estado (data/lib/statueDonation.lua)
-- ----------------------------------------------------------------------------
--  Uma linha por chave:
--    fire / water / air / earth -> pool de 150.000 + bonus_until (12h)
--    exp                        -> pool de 350.000 + bonus_until (8h, servidor todo)
--    potion                     -> pool de 400.000 + bonus_until (8h, servidor todo)
--
--  O pool e' acumulativo: as doacoes vao enchendo e a bencao ativa quando o
--  pool bate a meta. Tudo isto e' gravado a cada mudanca, entao pool acumulado
--  e bencao ativa (com o tempo que falta) sobrevivem a save/restart do servidor.
--
--  bonus_until = timestamp unix (0 = inativo)
--
--  Rode uma vez (a lib tambem tenta CREATE TABLE IF NOT EXISTS no boot, mas
--  assim voce nao depende de permissao de CREATE do usuario do banco):
--
--    mysql -u root -p avatar < statue_donation.sql
--
--  (troque "avatar" pelo nome do seu banco)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `statue_donation` (
  `name` VARCHAR(16) NOT NULL,
  `pool` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `bonus_until` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `updated` BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`name`)
) ENGINE = InnoDB;

-- Linhas iniciais (idempotente: nao zera pool que ja' existe)
INSERT IGNORE INTO `statue_donation` (`name`, `pool`, `bonus_until`, `updated`) VALUES
  ('fire',  0, 0, 0),
  ('water', 0, 0, 0),
  ('air',   0, 0, 0),
  ('earth', 0, 0, 0),
  ('exp',   0, 0, 0),
  ('potion', 0, 0, 0);

-- A antiga aba "Skill" virou "Potion" (mesmo slot/buffId): a linha velha nao
-- serve pra nada e a lib ignora. Apague se ela existir (idempotente).
DELETE FROM `statue_donation` WHERE `name` = 'skill';
