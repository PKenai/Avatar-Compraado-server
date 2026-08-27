-- ============================================================
-- Tabela: pedra_elemental
-- Armazena a quantidade de pontos obtidos pelo player
-- através das pedras elementais (dropadas no Baú elemental).
-- Máximo de 50 pontos por player. Zerado no reset de atributos.
-- ============================================================

CREATE TABLE IF NOT EXISTS `pedra_elemental` (
  `player_id` INT(11) UNSIGNED NOT NULL,
  `pontos` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trigger: ao zerar pontos no reset, atualiza a tabela
-- (pode ser chamado diretamente pelo script Lua do reset)
-- Exemplo de uso no reset de atributos:
--   UPDATE pedra_elemental SET pontos = 0 WHERE player_id = <GUID>;
