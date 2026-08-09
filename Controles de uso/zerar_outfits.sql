-- ============================================================
-- ZERA OS OUTFITS DE TODOS OS PLAYERS, DEIXA SÓ O APPRENTICE
-- Banco: avatar  |  Rodar com o servidor DESLIGADO (senão o save
-- do login recria os outfits de quem estiver online)
-- ============================================================

-- 1) Apaga todos os outfits comprados/concedidos guardados no
--    storage reservado do player:
--      10001001-10001500 = range antigo (formato lookType)
--      10001501-10002000 = range atual  (formato outfitId)
DELETE FROM `player_storage`
 WHERE `key` BETWEEN 10001001 AND 10002000;

-- 2) Concede o Apprentice (addon 3) do elemento de cada player.
--    Elemento = vocação: 1 fogo, 2 água, 3 ar, 4 terra.
--    Valor = (outfitId << 16) | addons
--      fogo -> id 1  = 65539
--      água -> id 6  = 393219
--      ar   -> id 11 = 720899
--      terra-> id 16 = 1048579
INSERT INTO `player_storage` (`player_id`, `key`, `value`)
SELECT p.`id`, 10001501,
       ((CASE p.`vocation`
             WHEN 2 THEN 6
             WHEN 3 THEN 11
             WHEN 4 THEN 16
             ELSE 1 END) << 16) | 3
  FROM `players` p
 WHERE p.`deleted` = 0
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

-- 3) Todo mundo passa a VESTIR o Apprentice do seu elemento.
--    lookType por sexo: 0 = feminino, 1 = masculino
--      fogo -> 1020 / 1025
--      água -> 1040 / 1045
--      ar   -> 1060 / 1065
--      terra-> 1080 / 1085
UPDATE `players` SET
  `looktype` = CASE
    WHEN `vocation` = 2 THEN IF(`sex` = 0, 1040, 1045)
    WHEN `vocation` = 3 THEN IF(`sex` = 0, 1060, 1065)
    WHEN `vocation` = 4 THEN IF(`sex` = 0, 1080, 1085)
    ELSE IF(`sex` = 0, 1020, 1025)
  END,
  `lookaddons` = 0
WHERE `deleted` = 0;
