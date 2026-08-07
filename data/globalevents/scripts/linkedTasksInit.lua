-- Linked Tasks - spawn dos displays e baus no mapa
-- Registrado em data/globalevents/globalevents.xml (type="start")

dofile(getDataDir().."lib/256-LinkedTasks.lua")

function onStartup()
  spawnLinkedTaskItems()
  return true
end
