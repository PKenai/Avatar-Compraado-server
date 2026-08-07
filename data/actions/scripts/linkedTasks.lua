-- Linked Tasks - acoes dos displays (46011-46057) e do bau central (46101-46105)
-- Registrado em data/actions/actions.xml

dofile(getDataDir().."lib/256-LinkedTasks.lua")

function onUse(cid, item, fromPosition, itemEx, toPosition)
  local aid = item.actionid
  if not aid or aid == 0 then
    return true
  end

  -- BAU CENTRAL: aid = 46100 + sala  (46101 a 46105)
  if aid > 46100 and aid <= 46105 then
    linkedChestOpen(cid, aid - 46100)
    return true
  end

  -- DISPLAY DE TASK: aid = 46000 + sala*10 + task  (46011 a 46057)
  if aid >= 46011 and aid <= 46057 then
    local offset = aid - 46000
    local roomId = math.floor(offset / 10)
    local taskIndex = offset % 10
    linkedDisplayClick(cid, roomId, taskIndex)
    return true
  end

  return true
end
