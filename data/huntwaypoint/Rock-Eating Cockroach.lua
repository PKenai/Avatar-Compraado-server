-- ==========================================================
-- HUNT WAYPOINT - configuracao de uma hunt
-- ----------------------------------------------------------
-- O NOME DESTE ARQUIVO e' o nome do monstro em monsters.xml:
-- "Elephant.lua" -> hunt "Elephant". Variacoes de escrita
-- (hifen/underscore/espaco/acento, maiusculas) sao toleradas.
--
-- Name, sprite (looktype) e exp sao buscados automaticamente do
-- monstro no servidor. O unico campo obrigatorio e' a Location
-- (copie do mapa e cole).
--
-- Campos opcionais que sobrescrevem o automatico / completam o card:
--   ["Creature exp"] = 1500            (exp exibida)
--   ["Recomended level"] = "25-35"     (faixa de level exibida no card)
-- ==========================================================
HuntWaypoint.register({
  ["Location"] = {x = 325, y = 324, z = 7},
  ["Recomended level"] = "250-300",   -- ajuste a faixa do seu servidor
})
