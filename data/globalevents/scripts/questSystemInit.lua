-- Quest System - carrega as quests do XML ao ligar o server
-- Registrado em data/globalevents/globalevents.xml (type="startup")

dofile(getDataDir() .. "lib/questSystemLib.lua")

function onStartup()
    qsLoadQuestsFromXML()
    return true
end
