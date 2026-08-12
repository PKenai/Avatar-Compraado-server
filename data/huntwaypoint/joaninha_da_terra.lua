-- ==========================================================
-- HUNT WAYPOINT - configuração de uma hunt
-- ----------------------------------------------------------
-- Duplique este arquivo e edite os valores para adicionar
-- uma nova hunt. Reinicie o servidor (ou recarregue as libs)
-- para aplicar.
--
--   Creature name       = nome da hunt (aparece na grade)
--   Creature apparence  = looktype da sprite no dat
--   Creature exp        = exp média (exibida no client)
--   Recomended level    = level recomendado (exibido no client)
--   Location            = X,Y,Z do alvo do caminho
-- ==========================================================
HuntWaypoint.register({
  ["Creature name"] = "Joaninha da terra",
  ["Creature apparence"] = 1246,
  ["Creature exp"] = 1025,
  ["Recomended level"] = "25-35",
  ["Location"] = "{x = 425, y = 418, z = 7}",
})
