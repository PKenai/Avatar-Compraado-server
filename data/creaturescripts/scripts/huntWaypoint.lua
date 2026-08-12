-- Hunt Waypoint - evento de extended opcode
dofile(getDataDir() .. "lib/huntWaypoint.lua")
HuntWaypoint.loadConfigs()

function onExtendedOpcode(cid, opcode, buffer)
  if opcode ~= HuntWaypoint.opcode then
    return true
  end

  if buffer == "list" then
    -- recarrega na hora: pega arquivos novos e o looktype/exp dos monstros
    -- (no boot os monstros ainda nao carregaram quando as configs rodam)
    HuntWaypoint.loadConfigs()
    HuntWaypoint.sendList(cid)
  elseif string.sub(buffer, 1, 5) == "path:" then
    local name = string.sub(buffer, 6)
    if name ~= "" then
      HuntWaypoint.sendPath(cid, name)
    end
  end

  return true
end
