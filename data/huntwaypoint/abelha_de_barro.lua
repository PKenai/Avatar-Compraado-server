-- ==========================================================
-- HUNT WAYPOINT - configuração de uma hunt
-- ----------------------------------------------------------
-- O NOME DESTE ARQUIVO é o nome da criatura: "abelha_de_barro.lua"
-- vira a hunt "Abelha de barro" (hífens/underscores = espaços).
--
-- Name, sprite (looktype) e exp são buscados automaticamente do
-- monstro no servidor. O único campo obrigatório é a Location
-- (copie do mapa e cole).
--
-- Campos opcionais que sobrescrevem o automático / completam o card:
--   ["Creature exp"] = 1500            (exp exibida)
--   ["Recomended level"] = "25-35"     (faixa de level exibida no card)
-- ==========================================================
HuntWaypoint.register({
  ["Location"] = {x = 448, y = 336, z = 7},
  ["Recomended level"] = "30-40",   -- ajuste a faixa do seu servidor
})
