-- /multi NomeDaCriatura, quantidade
-- Spawna N criaturas TODAS no MESMO tile do player.
-- Ex: /multi Rotworm, 250

local MULTI_MAX = 1000 -- limite de seguranca por uso

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function onSay(cid, words, param, channel)
  local t = string.explode(param, ",")
  local monsterName = trim(t[1] or "")
  local count = tonumber(trim(t[2] or "")) or 1

  if monsterName == "" then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Uso: /multi NomeDaCriatura, quantidade   (ex: /multi Rotworm, 250)")
    return true
  end

  if count < 1 then
    count = 1
  elseif count > MULTI_MAX then
    count = MULTI_MAX
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, "Limite de " .. MULTI_MAX .. " criaturas por uso atingido.")
  end

  local pos = getCreaturePosition(cid)

  -- nao spawna dentro de zona de protecao
  local info = getTileInfo(pos)
  if info and info.protection then
    doPlayerSendCancel(cid, "Voce esta numa zona de protecao. Saia dela para spawnar criaturas.")
    return true
  end

  -- force=true: coloca TODOS os monstros no MESMO tile (empilhados),
  -- ignorando a busca por tile livre do engine.
  errors(false)
  local spawned = 0
  for i = 1, count do
    if doCreateMonster(monsterName, pos, false, true) then
      spawned = spawned + 1
    end
  end
  errors(true)

  if spawned > 0 then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Spawnado " .. spawned .. "x " .. monsterName .. " no seu tile.")
    doSendMagicEffect(pos, CONST_ME_MAGIC_RED)
  else
    doPlayerSendCancel(cid, "Criatura nao encontrada: " .. monsterName)
  end

  return true
end
